
#import "PKGDistributionRequirementSourceListItem.h"

#import "PKGRequirement.h"

@interface PKGDistributionRequirementSourceListRequirementItem : PKGDistributionRequirementSourceListItem

	@property (readonly) PKGRequirement * requirement;

- (instancetype)initWithRequirement:(PKGRequirement *)inRequirement;

@end
