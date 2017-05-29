
#import "PKGPresentationInstallationTypeChoiceRequirementsViewController.h"

@interface PKGPresentationInstallationTypeChoiceRequirementsViewController () <NSTableViewDelegate>

	@property (readwrite) IBOutlet NSTableView * tableView;

- (IBAction)switchRequirementState:(id)sender;
- (IBAction)addRequirement:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)editRequirement:(id)sender;

@end

@implementation PKGPresentationInstallationTypeChoiceRequirementsViewController

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self refreshUI];
}

- (void)refreshUI
{
	[self.tableView reloadData];
}

#pragma mark -

- (IBAction)switchRequirementState:(NSButton *)sender
{
	/*NSInteger tRow=[self.tableView rowForView:sender];
	
	if (tRow==-1)
		return;
	
	[self.dataSource tableView:self.tableView setItem:[self.dataSource itemAtIndex:tRow] state:(sender.state==NSOnState)];*/
}

- (IBAction)addRequirement:(id)sender
{
	/*[self.view.window makeFirstResponder:self.tableView];
	
	[self.dataSource tableView:self.tableView addNewRequirementWithCompletionHandler:^(BOOL bSucceeded){
		
		if (bSucceeded==NO)
			return;
		
		// Enter edition mode
		
		NSInteger tRow=self.tableView.selectedRow;
		
		if (tRow==-1)
			return;
		
		[self.tableView editColumn:[self.tableView columnWithIdentifier:@"requirement"] row:tRow withEvent:nil select:YES];
	}];*/
}

- (IBAction)duplicate:(id)sender
{
	/*[self.view.window makeFirstResponder:self.tableView];
	
	NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	[self.dataSource tableView:self.tableView duplicateItems:[self.dataSource itemsAtIndexes:tIndexSet]];*/
}

- (IBAction)delete:(id)sender
{
	/*NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
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
		
		[self.dataSource tableView:self.tableView removeItems:[self.dataSource itemsAtIndexes:tIndexSet]];
	}];*/
}

- (IBAction)editRequirement:(id)sender
{
	/*[self.view.window makeFirstResponder:self.tableView];
	
	[self.dataSource editRequirement:self.tableView];*/
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	/*SEL tAction=inMenuItem.action;
	
	NSIndexSet * tSelectionIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	BOOL (^validateSelection)(NSIndexSet *) = ^BOOL(NSIndexSet * bSelectionIndex)
	{
		__block BOOL tValidationFailed=NO;
		
		[bSelectionIndex enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
			
			PKGDistributionRequirementSourceListNode * tSourceListNode=[self.dataSource itemAtIndex:bIndex];
			PKGDistributionRequirementSourceListRequirementItem * tSourceListItem=tSourceListNode.representedObject;
			
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
		return validateSelection(tSelectionIndexSet);*/
	
	return YES;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	// A COMPLETER
	
	return nil;
}

@end
