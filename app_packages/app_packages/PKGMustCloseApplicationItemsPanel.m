/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGMustCloseApplicationItemsPanel.h"

#import "PKGMustCloseApplicationItemsDataSource.h"

#import "NSTableView+Selection.h"

#import "PKGMustCloseApplicationItemCellView.h"


@interface PKGMustCloseApplicationItemsWindowController : NSWindowController <NSTableViewDelegate,PKGMustCloseApplicationItemsDataSourceDelegate>
{
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
}

	@property IBOutlet NSTableView * tableView;

	@property (nonatomic) PKGMustCloseApplicationItemsDataSource * dataSource;


- (IBAction)addApplicationItem:(id)sender;

- (IBAction)switchMustCloseApplicationItemState:(NSButton *)sender;

- (IBAction)setApplicationID:(id)sender;

- (IBAction)delete:(id)sender;

- (IBAction)endDialog:(id)sender;

- (void)refreshUI;

@end

@implementation PKGMustCloseApplicationItemsWindowController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"PKGMustCloseApplicationItemsPanel";
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[self.tableView registerForDraggedTypes:[PKGMustCloseApplicationItemsDataSource supportedDraggedTypes]];
}

#pragma mark -

- (void)setDataSource:(id<NSTableViewDataSource>)inDataSource
{
	_dataSource=inDataSource;
	_dataSource.delegate=self;
	
	if (self.tableView!=nil)
		self.tableView.dataSource=_dataSource;
}

#pragma mark -

- (void)refreshUI
{
	if (self.tableView==nil)
		return;
	
	[self.tableView reloadData];
	
	_addButton.enabled=YES;		// A VIRER
	_removeButton.enabled=NO;
}

#pragma mark -

- (IBAction)addApplicationItem:(id)sender
{
	[self.window makeFirstResponder:self.tableView];
	
	[self.dataSource addNewItem:self.tableView];
		
	// Enter edition mode
	
	NSInteger tRow=self.tableView.selectedRow;
	
	if (tRow==-1)
		return;
	
	[self.tableView editColumn:[self.tableView columnWithIdentifier:@"applicationItem"] row:tRow withEvent:nil select:YES];
}

- (IBAction)switchMustCloseApplicationItemState:(NSButton *)sender
{
	NSInteger tRow=[self.tableView rowForView:sender];
	
	if (tRow==-1)
		return;
	
	[self.dataSource tableView:self.tableView setItem:[self.dataSource itemAtRow:tRow] state:(sender.state==NSOnState)];
}

- (IBAction)setApplicationID:(NSTextField *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	id tItem=[self.dataSource itemAtRow:tEditedRow];
	
	if ([self.dataSource tableView:self.tableView shouldReplaceApplicationIDOfItem:tItem withString:[sender stringValue]]==NO)
		return;
	
	[self.dataSource tableView:self.tableView replaceApplicationIDOfItem:tItem withString:[sender stringValue]];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	[self.dataSource tableView:self.tableView removeItemsAtIndexes:tIndexSet];
}

- (IBAction)endDialog:(NSButton *)sender
{
	[NSApp endSheet:self.window returnCode:sender.tag];
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	PKGCheckboxTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	PKGMustCloseApplicationItem * tMustCloseApplicationItem=[self.dataSource itemAtRow:inRow];
	
	if ([tTableColumnIdentifier isEqualToString:@"applicationItem"]==YES)
	{
		tTableCellView.checkbox.state=(tMustCloseApplicationItem.isEnabled==YES) ? NSOnState : NSOffState;
		tTableCellView.textField.stringValue=tMustCloseApplicationItem.applicationID;
		
		/*NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
		
		NSURL * tURL=[tSharedWorkspace URLForApplicationWithBundleIdentifier:tMustCloseApplicationItem.applicationID];
		
		NSLog(@"%@",tURL);*/
		
		return tTableCellView;
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=self.tableView)
		return;
	
	NSIndexSet * tSelectionIndexSet=self.tableView.selectedRowIndexes;
	
	// Delete button state
	
	_removeButton.enabled=(tSelectionIndexSet.count>0);
}

#pragma mark - PKGApplicationIDsDataSourceDelegate

- (void)mustCloseApplicationItemsDataDidChange:(PKGMustCloseApplicationItemsDataSource *)inApplicationIDsDataSource
{
	// A COMPLETER
}

@end


@interface PKGMustCloseApplicationItemsPanel ()

	@property PKGMustCloseApplicationItemsWindowController * retainedWindowController;


- (void)_sheetDidEndSelector:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;

@end
	
@implementation PKGMustCloseApplicationItemsPanel

+ (PKGMustCloseApplicationItemsPanel *)mustCloseApplicationItemsPanel
{
	PKGMustCloseApplicationItemsWindowController * tWindowController=[PKGMustCloseApplicationItemsWindowController new];
	
	PKGMustCloseApplicationItemsPanel * tPanel=(PKGMustCloseApplicationItemsPanel *)tWindowController.window;
	tPanel.retainedWindowController=tWindowController;
	
	return tPanel;
}

#pragma mark -

- (NSMutableArray *)mustCloseApplicationItems
{
	return self.retainedWindowController.dataSource.mustCloseApplicationItems;
}

- (void)setMustCloseApplicationItems:(NSMutableArray *)inApplicationIDs
{
	PKGMustCloseApplicationItemsDataSource * tDataSource=[PKGMustCloseApplicationItemsDataSource new];
	
	tDataSource.mustCloseApplicationItems=inApplicationIDs;
	
	self.retainedWindowController.dataSource=tDataSource;
}

#pragma mark -

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSInteger result))handler;
{
	[self.retainedWindowController refreshUI];
	
	[NSApp beginSheet:self
	   modalForWindow:inWindow
		modalDelegate:self
	   didEndSelector:@selector(_sheetDidEndSelector:returnCode:contextInfo:)
		  contextInfo:(__bridge_retained void*)[handler copy]];
}

- (void)_sheetDidEndSelector:(PKGMustCloseApplicationItemsPanel *)inPanel returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger result) = (__bridge_transfer void(^)(NSInteger result)) contextInfo;
	
	if (handler!=nil)
		handler(inReturnCode);
	
	inPanel.retainedWindowController=nil;
	
	[inPanel orderOut:self];
}

@end
