
#import "PKGPackagePayload+Transformation.h"

#import "PKGPayloadTree+Transformation.h"

@implementation PKGPackagePayload (Transformation)

- (void)transformAllPathsUsingSourceConverter:(id<PKGFilePathConverter>)inSourceConverter destinationConverter:(id<PKGFilePathConverter>)inDestinationConverter
{
	if (inSourceConverter==nil || inDestinationConverter==nil)
		return;
	
	[self.filesTree transformAllPathsUsingSourceConverter:inSourceConverter destinationConverter:inDestinationConverter];
}

@end
