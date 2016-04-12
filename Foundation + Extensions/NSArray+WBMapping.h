
#import <Foundation/Foundation.h>

@interface NSArray (WBMapping)

- (NSArray *)WBmapObjectsUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

- (NSArray *)WBmapObjectsLenientlyUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

@end

@interface NSMutableArray (WBMapping)

- (NSMutableArray *)WBmapObjectsUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

- (NSMutableArray *)WBmapObjectsLenientlyUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock;

@end