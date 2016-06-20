
#import "NSArray+WBExtensions.h"

@implementation NSArray (WBExtensions)

- (instancetype)WB_arrayByMappingObjectsUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock
{
	if (inBlock==nil)
		return self;
	
	__block NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[self enumerateObjectsUsingBlock:^(id bOject,NSUInteger bIndex,BOOL * bOutStop){
	
		id tObject=inBlock(bOject,bIndex);
		
		if (tObject==nil)
		{
			*bOutStop=YES;
			tMutableArray=nil;
		}
		else
		{
			[tMutableArray addObject:tObject];
		}
	
	}];
	
	if ([self isKindOfClass:[NSMutableArray class]]==YES)
		return tMutableArray;
		
	return [tMutableArray copy];
}

- (instancetype)WB_arrayByMappingObjectsLenientlyUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock
{
	if (inBlock==nil)
		return self;
	
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[self enumerateObjectsUsingBlock:^(id bOject,NSUInteger bIndex,BOOL * bOutStop){
		
		id tObject=inBlock(bOject,bIndex);
		
		if (tObject!=nil)
			[tMutableArray addObject:tObject];
		
	}];
	
	if ([self isKindOfClass:[NSMutableArray class]]==YES)
		return tMutableArray;
	
	return [tMutableArray copy];
}

- (instancetype)WB_filteredArrayUsingBlock:(BOOL (^)(id bObject, NSUInteger bIndex))inBlock
{
	if (inBlock==nil)
		return self;
	
	__block NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[self enumerateObjectsUsingBlock:^(id bOject,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inBlock(bOject,bIndex)==YES)
			[tMutableArray addObject:bOject];
	}];
	
	if ([self isKindOfClass:[NSMutableArray class]]==YES)
		return tMutableArray;
	
	return [tMutableArray copy];
}

@end

@implementation NSMutableArray (WBExtensions)

- (void)WB_mergeWithArray:(NSArray *)inArray
{
	if (inArray==nil)
		return;
	
	[inArray enumerateObjectsUsingBlock:^(id bObject,NSUInteger bIndex,BOOL * bOutStop){
	
		if ([self containsObject:bObject]==NO)
			[self addObject:bObject];
		
	}];
}

@end
