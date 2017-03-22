
#import "PKGDistributionProjectSettingsAdvancedOptionsObject.h"

#import "PKGPackagesError.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsHeader.h"

NSString * const PKGDistributionProjectSettingsAdvancedOptionsObjectTypeKey=@"TYPE";
NSString * const PKGDistributionProjectSettingsAdvancedOptionsObjectTitleKey=@"TITLE";

@interface PKGDistributionProjectSettingsAdvancedOptionsObject ()

	@property (readwrite) NSString * title;

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionsObject

+ (NSDictionary *)advancedOptionsRegistryWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGFileURLNilError
									  userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGRepresentationInvalidTypeOfValueError
									  userInfo:nil];
		
		return nil;
	}
	
	NSMutableDictionary * tRegistry=[NSMutableDictionary dictionary];
	
	__block NSError * tError=nil;
	
	[inRepresentation enumerateKeysAndObjectsUsingBlock:^(NSString * bKey, NSDictionary * bRepresentation, BOOL *bOutStop) {
		
		if (bRepresentation==nil)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGFileURLNilError
								   userInfo:nil];
			
			*bOutStop=YES;
			
			return;
		}
		
		if ([bRepresentation isKindOfClass:NSDictionary.class]==NO)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGRepresentationInvalidTypeOfValueError
								   userInfo:nil];
			
			*bOutStop=YES;
			
			return;
		}
		
		NSString * tTypeName=bRepresentation[PKGDistributionProjectSettingsAdvancedOptionsObjectTypeKey];
		
		if (tTypeName==nil)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGFileURLNilError
								   userInfo:nil];
			
			*bOutStop=YES;
			
			return;
		}
		
		if ([tTypeName isKindOfClass:NSString.class]==NO)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGRepresentationInvalidTypeOfValueError
								   userInfo:nil];
			
			*bOutStop=YES;
			
			return;
		}
		
		PKGDistributionProjectSettingsAdvancedOptionsObject * tObject=nil;
		
		//if ([tTypeName isEqualToString:@"Header"]==YES)
		{
			tObject=[[PKGDistributionProjectSettingsAdvancedOptionsHeader alloc] initWithRepresentation:bRepresentation error:&tError];
		}
		
		
		if (tObject==nil)
		{
			*bOutStop=YES;
			
			return;
		}
		
		tRegistry[bKey]=tObject;
	}];
	
	if (tError!=nil)
	{
		if (outError!=NULL)
			*outError=tError;
		
		return nil;
	}
	
	return [tRegistry copy];
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	self=[super init];
	
	if (self!=nil)
	{
		NSString * tTtile=inRepresentation[PKGDistributionProjectSettingsAdvancedOptionsObjectTitleKey];
		
		PKGFullCheckStringValueForKey(tTtile,PKGDistributionProjectSettingsAdvancedOptionsObjectTitleKey);
		
		_title=[tTtile copy];
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	return [NSMutableDictionary dictionary];
}

@end
