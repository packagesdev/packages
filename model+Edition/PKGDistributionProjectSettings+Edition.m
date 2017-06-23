
#import "PKGDistributionProjectSettings+Edition.h"

@implementation PKGDistributionProjectSettings (Edition)

- (PKGPackageProjectSettings *)packageProjectSettings
{
	return [[PKGPackageProjectSettings alloc] initWithProjectSettings:self];
}

@end
