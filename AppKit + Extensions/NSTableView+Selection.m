
#import "NSTableView+Selection.h"

@implementation NSTableView (Selection_WB)

- (NSIndexSet *)WB_selectedOrClickedRowIndexes
{
	NSIndexSet * tSelectionIndexSet=self.selectedRowIndexes;
	
	NSInteger tClickedRow=self.clickedRow;
	
	if (tClickedRow!=-1 && [tSelectionIndexSet containsIndex:tClickedRow]==NO)
		tSelectionIndexSet=[NSIndexSet indexSetWithIndex:tClickedRow];
	
	return tSelectionIndexSet;
}

@end
