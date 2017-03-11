
#import "NSDictionary+WBExtensions.h"

@implementation NSDictionary (WBExtensions)

- (instancetype)WB_dictionaryByMappingKeysUsingBlock:(id (^)(id bKey,id bObject))inBlock
{
	if (inBlock==nil)
		return self;
	
	__block NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id bKey, id bObject, BOOL *bOutStop) {
		id tKey=inBlock(bKey,bObject);
		
		if (tKey==nil)
		{
			*bOutStop=YES;
			tMutableDictionary=nil;
		}
		else
		{
			tMutableDictionary[tKey]=bObject;
		}
	}];
	
	if ([self isKindOfClass:NSMutableDictionary.class]==YES)
		return tMutableDictionary;
	
	return [tMutableDictionary copy];
}

- (instancetype)WB_dictionaryByMappingObjectsUsingBlock:(id (^)(id bKey,id bObject))inBlock
{
	if (inBlock==nil)
		return self;
	
	__block NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id bKey, id bObject, BOOL *bOutStop) {
		id tObject=inBlock(bKey,bObject);
		
		if (tObject==nil)
		{
			*bOutStop=YES;
			tMutableDictionary=nil;
		}
		else
		{
			tMutableDictionary[bKey]=tObject;
		}
	}];
	
	if ([self isKindOfClass:NSMutableDictionary.class]==YES)
		return tMutableDictionary;
	
	return [tMutableDictionary copy];
}

- (instancetype)WB_dictionaryByMappingObjectsLenientlyUsingBlock:(id (^)(id bKey,id bObject))inBlock
{
	if (inBlock==nil)
		return self;
	
	NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id bKey, id bObject,__attribute__((unused))BOOL *bOutStop) {
		id tObject=inBlock(bKey,bObject);
		
		if (tObject!=nil)
			tMutableDictionary[bKey]=tObject;
	}];
	
	if ([self isKindOfClass:NSMutableDictionary.class]==YES)
		return tMutableDictionary;
	
	return [tMutableDictionary copy];
}

- (instancetype)WB_filteredDictionaryUsingBlock:(BOOL (^)(id bKey,id bObject))inBlock
{
	if (inBlock==nil)
		return self;
	
	NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id bKey, id bObject,__attribute__((unused))BOOL *bOutStop) {
		BOOL tDoNotFilter=inBlock(bKey,bObject);
		
		if (tDoNotFilter==YES)
			tMutableDictionary[bKey]=bObject;
	}];
	
	if ([self isKindOfClass:NSMutableDictionary.class]==YES)
		return tMutableDictionary;
	
	return [tMutableDictionary copy];
}

@end
