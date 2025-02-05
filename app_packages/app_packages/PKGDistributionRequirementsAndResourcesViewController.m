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
	
	IBOutlet NSView * _requirementsSectioniew;
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
	
	CGFloat _cachedHierarchyPlaceHolderViewInitialHeight;
}

- (IBAction)switchRootVolumeOnlyRequirement:(id)sender;

// Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification;

- (void)viewLayoutShouldChange:(NSNotification *)inNotification;
- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation PKGDistributionRequirementsAndResourcesViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		// Requirements
		
		_requirementsSourceListDataSource=[PKGDistributionRequirementSourceListDataSource new];
		_requirementsSourceListDataSource.filePathConverter=self.filePathConverter;
		
		_requirementsViewController=[[PKGDistributionRequirementsViewController alloc] initWithDocument:inDocument];
		_requirementsViewController.dataSource=_requirementsSourceListDataSource;
		
		_requirementsSourceListDataSource.delegate=_requirementsViewController;
		
		// Additional Resources
		
		_resourcesDataSource=[PKGPayloadDataSource new];
		_resourcesDataSource.editableRootNodes=YES;
		_resourcesDataSource.filePathConverter=self.filePathConverter;
        _resourcesDataSource.keysReplacer=self;
        
		_filesHierarchyViewController=[[PKGFilesHierarchyViewController alloc] initWithDocument:inDocument];
		
		_filesHierarchyViewController.label=NSLocalizedString(@"Additional Resources", @"");
		_filesHierarchyViewController.informationLabel=NSLocalizedString(@"These resources can be used by the above requirements and scripts \nor the requirements for the choices of the Installation Type step.", @"");
		_filesHierarchyViewController.disclosedStateKey=@"ui.distribution.additionalResources.disclosed";
		_filesHierarchyViewController.selectionStateKey=@"ui.distribution.additionalResources.selection";
		_filesHierarchyViewController.hierarchyDataSource=_resourcesDataSource;
		
		_resourcesDataSource.delegate=_filesHierarchyViewController;
	}
	
	return self;
}

#pragma mark -

- (NSUInteger)tag
{
	return PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources;
}

- (void)WB_viewDidLoad
{
    [super WB_viewDidLoad];
	
	_cachedHierarchyPlaceHolderViewInitialHeight=NSHeight(_hierarchyPlaceHolderView.frame);
	
	// Requirements
	
	_requirementsViewController.view.frame=_requirementsPlaceHolderView.bounds;
	
	[_requirementsPlaceHolderView addSubview:_requirementsViewController.view];
	
	// Files Hierarchy
	
	_filesHierarchyViewController.view.frame=_hierarchyPlaceHolderView.bounds;
	
	[_hierarchyPlaceHolderView addSubview:_filesHierarchyViewController.view];
}

#pragma mark -

- (void)setRequirementsAndResources:(PKGDistributionProjectRequirementsAndResources *)inRequirementsAndResources
{
	if (_requirementsAndResources!=inRequirementsAndResources)
	{
		_requirementsAndResources=inRequirementsAndResources;
		
		_requirementsSourceListDataSource.requirements=self.requirementsAndResources.requirements;
		
		_resourcesDataSource.rootNodes=self.requirementsAndResources.resourcesForest.rootNodes.array;
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[_requirementsViewController WB_viewWillAppear];

	[_filesHierarchyViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Requirements
	
	_rootVolumeOnlyCheckbox.state=(self.requirementsAndResources.rootVolumeOnlyRequirement==YES) ? WBControlStateValueOn : WBControlStateValueOff;
	
	[_requirementsViewController WB_viewDidAppear];
	
	// Resources
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHierarchySelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView];
	
	[_filesHierarchyViewController WB_viewDidAppear];
	
	[self fileHierarchySelectionDidChange:[NSNotification notificationWithName:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView]];

	
	[self viewLayoutShouldChange:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewLayoutShouldChange:) name:PKGDistributionRequirementsDataDidChangeNotification object:_requirementsViewController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
	
	//[self.view.window makeFirstResponder:_requirementsViewController.outlineView];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGDistributionRequirementsDataDidChangeNotification object:_requirementsViewController];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
	
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
	BOOL tNewValue=(sender.state==WBControlStateValueOn);
	
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

- (void)viewLayoutShouldChange:(NSNotification *)inNotification
{
	[self viewFrameDidChange:nil];
}

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	NSRect tBounds=self.view.bounds;
	NSRect tRequirementsFrame=_requirementsSectioniew.frame;
	NSRect tResourcesFrame=_hierarchyPlaceHolderView.frame;
	
	CGFloat tAvailableHeight=NSHeight(tBounds)-_cachedHierarchyPlaceHolderViewInitialHeight;
	CGFloat tMaximumRequirementsHeight=NSHeight(tRequirementsFrame)-NSHeight(_requirementsPlaceHolderView.frame)+_requirementsViewController.maximumViewHeight;
	
	if (tMaximumRequirementsHeight<tAvailableHeight)
	{
		tRequirementsFrame.size.height=tMaximumRequirementsHeight;
		tResourcesFrame.size.height=NSHeight(tBounds)-tRequirementsFrame.size.height;
	}
	else
	{
		tRequirementsFrame.size.height=tAvailableHeight;
		tResourcesFrame.size.height=_cachedHierarchyPlaceHolderViewInitialHeight;
	}
	
	tResourcesFrame.origin.y=0.0;
	
	tRequirementsFrame.origin.y=NSMaxY(tResourcesFrame);
	
	_requirementsSectioniew.frame=tRequirementsFrame;
	_hierarchyPlaceHolderView.frame=tResourcesFrame;
	
	if (inNotification==nil)
		[self.view setNeedsDisplay:YES];
}

@end
