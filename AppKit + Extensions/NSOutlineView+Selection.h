
#import <AppKit/AppKit.h>

@interface NSOutlineView (Selection_WB)

	@property (readonly, copy) NSIndexSet *WB_selectedOrClickedRowIndexes;

- (NSArray *)WB_selectedItems;

- (NSArray *)WB_selectedOrClickedItems;

- (NSArray *)WB_itemsAtRowIndexes:(NSIndexSet *)inIndexSet;

@end
