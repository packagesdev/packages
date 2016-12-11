
#import "NSOutlineView+Selection.h"

@implementation NSOutlineView (Selection)

- (NSIndexSet *)selectedOrClickedRowIndexes
{
	NSIndexSet * tSelectionIndexSet=self.selectedRowIndexes;
	
	NSInteger tClickedRow=self.clickedRow;
	
	if (tClickedRow!=-1 && [tSelectionIndexSet containsIndex:tClickedRow]==NO)
		tSelectionIndexSet=[NSIndexSet indexSetWithIndex:tClickedRow];
	
	return tSelectionIndexSet;
}

- (NSArray *)selectedItems
{
	NSIndexSet * tIndexSet=[self selectedRowIndexes];
	NSMutableArray * tMutableSelectedItems=[NSMutableArray array];
	
	[tIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL *bOutStop){
	
		id tItem=[self itemAtRow:bIndex];
		
		if (tItem!=nil)
			[tMutableSelectedItems addObject:tItem];
	
	}];
	
	return [tMutableSelectedItems copy];
}

@end
