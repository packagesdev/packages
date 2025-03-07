/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFilesHierarchyViewController.h"

#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

#import "NSObject+Conformance.h"

#import "NSOutlineView+Selection.h"

#import "PKGApplicationPreferences.h"

#import "PKGPayloadFilenameTableCellView.h"

#import "PKGOwnershipAndReferenceStyleViewController.h"
#import "PKGPayloadDropView.h"

#import "PKGPackagePayloadDataSource.h"

#import "PKGFileNameFormatter.h"
#import "PKGElasticFolderNameFormatter.h"

@interface PKGFilesHierarchyOpenPanelDelegate : NSObject<NSOpenSavePanelDelegate>

	@property NSArray * sibblings;

@end

@implementation PKGFilesHierarchyOpenPanelDelegate

- (BOOL)panel:(NSOpenPanel *)inPanel shouldEnableURL:(NSURL *)inURL
{
	if (inURL.isFileURL==NO)
		return NO;
	
	NSString * tLastPathComponent=inURL.path.lastPathComponent;
	
	if ([self.sibblings indexOfObjectPassingTest:^BOOL(PKGPayloadTreeNode *bPayloadTreeNode,NSUInteger bIndex,BOOL * bOutStop){
	
		return ([tLastPathComponent caseInsensitiveCompare:bPayloadTreeNode.fileName]==NSOrderedSame);
	
	}]!=NSNotFound)
		return NO;
	
	return YES;
}

@end


NSString * const PKGFilesHierarchyDidRenameItemNotification=@"PKGFilesHierarchyDidRenameItemNotification";


@interface PKGFilesHierarchyViewController () <NSOutlineViewDelegate,NSTextFieldDelegate>
{
	IBOutlet NSTextField * _viewLabel;
	
	IBOutlet NSView * _accessoryViewPlaceHolder;
	
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	
	IBOutlet NSTextField * _viewInformationLabel;
	
	PKGFilesHierarchyOpenPanelDelegate * _openPanelDelegate;
	
	PKGFileNameFormatter * _cachedFileNameFormatter;
    PKGElasticFolderNameFormatter * _cachedElasticFolderNameFormatter;
    
	BOOL _highlightExcludedItems;
	NSArray * _optimizedFilesFilters;
	
	NSTimeInterval _lastRefreshTimeMark;
	
	BOOL _restoringDiscloseStates;
}

	@property (readwrite) IBOutlet NSOutlineView * outlineView;

- (void)restoreDisclosedStates;

- (void)archiveSelection;
- (void)restoreSelection;

- (IBAction)showInFinder:(id)sender;

- (IBAction)delete:(id)sender;

// Notifications

- (void)highlightExludedFilesStateDidChange:(NSNotification *)inNotification;

- (void)windowDidResignMain:(NSNotification *)inNotification;
- (void)windowDidBecomeMain:(NSNotification *)inNotification;

@end

@implementation PKGFilesHierarchyViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		_label=@"";
		_informationLabel=@"";
		
		_cachedFileNameFormatter=[PKGFileNameFormatter new];
		_cachedFileNameFormatter.fileNameCanStartWithDot=YES;
        _cachedFileNameFormatter.keysReplacer=self;
        
        _cachedElasticFolderNameFormatter=[PKGElasticFolderNameFormatter new];
        _cachedElasticFolderNameFormatter.keysReplacer=self;
	}
	
	return self;
}

#pragma mark -

- (NSString *)nibName
{
	return @"PKGFilesHierarchyViewController";
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	[self.outlineView registerForDraggedTypes:[PKGPayloadDataSource supportedDraggedTypes]];
	
    // Do view setup here.
}

#pragma mark -

- (BOOL)highlightExcludedItems
{
	return [PKGApplicationPreferences sharedPreferences].highlightExcludedFiles;
}

#pragma mark -

