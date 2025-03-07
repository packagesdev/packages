/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadFilesSelectionInspectorRulesViewController.h"

#import "PKGPayloadTreeNode.h"
#import "PKGPayloadBundleItem.h"

#import "PKGCheckboxTableCellView.h"

#import "NSTableView+Selection.h"

#import "NSArray+UniqueName.h"

#import "PKGLocatorPluginsManager.h"
#import "PKGLocatorPanel.h"

#import "NSIndexSet+Analysis.h"

// TODO: Use a sub view controller for the locators (and a data source)

NSString * const PKGBundleLocatorsInternalPboardType=@"fr.whitebox.packages.internal.bundle.locators";

@interface PKGPayloadFilesSelectionInspectorRulesViewController () <NSTableViewDataSource,NSTableViewDelegate>
{
	IBOutlet NSButton * _allowDowngradeCheckBox;
	
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	IBOutlet NSButton * _editButton;
	
	NSIndexSet * _internalDragData;
}

	@property IBOutlet NSTableView * tableView;

- (IBAction)switchAllowDowngrade:(id)sender;

- (IBAction)addLocator:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)editLocator:(id)sender;

- (IBAction)switchLocatorState:(id)sender;
- (IBAction)setLocatorName:(id)sender;

@end

@implementation PKGPayloadFilesSelectionInspectorRulesViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	self.tableView.doubleAction=@selector(editLocator:);
	
	[self.tableView registerForDraggedTypes:@[PKGBundleLocatorsInternalPboardType]];
}

- (void)refreshSingleSelection
{
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
	
	if ([tBundleItem isKindOfClass:PKGPayloadBundleItem.class]==NO)
		return;
	
	// Allow Downgrade
	
	_allowDowngradeCheckBox.state=(tBundleItem.allowDowngrade==YES) ? WBControlStateValueOn : WBControlStateValueOff;
	
	// Locators
	
	[self.tableView reloadData];
}

#pragma mark -

- (IBAction)switchAllowDowngrade:(id)sender
{
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
	
	tBundleItem.allowDowngrade=(_allowDowngradeCheckBox.state==WBControlStateValueOn);
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchLocatorState:(NSButton *)sender
{
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
	NSMutableArray * tLocators=tBundleItem.locators;
	
	NSInteger tRow=[self.tableView rowForView:sender];
	
	if (tRow==-1 || tRow>tLocators.count)
		return;
	
	PKGLocator * tLocator=tLocators[tRow];
	BOOL tEnabled=(sender.state==WBControlStateValueOn);
	
	if (tLocator.isEnabled==tEnabled)
		return;
	
	tLocator.enabled=tEnabled;
	
	[self noteDocumentHasChanged];
}

- (IBAction)setLocatorName:(NSTextField *)sender
{
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
	NSMutableArray * tLocators=tBundleItem.locators;
	
	NSInteger tRow=[self.tableView rowForView:sender];
	
	if (tRow==-1 || tRow>tLocators.count)
		return;
	
	
	NSString * tNewName=sender.stringValue;
	
	if ([tLocators indexOfObjectPassingTest:^BOOL(PKGLocator * bLocator,NSUInteger bIndex,BOOL * bOutStop){
	
		if (bIndex==tRow)
			return NO;
		
		return ([bLocator.name isEqualToString:tNewName]);
	
	}]!=NSNotFound)
	{
		NSBeep();
		
		NSAlert * tAlert=[NSAlert new];
		tAlert.alertStyle=WBAlertStyleCritical;
		tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" can't be used.",@""),tNewName];
		tAlert.informativeText=NSLocalizedString(@"Please choose a different name.",@"");
		
		[tAlert runModal];
		
		[self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tRow]
								  columnIndexes:[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"locator.value"]]];
		
		return;
	}
	
	PKGLocator * tLocator=tLocators[tRow];
	tLocator.name=tNewName;
	
	[self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tRow]
							  columnIndexes:[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"locator.value"]]];
	
	[self noteDocumentHasChanged];
}

- (IBAction)addLocator:(id)sender
{
	[self.view.window makeFirstResponder:self.tableView];
	
	PKGLocator * tNewLocator=[PKGLocator new];
	
	tNewLocator.identifier=@"fr.whitebox.Packages.locator.standard";
	
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	
	PKGLocatorPanel * tLocatorPanel=[PKGLocatorPanel locatorPanel];
	tLocatorPanel.prompt=NSLocalizedString(@"Add", @"");
	
	tLocatorPanel.locator=tNewLocator;
	tLocatorPanel.payloadTreeNode=tTreeNode;
	
	[tLocatorPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult) {
		
		if (bResult==PKGPanelCancelButton)
			return;
		
		PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
		
		NSString * tBaseName=[[PKGLocatorPluginsManager defaultManager]localizedPluginNameForIdentifier:tNewLocator.identifier];
		
		tNewLocator.name=[tBundleItem.locators uniqueNameWithBaseName:tBaseName usingNameExtractor:^NSString *(PKGLocator * bLocator,NSUInteger bIndex) {
		
			return bLocator.name;
		}];
		
		if (tNewLocator.name==nil)
		{
			NSLog(@"Could not determine a unique name for the locator");
			
			tNewLocator.name=@"";
		}
		
		[tBundleItem.locators addObject:tNewLocator];
		
		NSInteger tRow=tBundleItem.locators.count-1;
		
		[self.tableView reloadData];
		
		[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRow] byExtendingSelection:NO];
		
		[self.tableView editColumn:[self.tableView columnWithIdentifier:@"locator.value"]
							   row:tRow
						 withEvent:nil
							select:YES];
		
		[self noteDocumentHasChanged];
	}];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[NSAlert new];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this locator?",@"No comment") : NSLocalizedString(@"Do you really want to remove these locators?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
		PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
		
		[tBundleItem.locators removeObjectsAtIndexes:tIndexSet];
		
		[self.tableView deselectAll:self];
		
		[self.tableView reloadData];
		
		[self noteDocumentHasChanged];
	}];
}

