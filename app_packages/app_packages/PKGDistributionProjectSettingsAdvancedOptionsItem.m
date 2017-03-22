
#import "PKGDistributionProjectSettingsAdvancedOptionsItem.h"

#import "PKGPackagesError.h"

NSString * const PKGDistributionProjectSettingsAdvancedOptionsItemIDKey=@"ID";

@interface PKGDistributionProjectSettingsAdvancedOptionsItem ()

	@property (readwrite) NSString * itemID;

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionsItem

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		NSString * tString=inRepresentation[PKGDistributionProjectSettingsAdvancedOptionsItemIDKey];
		
		PKGFullCheckStringValueForKey(tString,PKGDistributionProjectSettingsAdvancedOptionsItemIDKey);
		
		_itemID=[tString copy];
	}
	
	return self;
}

- (NSMutableDictionary *) representation
{
	return [NSMutableDictionary dictionary];
}

@end
