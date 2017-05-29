
#import "PKGChoiceTreeNode+UI.h"

#import "NSDictionary+WBExtensions.h"

#import "PKGLanguageConverter.h"

#import "NSMutableDictionary+Localizations.h"

@interface PKGChoiceDependencyTree (UI)

- (BOOL)isInHiddenGroup;

@end

@implementation PKGChoiceTreeNode (UI)

- (NSString *)choiceUUID
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	return tChoiceItem.UUID;
}

- (NSString *)packageUUID
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	if (tChoiceItem.type!=PKGChoiceItemTypePackage)
		return nil;
	
	return ((PKGChoicePackageItem *)tChoiceItem).packageUUID;
}

- (BOOL)isEnabled
{
	if (self.isMergedIntoPackagesChoice==YES)
	{
		PKGChoiceTreeNode * tParentNode=((PKGChoiceTreeNode *)[self parent]);
	
		return tParentNode.isEnabled;
	}
	
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	PKGChoiceState tState=tChoiceItem.options.state;
	
	if (tState==PKGRequiredChoiceState ||
		tState==PKGDisabledChoiceGroupState)
		return NO;
	
	PKGChoiceTreeNode * tParentNode=((PKGChoiceTreeNode *)[self parent]);
	
	if (tParentNode==nil)
		return YES;
	
	return tParentNode.isEnabled;
}

- (BOOL)isInHiddenGroup
{
	PKGChoiceTreeNode * tParentNode=((PKGChoiceTreeNode *)[self parent]);
	
	if (tParentNode==nil)
		return NO;
	
	PKGChoiceItem * tChoiceItem=tParentNode.representedObject;
	
	if (tChoiceItem.options.hideChildren==YES)
		return YES;
	
	return NO;
}

- (BOOL)isInvisible
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	if (tChoiceItem.type==PKGChoiceItemTypePackage && [self isInHiddenGroup]==YES)
	{
		PKGChoiceTreeNode * tParentNode=((PKGChoiceTreeNode *)[self parent]);
			
		return tParentNode.isInvisible;
	}
	
	if (tChoiceItem.options.isHidden==YES)
		return YES;
	
	PKGChoiceTreeNode * tParentNode=((PKGChoiceTreeNode *)[self parent]);
	
	if (tParentNode!=nil)
		return tParentNode.isInvisible;
	
	return NO;
}

- (BOOL)isPackageChoice
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	return (tChoiceItem.type==PKGChoiceItemTypePackage);
}

- (BOOL)isGenuineGroupChoice
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	if (tChoiceItem.type!=PKGChoiceItemTypeGroup)
		return NO;
	
	return (tChoiceItem.options.hideChildren==NO);
}

- (BOOL)isMergedPackagesChoice
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	if (tChoiceItem.type!=PKGChoiceItemTypeGroup)
		return NO;
	
	return (tChoiceItem.options.hideChildren==YES);
}

- (BOOL)isMergedIntoPackagesChoice
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	if (tChoiceItem.type!=PKGChoiceItemTypePackage)
		return NO;
	
	return [self isInHiddenGroup];
}

- (PKGChoiceSelectedState)selectedState
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	PKGChoiceItemOptions * tOptions=tChoiceItem.options;
	PKGChoiceState tState=tOptions.state;
	
	if (tChoiceItem.type==PKGChoiceItemTypePackage)
	{
		if (tState==PKGDependentChoiceState)
			return PKGChoiceSelectedStateDependent;

		return (tState==PKGRequiredChoiceState || tState==PKGSelectedChoiceState) ? PKGChoiceSelectedStateOn : PKGChoiceSelectedStateOff;
	}
	
	if (tState==PKGDependentChoiceGroupState)
		return PKGChoiceSelectedStateDependent;
	
	if (tOptions.hideChildren==YES)
		return (tState==PKGRequiredChoiceState || tState==PKGSelectedChoiceState) ? PKGChoiceSelectedStateOn : PKGChoiceSelectedStateOff;
	
	PKGChoiceSelectedState tFinalState=PKGChoiceSelectedStateUnknown;
	
	for(PKGChoiceTreeNode * tChild in [self children])
	{
		PKGChoiceSelectedState tSelectedState=tChild.selectedState;
		
		if (tFinalState==PKGChoiceSelectedStateUnknown)
		{
			tFinalState=tSelectedState;
		}
		else
		{
			if (tFinalState!=tSelectedState)
			{
				return PKGChoiceSelectedStateMixed;
			}
		}
	}
	
	if (tFinalState==PKGChoiceSelectedStateDependent)
		tFinalState=PKGChoiceSelectedStateMixed;
	
	if (tFinalState!=PKGChoiceSelectedStateUnknown)
		return tFinalState;
	
	return PKGChoiceSelectedStateOff;
}

- (NSString *)choiceAction
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	if (tChoiceItem.type==PKGChoiceItemTypeGroup)
		return (tChoiceItem.options.hideChildren==NO) ? @"" : @"-";
	
	return (self.isInHiddenGroup==YES) ? @"" : @"-";
}

- (NSString *)titleForLocalization:(NSString *)inLocalization
{
	return [((PKGChoiceItem *)[self representedObject]).localizedTitles valueForLocalization:inLocalization exactMatch:NO valueSetChecker:^BOOL(NSString * bTitle){
		
		return (bTitle.length>0);
	}];
}

- (NSString *)descriptionForLocalization:(NSString *)inLocalization
{
	return [((PKGChoiceItem *)[self representedObject]).localizedDescriptions valueForLocalization:inLocalization exactMatch:NO valueSetChecker:^BOOL(NSString * bDescription){
		
		return (bDescription.length>0);
	}];
}

@end
