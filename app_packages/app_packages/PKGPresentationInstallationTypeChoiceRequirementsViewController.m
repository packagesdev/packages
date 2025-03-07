/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationInstallationTypeChoiceRequirementsViewController.h"

#import "PKGRequirement.h"

#import "PKGCheckboxTableCellView.h"

#import "NSTableView+Selection.h"

@interface PKGPresentationInstallationTypeChoiceRequirementsViewController () <NSTableViewDelegate,NSTextFieldDelegate,PKGPresentationInstallationTypeChoiceRequirementsDataSourceDelegate>
{
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	IBOutlet NSButton * _editButton;
}

	@property (readwrite) IBOutlet NSTableView * tableView;

- (IBAction)switchRequirementState:(id)sender;

- (IBAction)addRequirement:(id)sender;

- (IBAction)duplicate:(id)sender;

- (IBAction)editRequirement:(id)sender;

@end

@implementation PKGPresentationInstallationTypeChoiceRequirementsViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	self.tableView.dataSource=self.dataSource;
	self.tableView.doubleAction=@selector(editRequirement:);
	
	[self.tableView registerForDraggedTypes:[PKGPresentationInstallationTypeChoiceRequirementsDataSource supportedDraggedTypes]];
}

- (void)setDataSource:(PKGPresentationInstallationTypeChoiceRequirementsDataSource *)inDataSource
{
	_dataSource=inDataSource;
	_dataSource.delegate=self;
	
	if (self.tableView!=nil)
		self.tableView.dataSource=_dataSource;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self refreshUI];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionDidChangeNotification object:self.tableView userInfo:nil];
}

- (void)refreshUI
{
	[self.tableView reloadData];
}

#pragma mark -

- (IBAction)switchRequirementState:(NSButton *)sender
{
	NSInteger tRow=[self.tableView rowForView:sender];
	
	if (tRow==-1)
		return;
	
	[self.dataSource tableView:self.tableView setItem:[self.dataSource itemAtIndex:tRow] state:(sender.state==WBControlStateValueOn)];
}

- (IBAction)addRequirement:(id)sender
{
	[self.view.window makeFirstResponder:self.tableView];
	
	[self.dataSource tableView:self.tableView addNewRequirementWithCompletionHandler:^(BOOL bSucceeded){
		
		if (bSucceeded==NO)
			return;
		
		// Enter edition mode
		
		NSInteger tRow=self.tableView.selectedRow;
		
		if (tRow==-1)
			return;
		
		[self.tableView editColumn:[self.tableView columnWithIdentifier:@"requirement"] row:tRow withEvent:nil select:YES];
	}];
}

- (IBAction)duplicate:(id)sender
{
	[self.view.window makeFirstResponder:self.tableView];
	
	NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	[self.dataSource tableView:self.tableView duplicateItems:[self.dataSource itemsAtIndexes:tIndexSet]];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this requirement?",@"No comment") : NSLocalizedString(@"Do you really want to remove these requirements?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self.dataSource tableView:self.tableView removeItems:[self.dataSource itemsAtIndexes:tIndexSet]];
	}];
}

- (IBAction)editRequirement:(id)sender
{
	[self.view.window makeFirstResponder:self.tableView];
	
	[self.dataSource editRequirement:self.tableView];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	NSIndexSet * tSelectionIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tAction==@selector(duplicate:) ||
		tAction==@selector(delete:))
		return (tSelectionIndexSet.count>0);
	
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
	
	NSInteger tEditedRow=[self.tableView rowForView:tTextField];
	
	if (tEditedRow==-1)
		return;
	
	PKGRequirement * tEditedRequirement=[self.dataSource itemAtIndex:tEditedRow];
	
	if ([self.dataSource tableView:self.tableView shouldRenameRequirement:tEditedRequirement as:tTextField.stringValue]==NO)
	{
		NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[self.dataSource rowForItem:tEditedRequirement]];
		NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"requirement"]];
		
		[self.tableView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
		
		return;
	}
	
	[self.dataSource tableView:self.tableView renameRequirement:tEditedRequirement as:tTextField.stringValue];
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	PKGRequirement * tRequirement=[self.dataSource itemAtIndex:inRow];
	
	if (tRequirement==nil)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	
	if ([tTableColumnIdentifier isEqualToString:@"requirement"]==YES)
	{
		NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		PKGCheckboxTableCellView * tCheckBoxView=(PKGCheckboxTableCellView *)tTableCellView;
		
		tCheckBoxView.checkbox.state=(tRequirement.isEnabled==YES) ? WBControlStateValueOn : WBControlStateValueOff;
		
		tCheckBoxView.textField.stringValue=tRequirement.name;
		tCheckBoxView.textField.delegate=self;
		
		return tCheckBoxView;
	}
	
	return nil;
}

#pragma mark - PKGPresentationInstallationTypeChoiceRequirementsDataSourceDelegate

- (void)requirementsDataDidChange:(PKGPresentationInstallationTypeChoiceRequirementsDataSource *)inRequirementsDataSource
{
	[self noteDocumentHasChanged];
}

#pragma mark - Notifications

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
