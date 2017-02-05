
#import "PKGFilesSelectionInspectorTabViewItemViewController.h"

@interface PKGFilesSelectionInspectorTabViewItemViewController ()

@end

@implementation PKGFilesSelectionInspectorTabViewItemViewController

- (void)setSelectedItems:(NSArray *)inSelectedItems
{
	if ([_selectedItems isEqualToArray:inSelectedItems]==NO)
	{
		_selectedItems=inSelectedItems;
		[self refreshUI];
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
}

- (void)WB_viewDidAppear
{
	[self refreshUI];
	
	// Register for notifications (rename folder)
	
	// A COMPLETER
}

- (void)WB_viewWillDisappear
{
}

- (void)WB_viewDidDisappear
{
}

#pragma mark -

- (void)refreshUI
{
	if (self.selectedItems==nil)
		return;
	
	if (self.selectedItems.count>1)
		[self refreshMultipleSelection];
	else
		[self refreshSingleSelection];
}

- (void)refreshSingleSelection
{
}

- (void)refreshMultipleSelection
{
}

@end
