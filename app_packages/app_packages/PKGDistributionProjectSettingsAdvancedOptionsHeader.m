
#import "PKGDistributionProjectSettingsAdvancedOptionsHeader.h"

@implementation PKGDistributionProjectSettingsAdvancedOptionsHeader

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self==nil)
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return self;
}

@end
