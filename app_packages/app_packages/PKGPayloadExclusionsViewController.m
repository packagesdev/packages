
#import "PKGPayloadExclusionsViewController.h"

#import "PKGCheckboxTableCellView.h"
#import "PKGPopUpButtonTableCellView.h"

#import "PKGSeparatorTableRowView.h"

#import "PKGFileFilter.h"

#import "PKGPatternFormatter.h"

#import "NSAlert+block.h"
#import "NSTableView+Selection.h"

@interface PKGPayloadExclusionsViewController () <NSTableViewDelegate>
{
	IBOutlet NSTableView * _tableView;
	
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	
	PKGPatternFormatter * _cachedPatternFormatter;
	
	NSImage * _cachedSmallFileIcon;
	NSImage * _cachedSmallFolderIcon;
	NSImage * _cachedSmallFileFolderIcon;
}

- (IBAction)switchFilterState:(id)sender;
- (IBAction)setPredicatePattern:(id)sender;
- (IBAction)switchPredicateFileType:(id)sender;
- (IBAction)switchPredicateRegularExpressionState:(id)sender;

- (IBAction)addExclusion:(id)sender;
- (IBAction)delete:(id)sender;

@end

@implementation PKGPayloadExclusionsViewController

- (instancetype)initWithNibName:(NSString *)inNibName bundle:(NSBundle *)inNibBundle
{
	self=[super initWithNibName:inNibName bundle:inNibBundle];
	
	if (self!=nil)
	{
		_cachedPatternFormatter=[PKGPatternFormatter new];
		
		_cachedSmallFileIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
		_cachedSmallFileIcon.size=NSMakeSize(16.,16.);
		
		_cachedSmallFolderIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode((kGenericFolderIcon))];
		_cachedSmallFolderIcon.size=NSMakeSize(16.,16.);
		
		_cachedSmallFileFolderIcon=[NSImage imageWithSize:NSMakeSize(16.,16.)
												  flipped:NO
										   drawingHandler:^BOOL(NSRect bDestinationRect){
											   
											   [NSGraphicsContext saveGraphicsState];
											   [NSBezierPath clipRect:NSMakeRect(8.0,0.0,8.0,16.0)];
											   [_cachedSmallFileIcon drawAtPoint:NSMakePoint(+2,0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
											   [NSGraphicsContext restoreGraphicsState];
											   
											   [NSGraphicsContext saveGraphicsState];
											   [NSBezierPath clipRect:NSMakeRect(0.0,0.0,8.0,16.0)];
											   [_cachedSmallFolderIcon drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
											   [NSGraphicsContext restoreGraphicsState];
											   
											   [[NSColor blueColor] set];
											   [NSBezierPath strokeLineFromPoint:NSMakePoint(7.5,0.0) toPoint:NSMakePoint(7.5,16.0)];
											   
											   return YES;
										   }];
	}
	
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark -

- (void)setFileFiltersDataSource:(PKGFileFiltersDataSource *)inDataSource
{
	_fileFiltersDataSource=inDataSource;
	_fileFiltersDataSource.delegate=self;
	
	if (_tableView!=nil)
		_tableView.dataSource=_fileFiltersDataSource;
}

#pragma mark -

- (void)WB_viewWillAdd
{
	_tableView.dataSource=self.fileFiltersDataSource;
}

- (void)WB_viewDidAdd
{
	_addButton.enabled=YES;
	_removeButton.enabled=NO;
}

#pragma mark -

- (IBAction)switchFilterState:(NSButton *)sender
{
	NSInteger tEditedRow=[_tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:_tableView itemAtRow:tEditedRow];
	
	BOOL tNewState=([sender state]==NSOnState);
	
	if (tFilter.isEnabled==tNewState)
		return;
	
	tFilter.enabled=tNewState;
	
	[self noteDocumentHasChanged];
}

- (IBAction)setPredicatePattern:(NSTextField *)sender
{
	NSInteger tEditedRow=[_tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:_tableView itemAtRow:tEditedRow];
	
	NSString * tNewValue=sender.stringValue;
	
	if ([tFilter.predicate.pattern isEqualToString:tNewValue]==YES)
		return;
	
	tFilter.predicate.pattern=tNewValue;
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchPredicateFileType:(NSPopUpButton *)sender
{
	NSInteger tEditedRow=[_tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:_tableView itemAtRow:tEditedRow];
	
	NSInteger tNewFileType=[sender selectedTag];
	
	if (tFilter.predicate.fileType==tNewFileType)
		return;
	
	tFilter.predicate.fileType=tNewFileType;
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchPredicateRegularExpressionState:(NSButton *)sender
{
	NSInteger tEditedRow=[_tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:_tableView itemAtRow:tEditedRow];
	
	BOOL tNewState=([sender state]==NSOnState);
	
	if (tFilter.predicate.isRegularExpression==tNewState)
		return;
	
	tFilter.predicate.regularExpression=tNewState;
	
	[self noteDocumentHasChanged];
}

- (IBAction)addExclusion:(id)sender
{
	PKGFileFilter * tFileFilter=[PKGFileFilter new];
	
	[self.fileFiltersDataSource tableView:_tableView addItem:tFileFilter];
	
	// Enter edition mode
	
	NSInteger tRow=_tableView.selectedRow;
	
	if (tRow==-1)
		return;
	
	[_tableView scrollRowToVisible:tRow];
	
	[_tableView editColumn:[_tableView columnWithIdentifier:@"exclusion.value"] row:tRow withEvent:nil select:YES];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this exclusion?",@"No comment") : NSLocalizedString(@"Do you really want to remove these exclusions?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert WB_beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self.fileFiltersDataSource tableView:_tableView removeItems:[self.fileFiltersDataSource tableView:_tableView itemsAtRowIndexes:tIndexSet]];
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tSelector=inMenuItem.action;

	// A COMPLETER
	
	return YES;
}

#pragma mark - PKGFileFiltersDataSourceDelegate

- (void)fileFiltersDataDidChange:(PKGFileFiltersDataSource *)inFileFiltersDataSource
{
	[self noteDocumentHasChanged];
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=_tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=[inTableColumn identifier];
	NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:_tableView itemAtRow:inRow];
	
	if ([tFilter isKindOfClass:[PKGSeparatorFilter class]]==YES)
		return nil;
	
	if (tFilter==nil)
		return nil;
	
	if ([tTableColumnIdentifier isEqualToString:@"exclusion.state"]==YES)
	{
		PKGCheckboxTableCellView * tCheckBoxView=(PKGCheckboxTableCellView *)tTableCellView;
		
		tCheckBoxView.checkbox.state=(tFilter.isEnabled==YES) ? NSOnState : NSOffState;
		
		return tCheckBoxView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"exclusion.value"]==YES)
	{
		if ([tFilter isKindOfClass:[PKGDefaultFileFilter class]]==YES)
		{
			PKGDefaultFileFilter * tDefaultFileFilter=(PKGDefaultFileFilter *)tFilter;
			
			tTableCellView.textField.formatter=nil;
			
			tTableCellView.textField.stringValue=NSLocalizedString(tDefaultFileFilter.displayName,@"");
			tTableCellView.textField.editable=NO;
		}
		else
		{
			tTableCellView.textField.formatter=_cachedPatternFormatter;
			
			tTableCellView.textField.stringValue=tFilter.predicate.pattern;
			tTableCellView.textField.editable=YES;
		}
		
		return tTableCellView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"exclusion.kind"]==YES)
	{
		PKGPopUpButtonTableCellView * tPopUpButtonView=(PKGPopUpButtonTableCellView *)tTableCellView;
		
		if ([tFilter isKindOfClass:[PKGDefaultFileFilter class]]==YES)
		{
			tPopUpButtonView.hidden=YES;
		}
		else
		{
			tPopUpButtonView.hidden=NO;
			
			NSMenu * tMenu=tPopUpButtonView.popUpButton.menu;
			
			NSMenuItem * tMenuItem=[tMenu itemAtIndex:PKGFileSystemTypeFile];
			tMenuItem.image=_cachedSmallFileIcon;
			
			tMenuItem=[tMenu itemAtIndex:PKGFileSystemTypeFolder];
			tMenuItem.image=_cachedSmallFolderIcon;
			
			tMenuItem=[tMenu itemAtIndex:PKGFileSystemTypeFileorFolder];
			tMenuItem.image=_cachedSmallFileFolderIcon;
			
			[tPopUpButtonView.popUpButton selectItemWithTag:tFilter.predicate.fileType];
		}
		
		return tPopUpButtonView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"exclusion.regularExpression"]==YES)
	{
		PKGCheckboxTableCellView * tCheckBoxView=(PKGCheckboxTableCellView *)tTableCellView;
		
		if ([tFilter isKindOfClass:[PKGDefaultFileFilter class]]==YES)
		{
			tCheckBoxView.hidden=YES;
		}
		else
		{
			tCheckBoxView.hidden=NO;
			tCheckBoxView.checkbox.state=(tFilter.predicate.isRegularExpression==YES) ? NSOnState : NSOffState;
		}
		
		return tCheckBoxView;
	}
	
	return nil;
}

