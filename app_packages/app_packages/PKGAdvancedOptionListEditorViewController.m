
#import "PKGAdvancedOptionListEditorViewController.h"

#import "PKGCheckboxTableCellView.h"

@interface PKGAdvancedOptionListEditorViewController () <NSTableViewDelegate>
{
	IBOutlet NSTextField * _label;
}

	@property (readwrite) IBOutlet NSTableView * tableView;

@end

@implementation PKGAdvancedOptionListEditorViewController

- (void)WB_viewDidLoad
{
	// A COMPLETER
}

- (void)WB_viewWillAppear
{
	// A COMPLETER
}


#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	// A COMPLETER
	
	return nil;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	return [NSIndexSet indexSet];
}

@end
