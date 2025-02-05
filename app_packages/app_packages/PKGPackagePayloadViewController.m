/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackagePayloadViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGPackagePayloadDataSource.h"

#import "PKGReplaceableStringFormatter.h"

#import "PKGFilesEmptySelectionInspectorViewController.h"
#import "PKGPayloadFilesSelectionInspectorViewController.h"

#import "NSOutlineView+Selection.h"

#import "PKGPayloadTreeNode+UI.h"

@interface PKGPackagePayloadViewController ()
{
	IBOutlet NSView * _settingsView;
	
	IBOutlet NSTextField * _defaultDestinationLabel;
	IBOutlet NSButton * _defaultDestinationSetButton;
	
	IBOutlet NSView * _advancedBuildOptionsView;
	IBOutlet NSButton * _splitForksCheckbox;
	IBOutlet NSButton * _preserveExtendedAttributesCheckbox;
	IBOutlet NSButton * _treatMissingFilesAsWarningsCheckbox;
	
	IBOutlet NSView * _payloadTypeView;
	IBOutlet NSPopUpButton * _payloadTypePopUpButton;
	
	
	IBOutlet NSView * _hierarchyPlaceHolderView;
	IBOutlet NSView * _inspectorPlaceHolderView;
	
	PKGViewController *_emptySelectionInspectorViewController;
	PKGPayloadFilesSelectionInspectorViewController * _selectionInspectorViewController;
	
	PKGViewController *_currentInspectorViewController;
	
	PKGPackagePayloadDataSource * _dataSource;
}

	@property (readwrite) PKGPayloadFilesHierarchyViewController * payloadHierarchyViewController;

- (void)_updateLayout;

- (IBAction)switchSplitForks:(id)sender;
- (IBAction)switchPreserveExtendedAttributes:(id)sender;
- (IBAction)switchTreatMissingFilesAsWarnings:(id)sender;

- (IBAction)switchPayloadType:(id)sender;

// Hierarchy Menu

- (IBAction)addFiles:(id)sender;
- (IBAction)addNewFolder:(id)sender;

- (IBAction)expandOneLevel:(id)sender;
- (IBAction)expand:(id)sender;
- (IBAction)expandAll:(id)sender;
- (IBAction)contract:(id)sender;

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender;

- (IBAction)setDefaultDestination:(id)sender;

// Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification;

- (void)fileHierarchyDidRenameFolder:(NSNotification *)inNotification;

- (void)advancedModeStateDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPackagePayloadViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		_dataSource=[PKGPackagePayloadDataSource new];
		_dataSource.filePathConverter=self.filePathConverter;
        _dataSource.keysReplacer=self;
        
		_payloadHierarchyViewController=[[PKGPayloadFilesHierarchyViewController alloc] initWithDocument:inDocument];
		
		_payloadHierarchyViewController.label=NSLocalizedString(@"Contents",@"");
		_payloadHierarchyViewController.hierarchyDataSource=_dataSource;
		_payloadHierarchyViewController.disclosedStateKey=@"ui.package.payload.disclosed";
		_payloadHierarchyViewController.selectionStateKey=@"ui.package.payload.selection";
	}
	
	return self;
}

- (NSString *)nibName
{
	return @"PKGPackagePayloadViewController";
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
    PKGReplaceableStringFormatter * tFormatter=[PKGReplaceableStringFormatter new];
    tFormatter.keysReplacer=self;
    
    _defaultDestinationLabel.formatter=tFormatter;
    
	// Files Hierarchy
	
	_payloadHierarchyViewController.view.frame=_hierarchyPlaceHolderView.bounds;
	
	[_hierarchyPlaceHolderView addSubview:_payloadHierarchyViewController.view];
	
	_payloadHierarchyViewController.accessoryView=_payloadTypeView;
}

#pragma mark -

- (NSUInteger)tag
{
	return PKGPreferencesGeneralPackageProjectPanePayload;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self _updateLayout];
	
	[_payloadTypePopUpButton selectItemWithTag:self.payload.type];
	
	_splitForksCheckbox.state=(self.payload.splitForksIfNeeded==YES) ? WBControlStateValueOn : WBControlStateValueOff;
	
	_preserveExtendedAttributesCheckbox.enabled=self.payload.splitForksIfNeeded;
	
	_preserveExtendedAttributesCheckbox.state=(self.payload.preserveExtendedAttributes==YES) ? WBControlStateValueOn : WBControlStateValueOff;
	
	_treatMissingFilesAsWarningsCheckbox.state=(self.payload.treatMissingPayloadFilesAsWarnings==YES) ? WBControlStateValueOn : WBControlStateValueOff;
	
	_defaultDestinationLabel.objectValue=self.payload.defaultInstallLocation;
	
	_dataSource.rootNodes=self.payload.filesTree.rootNodes.array;
	
	_dataSource.delegate=_payloadHierarchyViewController;
	_dataSource.installLocationNode=[self.payload.filesTree.rootNode descendantNodeAtPath:self.payload.defaultInstallLocation];
	
	if (_dataSource.installLocationNode==nil)
	{
		// A COMPLETER
	}
	
	[_payloadHierarchyViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	//[self.view.window makeFirstResponder:_payloadHierarchyViewController.outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(advancedModeStateDidChange:) name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHierarchySelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_payloadHierarchyViewController.outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHierarchyDidRenameFolder:) name:PKGFilesHierarchyDidRenameItemNotification object:_payloadHierarchyViewController.outlineView];
	
	[_payloadHierarchyViewController WB_viewDidAppear];
	
	[self fileHierarchySelectionDidChange:[NSNotification notificationWithName:NSOutlineViewSelectionDidChangeNotification object:_payloadHierarchyViewController.outlineView]];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGFilesHierarchyDidRenameItemNotification object:nil];
	
	[_payloadHierarchyViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_payloadHierarchyViewController WB_viewDidDisappear];
}