- (void)refreshUI
{
	if (_viewLabel==nil)
		return;
	
	_viewLabel.stringValue=_label;
	
	NSRect tInformationlabelFrame=_viewInformationLabel.frame;
	
	_viewInformationLabel.stringValue=_informationLabel;
	
	[_viewInformationLabel sizeToFit];
	
	CGFloat tNewWidth=NSWidth(_viewInformationLabel.frame);
	
	tInformationlabelFrame.origin.x=NSMaxX(tInformationlabelFrame)-tNewWidth;
	tInformationlabelFrame.size.width=tNewWidth;
	
	_viewInformationLabel.frame=tInformationlabelFrame;
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_highlightExcludedItems=[self highlightExcludedItems];
	_lastRefreshTimeMark=[NSDate timeIntervalSinceReferenceDate];
	
	
	self.outlineView.dataSource=self.hierarchyDataSource;
	
	if ([_hierarchyDataSource WB_doesReallyConformToProtocol:@protocol(PKGFileDeadDropViewDelegate)]==YES)
		((PKGPayloadDropView *)self.view).delegate=(id<PKGFileDeadDropViewDelegate>)_hierarchyDataSource;
	
	// Owner and Group
	
	BOOL tHideColumn=(self.hierarchyDataSource.managedAttributes &  PKGFileAttributesOwnerAndGroup)==0;
	
	[self.outlineView tableColumnWithIdentifier:@"file.owner"].hidden=tHideColumn;
	[self.outlineView tableColumnWithIdentifier:@"file.group"].hidden=tHideColumn;
	
	// Permissions
	
	tHideColumn=(self.hierarchyDataSource.managedAttributes & PKGFileAttributesPOSIXPermissions)==0;
	
	[self.outlineView tableColumnWithIdentifier:@"file.permissions"].hidden=tHideColumn;
	
	
	[self refreshUI];
	
	// A COMPLETER
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	_optimizedFilesFilters=self.documentProject.settings.optimizedFilesFilters;
	
	// A COMPLETER
	
	_addButton.enabled=(_hierarchyDataSource.editableRootNodes==YES);
	_removeButton.enabled=NO;
	
	[self refreshHierarchy];
	
	
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highlightExludedFilesStateDidChange:) name:PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:self.view.window];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:self.view.window];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[self archiveSelection];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.view.window];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.view.window];
}

- (void)refreshHierarchy
{
	[self.outlineView reloadData];
	
	[self restoreDisclosedStates];
	
	[self restoreSelection];
}

#pragma mark -

- (void)setHierarchyDataSource:(id<NSOutlineViewDataSource>)inDataSource
{
	_hierarchyDataSource=inDataSource;
	_hierarchyDataSource.delegate=self;
	
	if (self.outlineView!=nil)
		self.outlineView.dataSource=_hierarchyDataSource;
}

- (NSView *)accessoryView
{
	NSArray * tSubviews=_accessoryViewPlaceHolder.subviews;
	
	if (tSubviews.count==0)
		return nil;
	
	return tSubviews.firstObject;
}

- (void)setAccessoryView:(NSView *)inAccessoryView
{
	NSArray * tSubviews=_accessoryViewPlaceHolder.subviews;
	
	for(NSView * tSubView in tSubviews)
		[tSubView removeFromSuperview];
	
	if (inAccessoryView!=nil)
	{
		inAccessoryView.frame=_accessoryViewPlaceHolder.bounds;
		
		[_accessoryViewPlaceHolder addSubview:inAccessoryView];
	}
}

- (void)setLabel:(NSString *)inLabel
{
	_label=(inLabel!=nil) ? [inLabel copy] : @"";
	
	[self refreshUI];
}

- (void)setInformationLabel:(NSString *)inInformationLabel
{
	_informationLabel=(inInformationLabel!=nil) ? [inInformationLabel copy] : @"";
	
	[self refreshUI];
}

#pragma mark - Restoration