- (IBAction)editLocator:(id)sender
{
	[self.view.window makeFirstResponder:self.tableView];
	
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
	
	PKGLocator * tOriginalLocator=tBundleItem.locators[self.tableView.WB_selectedOrClickedRowIndexes.firstIndex];
	PKGLocator * tEditedLocator=[tOriginalLocator copy];
	
	PKGLocatorPanel * tLocatorPanel=[PKGLocatorPanel locatorPanel];
	
	tLocatorPanel.locator=tEditedLocator;
	tLocatorPanel.payloadTreeNode=tTreeNode;
	
	[tLocatorPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult) {
		
		if (bResult==PKGPanelCancelButton)
			return;
		
		if ([tEditedLocator isEqualToLocator:tOriginalLocator]==YES)
			return;
		
		tBundleItem.locators[self.tableView.WB_selectedOrClickedRowIndexes.firstIndex]=[tEditedLocator copy];
		
		[self noteDocumentHasChanged];
	}];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView==self.tableView)
	{
		PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
		PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
		
		return tBundleItem.locators.count;
	}
	
	return 0;
}

#pragma mark - Drag and Drop support

- (void)tableView:(NSTableView *)inTableView draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:(NSDragOperation)inOperation
{
	_internalDragData=nil;
}

- (BOOL)tableView:(NSTableView *)inTableView writeRowsWithIndexes:(NSIndexSet *)inRowIndexes toPasteboard:(NSPasteboard *)inPasteboard;
{
	_internalDragData=inRowIndexes;
	
	[inPasteboard declareTypes:@[PKGBundleLocatorsInternalPboardType] owner:self];
	
	[inPasteboard setData:[NSData data] forType:PKGBundleLocatorsInternalPboardType];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)inTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)inRow proposedDropOperation:(NSTableViewDropOperation)inDropOperation
{
	if (inDropOperation==NSTableViewDropOn)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	// Internal Drag
	
	if ([tPasteBoard availableTypeFromArray:@[PKGBundleLocatorsInternalPboardType]]!=nil && [info draggingSource]==inTableView)
	{
		if ([_internalDragData WB_containsOnlyOneRange]==YES)
		{
			NSUInteger tFirstIndex=_internalDragData.firstIndex;
			NSUInteger tLastIndex=_internalDragData.lastIndex;
			
			if (inRow>=tFirstIndex && inRow<=(tLastIndex+1))
				return NSDragOperationNone;
		}
		else
		{
			if ([_internalDragData containsIndex:(inRow-1)]==YES)
				return NSDragOperationNone;
		}
		
		return NSDragOperationMove;
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)inTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)inRow dropOperation:(NSTableViewDropOperation)inDropOperation
{
	if (inTableView==nil)
		return NO;
	
	// Internal drag and drop
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[PKGBundleLocatorsInternalPboardType]]!=nil && [info draggingSource]==inTableView)
	{
		PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
		PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
		
		NSArray * tObjects=[tBundleItem.locators objectsAtIndexes:_internalDragData];
		
		[tBundleItem.locators removeObjectsAtIndexes:_internalDragData];
		
		NSUInteger tIndex=[_internalDragData firstIndex];
		
		while (tIndex!=NSNotFound)
		{
			if (tIndex<inRow)
				inRow--;
			
			tIndex=[_internalDragData indexGreaterThanIndex:tIndex];
		}
		
		NSIndexSet * tNewIndexSet=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inRow, _internalDragData.count)];
		
		[tBundleItem.locators insertObjects:tObjects atIndexes:tNewIndexSet];
		
		[inTableView deselectAll:nil];
		
		[inTableView reloadData];
		
		[inTableView selectRowIndexes:tNewIndexSet
				 byExtendingSelection:NO];
		
		return YES;
	}
	
	return NO;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView==self.tableView)
	{
		PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
		PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
		
		PKGLocator * tLocator=tBundleItem.locators[inRow];
		
		PKGCheckboxTableCellView * tCellView=[self.tableView makeViewWithIdentifier:@"locator.value" owner:self];
		
		tCellView.checkbox.state=(tLocator.isEnabled==YES) ? WBControlStateValueOn : WBControlStateValueOff;
		tCellView.textField.stringValue=tLocator.name;
			
		return tCellView;
	}
	
	return nil;
}

// Notifications

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=self.tableView)
		return;
	
	NSIndexSet * tSelectionIndexSet=self.tableView.selectedRowIndexes;
	
	// Delete button state
	
	_removeButton.enabled=(tSelectionIndexSet.count>0);
	_editButton.enabled=(tSelectionIndexSet.count==1);
}

@end
