
#import "PKGFilesHierarchyViewController.h"

#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

#import "NSOutlineView+Selection.h"

#import "PKGApplicationPreferences.h"

#import "PKGPayloadDropView.h"

@interface PKGFilesHierarchyAddPanelDelegate : NSObject<NSOpenSavePanelDelegate>

	@property id destination;

@end

@implementation PKGFilesHierarchyAddPanelDelegate

- (BOOL)panel:(NSOpenPanel *)inPanel shouldEnableURL:(NSURL *)inURL
{
	if (inURL.isFileURL==NO)
		return NO;
	
	// A COMPLETER
	
	return YES;
}

@end

@interface PKGFilesHierarchyViewController () <NSOutlineViewDelegate>
{
	IBOutlet NSTextField * _viewLabel;
	
	IBOutlet NSOutlineView * _outlineView;
	
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	
	
	BOOL _highlightExcludedItems;
	NSArray * _optimizedFilesFilters;
	
	NSTimeInterval _lastRefreshTimeMark;
}

- (IBAction)showInFinder:(id)sender;

- (IBAction)addFiles:(id)sender;
- (IBAction)addNewFolder:(id)sender;

- (IBAction)delete:(id)sender;
- (void)deleteSheetDidEnd:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo;


- (IBAction)expand:(id)sender;
- (IBAction)contract:(id)sender;

// Notifications

- (void)highlightExludedFilesStateDidChange:(NSNotification *)inNotification;

@end

@implementation PKGFilesHierarchyViewController

- (id<PKGFilePathConverter>)filePathConverter
{
	return (id<PKGFilePathConverter>) [NSApplication sharedApplication].delegate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_addButton.enabled=(self.canAddRootNodes==YES);
	_removeButton.enabled=NO;
	
	[_outlineView registerForDraggedTypes:@[NSFilenamesPboardType]];
	 /*ICFilePboardType,
	 ICFileExternalPboardType*/
	
	
    // Do view setup here.
}

#pragma mark -

- (BOOL)highlightExcludedItems
{
	return [PKGApplicationPreferences sharedPreferences].highlightExcludedFiles;
}

#pragma mark -

- (void)WB_viewWillAdd
{
	_viewLabel.stringValue=_label;
	
	_outlineView.dataSource=_hierarchyDatasource;
	
	if ([self.view isKindOfClass:[PKGPayloadDropView class]]==YES)
		((PKGPayloadDropView *)self.view).delegate=(id<PKGFileDeadDropViewDelegate>)_hierarchyDatasource;
	
	
	_highlightExcludedItems=[self highlightExcludedItems];
	_optimizedFilesFilters=[self project].settings.optimizedFilesFilters;
	
	
	_lastRefreshTimeMark=[NSDate timeIntervalSinceReferenceDate];
	// A COMPLETER
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highlightExludedFilesStateDidChange:) name:PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification object:nil];
}

- (void)WB_viewWillRemove
{
	// A COMPLETER
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification object:nil];
}

- (void)refreshHierarchy
{
	[_outlineView reloadData];
}

#pragma mark -

- (void)setHierarchyDatasource:(id<NSOutlineViewDataSource>)inDataSource
{
	_hierarchyDatasource=inDataSource;
	
	if (_outlineView!=nil)
		_outlineView.dataSource=_hierarchyDatasource;
}

- (void)setLabel:(NSString *)inLabel
{
	_label=[inLabel copy];
	
	if (_viewLabel!=nil)
		_viewLabel.stringValue=_label;
}