- (void)restoreDisclosedStates
{
	NSDictionary * tDictionary=self.documentRegistry[self.disclosedStateKey];
	
	if (tDictionary.count==0)
	{
		[self.hierarchyDataSource expandByDefault:self.outlineView];
		
		return;
	}
	
	__block __weak void (^_weakDiscloseNodeAndDescendantsIfNeeded)(PKGPayloadTreeNode *);
	__block void(^_discloseNodeAndDescendantsIfNeeded)(PKGPayloadTreeNode *);
	
	_discloseNodeAndDescendantsIfNeeded = ^(PKGPayloadTreeNode * bTreeNode)
	{
		if (bTreeNode==nil)
			return;
		
		if ([bTreeNode isLeaf]==YES)
			return;
		
		NSString * tFilePath=[bTreeNode filePathWithSeparator:self.hierarchyDataSource.fakeFileSeparator];
		
		[self.outlineView expandItem:bTreeNode];
		
		// Check children
		
		NSArray * tChildren=[bTreeNode children];
		
		for(PKGPayloadTreeNode * tTreeNode in tChildren)
			_weakDiscloseNodeAndDescendantsIfNeeded(tTreeNode);
		
		if (tDictionary[tFilePath]==nil)
			[self.outlineView collapseItem:bTreeNode];
	};
	
	_weakDiscloseNodeAndDescendantsIfNeeded = _discloseNodeAndDescendantsIfNeeded;
	
	_restoringDiscloseStates=YES;
	
	for(PKGPayloadTreeNode * tTreeNode in self.hierarchyDataSource.rootNodes)
		_discloseNodeAndDescendantsIfNeeded(tTreeNode);
	
	_restoringDiscloseStates=NO;
}

#pragma mark -

- (void)archiveSelection
{
	NSIndexSet * tIndexSet=self.outlineView.selectedRowIndexes;
	
	if (tIndexSet==nil)
		return;
	
	__block NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[tIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex, BOOL *bOutStop) {
		
		PKGPayloadTreeNode * tTreeNode=[self.outlineView itemAtRow:bIndex];
		
		if (tTreeNode==nil)
			return;
		
		NSString * tPath=[tTreeNode filePathWithSeparator:self.hierarchyDataSource.fakeFileSeparator];
		
		if (tPath!=nil)
		{
			[tMutableArray addObject:tPath];
		}
	}];
	
	self.documentRegistry[self.selectionStateKey]=tMutableArray;
}

- (void)restoreSelection
{
	NSArray * tArray=self.documentRegistry[self.selectionStateKey];
	
	if (tArray.count==0)
		return;
	
	__block NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	[tArray enumerateObjectsUsingBlock:^(NSString * bItemPath, NSUInteger bIndex, BOOL *bOutStop) {
		
        PKGPayloadTreeNode * tTreeNode=[self.hierarchyDataSource itemAtPath:bItemPath separator:self.hierarchyDataSource.fakeFileSeparator];
		
		if (tTreeNode==nil)
			return;
		
		NSInteger tRow=[self.outlineView rowForItem:tTreeNode];
		
		if (tRow!=-1)
			[tMutableIndexSet addIndex:tRow];
	}];
	
	[self.outlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldDeleteItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems==nil)
		return NO;
	
	NSArray * tMinimumCover=[PKGTreeNode minimumNodeCoverFromNodesInArray:inItems];
	
	if (tMinimumCover.count==0)
		return NO;
	
	for(PKGPayloadTreeNode * tTreeNode in tMinimumCover)
	{
		if ([tTreeNode isTemplateNode]==YES)
			return NO;
	}
	
	return YES;
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(PKGPayloadTreeNode *)inPayloadTreeNode
{
	if (inOutlineView!=self.outlineView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	if ([inPayloadTreeNode needsRefresh:_lastRefreshTimeMark]==YES)
		[inPayloadTreeNode refreshWithAbsolutePath:[inPayloadTreeNode referencedPathUsingConverter:self.filePathConverter]
									   fileFilters:(_highlightExcludedItems==YES) ? _optimizedFilesFilters : nil];
	
	if ([tTableColumnIdentifier isEqualToString:@"file.name"]==YES)
	{
		PKGPayloadFilenameTableCellView *tPayloadFileNameCellView=(PKGPayloadFilenameTableCellView *)tView;
		
		PKGPayloadTreeNodeAttributedImage * tAttributedImage=inPayloadTreeNode.nameAttributedIcon;
		
		tAttributedImage.drawsTargetCross=[self.hierarchyDataSource outlineView:inOutlineView shouldDrawTargetCrossForItem:inPayloadTreeNode];
		
		tPayloadFileNameCellView.attributedImageView.attributedImage=tAttributedImage;
		
		//[tView.imageView unregisterDraggedTypes];	// To prevent the imageView from interfering with drag and drop
		
        NSAttributedString * tAttributedString=inPayloadTreeNode.nameAttributedTitle;
        
        tView.textField.objectValue=@"";        // Hack to make sure the textfield is refreshed when user defined settings are modified
        tView.textField.objectValue=tAttributedString;
		tView.textField.editable=inPayloadTreeNode.isNameTitleEditable;
		
		if (inPayloadTreeNode.isNameTitleEditable==YES)
        {
            if (inPayloadTreeNode.isElasticFolder==NO)
            {
                tView.textField.formatter=_cachedFileNameFormatter;
            }
            else
            {
                tView.textField.formatter=_cachedElasticFolderNameFormatter;
            }
        }
        else
        {
            if ([tAttributedString.string containsString:@"${"]==NO)
                tView.textField.formatter=nil;
            else
                tView.textField.formatter=_cachedFileNameFormatter;
        }
        
        tView.textField.delegate=self;
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"file.owner"]==YES)
	{
		tView.textField.stringValue=inPayloadTreeNode.ownerTitle;
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"file.group"]==YES)
	{
		tView.textField.stringValue=inPayloadTreeNode.groupTitle;
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"file.permissions"]==YES)
	{
		tView.textField.stringValue=inPayloadTreeNode.posixPermissionsTitle;
		
		return tView;
	}
	
	return nil;
}

