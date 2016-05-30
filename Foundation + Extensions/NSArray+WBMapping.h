
#import <Foundation/Foundation.h>

@interface NSArray (WBMapping)

- (NSArray *)WBmapObjectsUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

- (NSArray *)WBmapObjectsLenientlyUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

- (NSArray *)WBfilterObjectsUsingBlock:(BOOL (^)(id bObject, NSUInteger bIndex))inBlock;

@end

@interface NSMutableArray (WBMapping)

- (void)WBmergeWithArray:(NSArray *)inArray;

- (NSMutableArray *)WBmapObjectsUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

- (NSMutableArray *)WBmapObjectsLenientlyUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

@end