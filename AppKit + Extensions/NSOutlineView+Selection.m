
#import "NSOutlineView+Selection.h"

@implementation NSOutlineView (Selection_WB)

- (NSIndexSet *)WB_selectedOrClickedRowIndexes
{
	NSIndexSet * tSelectionIndexSet=self.selectedRowIndexes;
	
	NSInteger tClickedRow=self.clickedRow;
	
	if (tClickedRow!=-1 && [tSelectionIndexSet containsIndex:tClickedRow]==NO)
		tSelectionIndexSet=[NSIndexSet indexSetWithIndex:tClickedRow];
	
	return tSelectionIndexSet;
}

- (NSArray *)WB_selectedItems
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

- (NSArray *)WB_selectedOrClickedItems
{
	NSIndexSet * tSelectionIndexSet=self.selectedRowIndexes;
	
	NSInteger tClickedRow=self.clickedRow;
	
	if (tClickedRow!=-1 && [tSelectionIndexSet containsIndex:tClickedRow]==NO)
		tSelectionIndexSet=[NSIndexSet indexSetWithIndex:tClickedRow];
	
	NSMutableArray * tMutableSelectedItems=[NSMutableArray array];
	
	[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL *bOutStop){
		
		id tItem=[self itemAtRow:bIndex];
		
		if (tItem!=nil)
			[tMutableSelectedItems addObject:tItem];
		
	}];
	
	return [tMutableSelectedItems copy];
}

- (NSArray *)WB_itemsAtRowIndexes:(NSIndexSet *)inIndexSet
{
	NSMutableArray * tMutableSelectedItems=[NSMutableArray array];
	
	[inIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL *bOutStop){
		
		id tItem=[self itemAtRow:bIndex];
		
		if (tItem!=nil)
			[tMutableSelectedItems addObject:tItem];
		
	}];
	
	return [tMutableSelectedItems copy];
}

@end