#pragma mark -

- (IBAction)showInFinder:(id)sender
{
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
	
	[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
		
		PKGPayloadTreeNode * tPayloadTreeNode=[self.outlineView itemAtRow:bIndex];
		
		[tSharedWorkspace selectFile:[tPayloadTreeNode referencedPathUsingConverter:self.filePathConverter] inFileViewerRootedAtPath:@""];
	}];
}

- (IBAction)addFiles:(id)sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.resolvesAliases=NO;
	tOpenPanel.canChooseFiles=YES;
	tOpenPanel.canChooseDirectories=YES;
	tOpenPanel.allowsMultipleSelection=YES;
	tOpenPanel.treatsFilePackagesAsDirectories=YES;
	tOpenPanel.showsHiddenFiles=[PKGApplicationPreferences sharedPreferences].showAllFilesInOpenDialog;
	
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	PKGTreeNode * tParentNode=nil;
	
	if (tSelectionIndexSet.count>0)
	{
		NSInteger tClickedRow=self.outlineView.clickedRow;
		
		if (tClickedRow==-1)
			tClickedRow=tSelectionIndexSet.firstIndex;
		
		PKGPayloadTreeNode * tNode=[self.outlineView itemAtRow:tClickedRow];
		
		tParentNode=(tNode.isLeaf==NO) ? tNode : tNode.parent;
	}
	
	_openPanelDelegate=[PKGFilesHierarchyOpenPanelDelegate new];
	
	_openPanelDelegate.sibblings=(tParentNode==nil) ? self.hierarchyDataSource.rootNodes : tParentNode.children;
	
	tOpenPanel.delegate=_openPanelDelegate;
	
	tOpenPanel.prompt=NSLocalizedString(@"Add",@"No comment");
	
	__block BOOL tKeepOwnerAndGroup=((self.hierarchyDataSource.managedAttributes & PKGFileAttributesOwnerAndGroup)==0) ? NO : [PKGApplicationPreferences sharedPreferences].keepOwnership;
	__block PKGFilePathType tReferenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	PKGOwnershipAndReferenceStyleViewController * tOwnershipAndReferenceStyleViewController=nil;
	
	if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
	{
		tOwnershipAndReferenceStyleViewController=[PKGOwnershipAndReferenceStyleViewController new];
		
		tOwnershipAndReferenceStyleViewController.canChooseOwnerAndGroupOptions=((self.hierarchyDataSource.managedAttributes & PKGFileAttributesOwnerAndGroup)!=0);
		tOwnershipAndReferenceStyleViewController.keepOwnerAndGroup=tKeepOwnerAndGroup;
		tOwnershipAndReferenceStyleViewController.referenceStyle=tReferenceStyle;
		
		NSView * tAccessoryView=tOwnershipAndReferenceStyleViewController.view;
		
		tOpenPanel.accessoryView=tAccessoryView;
	}
	
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
	
		if (bResult!=WBFileHandlingPanelOKButton)
			return;
		
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
		{
			tKeepOwnerAndGroup=tOwnershipAndReferenceStyleViewController.keepOwnerAndGroup;
			tReferenceStyle=tOwnershipAndReferenceStyleViewController.referenceStyle;
		}
		
		NSArray * tPaths=[tOpenPanel.URLs WB_arrayByMappingObjectsUsingBlock:^(NSURL * bURL,NSUInteger bIndex){
			
			return bURL.path;
		}];
		
		if ([self.hierarchyDataSource outlineView:self.outlineView
									 addFileNames:tPaths
									referenceType:tReferenceStyle
										toParents:(tParentNode==nil) ? nil : @[tParentNode]
										  options:(tKeepOwnerAndGroup==YES) ? PKGPayloadAddKeepOwnership : 0]==YES)
		{
			[self noteDocumentHasChanged];
		}
	}];
}

