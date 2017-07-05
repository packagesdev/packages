
#import "PKGChoiceTreeNode+Edition.h"

@implementation PKGChoiceTreeNode (Edition)

- (BOOL)isEnabledStateConstant
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	PKGChoiceItemOptions * tItemOptions=tChoiceItem.options;
	
	// Check the Type of Choice
	
	BOOL tIsGroup=(tChoiceItem.type==PKGChoiceItemTypeGroup && tItemOptions.hideChildren==NO);
	
	PKGChoiceState tOptionsState=tItemOptions.state;
	
	if (tIsGroup==NO)
	{
		if (tOptionsState==PKGDependentChoiceState)
		{
			PKGChoiceItemOptionsDependencies * tDependencies=tItemOptions.stateDependencies;
			
			if (tDependencies!=nil && tDependencies.enabledStateDependencyType==PKGEnabledStateDependencyTypeDependent)
				return NO;
		}
		
		return YES;
	}
	
	return (tOptionsState!=PKGDependentChoiceGroupState);
}

@end
