
#import "PKGDistributionInstallationRequirementBehaviorViewController.h"

@implementation PKGDistributionInstallationRequirementBehaviorViewController

- (PKGRequirementFailureMessage *)defaultMessage
{
	PKGRequirementFailureMessage * tMessage=[PKGRequirementFailureMessage new];
	
	tMessage.messageTitle=@"";
	tMessage.messageDescription=@"";
	
	return tMessage;
}

@end
