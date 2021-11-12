/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageScriptsAndResourcesViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGPayloadDataSource.h"



#import "PKGFilesEmptySelectionInspectorViewController.h"
#import "PKGFilesSelectionInspectorViewController.h"

#import "PKGScriptViewController.h"

#import "PKGTellerView.h"

#import "PKGPackageScriptsStackView.h"


#import "NSOutlineView+Selection.h"

@interface PKGPackageScriptsAndResourcesViewController ()
{
	IBOutlet PKGPackageScriptsStackView * _installationScriptView;
	
	IBOutlet NSView * _hierarchyPlaceHolderView;
	IBOutlet NSView * _inspectorPlaceHolderView;
	
	PKGScriptViewController * _preInstallationScriptViewController;
	
	PKGScriptViewController * _postInstallationScriptViewController;
	
	PKGViewController *_emptySelectionInspectorViewController;
	PKGFilesSelectionInspectorViewController * _selectionInspectorViewController;
	
	PKGViewController *_currentInspectorViewController;
	
	PKGPayloadDataSource * _dataSource;
}

	@property (readwrite) PKGFilesHierarchyViewController * additionalResourcesHierarchyViewController;

- (PKGFilePath *)preInstallationScriptPath_safe;
- (PKGFilePath *)postInstallationScriptPath_safe;

// Hierarchy Menu

- (IBAction)addFiles:(id)sender;
- (IBAction)addNewFolder:(id)sender;
- (IBAction)expandOneLevel:(id)sender;
- (IBAction)expand:(id)sender;
- (IBAction)expandAll:(id)sender;
- (IBAction)contract:(id)sender;

// Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPackageScriptsAndResourcesViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		_dataSource=[PKGPayloadDataSource new];
		_dataSource.editableRootNodes=YES;
		_dataSource.filePathConverter=self.filePathConverter;
        _dataSource.keysReplacer=self;
        
		_additionalResourcesHierarchyViewController=[[PKGFilesHierarchyViewController alloc] initWithDocument:self.document];
		
		_additionalResourcesHierarchyViewController.label=NSLocalizedString(@"Additional Resources", @"");
		_additionalResourcesHierarchyViewController.informationLabel=NSLocalizedString(@"These resources can be used by the pre and post-installation scripts.", @"");
		_additionalResourcesHierarchyViewController.hierarchyDataSource=_dataSource;
		_additionalResourcesHierarchyViewController.disclosedStateKey=@"ui.package.additionalResources.disclosed";
		_additionalResourcesHierarchyViewController.selectionStateKey=@"ui.package.additionalResources.selection";
	}
	
	return self;
}

- (NSString *)nibName
{
	return @"PKGPackageScriptsAndResourcesViewController";
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
    // Pre-installation
	
	_preInstallationScriptViewController=[[PKGScriptViewController alloc] initWithDocument:self.document];
	_preInstallationScriptViewController.label=NSLocalizedString(@"Pre-installation", @"");
	
	[_installationScriptView addView:_preInstallationScriptViewController.view];
	
	// Post-installation
	
	_postInstallationScriptViewController=[[PKGScriptViewController alloc] initWithDocument:self.document];
	_postInstallationScriptViewController.label=NSLocalizedString(@"Post-installation", @"");
	
	[_installationScriptView addView:_postInstallationScriptViewController.view];
	
	// Files Hierarchy
	
	_additionalResourcesHierarchyViewController.view.frame=_hierarchyPlaceHolderView.bounds;
	
	[_hierarchyPlaceHolderView addSubview:_additionalResourcesHierarchyViewController.view];
	
	_dataSource.delegate=_additionalResourcesHierarchyViewController;
}

#pragma mark -

- (NSUInteger)tag
{
	return PKGPreferencesGeneralPackageProjectPaneScriptsAndResources;
}