- (IBAction)addNewFolder:(id)sender
{
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	NSInteger tClickedRow=self.outlineView.clickedRow;
	
	// Selection is not empty and no row was clicked
	
	if (tSelectionIndexSet.count>0 && tClickedRow==-1)
		tClickedRow=tSelectionIndexSet.firstIndex;
	
	if ([self.hierarchyDataSource outlineView:self.outlineView addNewFolderToParent:(tClickedRow!=-1) ? ((PKGTreeNode *)[self.outlineView itemAtRow:tClickedRow]) : nil]==NO)
		return;
	
	// Enter edition mode
	
	NSInteger tRow=[self.outlineView selectedRow];
	
	if (tRow==-1)
		return;
	
	[self.outlineView scrollRowToVisible:tRow];
	
	[self.outlineView editColumn:[self.outlineView columnWithIdentifier:@"file.name"] row:tRow withEvent:nil select:YES];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this item?",@"No comment") : NSLocalizedString(@"Do you really want to remove these items?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
	
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self.hierarchyDataSource outlineView:self.outlineView removeItems:[self.outlineView WB_itemsAtRowIndexes:tIndexSet]];
	}];
}

- (IBAction)expandOneLevel:(id)sender
{
	NSIndexSet * tIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	// A COMPLETER
	
	[tIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL *bOutStop){
	
		id tItem=[self.outlineView itemAtRow:bIndex];
		
		if (tItem!=nil)
			[self.hierarchyDataSource outlineView:self.outlineView expandItem:tItem options:0];
	}];
}

- (IBAction)expand:(id)sender
{
	NSIndexSet * tIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	if (tIndexSet.count<1)
		return;
	
	// A COMPLETER
	
	[tIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL *bOutStop){
		
		id tItem=[self.outlineView itemAtRow:bIndex];
		
		if (tItem!=nil)
			[self.hierarchyDataSource outlineView:self.outlineView expandItem:tItem options:PKGPayloadExpandRecursively];
	}];
}

- (IBAction)expandAll:(id)sender
{
	[self.hierarchyDataSource outlineView:self.outlineView expandAllItemsWithOptions:0];
}

