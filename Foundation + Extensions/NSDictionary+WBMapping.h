
#import <Foundation/Foundation.h>

@interface NSDictionary (WBMapping)

- (instancetype)WBmapObjectsUsingBlock:(id (^)(id bKey,id bObject))inBlock;

- (instancetype)WBmapObjectsLenientlyUsingBlock:(id (^)(id bKey,id bObject))inBlock;

@end
