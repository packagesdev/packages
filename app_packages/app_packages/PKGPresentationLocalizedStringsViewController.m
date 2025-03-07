/*
 Copyright (c) 2017-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationLocalizedStringsViewController.h"

#import "PKGPopUpButtonTableCellView.h"

#import "PKGLocalizationUtilities.h"

#import "NSTableView+Selection.h"

#import "PKGReplaceableStringFormatter.h"

@interface PKGPresentationLocalizedStringsViewController () <NSTableViewDelegate>
{
	IBOutlet NSTextField * _viewLabel;
	
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	
	IBOutlet NSTextField * _viewInformationLabel;
    
    PKGReplaceableStringFormatter * _cachedFormatter;
}

@property (readwrite) IBOutlet NSTableView * tableView;

- (IBAction)switchLanguage:(id)sender;

- (IBAction)setValue:(id)sender;

- (IBAction)addLocalization:(id)sender;
- (IBAction)delete:(id)sender;

@end

@implementation PKGPresentationLocalizedStringsViewController

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

- (void)setLabel:(NSString *)inLabel
{
	if (_label==inLabel)
		return;
	
	_label=[inLabel copy];
	
	[self refreshUI];
}

- (void)setInformationLabel:(NSString *)inInformationLabel
{
	_informationLabel=(inInformationLabel!=nil) ? [inInformationLabel copy] : @"";
	
	[self refreshUI];
}

- (void)setDataSource:(PKGPresentationLocalizationsDataSource *)inDataSource
{
	_dataSource=inDataSource;
	
	if (self.tableView!=nil)
		self.tableView.dataSource=_dataSource;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	self.tableView.dataSource=_dataSource;
	
	[self.tableView reloadData];
	
	[self refreshUI];
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
	
	NSSize tNewWSize=_viewInformationLabel.frame.size;
	
	tInformationlabelFrame.origin.x=NSMaxX(tInformationlabelFrame)-tNewWSize.width;
	tInformationlabelFrame.origin.y=NSMaxY(tInformationlabelFrame)-tNewWSize.height;
	if (tInformationlabelFrame.origin.y<0.0)
		tInformationlabelFrame.origin.y=0.0;
	tInformationlabelFrame.size=tNewWSize;
	
	_viewInformationLabel.frame=tInformationlabelFrame;
}

#pragma mark -

- (IBAction)switchLanguage:(NSPopUpButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	[_dataSource tableView:self.tableView setLanguageTag:sender.selectedTag forItemAtRow:tEditedRow];
}

- (IBAction)setValue:(NSTextField *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	[_dataSource tableView:self.tableView setValue:sender.objectValue forItemAtRow:tEditedRow];
}

- (IBAction)addLocalization:(id)sender
{
	[self.view.window makeFirstResponder:self.tableView];
	
	[_dataSource addNewItem:self.tableView];
	
	[self.tableView editColumn:[self.tableView columnWithIdentifier:@"title.value"]
						   row:self.tableView.selectedRow
					 withEvent:nil
						select:YES];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this localization?",@"No comment") : NSLocalizedString(@"Do you really want to remove these localizations?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self->_dataSource tableView:self.tableView removeItemsAtIndexes:tIndexSet];
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *) inMenuItem
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
		
		return ([[_dataSource availableLanguageTagsSet] containsIndex:inMenuItem.tag]==YES);
	}
	
	return YES;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	
	if ([tTableColumnIdentifier isEqualToString:@"title.language"]==YES)
	{
		PKGPopUpButtonTableCellView * tLanguageView=(PKGPopUpButtonTableCellView *)[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		NSString * tLanguage=[_dataSource tableView:self.tableView languageAtRow:inRow];
		
		NSUInteger tIndex=[[PKGLocalizationUtilities englishLanguages] indexOfObject:tLanguage];
		
		if (tIndex==NSNotFound)
			return nil;
		
		[tLanguageView.popUpButton selectItemWithTag:tIndex];
		
		return tLanguageView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"title.value"]==YES)
	{
       NSString * tTitle=[_dataSource tableView:self.tableView itemAtRow:inRow];
		
		if (tTitle==nil)
			return nil;
		
		NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
        tTableCellView.textField.objectValue=@"";   // Hack to make the textfield to be refreshed when user defined settings are modified.
        if (tTitle!=nil)
           tTableCellView.textField.objectValue=tTitle;
        
        tTableCellView.textField.formatter=_cachedFormatter;
        
		return tTableCellView;
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=self.tableView)
		return;
	
	_addButton.enabled=(_dataSource.localizations.count<[PKGLocalizationUtilities englishLanguages].count);
	
	NSIndexSet * tSelectionIndexSet=self.tableView.selectedRowIndexes;
	
	// Delete button state
	
	_removeButton.enabled=(tSelectionIndexSet.count>0);
}

#pragma mark - Notifications

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfRows)]
                              columnIndexes:[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"title.value"]]];
}


@end
