
#import "PKGDistributionRequirementsViewController.h"

#import "PKGCheckboxTableCellView.h"

#import "PKGRequirement.h"

#import "NSTableView+Selection.h"
#import "NSAlert+block.h"

#import "NSArray+UniqueName.h"

#import "PKGRequirementPluginsManager.h"
#import "PKGDistributionRequirementPanel.h"

@interface PKGDistributionRequirementsViewController () <NSTableViewDelegate>
{
	
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	IBOutlet NSButton * _editButton;
}

- (IBAction)addRequirement:(id)sender;
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

- (void)setRequirementsDataSource:(PKGDistributionRequirementsDataSource *)inDataSource
{
	_requirementsDataSource=inDataSource;
	_requirementsDataSource.delegate=self;
	
	if (self.tableView!=nil)
		self.tableView.dataSource=_requirementsDataSource;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	self.tableView.dataSource=self.requirementsDataSource;
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
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
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGRequirement * tRequirement=[self.requirementsDataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	BOOL tNewState=(sender.state==NSOnState);
	
	if (tRequirement.isEnabled==tNewState)
		return;
	
	tRequirement.enabled=tNewState;
	
	[self noteDocumentHasChanged];
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
	PKGRequirement * tNewRequirement=[PKGRequirement new];
	
	tNewRequirement.identifier=@"fr.whitebox.Packages.requirement.os";
	
	PKGDistributionRequirementPanel * tRequirementPanel=[PKGDistributionRequirementPanel distributionRequirementPanel];
	
	tRequirementPanel.requirement=tNewRequirement;
	
	[tRequirementPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult) {
		
		if (bResult==PKGPanelCancelButton)
			return;
		
		NSString * tBaseName=[[PKGRequirementPluginsManager defaultManager]localizedPluginNameForIdentifier:tNewRequirement.identifier];
		
		tNewRequirement.name=[self.requirementsDataSource.items uniqueNameWithBaseName:tBaseName usingNameExtractor:^NSString *(PKGRequirement * bRequirement,NSUInteger bIndex) {
			
			return bRequirement.name;
		}];
		
		if (tNewRequirement.name==nil)
		{
			NSLog(@"Could not determine a unique name for the requirement");
			
			tNewRequirement.name=@"";
		}
		
		[self.requirementsDataSource tableView:self.tableView addItem:tNewRequirement];
		
		// Enter edition mode
		
		NSInteger tRow=self.tableView.selectedRow;
		
		if (tRow==-1)
			return;
		
		[self.tableView scrollRowToVisible:tRow];
		
		[self.tableView editColumn:[self.tableView columnWithIdentifier:@"requirement.name"] row:tRow withEvent:nil select:YES];
	}];
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
	
	[tAlert WB_beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self.requirementsDataSource tableView:self.tableView removeItems:[self.requirementsDataSource tableView:self.tableView itemsAtRowIndexes:tIndexSet]];
	}];
}

- (IBAction)editRequirement:(id)sender
{
	NSUInteger tIndex=self.tableView.WB_selectedOrClickedRowIndexes.firstIndex;
	PKGRequirement * tOriginalRequirement=[self.requirementsDataSource tableView:self.tableView itemAtRow:tIndex];
	PKGRequirement * tEditedRequirement=[tOriginalRequirement copy];
	
	PKGDistributionRequirementPanel * tRequirementPanel=[PKGDistributionRequirementPanel distributionRequirementPanel];
	
	tRequirementPanel.requirement=tEditedRequirement;
	
	[tRequirementPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult) {
		
		if (bResult==PKGPanelCancelButton)
			return;
		
		if ([tEditedRequirement isEqualToRequirement:tOriginalRequirement]==YES)
			return;
		
		[self.requirementsDataSource tableView:self.tableView replaceItemAtIndex:tIndex withItem:tEditedRequirement];
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tSelector=inMenuItem.action;
	
	if (tSelector==@selector(delete:))
	{
		NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
		
		return (tIndexSet.count>0);
	}
	
	return YES;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=[inTableColumn identifier];
	NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	PKGRequirement * tRequirement=[self.requirementsDataSource tableView:self.tableView itemAtRow:inRow];
	
	//if ([tRequirement isKindOfClass:PKGSeparatorFilter.class]==YES)
	//	return nil;
	
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
	
	return nil;
}

- (NSIndexSet *)tableView:(NSTableView *)inTableView selectionIndexesForProposedSelection:(NSIndexSet *)inProposedSelectionIndexes
{
	if (inTableView!=self.tableView)
		return inProposedSelectionIndexes;
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	[inProposedSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
		
		id tItem=[self.requirementsDataSource tableView:self.tableView itemAtRow:bIndex];
		
		if ([tItem isMemberOfClass:PKGRequirement.class]==YES)
			[tMutableIndexSet addIndex:bIndex];
	}];
	
	return [tMutableIndexSet copy];
}

#pragma mark - PKGTableViewDataSourceDelegate

- (void)dataDidChange:(PKGTableViewDataSource *)inDataSource
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
