
#import "NSCollection+DeepCopy.h"

#import "NSDictionary+WBExtensions.h"

#import "NSArray+WBExtensions.h"

@implementation NSDictionary (WB_DeepCopy)

- (instancetype)deepCopy
{
	return [self WB_dictionaryByMappingObjectsUsingBlock:^id(id bKey, id bObject) {
		
		if ([bObject isKindOfClass:[NSArray class]]==YES)
			return [(NSArray *)bObject deepCopy];
		
		if ([bObject isKindOfClass:[NSDictionary class]]==YES)
			return [(NSDictionary *)bObject deepCopy];
		
		if ([bObject isKindOfClass:[NSSet class]]==YES)
			return [(NSSet *)bObject deepCopy];
		
		if ([bObject isKindOfClass:[NSOrderedSet class]]==YES)
			return [(NSOrderedSet *)bObject deepCopy];
		
		return [bObject copy];
		
	}];
}

@end

@implementation NSArray (WB_DeepCopy)

- (instancetype)deepCopy
{
	return [self WB_arrayByMappingObjectsUsingBlock:^id(id bObject, NSUInteger bIndex) {
		
		if ([bObject isKindOfClass:[NSArray class]]==YES)
			return [(NSArray *)bObject deepCopy];
		
		if ([bObject isKindOfClass:[NSDictionary class]]==YES)
			return [(NSDictionary *)bObject deepCopy];
		
		if ([bObject isKindOfClass:[NSSet class]]==YES)
			return [(NSSet *)bObject deepCopy];
		
		if ([bObject isKindOfClass:[NSOrderedSet class]]==YES)
			return [(NSOrderedSet *)bObject deepCopy];
		
		return [bObject copy];
	}];
}

@end

@implementation NSSet (WB_DeepCopy)

- (instancetype)deepCopy
{
	// A COMPLETER
	
	return nil;
}

@end

@implementation NSOrderedSet (WB_DeepCopy)

- (instancetype)deepCopy
{
	// A COMPLETER
	
	return nil;
}

@end


