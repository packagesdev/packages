/*
 Copyright (c) 2017-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementBehaviorViewController.h"

#import "PKGPopUpButtonTableCellView.h"
#import "PKGRequirementFailureMessageTableCellView.h"

#import "PKGRequirementFailureMessage.h"

#import "NSTableView+Selection.h"

#import "PKGLocalizationUtilities.h"

#import "PKGReplaceableStringFormatter.h"

@interface PKGRequirementBehaviorViewController () <NSTextFieldDelegate>
{
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
    
    PKGReplaceableStringFormatter * _cachedFormatter;
}

	@property (readwrite) IBOutlet NSTableView * tableView;


- (IBAction)switchLanguage:(id)sender;

- (IBAction)setMessageTitle:(id)sender;

- (IBAction)setMessageDescription:(id)sender;


- (IBAction)addRequirementMessage:(id)sender;

- (IBAction)delete:(id)sender;

@end

@implementation PKGRequirementBehaviorViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
    self=[super initWithDocument:inDocument];
    
    if (self!=nil)
    {
        _cachedFormatter=[PKGReplaceableStringFormatter new];
        _cachedFormatter.keysReplacer=self;
    }
    
    return self;
}

- (void)setDataSource:(PKGRequirementMessagesDataSource *)inDataSource
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
	
	self.tableView.dataSource=self.dataSource;
	
	[self refreshUI];
}

- (void)refreshUI
{
	[self.tableView reloadData];
}

#pragma mark -

- (IBAction)switchLanguage:(NSPopUpButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	[self.dataSource tableView:self.tableView setLanguageTag:sender.selectedTag forItemAtRow:tEditedRow];
}

- (IBAction)setMessageTitle:(NSTextField *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	[self.dataSource tableView:self.tableView setTitle:sender.objectValue forItemAtRow:tEditedRow];
}

- (IBAction)setMessageDescription:(NSTextField *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	[self.dataSource tableView:self.tableView setDescription:sender.objectValue forItemAtRow:tEditedRow];
}

- (IBAction)addRequirementMessage:(id)sender
{
	[self.dataSource addNewItem:self.tableView];
	
	NSInteger tSelectedRow=self.tableView.selectedRow;
		
	if (tSelectedRow!=-1)
		[self.tableView editColumn:[self.tableView columnWithIdentifier:@"message.value"] row:tSelectedRow withEvent:nil select:YES];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this message?",@"No comment") : NSLocalizedString(@"Do you really want to remove these messages?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self.dataSource tableView:self.tableView removeItemsAtIndexes:tIndexSet];
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
	
	if (tAction==@selector(switchLanguage:))
	{
		if (inMenuItem.state==WBControlStateValueOn)
			return YES;
		
		return ([[self.dataSource availableLanguageTagsSet] containsIndex:inMenuItem.tag]==YES);
	}
	
	return YES;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	
	if ([tTableColumnIdentifier isEqualToString:@"message.language"]==YES)
	{
		PKGPopUpButtonTableCellView * tLanguageView=(PKGPopUpButtonTableCellView *)[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
		NSString * tLanguage=[self.dataSource tableView:self.tableView languageAtRow:inRow];
		
		NSUInteger tIndex=[[PKGLocalizationUtilities englishLanguages] indexOfObject:tLanguage];
		
		if (tIndex==NSNotFound)
			return nil;
		
		[tLanguageView.popUpButton selectItemWithTag:tIndex];
	
		return tLanguageView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"message.value"]==YES)
	{
		PKGRequirementFailureMessage * tMessage=[self.dataSource tableView:self.tableView itemAtRow:inRow];
		
		if (tMessage==nil)
			return nil;
		
		NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		if ([tTableCellView isKindOfClass:PKGRequirementFailureMessageTableCellView.class]==NO)
		{
            tTableCellView.textField.objectValue=@"";
            if (tMessage.messageTitle!=nil)
                tTableCellView.textField.objectValue=tMessage.messageTitle;
            
            tTableCellView.textField.formatter=_cachedFormatter;
		}
		else
		{
			PKGRequirementFailureMessageTableCellView * tMessageView=(PKGRequirementFailureMessageTableCellView *)tTableCellView;
		
			tMessageView.gridColor=self.tableView.gridColor;
			
            tMessageView.titleTextField.objectValue=@"";
            if (tMessage.messageTitle!=nil)
                tMessageView.titleTextField.objectValue=tMessage.messageTitle;
			
            tMessageView.titleTextField.formatter=_cachedFormatter;
            
			if (tMessageView.descriptionTextField!=nil)
            {
                tMessageView.descriptionTextField.objectValue=@"";
                if (tMessage.messageDescription!=nil)
                    tMessageView.descriptionTextField.objectValue=tMessage.messageDescription;
                
                tMessageView.descriptionTextField.formatter=_cachedFormatter;
            }
		}
		
		return tTableCellView;
	}
	
	return nil;
}

#pragma mark - PKGDistributionRequirementMessagesDataSourceDelegate

- (PKGRequirementFailureMessage *)defaultMessage
{
	return [PKGRequirementFailureMessage new];
}

- (void)messagesDataDidChange:(PKGRequirementMessagesDataSource *)inDataSource
{
}

#pragma mark -

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=self.tableView)
		return;
	
	_addButton.enabled=(self.dataSource.messages.count<[PKGLocalizationUtilities englishLanguages].count);
		
	NSIndexSet * tSelectionIndexSet=self.tableView.selectedRowIndexes;
	
	// Delete button state
	
	_removeButton.enabled=(tSelectionIndexSet.count>0);
}

@end
