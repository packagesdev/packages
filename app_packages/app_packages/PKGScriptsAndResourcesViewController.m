/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGScriptsAndResourcesViewController.h"

#import "PKGPayloadDataSource.h"

#import "PKGFilesHierarchyViewController.h"

#import "PKGFilesEmptySelectionInspectorViewController.h"
#import "PKGFilesSelectionInspectorViewController.h"

#import "PKGScriptViewController.h"

#import "PKGTellerView.h"

#import "PKGPackageScriptsStackView.h"


#import "NSOutlineView+Selection.h"

@interface PKGScriptsAndResourcesViewController ()
{
	IBOutlet PKGPackageScriptsStackView * _installationScriptView;
	
	IBOutlet NSView * _hierarchyPlaceHolderView;
	IBOutlet NSView * _inspectorPlaceHolderView;
	
	PKGScriptViewController * _preInstallationScriptViewController;
	
	PKGScriptViewController * _postInstallationScriptViewController;
	
	PKGFilesHierarchyViewController * _filesHierarchyViewController;
	
	PKGViewController *_emptySelectionInspectorViewController;
	PKGFilesSelectionInspectorViewController * _selectionInspectorViewController;
	
	PKGViewController *_currentInspectorViewController;
	
	PKGPayloadDataSource * _dataSource;
}

// Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification;

@end

@implementation PKGScriptsAndResourcesViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	_dataSource=[PKGPayloadDataSource new];
	_dataSource.editableRootNodes=YES;
	
	return self;
}

- (NSString *)nibName
{
	return @"PKGScriptsAndResourcesViewController";
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
    // Pre-installation
	
	_preInstallationScriptViewController=[PKGScriptViewController new];
	_preInstallationScriptViewController.label=NSLocalizedString(@"Pre-installation", @"");
	
	[_installationScriptView addView:_preInstallationScriptViewController.view];
	
	// Post-installation
	
	_postInstallationScriptViewController=[PKGScriptViewController new];
	_postInstallationScriptViewController.label=NSLocalizedString(@"Post-installation", @"");
	
	[_installationScriptView addView:_postInstallationScriptViewController.view];
	
	// Files Hierarchy
	
	_filesHierarchyViewController=[PKGFilesHierarchyViewController new];
	
	_filesHierarchyViewController.label=NSLocalizedString(@"Additional Resources", @"");
	_filesHierarchyViewController.informationLabel=NSLocalizedString(@"These resources can be used by the pre and post-installation scripts.", @"");
	_filesHierarchyViewController.hierarchyDataSource=_dataSource;
	
	_filesHierarchyViewController.view.frame=_hierarchyPlaceHolderView.bounds;
	
	[_hierarchyPlaceHolderView addSubview:_filesHierarchyViewController.view];
	
	_dataSource.delegate=_filesHierarchyViewController;
}

#pragma mark -

- (void)setScriptsAndResources:(PKGPackageScriptsAndResources *)inScriptsAndResources
{
	if (_scriptsAndResources!=inScriptsAndResources)
	{
		_scriptsAndResources=inScriptsAndResources;
		
		_preInstallationScriptViewController.installationScriptPath=self.scriptsAndResources.preInstallationScriptPath;
		_postInstallationScriptViewController.installationScriptPath=self.scriptsAndResources.postInstallationScriptPath;
		
		_dataSource.rootNodes=self.scriptsAndResources.resourcesForest.rootNodes;
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_preInstallationScriptViewController.installationScriptPath=self.scriptsAndResources.preInstallationScriptPath;
	_postInstallationScriptViewController.installationScriptPath=self.scriptsAndResources.postInstallationScriptPath;
	
	[_preInstallationScriptViewController WB_viewWillAppear];
	[_postInstallationScriptViewController WB_viewWillAppear];
	[_filesHierarchyViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self.view.window makeFirstResponder:_filesHierarchyViewController.outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHierarchySelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView];
	
	_dataSource.filePathConverter=self.filePathConverter;
	
	[_preInstallationScriptViewController WB_viewDidAppear];
	[_postInstallationScriptViewController WB_viewDidAppear];
	[_filesHierarchyViewController WB_viewDidAppear];
	
	[self fileHierarchySelectionDidChange:[NSNotification notificationWithName:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView]];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_preInstallationScriptViewController WB_viewWillDisappear];
	[_postInstallationScriptViewController WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:nil];
	
	[_filesHierarchyViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_preInstallationScriptViewController WB_viewDidDisappear];
	[_postInstallationScriptViewController WB_viewDidDisappear];
	[_filesHierarchyViewController WB_viewDidDisappear];
}

#pragma mark - Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification
{
	NSOutlineView * tOutlineView=_filesHierarchyViewController.outlineView;
	
	if (inNotification.object!=tOutlineView)
		return;
	
	NSUInteger tNumberOfSelectedRows=tOutlineView.numberOfSelectedRows;
	
	// Inspector
	
	if (tNumberOfSelectedRows==0)
	{
		if (_emptySelectionInspectorViewController==nil)
			_emptySelectionInspectorViewController=[PKGFilesEmptySelectionInspectorViewController new];
		
		if (_currentInspectorViewController!=_emptySelectionInspectorViewController)
		{
			[_currentInspectorViewController WB_viewWillDisappear];
			
			[_currentInspectorViewController.view removeFromSuperview];
			
			[_currentInspectorViewController WB_viewDidDisappear];
			
			_currentInspectorViewController=_emptySelectionInspectorViewController;
			
			_currentInspectorViewController.view.frame=_inspectorPlaceHolderView.bounds;
			
			[_currentInspectorViewController WB_viewWillAppear];
			
			[_inspectorPlaceHolderView addSubview:_currentInspectorViewController.view];
			
			[_currentInspectorViewController WB_viewDidAppear];
		}
	}
	else
	{
		if (_selectionInspectorViewController==nil)
		{
			_selectionInspectorViewController=[PKGFilesSelectionInspectorViewController new];
			_selectionInspectorViewController.delegate=_filesHierarchyViewController;
		}
		
		if (_currentInspectorViewController!=_selectionInspectorViewController)
		{
			[_currentInspectorViewController WB_viewWillDisappear];
			
			[_currentInspectorViewController.view removeFromSuperview];
			
			[_currentInspectorViewController WB_viewDidDisappear];
			
			
			_currentInspectorViewController=_selectionInspectorViewController;
			
			_currentInspectorViewController.view.frame=_inspectorPlaceHolderView.bounds;
			
			[_currentInspectorViewController WB_viewWillAppear];
			
			[_inspectorPlaceHolderView addSubview:_currentInspectorViewController.view];
			
			[_currentInspectorViewController WB_viewDidAppear];
		}
		
		_selectionInspectorViewController.selectedItems=[tOutlineView WB_selectedItems];
	}
	
	// A COMPLETER
}

@end