- (IBAction)contract:(id)sender
{
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	NSUInteger tIndex=tSelectionIndexSet.firstIndex;
	
	PKGPayloadTreeNode * tItem=[self.outlineView itemAtRow:tIndex];
	
	[self.hierarchyDataSource outlineView:self.outlineView contractItem:tItem];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tSelector=inMenuItem.action;
	
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;

	NSInteger tSelectedCount=tSelectionIndexSet.count;
	
	if (tSelectedCount==0)
	{
		// New Folder
		
		if (tSelector==@selector(addNewFolder:))
			return _hierarchyDataSource.editableRootNodes;
		
		if (tSelector==@selector(addFiles:))
			return _hierarchyDataSource.editableRootNodes;
		
		if (tSelector==@selector(expandAll:))
			return YES;
		
		return NO;
	}
	
	if (tSelectedCount>0)
	{
		// Add Files
		
		if (tSelector==@selector(addFiles:))
			return YES;
		
		// New Folder
		
		if (tSelector==@selector(addNewFolder:))
		{
			NSInteger tClickedRow=self.outlineView.clickedRow;
			
			if (tClickedRow==-1)
				tClickedRow=tSelectionIndexSet.firstIndex;
			
			PKGPayloadTreeNode * tParentNode=[self.outlineView itemAtRow:tClickedRow];
			
			if (tParentNode.isLeaf==NO)
				return YES;
			
			tParentNode=(PKGPayloadTreeNode *)tParentNode.parent;
			
			if (tParentNode!=NULL)
				return YES;
			
			return _hierarchyDataSource.editableRootNodes;
		}
		
		// Show in Finder
		
		if (tSelector==@selector(showInFinder:))
		{
			__block BOOL tIsValidated=YES;
			
			[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
			
				PKGPayloadTreeNode * tPayloadTreeNode=[self.outlineView itemAtRow:bIndex];
				
				if ([tPayloadTreeNode isFileSystemItemNode]==NO)
				{
					tIsValidated=NO;
					*bOutStop=NO;
				}
			}];
			
			return tIsValidated;
		}
		
		// Delete
		
		if (tSelector==@selector(delete:))
			return [self outlineView:self.outlineView shouldDeleteItems:[self.outlineView WB_selectedOrClickedItems]];
		
		// Expand One Level, Expand
		
		if (tSelector==@selector(expandOneLevel:) ||
			tSelector==@selector(expand:))
		{
			__block BOOL tIsValidated=YES;
			
			NSFileManager * tFileManager=[NSFileManager defaultManager];
			
			[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
				
				PKGPayloadTreeNode * tPayloadTreeNode=[self.outlineView itemAtRow:bIndex];
				
				if ([tPayloadTreeNode isFileSystemItemNode]==NO)
				{
					tIsValidated=NO;
					*bOutStop=NO;
				}
				
				if ([tPayloadTreeNode isReferencedItemMissing]==YES)
				{
					tIsValidated=NO;
					*bOutStop=NO;
				}
				
				if ([tPayloadTreeNode isContentsDisclosed]==YES)	// This will also take care of parent and child being in the selection
				{
					tIsValidated=NO;
					*bOutStop=NO;
				}
				
				NSString * tReferencedPath=[tPayloadTreeNode referencedPathUsingConverter:self.hierarchyDataSource.filePathConverter];
				
				if (tReferencedPath==nil)
				{
					tIsValidated=NO;
					*bOutStop=NO;
				}
				
				BOOL tIsDirectory=NO;
				if ([tFileManager fileExistsAtPath:tReferencedPath isDirectory:&tIsDirectory]==NO || tIsDirectory==NO)
				{
					tIsValidated=NO;
					*bOutStop=NO;
				}
			}];
			
			return tIsValidated;
		}
		
		// Expand All
		
		if (tSelector==@selector(expandAll:))
			return YES;
	}
	
	if (tSelectedCount==1)
	{
		PKGPayloadTreeNode * tPayloadTreeNode=[self.outlineView itemAtRow:tSelectionIndexSet.firstIndex];

		// Contraction and expansion actions
		
		if ([tPayloadTreeNode isFileSystemItemNode]==NO)
			return NO;
		
		if (tSelector==@selector(contract:))
			return ([tPayloadTreeNode isLeaf]==NO);
		
		if (tSelector==@selector(expand:))
		{
			if ([tPayloadTreeNode isLeaf]==NO)
				return NO;
			
			NSString * tReferencedPath=[tPayloadTreeNode referencedPathUsingConverter:self.filePathConverter];
			
			if (tReferencedPath==nil)
			{
				NSLog(@"Could not compute the referenced path for %@",tPayloadTreeNode);
				return NO;
			}
			
			NSError * tError=nil;
			NSDictionary * tAttributes=[[NSFileManager defaultManager] attributesOfItemAtPath:tReferencedPath error:&tError];
			
			if (tAttributes==nil)
			{
				if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
				{
					// A COMPLETER
				}
				
				return NO;
			}
			
			return ([tAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]==YES);
		}
	}
	
	return NO;
}

