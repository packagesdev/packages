/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionRequirementsAndResourcesViewController.h"

#import "PKGDistributionRequirementSourceListDataSource.h"
#import "PKGPayloadDataSource.h"

#import "PKGDistributionRequirementsViewController.h"
#import "PKGFilesHierarchyViewController.h"

#import "PKGFilesEmptySelectionInspectorViewController.h"
#import "PKGFilesSelectionInspectorViewController.h"

#import "NSOutlineView+Selection.h"

#import "PKGApplicationPreferences.h"

@interface PKGDistributionRequirementsAndResourcesViewController ()
{
	IBOutlet NSButton * _rootVolumeOnlyCheckbox;
	
	IBOutlet NSView * _requirementsPlaceHolderView;
	
	IBOutlet NSView * _hierarchyPlaceHolderView;
	IBOutlet NSView * _inspectorPlaceHolderView;
	
	PKGDistributionRequirementsViewController * _requirementsViewController;
	
	PKGFilesHierarchyViewController * _filesHierarchyViewController;
	
	PKGViewController *_emptySelectionInspectorViewController;
	PKGFilesSelectionInspectorViewController * _selectionInspectorViewController;
	
	PKGViewController *_currentInspectorViewController;
	
	PKGDistributionRequirementSourceListDataSource * _requirementsSourceListDataSource;
	PKGPayloadDataSource * _resourcesDataSource;
}

- (IBAction)switchRootVolumeOnlyRequirement:(id)sender;

// Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification;

@end

@implementation PKGDistributionRequirementsAndResourcesViewController


- (NSUInteger)tag
{
	return PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources;
}

- (void)WB_viewDidLoad
{
    [super WB_viewDidLoad];
	
	// A COMPLETER
	
	// Requirements
	
	_requirementsViewController=[[PKGDistributionRequirementsViewController alloc] initWithDocument:self.document];
	
	_requirementsViewController.view.frame=_requirementsPlaceHolderView.bounds;
	
	[_requirementsPlaceHolderView addSubview:_requirementsViewController.view];
	
	// Files Hierarchy
	
	_filesHierarchyViewController=[PKGFilesHierarchyViewController new];
	
	_filesHierarchyViewController.label=NSLocalizedString(@"Additional Resources", @"");
	_filesHierarchyViewController.informationLabel=NSLocalizedString(@"These resources can be used by the above requirements and scripts \nor the requirements for the choices of the Installation Type step.", @"");
	
	_filesHierarchyViewController.view.frame=_hierarchyPlaceHolderView.bounds;
	
	[_hierarchyPlaceHolderView addSubview:_filesHierarchyViewController.view];
	
	
}

#pragma mark -

- (void)setRequirementsAndResources:(PKGDistributionProjectRequirementsAndResources *)inRequirementsAndResources
{
	if (_requirementsAndResources!=inRequirementsAndResources)
	{
		_requirementsAndResources=inRequirementsAndResources;
		
		_requirementsSourceListDataSource=[PKGDistributionRequirementSourceListDataSource new];
		_requirementsSourceListDataSource.requirements=self.requirementsAndResources.requirements;
		_requirementsSourceListDataSource.delegate=_requirementsViewController;
		_requirementsSourceListDataSource.filePathConverter=self.filePathConverter;
		
		_resourcesDataSource=[PKGPayloadDataSource new];
		_resourcesDataSource.editableRootNodes=YES;
		_resourcesDataSource.rootNodes=self.requirementsAndResources.resourcesForest.rootNodes;
		_resourcesDataSource.delegate=_filesHierarchyViewController;
		_resourcesDataSource.filePathConverter=self.filePathConverter;
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_requirementsViewController.dataSource=_requirementsSourceListDataSource;
	
	[_requirementsViewController WB_viewWillAppear];
	
	_filesHierarchyViewController.hierarchyDataSource=_resourcesDataSource;
	if (_resourcesDataSource!=nil)
		_resourcesDataSource.delegate=_filesHierarchyViewController;
	
	[_filesHierarchyViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Requirements
	
	_rootVolumeOnlyCheckbox.state=(self.requirementsAndResources.rootVolumeOnlyRequirement==YES) ? NSOnState : NSOffState;
	
	[_requirementsViewController WB_viewDidAppear];
	
	// Resources
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHierarchySelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView];
	
	[_filesHierarchyViewController WB_viewDidAppear];
	
	[self fileHierarchySelectionDidChange:[NSNotification notificationWithName:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView]];

	//[self.view.window makeFirstResponder:_requirementsViewController.outlineView];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_requirementsViewController WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:nil];
	
	[_filesHierarchyViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_requirementsViewController WB_viewDidDisappear];
	
	[_filesHierarchyViewController WB_viewDidDisappear];
}

#pragma mark -

- (IBAction)switchRootVolumeOnlyRequirement:(NSButton *)sender
{
	BOOL tNewValue=(sender.state==NSOnState);
	
	if (self.requirementsAndResources.rootVolumeOnlyRequirement!=tNewValue)
	{
		self.requirementsAndResources.rootVolumeOnlyRequirement=tNewValue;
		
		[self noteDocumentHasChanged];
	}
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
			_selectionInspectorViewController=[[PKGFilesSelectionInspectorViewController alloc] initWithDocument:self.document];
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