- (CGFloat)tableView:(NSTableView *)inTableView heightOfRow:(NSInteger)inRow
{
	if (inTableView!=_tableView)
		return 17.0;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:_tableView itemAtRow:inRow];
	
	if ([tFilter isKindOfClass:[PKGSeparatorFilter class]]==YES)
		return 8.0;
	
	return 15.0;
}

- (NSTableRowView *)tableView:(NSTableView *)inTableView rowViewForRow:(NSInteger)inRow
{
	if (inTableView!=_tableView)
		return nil;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:_tableView itemAtRow:inRow];
	
	if ([tFilter isKindOfClass:[PKGSeparatorFilter class]]==YES)
	{
		return [PKGSeparatorTableRowView new];
	}
	
	NSTableRowView * tTableRowView=[NSTableRowView new];
	
	if ([tFilter isKindOfClass:[PKGDefaultFileFilter class]]==YES)
	{
		PKGDefaultFileFilter * tDefaultFileFilter=(PKGDefaultFileFilter *)tFilter;
		
		tTableRowView.toolTip=tDefaultFileFilter.tooltip;
	}
	
	return tTableRowView;
}

- (NSIndexSet *)tableView:(NSTableView *)inTableView selectionIndexesForProposedSelection:(NSIndexSet *)inProposedSelectionIndexes
{
	if (inTableView!=_tableView)
		return inProposedSelectionIndexes;
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	[inProposedSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
	
		id tItem=[self.fileFiltersDataSource tableView:_tableView itemAtRow:bIndex];
		
		if ([tItem isMemberOfClass:[PKGFileFilter class]]==YES)
			[tMutableIndexSet addIndex:bIndex];
	}];
	
	return [tMutableIndexSet copy];
}

#pragma mark - Notifications

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=_tableView)
		return;
	
	NSIndexSet * tSelectionIndexSet=_tableView.selectedRowIndexes;
	
	// Delete button state
	
	_removeButton.enabled=(tSelectionIndexSet.count>0);
}

@end
