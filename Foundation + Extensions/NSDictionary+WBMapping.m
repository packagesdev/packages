
#import "NSDictionary+WBMapping.h"

@implementation NSDictionary (WBMapping)

- (instancetype)WBmapObjectsUsingBlock:(id (^)(id bKey,id bObject))inBlock
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
	
	if ([[self class] isKindOfClass:[NSMutableDictionary class]]==YES)
		return tMutableDictionary;
	
	return [tMutableDictionary copy];
}

- (instancetype)WBmapObjectsLenientlyUsingBlock:(id (^)(id bKey,id bObject))inBlock
{
	if (inBlock==nil)
		return self;
	
	NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	[self enumerateKeysAndObjectsUsingBlock:^(id bKey, id bObject, BOOL *bOutStop) {
		id tObject=inBlock(bKey,bObject);
		
		if (tObject!=nil)
			[tMutableDictionary setObject:tObject forKey:bKey];
	}];
	
	if ([[self class] isKindOfClass:[NSMutableDictionary class]]==YES)
		return tMutableDictionary;
	
	return [tMutableDictionary copy];
}

@end
