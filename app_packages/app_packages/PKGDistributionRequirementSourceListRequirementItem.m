
#import "PKGDistributionRequirementSourceListRequirementItem.h"

@interface PKGDistributionRequirementSourceListRequirementItem ()

	@property (readwrite) PKGRequirement * requirement;

@end

@implementation PKGDistributionRequirementSourceListRequirementItem

- (instancetype)initWithRequirement:(PKGRequirement *)inRequirement
{
	self=[super init];
	
	if (self!=nil)
	{
		_requirement=inRequirement;
	}
	
	return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGDistributionRequirementSourceListRequirementItem * nRequirementItem=[[[self class] allocWithZone:inZone] init];
	
	if (nRequirementItem!=nil)
	{
		nRequirementItem.requirement=[self.requirement copyWithZone:inZone];
	}
	
	return nRequirementItem;
}

@end