- (void)setScriptsAndResources:(PKGPackageScriptsAndResources *)inScriptsAndResources
{
	if (_scriptsAndResources!=inScriptsAndResources)
	{
		_scriptsAndResources=inScriptsAndResources;
		
		_preInstallationScriptViewController.installationScriptPath=[self preInstallationScriptPath_safe];
		_postInstallationScriptViewController.installationScriptPath=[self postInstallationScriptPath_safe];
		
		_dataSource.rootNodes=self.scriptsAndResources.resourcesForest.rootNodes.array;
	}
}

- (PKGFilePath *)preInstallationScriptPath_safe
{
	if (self.scriptsAndResources==nil)
		return nil;
	
	if (self.scriptsAndResources.preInstallationScriptPath==nil)
	{
		PKGFilePath * tFilePath=[PKGFilePath new];
		
		tFilePath.type=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		self.scriptsAndResources.preInstallationScriptPath=tFilePath;
	}
	
	return self.scriptsAndResources.preInstallationScriptPath;
}

- (PKGFilePath *)postInstallationScriptPath_safe
{
	if (self.scriptsAndResources==nil)
		return nil;
	
	if (self.scriptsAndResources.postInstallationScriptPath==nil)
	{
		PKGFilePath * tFilePath=[PKGFilePath new];
		
		tFilePath.type=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		self.scriptsAndResources.postInstallationScriptPath=tFilePath;
	}
	
	return self.scriptsAndResources.postInstallationScriptPath;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_preInstallationScriptViewController.installationScriptPath=[self preInstallationScriptPath_safe];
	_postInstallationScriptViewController.installationScriptPath=[self postInstallationScriptPath_safe];
	
	[_preInstallationScriptViewController WB_viewWillAppear];
	[_postInstallationScriptViewController WB_viewWillAppear];
	[_additionalResourcesHierarchyViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	//[self.view.window makeFirstResponder:_additionalResourcesHierarchyViewController.outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHierarchySelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_additionalResourcesHierarchyViewController.outlineView];
	
	[_preInstallationScriptViewController WB_viewDidAppear];
	[_postInstallationScriptViewController WB_viewDidAppear];
	[_additionalResourcesHierarchyViewController WB_viewDidAppear];
	
	[self fileHierarchySelectionDidChange:[NSNotification notificationWithName:NSOutlineViewSelectionDidChangeNotification object:_additionalResourcesHierarchyViewController.outlineView]];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_preInstallationScriptViewController WB_viewWillDisappear];
	[_postInstallationScriptViewController WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:nil];
	
	[_additionalResourcesHierarchyViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_preInstallationScriptViewController WB_viewDidDisappear];
	[_postInstallationScriptViewController WB_viewDidDisappear];
	[_additionalResourcesHierarchyViewController WB_viewDidDisappear];
}

#pragma mark -

- (IBAction)addFiles:(id)sender
{
	[_additionalResourcesHierarchyViewController addFiles:sender];
}

- (IBAction)addNewFolder:(id)sender
{
	[_additionalResourcesHierarchyViewController addNewFolder:sender];
}

- (IBAction)expandOneLevel:(id)sender
{
	[_additionalResourcesHierarchyViewController expandOneLevel:sender];
}

- (IBAction)expand:(id)sender
{
	[_additionalResourcesHierarchyViewController expand:sender];
}

- (IBAction)expandAll:(id)sender
{
	[_additionalResourcesHierarchyViewController expandAll:sender];
}

- (IBAction)contract:(id)sender
{
	[_additionalResourcesHierarchyViewController contract:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(addFiles:) ||
		tAction==@selector(addNewFolder:) ||
		tAction==@selector(expandOneLevel:) ||
		tAction==@selector(expand:) ||
		tAction==@selector(expandAll:) ||
		tAction==@selector(contract:))
	{
		return [_additionalResourcesHierarchyViewController validateMenuItem:inMenuItem];
	}
	
	return YES;
}

#pragma mark - Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification
{
	NSOutlineView * tOutlineView=_additionalResourcesHierarchyViewController.outlineView;
	
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
			_selectionInspectorViewController=[[PKGFilesSelectionInspectorViewController alloc] initWithDocument:self.document];
			_selectionInspectorViewController.delegate=_additionalResourcesHierarchyViewController;
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
