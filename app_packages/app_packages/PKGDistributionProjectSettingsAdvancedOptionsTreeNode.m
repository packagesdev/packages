
#import "PKGDistributionProjectSettingsAdvancedOptionsTreeNode.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsItem.h"

@implementation PKGDistributionProjectSettingsAdvancedOptionsTreeNode

- (Class)representedObjectClassForRepresentation:(NSDictionary *)inRepresentation;
{
	return PKGDistributionProjectSettingsAdvancedOptionsItem.class;
}

@end