#pragma mark - PKGFilesSelectionInspectorDelegate

- (void)viewController:(NSViewController *)inViewController didUpdateSelectedItems:(NSArray *)inArray
{
	[self noteDocumentHasChanged];
	
	[_hierarchyDataSource outlineView:self.outlineView reloadDataForItems:inArray];
}

- (BOOL)viewController:(NSViewController *)inViewController shouldRenameItem:(id)inItem to:(NSString *)inName
{
	return [self.hierarchyDataSource outlineView:self.outlineView shouldRenameNewFolder:inItem as:inName];
}

- (void)viewController:(NSViewController *)inViewController didRenameItem:(id)inItem to:(NSString *)inName
{
	if ([self.hierarchyDataSource outlineView:self.outlineView renameItem:inItem as:inName]==YES)
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGFilesHierarchyDidRenameItemNotification object:self.outlineView userInfo:@{@"NSObject":inItem}];
	
	[self noteDocumentHasChanged];
}

#pragma mark - PKGPayloadDataSourceDelegate

- (NSMutableDictionary *)disclosedDictionary
{
	return self.documentRegistry[self.disclosedStateKey];
}

- (void)payloadDataDidChange:(PKGPayloadDataSource *)inPayloadDataSource
{
	[self noteDocumentHasChanged];
}

- (void)dataSource:(PKGPayloadDataSource *)inPayloadDataSource didDragAndDropNodes:(NSArray *)inNodes
{
    // Do nothing
}

#pragma mark - NSControlTextEditingDelegate

- (void)control:(NSControl *)inControl didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)inError
{
	NSBeep();
}

- (void)controlTextDidEndEditing:(NSNotification *)inNotification
{
	NSTextField * tTextField=inNotification.object;
	
	if ([tTextField isKindOfClass:NSTextField.class]==NO)
		return;
	
	NSInteger tEditedRow=[self.outlineView rowForView:tTextField];
	
	if (tEditedRow==-1)
		return;
	
	PKGPayloadTreeNode * tEditedNode=[self.outlineView itemAtRow:tEditedRow];
	
	if ([self.hierarchyDataSource outlineView:self.outlineView shouldRenameNewFolder:tEditedNode as:tTextField.objectValue]==NO)
	{
		NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView rowForItem:tEditedNode]];
		NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView columnWithIdentifier:@"file.name"]];
		
		[self.outlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
		
		return;
	}
	
	if ([self.hierarchyDataSource outlineView:self.outlineView renameItem:tEditedNode as:tTextField.objectValue]==YES)
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGFilesHierarchyDidRenameItemNotification object:self.outlineView userInfo:@{@"NSObject":tEditedNode}];
}

#pragma mark - Notifications

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
 
    [self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.outlineView.numberOfRows)]
                                columnIndexes:[NSIndexSet indexSetWithIndex:[self.outlineView columnWithIdentifier:@"file.name"]]];
    
}

