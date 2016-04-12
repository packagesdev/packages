
#import "NSDictionary+WBMapping.h"

@implementation NSDictionary (WBMapping)

- (NSDictionary *)WBmapObjectsUsingBlock:(id (^)(id bKey,id bObject))inBlock
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
			[tMutableDictionary setObject:tObject forKey:bKey];
		}
	}];
	
	return [tMutableDictionary copy];
}

- (NSDictionary *)WBmapObjectsLenientlyUsingBlock:(id (^)(id bKey,id bObject))inBlock
{
	if (inBlock==nil)
		return self;
	
	NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id bKey, id bObject, BOOL *bOutStop) {
		id tObject=inBlock(bKey,bObject);
		
		if (tObject!=nil)
			[tMutableDictionary setObject:tObject forKey:bKey];
	}];
	
	return [tMutableDictionary copy];
}

@end
