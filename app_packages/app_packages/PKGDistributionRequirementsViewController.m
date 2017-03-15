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

NSString * const PKGDistributionRequirementsDataDidChangeNotification=@"PKGDistributionRequirementsDataDidChangeNotification";

@interface PKGDistributionRequirementsViewController () <NSTableViewDelegate,NSTextFieldDelegate>
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

- (CGFloat)maximumViewHeight
{
	NSUInteger tNumberOfRows=self.dataSource.numberOfItems;
	
	if (tNumberOfRows<3)
		tNumberOfRows=3;
	
	CGFloat tRowHeight=self.outlineView.rowHeight;
	NSSize tIntercellSpacing=self.outlineView.intercellSpacing;
	
	return NSHeight(self.view.frame)-NSHeight(self.outlineView.enclosingScrollView.frame)+tRowHeight*tNumberOfRows+(tNumberOfRows-1)*tIntercellSpacing.height+4.0;
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
	
	[self.outlineView reloadData];
	
	[self.outlineView expandItem:nil expandChildren:YES];
	
	// Restore selection
	
	_addButton.enabled=YES;		// A VIRER
	_removeButton.enabled=NO;
	
	// A COMPLETER
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	// Save selection
	
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
	NSInteger tRow=[self.outlineView rowForView:sender];
	
	if (tRow==-1)
		return;
	
	[self.dataSource outlineView:self.outlineView setItem:[self.outlineView itemAtRow:tRow] state:(sender.state==NSOnState)];
}

- (IBAction)addRequirement:(id)sender
{
	[self.dataSource addRequirement:self.outlineView];
	
	// Enter edition mode
	
	NSInteger tRow=self.outlineView.selectedRow;
	
	if (tRow==-1)
		return;
	
	//[self.view.window makeFirstResponder:self.outlineView];
	
	[self.outlineView editColumn:[self.outlineView columnWithIdentifier:@"requirement"] row:tRow withEvent:nil select:YES];
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

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	return YES;
}

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
	
	PKGDistributionRequirementSourceListTreeNode * tEditedNode=[self.outlineView itemAtRow:tEditedRow];
	
	if ([self.dataSource outlineView:self.outlineView shouldRenameRequirement:tEditedNode as:tTextField.stringValue]==NO)
	{
		NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView rowForItem:tEditedNode]];
		NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView columnWithIdentifier:@"requirement"]];
		
		[self.outlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
		
		return;
	}
	
	[self.dataSource outlineView:self.outlineView renameRequirement:tEditedNode as:tTextField.stringValue];
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(PKGDistributionRequirementSourceListTreeNode *)inSourceListTreeNode
{
	if (inOutlineView!=self.outlineView)
		return nil;
	
	PKGDistributionRequirementSourceListItem * tSourceListItem=inSourceListTreeNode.representedObject;
	
	if ([tSourceListItem isKindOfClass:PKGDistributionRequirementSourceListGroupItem.class]==YES)
	{
		NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
		
		tView.backgroundStyle=NSBackgroundStyleDark;
		tView.textField.stringValue=tSourceListItem.label;
		
		return tView;
	}
	
	if ([tSourceListItem isKindOfClass:PKGDistributionRequirementSourceListRequirementItem.class]==YES)
	{
		NSString * tTableColumnIdentifier=inTableColumn.identifier;
		NSTableCellView * tTableCellView=[inOutlineView makeViewWithIdentifier:@"DataCell" owner:self];
		
		PKGRequirement * tRequirement=((PKGDistributionRequirementSourceListRequirementItem *)tSourceListItem).requirement;
		
		if (tRequirement==nil)
			return nil;
		
		if ([tTableColumnIdentifier isEqualToString:@"requirement"]==YES)
		{
			PKGCheckboxTableCellView * tCheckBoxView=(PKGCheckboxTableCellView *)tTableCellView;
			
			tCheckBoxView.checkbox.state=(tRequirement.isEnabled==YES) ? NSOnState : NSOffState;
			
			tCheckBoxView.textField.stringValue=tRequirement.name;
			tCheckBoxView.textField.editable=YES;
			tCheckBoxView.textField.delegate=self;
			
			return tCheckBoxView;
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGDistributionRequirementsDataDidChangeNotification object:self userInfo:nil];
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
