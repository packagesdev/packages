
#import "NSArray+WBMapping.h"

@implementation NSArray (WBMapping)

- (NSArray *)WBmapObjectsUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock
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
	
	return [tMutableArray copy];
}

- (NSArray *)WBmapObjectsLenientlyUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock
{
	if (inBlock==nil)
		return self;
	
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[self enumerateObjectsUsingBlock:^(id bOject,NSUInteger bIndex,BOOL * bOutStop){
		
		id tObject=inBlock(bOject,bIndex);
		
		if (tObject!=nil)
			[tMutableArray addObject:tObject];
		
	}];
	
	return [tMutableArray copy];
}

- (NSArray *)WBfilterObjectsUsingBlock:(BOOL (^)(id bObject, NSUInteger bIndex))inBlock
{
	if (inBlock==nil)
		return self;
	
	__block NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[self enumerateObjectsUsingBlock:^(id bOject,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inBlock(bOject,bIndex)==YES)
			[tMutableArray addObject:bOject];
	}];
	
	return [tMutableArray copy];
}

@end

@implementation NSMutableArray (WBMapping)

- (void)WBmergeWithArray:(NSArray *)inArray
{
	if (inArray==nil)
		return;
	
	[inArray enumerateObjectsUsingBlock:^(id bObject,NSUInteger bIndex,BOOL * bOutStop){
	
		if ([self containsObject:bObject]==NO)
			[self addObject:bObject];
		
	}];
}

- (NSMutableArray *)WBmapObjectsUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock
{
	if (inBlock==nil)
		return self;
	
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[self enumerateObjectsUsingBlock:^(id bOject,NSUInteger bIndex,BOOL * bOutStop){
		
		id tObject=inBlock(bOject,bIndex);
		
		if (tObject!=nil)
			[tMutableArray addObject:tObject];
		
	}];
	
	return tMutableArray;
}

- (NSMutableArray *)WBmapObjectsLenientlyUsingBlock:(id (^)(id bObject, NSUInteger bIndex))inBlock
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
	
	return tMutableArray;
}

@end