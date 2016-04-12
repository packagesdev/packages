
#import <Foundation/Foundation.h>

@interface NSDictionary (WBMapping)

- (NSDictionary *)WBmapObjectsUsingBlock:(id (^)(id bKey,id bObject))inBlock;

- (NSDictionary *)WBmapObjectsLenientlyUsingBlock:(id (^)(id bKey,id bObject))inBlock;

@end