#pragma mark -

- (void)_updateLayout
{
	BOOL tAdvancedModeEnabled=[PKGApplicationPreferences sharedPreferences].advancedMode;
	
	if (tAdvancedModeEnabled==NO && [_advancedBuildOptionsView isHidden]==NO)
	{
		NSRect tSettingsViewFrame=_settingsView.frame;
		NSRect tFilesHierarchyViewFrame=_hierarchyPlaceHolderView.frame;
		
		CGFloat tDeltaHeight=NSHeight(_advancedBuildOptionsView.frame);
		
		_advancedBuildOptionsView.hidden=YES;
		
		tSettingsViewFrame.size.height-=tDeltaHeight;
		tSettingsViewFrame.origin.y+=tDeltaHeight;
		
		_settingsView.frame=tSettingsViewFrame;
		
		tFilesHierarchyViewFrame.size.height+=tDeltaHeight;
		
		_hierarchyPlaceHolderView.frame=tFilesHierarchyViewFrame;
	}
	else if (tAdvancedModeEnabled==YES && [_advancedBuildOptionsView isHidden]==YES)
	{
		NSRect tSettingsViewFrame=_settingsView.frame;
		NSRect tFilesHierarchyViewFrame=_hierarchyPlaceHolderView.frame;
		
		CGFloat tDeltaHeight=NSHeight(_advancedBuildOptionsView.frame);
		
		_advancedBuildOptionsView.hidden=NO;
		
		tSettingsViewFrame.size.height+=tDeltaHeight;
		tSettingsViewFrame.origin.y-=tDeltaHeight;
		
		_settingsView.frame=tSettingsViewFrame;
		
		tFilesHierarchyViewFrame.size.height-=tDeltaHeight;
		
		_hierarchyPlaceHolderView.frame=tFilesHierarchyViewFrame;
	}
}

#pragma mark -

