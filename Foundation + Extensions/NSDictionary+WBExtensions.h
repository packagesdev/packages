
#import <Foundation/Foundation.h>

@interface NSDictionary (WBExtensions)

- (instancetype)WB_dictionaryByMappingKeysUsingBlock:(id (^)(id bKey,id bObject))inBlock;

- (instancetype)WB_dictionaryByMappingObjectsUsingBlock:(id (^)(id bKey,id bObject))inBlock;

- (instancetype)WB_dictionaryByMappingObjectsLenientlyUsingBlock:(id (^)(id bKey,id bObject))inBlock;

- (instancetype)WB_filteredDictionaryUsingBlock:(BOOL (^)(id bKey,id bObject))inBlock;

@end
