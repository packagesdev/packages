
#import "PKGPayloadTree+Transformation.h"

#import "PKGPayloadTreeNode+Transformation.h"

@implementation PKGPayloadTree (Transformation)

- (void)transformAllPathsUsingSourceConverter:(id<PKGFilePathConverter>)inSourceConverter destinationConverter:(id<PKGFilePathConverter>)inDestinationConverter
{
	if (inSourceConverter==nil || inDestinationConverter==nil)
		return;
	
	[self.rootNode transformAllPathsUsingSourceConverter:inSourceConverter destinationConverter:inDestinationConverter];
}

@end