- (IBAction)setDefaultDestination:(id)sender
{
	NSOutlineView * tOutlineView=_payloadHierarchyViewController.outlineView;
	NSIndexSet * tClickedOrSelectedIndexes=tOutlineView.WB_selectedOrClickedRowIndexes;
	
	if (tClickedOrSelectedIndexes.count!=1)
		return;
	
	_defaultDestinationSetButton.enabled=NO;
	
	PKGPayloadTreeNode * tPreviousDefaultInstallationLocationNode=_dataSource.installLocationNode;
	_dataSource.installLocationNode=[tOutlineView itemAtRow:tClickedOrSelectedIndexes.firstIndex];
	
	NSMutableIndexSet * tRowIndexes=[tClickedOrSelectedIndexes mutableCopy];
	NSInteger tIndex=[tOutlineView rowForItem:tPreviousDefaultInstallationLocationNode];
	
	if (tIndex!=-1)
		[tRowIndexes addIndex:tIndex];
	
	self.payload.defaultInstallLocation=[_dataSource.installLocationNode filePathWithSeparator:@"/"];
	_defaultDestinationLabel.objectValue=self.payload.defaultInstallLocation;
	
	[tOutlineView reloadDataForRowIndexes:tRowIndexes
							columnIndexes:[NSIndexSet indexSetWithIndex:[tOutlineView columnWithIdentifier:@"file.name"]]];
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchSplitForks:(NSButton *)sender
{
	BOOL tState=(_splitForksCheckbox.state==WBControlStateValueOn);
	
	if (tState==self.payload.splitForksIfNeeded)
		return;
	
	self.payload.splitForksIfNeeded=tState;
	
	_preserveExtendedAttributesCheckbox.enabled=tState;
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchPreserveExtendedAttributes:(id)sender
{
	BOOL tState=(_preserveExtendedAttributesCheckbox.state==WBControlStateValueOn);
	
	if (tState==self.payload.preserveExtendedAttributes)
		return;
	
	self.payload.preserveExtendedAttributes=tState;
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchTreatMissingFilesAsWarnings:(id)sender
{
	BOOL tState=(_treatMissingFilesAsWarningsCheckbox.state==WBControlStateValueOn);
	
	if (tState==self.payload.treatMissingPayloadFilesAsWarnings)
		return;
	
	self.payload.treatMissingPayloadFilesAsWarnings=tState;
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchPayloadType:(id)sender
{
	// A COMPLETER
}

- (IBAction)addFiles:(id)sender
{
	[_payloadHierarchyViewController addFiles:sender];
}

- (IBAction)addNewFolder:(id)sender
{
	[_payloadHierarchyViewController addNewFolder:sender];
}

- (IBAction)expandOneLevel:(id)sender
{
	[_payloadHierarchyViewController expandOneLevel:sender];
}

- (IBAction)expand:(id)sender
{
	[_payloadHierarchyViewController expand:sender];
}

- (IBAction)expandAll:(id)sender
{
	[_payloadHierarchyViewController expandAll:sender];
}

- (IBAction)contract:(id)sender
{
	[_payloadHierarchyViewController contract:sender];
}

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender
{
	self.payload.hiddenFolderTemplatesIncluded=!self.payload.hiddenFolderTemplatesIncluded;
	
	if (self.payload.hiddenFolderTemplatesIncluded==YES)
		[_payloadHierarchyViewController showHiddenFolderTemplates];
	else
		[_payloadHierarchyViewController hideHiddenFolderTemplates];
	
	[self noteDocumentHasChanged];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	// Set Default Location
	
	if (tAction==@selector(setDefaultDestination:))
	{
		NSOutlineView * tOutlineView=_payloadHierarchyViewController.outlineView;
		NSIndexSet * tClickedOrSelectedIndexes=tOutlineView.WB_selectedOrClickedRowIndexes;
		
		if (tClickedOrSelectedIndexes.count!=1)
			return NO;
		
		PKGPayloadTreeNode * tSelectedTreeNode=[tOutlineView itemAtRow:tClickedOrSelectedIndexes.firstIndex];
		
		if (tSelectedTreeNode==_dataSource.installLocationNode)
			return NO;
		
		return [tSelectedTreeNode isSelectableAsInstallationLocation];
	}
	
	// Show|Hide Hidden Folders
	
	if (tAction==@selector(switchHiddenFolderTemplatesVisibility:))
	{
		[inMenuItem setTitle:(self.payload.hiddenFolderTemplatesIncluded==YES) ? NSLocalizedString(@"Hide Hidden Folders", @"") : NSLocalizedString(@"Show Hidden Folders", @"")];
		 
		 return YES;
	}
	
	if (tAction==@selector(addFiles:) ||
		tAction==@selector(addNewFolder:) ||
		tAction==@selector(expandOneLevel:) ||
		tAction==@selector(expand:) ||
		tAction==@selector(expandAll:) ||
		tAction==@selector(contract:))
	{
		return [_payloadHierarchyViewController validateMenuItem:inMenuItem];
	}
	
	return YES;
}

#pragma mark - Notifications

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
    
    [_defaultDestinationLabel setNeedsDisplay:YES];
}

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification
{
	NSOutlineView * tOutlineView=_payloadHierarchyViewController.outlineView;
	
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
			_selectionInspectorViewController=[[PKGPayloadFilesSelectionInspectorViewController alloc] initWithDocument:self.document];
			_selectionInspectorViewController.delegate=_payloadHierarchyViewController;
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
		_selectionInspectorViewController.delegate=_payloadHierarchyViewController;
	}
	
	// Default Destination
	
	if (tNumberOfSelectedRows!=1)
	{
		_defaultDestinationSetButton.enabled=NO;
		return;
	}
	
	PKGPayloadTreeNode * tSelectedTreeNode=[tOutlineView itemAtRow:tOutlineView.selectedRow];
	
	if (tSelectedTreeNode==_dataSource.installLocationNode)
	{
		_defaultDestinationSetButton.enabled=NO;
		return;
	}
	
	_defaultDestinationSetButton.enabled=[tSelectedTreeNode isSelectableAsInstallationLocation];
		
	// A COMPLETER
}

- (void)fileHierarchyDidRenameFolder:(NSNotification *)inNotification
{
	NSOutlineView * tOutlineView=_payloadHierarchyViewController.outlineView;
	
	if (inNotification.object!=tOutlineView)
		return;
	
	PKGPayloadTreeNode * tTreeNode=inNotification.userInfo[@"NSObject"];
	
	if (tTreeNode==_dataSource.installLocationNode)
	{
		self.payload.defaultInstallLocation=[_dataSource.installLocationNode filePathWithSeparator:@"/"];
		_defaultDestinationLabel.objectValue=self.payload.defaultInstallLocation;
	}
}

- (void)advancedModeStateDidChange:(NSNotification *)inNotification
{
	[self _updateLayout];
}

@end