#pragma mark -

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(PKGPayloadTreeNode *)inPayloadTreeNode
{
	if (inOutlineView!=_outlineView)
		return nil;
	
	NSString * tTableColumnIdentifier=[inTableColumn identifier];
	NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	if ([inPayloadTreeNode needsRefresh:_lastRefreshTimeMark]==YES)
		[inPayloadTreeNode refreshWithAbsolutePath:[inPayloadTreeNode referencedPathUsingConverter:self.filePathConverter]
									   fileFilters:(_highlightExcludedItems==YES) ? _optimizedFilesFilters : nil];
	
	if ([tTableColumnIdentifier isEqualToString:@"file.name"]==YES)
	{
		tView.imageView.image=inPayloadTreeNode.nameIcon;
		
		tView.textField.attributedStringValue=inPayloadTreeNode.nameTitle;
		tView.textField.editable=inPayloadTreeNode.isNameTitleEditable;
		
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
	NSIndexSet * tSelectionIndexSet=_outlineView.selectedOrClickedRowIndexes;
	
	NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
	
	[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
		
		PKGPayloadTreeNode * tPayloadTreeNode=[_outlineView itemAtRow:bIndex];
		
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
	
	__block PKGFilesHierarchyAddPanelDelegate * tPanelDelegate=[PKGFilesHierarchyAddPanelDelegate new];
	
	NSIndexSet * tSelectionIndexSet=_outlineView.selectedOrClickedRowIndexes;
	
	PKGTreeNode * tParentNode=nil;
	
	if (tSelectionIndexSet.count>0)
	{
		NSInteger tClickedRow=_outlineView.clickedRow;
		
		if (tClickedRow==-1)
			tClickedRow=tSelectionIndexSet.firstIndex;
		
		PKGPayloadTreeNode * tNode=[_outlineView itemAtRow:tClickedRow];
		
		tParentNode=(tNode.isLeaf==NO) ? tNode : tNode.parent;
	}
	
	tPanelDelegate.destination=(tParentNode==nil) ? self.hierarchyDatasource.rootNodes : tParentNode;
	
	tOpenPanel.delegate=tPanelDelegate;
	
	tOpenPanel.prompt=NSLocalizedString(@"Add...",@"No comment");
	
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
	
		tPanelDelegate=nil;		// Trick to prevent ARC from deallocating the delegate before the completionHandler is reached
		
		// A COMPLETER
	}];
}

- (IBAction)addNewFolder:(id)sender
{
	NSIndexSet * tSelectionIndexSet=_outlineView.selectedOrClickedRowIndexes;
	
	PKGPayloadTreeNode * tNewFolderNode=nil;
	
	if (tSelectionIndexSet.count==0)
	{
		tNewFolderNode=[PKGPayloadTreeNode newFolderNodeWithSiblingsNodes:self.hierarchyDatasource.rootNodes];
		
		if (tNewFolderNode==nil)
			return;
		
		[self.hierarchyDatasource.rootNodes addObject:tNewFolderNode];	// A CHANGER : sorted insertion
	}
	else
	{
		NSInteger tClickedRow=_outlineView.clickedRow;
		
		if (tClickedRow==-1)
			tClickedRow=tSelectionIndexSet.firstIndex;
		
		PKGPayloadTreeNode * tParentNode=[_outlineView itemAtRow:tClickedRow];
		
		if (tParentNode.isLeaf==NO)
		{
			tNewFolderNode=[PKGPayloadTreeNode newFolderNodeWithParentNode:tParentNode];
			
			// Disclose parent if needed
			
			if ([_outlineView isItemExpanded:tParentNode]==NO)
				[_outlineView expandItem:tParentNode];
		}
		else
		{
			tParentNode=(PKGPayloadTreeNode *)tParentNode.parent;
			
			if (tParentNode!=NULL)
			{
				tNewFolderNode=[PKGPayloadTreeNode newFolderNodeWithSiblingsNodes:tParentNode.children];
			}
			else
			{
				if (self.canAddRootNodes==YES)
					tNewFolderNode=[PKGPayloadTreeNode newFolderNodeWithSiblingsNodes:self.hierarchyDatasource.rootNodes];
			}
		}
		
		if (tNewFolderNode==nil)
			return;
		
		[tParentNode insertChild:tNewFolderNode sortedUsingComparator:^NSComparisonResult(PKGPayloadTreeNode * bPayloadTreeNode,PKGPayloadTreeNode *bOtherPayloadTreeNode){
		
			return [bPayloadTreeNode compareName:bOtherPayloadTreeNode];
		}];
	}
	
	[self noteDocumentHasChanged];
	
	[_outlineView reloadData];
	
	// Enter edition mode
	
	NSInteger tRow=[_outlineView rowForItem:tNewFolderNode];
	
	[_outlineView scrollRowToVisible:tRow];
	
	[_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRow] byExtendingSelection:NO];
	
	[_outlineView editColumn:[_outlineView columnWithIdentifier:@"file.name"] row:tRow withEvent:nil select:YES];
}

