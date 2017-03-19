
#import "PKGDocumentRegistry.h"

@interface PKGDocumentRegistry ()
{
	NSMutableDictionary * _dictionary;
}

@end

@implementation PKGDocumentRegistry

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_dictionary=[NSMutableDictionary dictionary];
	}
	
	return self;
}

#pragma mark -

- (id)objectForKey:(NSString *)inKey
{
	if (inKey==nil)
		return nil;
	
	return _dictionary[inKey];
}

- (NSInteger)integerForKey:(NSString *)inKey
{
	if (inKey==nil)
		return 0;
	
	NSNumber * tNumber=_dictionary[inKey];
	
	if (tNumber==nil || [tNumber isKindOfClass:NSNumber.class]==NO)
		return 0;
	
	return [tNumber integerValue];
}

#pragma mark -

- (void)setObject:(id)inObject forKey:(NSString *)inKey
{
	if (inObject==nil)
	{
		[self removeObjectForKey:inKey];
		
		return;
	}
	
	if (inKey==nil)
		return;
	
	_dictionary[inKey]=inObject;
}

- (void)setInteger:(NSInteger)inInteger forKey:(NSString *)inKey
{
	if (inKey==nil)
		return;
	
	_dictionary[inKey]=@(inInteger);
}

#pragma mark -

- (id)objectForKeyedSubscript:(id)inKey
{
	if (inKey==nil)
		return nil;
	
	return _dictionary[inKey];
}

- (void)setObject:(id)inObject forKeyedSubscript:(id)inKey
{
	if (inObject==nil)
	{
		[self removeObjectForKey:inKey];
		
		return;
	}
	
	if (inKey==nil)
		return;
	
	_dictionary[inKey]=inObject;
}

#pragma mark -

- (void)removeObjectForKey:(NSString *)inKey
{
	if (inKey==nil)
		return;
	
	[_dictionary removeObjectForKey:inKey];
}

@end
