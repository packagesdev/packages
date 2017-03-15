
#import "PKGDistributionVolumeRequirementBehaviorViewController.h"

@implementation PKGDistributionVolumeRequirementBehaviorViewController

- (PKGRequirementFailureMessage *)defaultMessage
{
	PKGRequirementFailureMessage * tMessage=[PKGRequirementFailureMessage new];
	
	tMessage.messageTitle=@"";
	tMessage.messageDescription=nil;
	
	return tMessage;
}

@end
