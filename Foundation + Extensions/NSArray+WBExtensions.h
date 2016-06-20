
#import <Foundation/Foundation.h>

@interface NSArray (WBExtensions)

- (instancetype)WB_arrayByMappingObjectsUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

- (instancetype)WB_arrayByMappingObjectsLenientlyUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

- (instancetype)WB_filteredArrayUsingBlock:(BOOL (^)(id bObject, NSUInteger bIndex))inBlock;

@end

@interface NSMutableArray (WBExtensions)

- (void)WB_mergeWithArray:(NSArray *)inArray;

@end
