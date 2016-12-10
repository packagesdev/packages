
#import "NSOutlineView+Selection.h"

@implementation NSOutlineView (Selection)

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
