
#import <AppKit/AppKit.h>

@interface NSOutlineView (Selection)

	@property (readonly, copy) NSIndexSet *selectedOrClickedRowIndexes;

- (NSArray *)selectedItems;

- (NSArray *)selectedOrClickedItems;

@end
