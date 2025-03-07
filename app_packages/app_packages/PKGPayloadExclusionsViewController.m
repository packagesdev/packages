/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadExclusionsViewController.h"

#import "PKGCheckboxTableCellView.h"
#import "PKGPopUpButtonTableCellView.h"

#import "PKGSeparatorTableRowView.h"

#import "PKGFileFilter.h"

#import "PKGPatternFormatter.h"

#import "NSTableView+Selection.h"


#import "PKGTableView.h"

@interface PKGTableView_fixed : PKGTableView
@end

@implementation PKGTableView_fixed

- (BOOL)isOpaque
{
	return NO;
}

@end

NSString * const PKGFileFiltersSeparatorTableRowViewIdentifier=@"tablerowview.separator";
NSString * const PKGFileFiltersTableRowViewIdentifier=@"tablerowview.standard";

@interface PKGPayloadExclusionsViewController () <NSTableViewDelegate>
{
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	
	PKGPatternFormatter * _cachedPatternFormatter;
	
	NSImage * _cachedSmallFileIcon;
	NSImage * _cachedSmallFolderIcon;
	NSImage * _cachedSmallFileFolderIcon;
}

	@property (readwrite) IBOutlet NSTableView * tableView;

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
											   [_cachedSmallFileIcon drawAtPoint:NSMakePoint(+2,0) fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
											   [NSGraphicsContext restoreGraphicsState];
											   
											   [NSGraphicsContext saveGraphicsState];
											   [NSBezierPath clipRect:NSMakeRect(0.0,0.0,8.0,16.0)];
											   [_cachedSmallFolderIcon drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
											   [NSGraphicsContext restoreGraphicsState];
											   
											   [[NSColor blueColor] set];
											   [NSBezierPath strokeLineFromPoint:NSMakePoint(7.5,0.0) toPoint:NSMakePoint(7.5,16.0)];
											   
											   return YES;
										   }];
	}
	
	return self;
}

#pragma mark -

- (void)setFileFiltersDataSource:(PKGTableViewDataSource *)inDataSource
{
	_fileFiltersDataSource=inDataSource;
	_fileFiltersDataSource.delegate=self;
	
	if (self.tableView!=nil)
		self.tableView.dataSource=_fileFiltersDataSource;
}

- (void)awakeFromNib
{
	if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
		[self.tableView setBackgroundColor:[NSColor clearColor]];	// Fix a bug in AppKit on OS X 10.10
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	self.tableView.dataSource=self.fileFiltersDataSource;
}

- (void)WB_viewDidAppear
{
	_addButton.enabled=YES;
	_removeButton.enabled=NO;
	
	[self.tableView reloadData];
	
	// Restore selection
	
	// A COMPLETER
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	// Save selection
	
	// A COMPLETER
}

#pragma mark -

- (IBAction)switchFilterState:(NSButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	BOOL tNewState=(sender.state==WBControlStateValueOn);
	
	if (tFilter.isEnabled==tNewState)
		return;
	
	tFilter.enabled=tNewState;
	
	[self noteDocumentHasChanged];
}