- (void)outlineViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=self.outlineView)
		return;
	
	NSIndexSet * tSelectionIndexSet=self.outlineView.selectedRowIndexes;
	
	// Delete button state
	
	if (tSelectionIndexSet.count==0)
	{
		_addButton.enabled=_hierarchyDataSource.editableRootNodes;
		_removeButton.enabled=NO;
		
		return;
	}
	
	_addButton.enabled=YES;
	_removeButton.enabled=YES;
		
	[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
		
		PKGPayloadTreeNode * tPayloadTreeNode=[self.outlineView itemAtRow:bIndex];
		
		if ([tPayloadTreeNode isTemplateNode]==YES)
		{
			self->_removeButton.enabled=NO;
			*bOutStop=NO;
		}
	}];
	
	// A COMPLETER
}

- (void)outlineViewItemDidExpand:(NSNotification *)inNotification
{
	if (_restoringDiscloseStates==YES)
		return;
	
	if (inNotification.object!=self.outlineView)
		return;
	
	NSDictionary * tUserInfo=inNotification.userInfo;
	if (tUserInfo==nil)
		return;
	
	PKGPayloadTreeNode * tTreeNode=(PKGPayloadTreeNode *) tUserInfo[@"NSObject"];
	if (tTreeNode==nil)
		return;
	
	NSString * tFilePath=[tTreeNode filePathWithSeparator:self.hierarchyDataSource.fakeFileSeparator];
	
	NSString * tKey=[self disclosedStateKey];
	NSMutableDictionary * tDisclosedDictionary=self.documentRegistry[tKey];
	
	if (tDisclosedDictionary==nil)
	{
		tDisclosedDictionary=[NSMutableDictionary dictionary];
		self.documentRegistry[tKey]=tDisclosedDictionary;
	}
	
	if (tDisclosedDictionary!=nil)
		tDisclosedDictionary[tFilePath]=@(YES);
}

- (void)outlineViewItemWillCollapse:(NSNotification *)inNotification
{
	if (_restoringDiscloseStates==YES)
		return;
	
	if (inNotification.object!=self.outlineView)
		return;
	
	NSDictionary * tUserInfo=inNotification.userInfo;
	if (tUserInfo==nil)
		return;
	
	PKGPayloadTreeNode * tTreeNode=(PKGPayloadTreeNode *) tUserInfo[@"NSObject"];
	if (tTreeNode==nil)
		return;
	
	NSString * tFilePath=[tTreeNode filePathWithSeparator:self.hierarchyDataSource.fakeFileSeparator];
	
	NSString * tKey=[self disclosedStateKey];
	NSMutableDictionary * tDisclosedDictionary=self.documentRegistry[tKey];
	
	if (tDisclosedDictionary==nil)
	{
		tDisclosedDictionary=[NSMutableDictionary dictionary];
		self.documentRegistry[tKey]=tDisclosedDictionary;
	}
	
	// Check if the option key is down or not
	
	NSEvent * tCurrentEvent=[NSApp currentEvent];
	
	if (tCurrentEvent==nil || ((tCurrentEvent.modifierFlags & WBEventModifierFlagOption)==0))
	{
		if ([tFilePath isEqualToString:@"/"]==NO)
		{
			// Check the parents state
			
			NSString * tParentPath=tFilePath;
			
			do
			{
				tParentPath=[tParentPath stringByDeletingLastPathComponent];
				
				NSNumber * tNumber=tDisclosedDictionary[tParentPath];
				
				if (tNumber==nil)	// Parent is hidden
					return;
				
				if ([tParentPath isEqualToString:@"/"]==YES)
					break;
			}
			while (1);
		}
	}
	
	[tDisclosedDictionary removeObjectForKey:tFilePath];
}

- (void)highlightExludedFilesStateDidChange:(NSNotification *)inNotification
{
	_lastRefreshTimeMark=[NSDate timeIntervalSinceReferenceDate];
	
	_highlightExcludedItems=[self highlightExcludedItems];
	
	[self.outlineView reloadData];
}

- (void)windowDidResignMain:(NSNotification *)inNotification
{
	[self archiveSelection];
}

- (void)windowDidBecomeMain:(NSNotification *)inNotification
{
	_lastRefreshTimeMark=[NSDate timeIntervalSinceReferenceDate];
	
	[self.outlineView reloadData];
	
	[self restoreSelection];
}

@end
