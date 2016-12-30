
#import <AppKit/AppKit.h>

#import "NSTableView+Selection.h"

@interface NSOutlineView (Selection_WB)

- (NSArray *)WB_selectedItems;

- (NSArray *)WB_selectedOrClickedItems;

- (NSArray *)WB_itemsAtRowIndexes:(NSIndexSet *)inIndexSet;

@end
