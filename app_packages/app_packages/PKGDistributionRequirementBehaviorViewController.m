
#import "PKGDistributionRequirementBehaviorViewController.h"

#import "PKGPopUpButtonTableCellView.h"
#import "PKGRequirementFailureMessageTableCellView.h"

#import "PKGRequirementFailureMessage.h"

#import "NSTableView+Selection.h"
#import "NSAlert+block.h"

#import "PKGLocalizationUtilities.h"

@interface PKGDistributionRequirementBehaviorViewController ()
{
	IBOutlet id IBrequirementBehaviorMatrix_;
	
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
}

	@property (readwrite) IBOutlet NSTableView * tableView;

- (IBAction)switchBehavior:(id)sender;

- (IBAction)switchLanguage:(id)sender;

- (IBAction)setMessageTitle:(id)sender;

- (IBAction)setMessageDescription:(id)sender;

- (IBAction)addRequirementMessage:(id)sender;
- (IBAction)delete:(id)sender;

@end

@implementation PKGDistributionRequirementBehaviorViewController

- (void)setDataSource:(PKGDistributionRequirementMessagesDataSource *)inDataSource
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
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self.tableView reloadData];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	// A COMPLETER
}

#pragma mark -

- (IBAction)switchBehavior:(id)sender
{
	// A COMPLETER
}

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
	
	[self.dataSource tableView:self.tableView setTitle:sender.stringValue forItemAtRow:tEditedRow];
}

- (IBAction)setMessageDescription:(NSTextField *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	[self.dataSource tableView:self.tableView setDescription:sender.stringValue forItemAtRow:tEditedRow];
}

- (IBAction)addRequirementMessage:(id)sender
{
	[self.dataSource addNewItem:self.tableView];
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
	
	[tAlert WB_beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
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
		if (inMenuItem.state==NSOnState)
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
		PKGRequirementFailureMessageTableCellView * tMessageView=(PKGRequirementFailureMessageTableCellView *)[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		tMessageView.gridColor=self.tableView.gridColor;
		
		PKGRequirementFailureMessage * tMessage=[self.dataSource tableView:self.tableView itemAtRow:inRow];
		
		if (tMessage==nil)
			return nil;
		
		tMessageView.titleTextField.stringValue=(tMessage.messageTitle==nil) ? @"" : tMessage.messageTitle;
		
		if (tMessageView.descriptionTextField!=nil)
			tMessageView.descriptionTextField.stringValue=(tMessage.messageDescription==nil) ? @"" : tMessage.messageDescription;
		
		return tMessageView;
	}
	
	return nil;
}

#pragma mark - PKGDistributionRequirementMessagesDataSourceDelegate

- (PKGRequirementFailureMessage *)defaultMessage
{
	return [PKGRequirementFailureMessage new];
}

- (void)messagesDataDidChange:(PKGDistributionRequirementMessagesDataSource *)inDataSource
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