- (IBAction)delete:(id)sender
{
	NSInteger tNumberOfSelectedRows=_outlineView.numberOfSelectedRows;
	
	if (tNumberOfSelectedRows<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tNumberOfSelectedRows==1) ? NSLocalizedString(@"Do you really want to remove this item?",@"No comment") : NSLocalizedString(@"Do you really want to remove these items?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(deleteSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)deleteSheetDidEnd:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo
{
	if (inReturnCode!=NSAlertFirstButtonReturn)
		return;
	
	NSArray * tSelectedNodes=[_outlineView selectedItems];
	
	NSArray * tMinimumCover=[PKGTreeNode minimumNodeCoverFromNodesInArray:tSelectedNodes];
	
	for(PKGTreeNode * tTreeNode in tMinimumCover)
	{
		PKGTreeNode * tParentNode=tTreeNode.parent;
		
		// Replace the node with another one if needed
		
		PKGTreeNode * tSurrogateNode=[self.hierarchyDatasource surrogateItemForItem:tTreeNode];
		
		if (tSurrogateNode!=nil)
		{
			if (tTreeNode.parent!=nil)
			{
				NSUInteger tIndex=[tParentNode indexOfChildIdenticalTo:tTreeNode];
			
				if (tIndex!=NSNotFound)
					[tParentNode insertChild:tSurrogateNode atIndex:tIndex];
			}
			else
			{
				NSUInteger tIndex=[self.hierarchyDatasource.rootNodes indexOfObjectIdenticalTo:tTreeNode];
				
				if (tIndex!=NSNotFound)
					[self.hierarchyDatasource.rootNodes insertObject:tSurrogateNode atIndex:tIndex];
			}
		}
		
		if (tParentNode!=nil)
			[tTreeNode removeFromParent];
		else
			[self.hierarchyDatasource.rootNodes removeObject:tTreeNode];
	}
	
	[_outlineView deselectAll:nil];
	
	[self noteDocumentHasChanged];
	
	[_outlineView reloadData];
}

- (IBAction)expand:(id)sender
{
	// A COMPLETER
}

- (IBAction)contract:(id)sender
{
	// A COMPLETER
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tSelector=inMenuItem.action;
	
	NSIndexSet * tSelectionIndexSet=_outlineView.selectedOrClickedRowIndexes;

	
	NSInteger tSelectedCount=tSelectionIndexSet.count;
	
	if (tSelectedCount==0)
	{
		// New Folder
		
		if (tSelector==@selector(addNewFolder:))
			return self.canAddRootNodes;
		
		if (tSelector==@selector(addFiles:))
			return self.canAddRootNodes;
		
		return NO;
	}
	
	if (tSelectedCount>0)
	{
		// Add Files
		
		if (tSelector==@selector(addFiles:))
			return YES;
		
		// New Folder
		
		if (tSelector==@selector(addNewFolder:))
			return YES;
		
		__block BOOL tIsValidated=YES;
		
		// Show in Finder
		
		if (tSelector==@selector(showInFinder:))
		{
			[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
			
				PKGPayloadTreeNode * tPayloadTreeNode=[_outlineView itemAtRow:bIndex];
				
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
		{
			[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
				
				PKGPayloadTreeNode * tPayloadTreeNode=[_outlineView itemAtRow:bIndex];
				
				if ([tPayloadTreeNode isTemplateNode]==YES)
				{
					tIsValidated=NO;
					*bOutStop=NO;
				}
			}];
			
			return tIsValidated;
		}
	}
	
	if (tSelectedCount==1)
	{
		PKGPayloadTreeNode * tPayloadTreeNode=[_outlineView itemAtRow:tSelectionIndexSet.firstIndex];
		
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

#pragma mark - Notifications

- (void)outlineViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=_outlineView)
		return;
	
	NSIndexSet * tSelectionIndexSet=_outlineView.selectedRowIndexes;
	
	// Delete button state
	
	if (tSelectionIndexSet.count==0)
	{
		_addButton.enabled=(self.canAddRootNodes==YES);
		_removeButton.enabled=NO;
		
		return;
	}
	
	_addButton.enabled=YES;
	_removeButton.enabled=YES;
		
	[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
		
		PKGPayloadTreeNode * tPayloadTreeNode=[_outlineView itemAtRow:bIndex];
		
		if ([tPayloadTreeNode isTemplateNode]==YES)
		{
			_removeButton.enabled=NO;
			*bOutStop=NO;
		}
	}];
	
	// A COMPLETER
}

- (void)highlightExludedFilesStateDidChange:(NSNotification *)inNotification
{
	_highlightExcludedItems=[self highlightExcludedItems];
	
	[_outlineView reloadData];
}

@end
