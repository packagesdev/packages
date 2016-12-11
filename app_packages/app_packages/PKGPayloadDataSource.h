
#import <AppKit/AppKit.h>

@interface PKGPayloadDataSource : NSObject <NSOutlineViewDataSource>

	@property NSMutableArray * rootNodes;

- (id)surrogateItemForItem:(id)inItem;

@end
