
#import "PKGDistributionProjectSettingsAdvancedOptionsBoolean.h"

NSString * const PKGDistributionProjectSettingsAdvancedOptionsBooleanDontSetNoKey=@"BOOLEAN-DONT-SET-NO";

@interface PKGDistributionProjectSettingsAdvancedOptionsBoolean ()

	@property (readwrite) BOOL dontSetNO;

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionsBoolean

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self==nil)
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	NSNumber * tNumber=inRepresentation[PKGDistributionProjectSettingsAdvancedOptionsBooleanDontSetNoKey];
	
	if (tNumber!=nil)
	{
		if ([tNumber isKindOfClass:NSNumber.class]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGDistributionProjectSettingsAdvancedOptionsBooleanDontSetNoKey}];
			
			return nil;
		}
	
		_dontSetNO=[tNumber boolValue];
	}
	else
	{
		_dontSetNO=NO;
	}
		
	return self;
}

@end
