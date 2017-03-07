/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionRequirementsViewController.h"

#import "PKGDistributionRequirementSourceListTreeNode.h"

#import "PKGDistributionRequirementSourceListGroupItem.h"
#import "PKGDistributionRequirementSourceListRequirementItem.h"

#import "NSOutlineView+Selection.h"
#import "NSAlert+block.h"

#import "PKGCheckboxTableCellView.h"

#import "PKGRequirement.h"



#import "PKGRequirementPluginsManager.h"
#import "PKGDistributionRequirementPanel.h"

@interface PKGDistributionRequirementsViewController () <NSTableViewDelegate>
{
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	IBOutlet NSButton * _editButton;
}

- (IBAction)addRequirement:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)editRequirement:(id)sender;

- (IBAction)switchRequirementState:(NSButton *)sender;
- (IBAction)setRequirementName:(id)sender;

@end

@implementation PKGDistributionRequirementsViewController

- (void)WB_viewDidLoad
{
    [super WB_viewDidLoad];
	
	// A COMPLETER
}

#pragma mark -

- (void)setDataSource:(id<NSOutlineViewDataSource>)inDataSource
{
	_dataSource=inDataSource;
	_dataSource.delegate=self;
	
	if (self.outlineView!=nil)
		self.outlineView.dataSource=_dataSource;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	self.outlineView.dataSource=self.dataSource;
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	_addButton.enabled=YES;
	_removeButton.enabled=NO;
	
	[self.outlineView reloadData];
	
	[self.outlineView expandItem:nil expandChildren:YES];
	
	// Restore selection
	
	// A COMPLETER
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	// Save selection
	
	// A COMPLETER
	
	// A COMPLETER
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	// A COMPLETER
}

#pragma mark -

- (IBAction)switchRequirementState:(NSButton *)sender
{
	/*NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGRequirement * tRequirement=[self.requirementsDataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	BOOL tNewState=(sender.state==NSOnState);
	
	if (tRequirement.isEnabled==tNewState)
		return;
	
	tRequirement.enabled=tNewState;
	
	[self noteDocumentHasChanged];*/
}

- (IBAction)setRequirementName:(NSTextField *)sender
{
	/*PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
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
		tAlert.alertStyle=NSCriticalAlertStyle;
		tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" can't be used.",@""),tNewName];
		tAlert.informativeText=NSLocalizedString(@"Please choose a different name.",@"");
		
		[tAlert runModal];
		
		[self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tRow]
									  columnIndexes:[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"requirement.name"]]];
		
		return;
	}
	
	PKGLocator * tLocator=tLocators[tRow];
	tLocator.name=tNewName;
	
	[_locatorsTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tRow]
								  columnIndexes:[NSIndexSet indexSetWithIndex:[_locatorsTableView columnWithIdentifier:@"locator.name"]]];
	
	[self noteDocumentHasChanged];*/
}

- (IBAction)addRequirement:(id)sender
{
	[self.dataSource addRequirement:self.outlineView];
	
	// Enter edition mode
	
	NSInteger tRow=self.outlineView.selectedRow;
	
	if (tRow==-1)
		return;
	
	[self.outlineView scrollRowToVisible:tRow];
	
	[self.outlineView editColumn:[self.outlineView columnWithIdentifier:@"requirement.name"] row:tRow withEvent:nil select:YES];
}

- (IBAction)duplicate:(id)sender
{
	NSIndexSet * tIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	[self.dataSource outlineView:self.outlineView duplicateItems:[self.outlineView WB_itemsAtRowIndexes:tIndexSet]];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this requirement?",@"No comment") : NSLocalizedString(@"Do you really want to remove these requirements?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert WB_beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self.dataSource outlineView:self.outlineView removeItems:[self.outlineView WB_itemsAtRowIndexes:tIndexSet]];
	}];
}

