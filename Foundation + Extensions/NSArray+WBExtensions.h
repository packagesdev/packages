
#import <Foundation/Foundation.h>

@interface NSArray (WBExtensions)

- (instancetype)WBmapObjectsUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

- (instancetype)WBmapObjectsLenientlyUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

- (instancetype)WBfilterObjectsUsingBlock:(BOOL (^)(id bObject, NSUInteger bIndex))inBlock;

@end

@interface NSMutableArray (WBExtensions)

- (void)WBmergeWithArray:(NSArray *)inArray;

@end
