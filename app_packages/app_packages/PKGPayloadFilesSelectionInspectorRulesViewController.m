
#import "PKGPayloadFilesSelectionInspectorRulesViewController.h"

#import "PKGPayloadTreeNode.h"
#import "PKGPayloadBundleItem.h"

@interface PKGPayloadFilesSelectionInspectorRulesViewController () <NSTableViewDataSource,NSTableViewDelegate>
{
	IBOutlet NSButton * _allowDowngradeCheckBox;
	
	IBOutlet NSTableView * _locatorsTableView;
	
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	IBOutlet NSButton * _editButton;
}

- (IBAction)switchAllowDowngrade:(id)sender;

- (IBAction)addLocator:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)editLocator:(id)sender;

@end

@implementation PKGPayloadFilesSelectionInspectorRulesViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// A COMPLETER
}

- (void)refreshSingleSelection
{
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
	
	// Allow Downgrade
	
	_allowDowngradeCheckBox.state=(tBundleItem.allowDowngrade==YES) ? NSOnState : NSOffState;
	
	// Locators
	
	// A COMPLETER
	
	[_locatorsTableView reloadData];
}

#pragma mark -

- (IBAction)switchAllowDowngrade:(id)sender
{
	// A COMPLETER
}

- (IBAction)addLocator:(id)sender
{
	// A COMPLETER
}

- (IBAction)delete:(id)sender
{
	// A COMPLETER
}

- (IBAction)editLocator:(id)sender
{
	// A COMPLETER
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView==_locatorsTableView)
	{
		PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
		PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
		
		return tBundleItem.locators.count;
	}
	return 0;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView==_locatorsTableView)
	{
		PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
		PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
		
		// A COMPLETER
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	// A COMPLETER
}

@end