- (IBAction)setPredicatePattern:(NSTextField *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	NSString * tNewValue=sender.stringValue;
	
	if ([tFilter.predicate.pattern isEqualToString:tNewValue]==YES)
		return;
	
	tFilter.predicate.pattern=tNewValue;
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchPredicateFileType:(NSPopUpButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	NSInteger tNewFileType=sender.selectedTag;
	
	if (tFilter.predicate.fileType==tNewFileType)
		return;
	
	tFilter.predicate.fileType=tNewFileType;
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchPredicateRegularExpressionState:(NSButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	BOOL tNewState=(sender.state==WBControlStateValueOn);
	
	if (tFilter.predicate.isRegularExpression==tNewState)
		return;
	
	tFilter.predicate.regularExpression=tNewState;
	
	[self noteDocumentHasChanged];
}

- (IBAction)addExclusion:(id)sender
{
	PKGFileFilter * tFileFilter=[PKGFileFilter new];
	
	[self.fileFiltersDataSource tableView:self.tableView addItem:tFileFilter];
	
	// Enter edition mode
	
	NSInteger tRow=self.tableView.selectedRow;
	
	if (tRow==-1)
		return;
	
	[self.tableView scrollRowToVisible:tRow];
	
	[self.tableView editColumn:[self.tableView columnWithIdentifier:@"exclusion.value"] row:tRow withEvent:nil select:YES];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this exclusion?",@"No comment") : NSLocalizedString(@"Do you really want to remove these exclusions?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self.fileFiltersDataSource tableView:self.tableView removeItems:[self.fileFiltersDataSource tableView:self.tableView itemsAtRowIndexes:tIndexSet]];
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;

	if (tAction==@selector(delete:))
	{
		NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
		
		return (tIndexSet.count>0);
	}
	
	return YES;
}

#pragma mark - PKGTableViewDataSourceDelegate

- (void)dataDidChange:(PKGTableViewDataSource *)inDataSource
{
	[self noteDocumentHasChanged];
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:self.tableView itemAtRow:inRow];
	
	if ([tFilter isKindOfClass:PKGSeparatorFilter.class]==YES)
		return nil;
	
	if (tFilter==nil)
		return nil;
	
	if ([tTableColumnIdentifier isEqualToString:@"exclusion.state"]==YES)
	{
		PKGCheckboxTableCellView * tCheckBoxView=(PKGCheckboxTableCellView *)tTableCellView;
		
		tCheckBoxView.checkbox.state=(tFilter.isEnabled==YES) ? WBControlStateValueOn : WBControlStateValueOff;
		
		return tCheckBoxView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"exclusion.value"]==YES)
	{
		if ([tFilter isKindOfClass:PKGDefaultFileFilter.class]==YES)
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
		
		if ([tFilter isKindOfClass:PKGDefaultFileFilter.class]==YES)
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
			
			tMenuItem=[tMenu itemAtIndex:PKGFileSystemTypeFileOrFolder];
			tMenuItem.image=_cachedSmallFileFolderIcon;
			
			[tPopUpButtonView.popUpButton selectItemWithTag:tFilter.predicate.fileType];
		}
		
		return tPopUpButtonView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"exclusion.regularExpression"]==YES)
	{
		PKGCheckboxTableCellView * tCheckBoxView=(PKGCheckboxTableCellView *)tTableCellView;
		
		if ([tFilter isKindOfClass:PKGDefaultFileFilter.class]==YES)
		{
			tCheckBoxView.hidden=YES;
		}
		else
		{
			tCheckBoxView.hidden=NO;
			tCheckBoxView.checkbox.state=(tFilter.predicate.isRegularExpression==YES) ? WBControlStateValueOn : WBControlStateValueOff;
		}
		
		return tCheckBoxView;
	}
	
	return nil;
}

- (CGFloat)tableView:(NSTableView *)inTableView heightOfRow:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return 17;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:self.tableView itemAtRow:inRow];
	
	if ([tFilter isKindOfClass:PKGSeparatorFilter.class]==YES)
		return 8.0;
	
	return 15.0;
}

- (NSTableRowView *)tableView:(NSTableView *)inTableView rowViewForRow:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	PKGFileFilter * tFilter=[self.fileFiltersDataSource tableView:self.tableView itemAtRow:inRow];
	
	if ([tFilter isKindOfClass:PKGSeparatorFilter.class]==YES)
	{
		PKGSeparatorTableRowView * tSeparatorRowView=[inTableView makeViewWithIdentifier:PKGFileFiltersSeparatorTableRowViewIdentifier owner:self];
		
		if (tSeparatorRowView!=nil)
			return tSeparatorRowView;
		
		tSeparatorRowView=[[PKGSeparatorTableRowView alloc] initWithFrame:NSZeroRect];
		tSeparatorRowView.identifier=PKGFileFiltersSeparatorTableRowViewIdentifier;
		
		return tSeparatorRowView;
	}
	
	NSTableRowView * tTableRowView=[inTableView makeViewWithIdentifier:PKGFileFiltersTableRowViewIdentifier owner:self];
	
	if (tTableRowView==nil)
	{
		tTableRowView=[[NSTableRowView alloc] initWithFrame:NSZeroRect];
		tTableRowView.identifier=PKGFileFiltersTableRowViewIdentifier;
	}
	
	if ([tFilter isKindOfClass:PKGDefaultFileFilter.class]==YES)
	{
		PKGDefaultFileFilter * tDefaultFileFilter=(PKGDefaultFileFilter *)tFilter;
		
		tTableRowView.toolTip=(tDefaultFileFilter.tooltip!=nil) ? NSLocalizedString(tDefaultFileFilter.tooltip ,@"") : nil;
	}
	
	return tTableRowView;
}

- (NSIndexSet *)tableView:(NSTableView *)inTableView selectionIndexesForProposedSelection:(NSIndexSet *)inProposedSelectionIndexes
{
	if (inTableView!=self.tableView)
		return inProposedSelectionIndexes;
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	[inProposedSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
	
		id tItem=[self.fileFiltersDataSource tableView:self.tableView itemAtRow:bIndex];
		
		if ([tItem isMemberOfClass:PKGFileFilter.class]==YES)
			[tMutableIndexSet addIndex:bIndex];
	}];
	
	return [tMutableIndexSet copy];
}

#pragma mark - Notifications

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=self.tableView)
		return;
	
	NSIndexSet * tSelectionIndexSet=self.tableView.selectedRowIndexes;
	
	// Delete button state
	
	_removeButton.enabled=(tSelectionIndexSet.count>0);
}

@end