- (IBAction)editRequirement:(id)sender
{
	[self.dataSource editRequirement:self.outlineView];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	BOOL (^validateSelection)(NSIndexSet *) = ^BOOL(NSIndexSet * bSelectionIndex)
	{
		__block BOOL tValidationFailed=NO;
		
		[bSelectionIndex enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
			
			PKGDistributionRequirementSourceListTreeNode * tSourceListTreeNode=[self.outlineView itemAtRow:bIndex];
			PKGDistributionRequirementSourceListRequirementItem * tSourceListItem=tSourceListTreeNode.representedObject;
			
			if ([tSourceListItem isKindOfClass:PKGDistributionRequirementSourceListRequirementItem.class]==NO)
			{
				tValidationFailed=YES;
				*bOutStop=YES;
				return;
			}
		}];
		
		return (tValidationFailed==NO);
	};
	
	if (tAction==@selector(renameRequirement:))
	{
		if (tSelectionIndexSet.count!=1)
			return NO;
		
		return validateSelection(tSelectionIndexSet);
	}
	
	if (tAction==@selector(duplicate:) ||
		tAction==@selector(delete:))
		return validateSelection(tSelectionIndexSet);
	
	return YES;
}

#pragma mark - NSTableViewDelegate

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(PKGDistributionRequirementSourceListTreeNode *)inSourceListTreeNode
{
	if (inOutlineView!=self.outlineView)
		return nil;
	
	PKGDistributionRequirementSourceListItem * tSourceListItem=inSourceListTreeNode.representedObject;
	
	if ([tSourceListItem isKindOfClass:PKGDistributionRequirementSourceListGroupItem.class]==YES)
	{
		/*NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
		
		tView.textField.stringValue=tSourceListItem.label;
		tView.textField.controlSize=NSMiniControlSize;
		
		return tView;*/
		
		return nil;
	}
	
	if ([tSourceListItem isKindOfClass:PKGDistributionRequirementSourceListRequirementItem.class]==YES)
	{
		NSString * tTableColumnIdentifier=inTableColumn.identifier;
		NSTableCellView * tTableCellView=[inOutlineView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		PKGRequirement * tRequirement=((PKGDistributionRequirementSourceListRequirementItem *)tSourceListItem).requirement;
		
		if (tRequirement==nil)
			return nil;
		
		if ([tTableColumnIdentifier isEqualToString:@"requirement.state"]==YES)
		{
			PKGCheckboxTableCellView * tCheckBoxView=(PKGCheckboxTableCellView *)tTableCellView;
			
			tCheckBoxView.checkbox.state=(tRequirement.isEnabled==YES) ? NSOnState : NSOffState;
			
			return tCheckBoxView;
		}
		
		if ([tTableColumnIdentifier isEqualToString:@"requirement.name"]==YES)
		{
			tTableCellView.textField.stringValue=tRequirement.name;
			tTableCellView.textField.editable=YES;
			
			return tTableCellView;
		}
	}
	
	return nil;
	
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isGroupItem:(PKGDistributionRequirementSourceListTreeNode *)inSourceListTreeNode
{
	if (inOutlineView!=self.outlineView)
		return nil;
	
	return ([inSourceListTreeNode.representedObject isKindOfClass:PKGDistributionRequirementSourceListGroupItem.class]==YES);
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldShowOutlineCellForItem:(id)inItem
{
	return NO;
}

- (NSIndexSet *)outlineView:(NSOutlineView *)inOutlineView selectionIndexesForProposedSelection:(NSIndexSet *)inProposedSelectionIndexes
{
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	[inProposedSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
		
		PKGDistributionRequirementSourceListTreeNode * tSourceListTreeNode=[inOutlineView itemAtRow:bIndex];
		
		PKGDistributionRequirementSourceListItem * tSourceListItem=[tSourceListTreeNode representedObject];
		
		if ([tSourceListItem isKindOfClass:PKGDistributionRequirementSourceListGroupItem.class]==YES)
			return;
		
		[tMutableIndexSet addIndex:bIndex];
	}];
	
	return [tMutableIndexSet copy];
}

#pragma mark - PKGDistributionRequirementSourceListDataSourceDelegate

- (void)sourceListDataDidChange:(PKGDistributionRequirementSourceListDataSource *)inSourceListDataSource
{
	[self noteDocumentHasChanged];
}

#pragma mark - Notifications

- (void)outlineViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=self.outlineView)
		return;
	
	NSIndexSet * tSelectionIndexSet=self.outlineView.selectedRowIndexes;
	
	// Delete button state
	
	_removeButton.enabled=(tSelectionIndexSet.count>0);
	_editButton.enabled=(tSelectionIndexSet.count==1);
}

@end
