
#import "PKGChoicesForest+DependenciesEdition.h"

#import "PKGChoiceTreeNode+Edition.h"
#import "PKGChoiceDependencyTree+Edition.h"

#import "PKGChoiceTreeNode+UI.h"

@implementation PKGChoiceDependencyRecord

@end

@implementation PKGChoicesForest(Dependencies_Edition)

- (NSDictionary *)allDependencyRecords
{
	NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	for(PKGChoiceTreeNode * tTreeNode in self.rootNodes)
	{
		[tTreeNode enumerateNodesLenientlyUsingBlock:^(PKGChoiceTreeNode * bChoiceTreeNode, BOOL *bOutSkipChildren,BOOL *bOutStop) {
			
			PKGChoiceItem * tChoiceItem=[bChoiceTreeNode representedObject];
			
			// Check the Type of Choice
			
			PKGChoiceItemOptions * tChoiceItemOptions=tChoiceItem.options;
			
			PKGChoiceState tState=tChoiceItemOptions.state;
			
			if (bChoiceTreeNode.isGenuineGroupChoice==NO)
			{
				NSSet * tSelectedDependencies=nil;
				NSSet * tEnabledDependencies=nil;
				
				if (tState==PKGDependentChoiceState)
				{
					PKGChoiceItemOptionsDependencies * tDependencies=tChoiceItemOptions.stateDependencies;
					
					if (tDependencies!=nil)
					{
						if (tDependencies.enabledStateDependencyType==PKGEnabledStateDependencyTypeDependent)
							tEnabledDependencies=[tDependencies.enabledStateDependenciesTree allDependenciesStates];
						
						
						tSelectedDependencies=[tDependencies.selectedStateDependenciesTree allDependenciesStates];
					}
				}
				
				PKGChoiceDependencyRecord * tDependencyRecord=[PKGChoiceDependencyRecord new];
				
				tDependencyRecord.choiceTreeNode=bChoiceTreeNode;
				tDependencyRecord.group=NO;
				tDependencyRecord.enabledDependencySupported=YES;
				tDependencyRecord.selectedDependencySupported=YES;
				tDependencyRecord.enabledDependencies=tEnabledDependencies;
				tDependencyRecord.selectedDependencies=tSelectedDependencies;
				
				tMutableDictionary[tChoiceItem.UUID]=tDependencyRecord;
				
				*bOutSkipChildren=YES;
				
				return;
			}
			
			NSSet * tEnabledDependencies=nil;
			
			if (tState==PKGDependentChoiceGroupState)
			{
				PKGChoiceItemOptionsDependencies * tDependencies=tChoiceItemOptions.stateDependencies;
				
				if (tDependencies!=nil)
					tEnabledDependencies=[tDependencies.enabledStateDependenciesTree allDependenciesStates];
			}
			
			PKGChoiceDependencyRecord * tDependencyRecord=[PKGChoiceDependencyRecord new];
			
			tDependencyRecord.choiceTreeNode=bChoiceTreeNode;
			tDependencyRecord.group=YES;
			tDependencyRecord.enabledDependencySupported=YES;
			tDependencyRecord.selectedDependencySupported=NO;
			tDependencyRecord.enabledDependencies=tEnabledDependencies;
			tDependencyRecord.selectedDependencies=nil;
			
			tMutableDictionary[tChoiceItem.UUID]=tDependencyRecord;
		}];
	}
	
	return [tMutableDictionary copy];
}

- (NSMutableDictionary *)availableDependenciesDictionaryForEnabledStateOfGroupNode:(PKGChoiceTreeNode *)inTreeNode
{
	NSMutableDictionary * tAvailableDependenciesDictionary=[[self allDependencyRecords] mutableCopy];
	
	if (tAvailableDependenciesDictionary==nil)
		return nil;
	
	PKGChoiceGroupItem * tChoiceGroupItem=[inTreeNode representedObject];
	NSString * tChoiceUUID=tChoiceGroupItem.UUID;
	
	// Remove the group itself
	
	[tAvailableDependenciesDictionary removeObjectForKey:tChoiceUUID];
	
	// Remove the items which are children of this group
	
	NSMutableArray * tRemovedKeys=[NSMutableArray array];
	
	[tAvailableDependenciesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bUUID, PKGChoiceDependencyRecord * bDependencyRecord, BOOL *bOutStop) {
		
		if ([bDependencyRecord.choiceTreeNode isDescendantOfNode:inTreeNode]==YES)
			[tRemovedKeys addObject:bUUID];
	}];
	
	
	[tAvailableDependenciesDictionary removeObjectsForKeys:tRemovedKeys];
	
	// Remove the items creating a loop
	
	PKGChoiceDependencyPredicateValues * tPredicateValues=[PKGChoiceDependencyPredicateValues new];
	tPredicateValues.choiceUUID=tChoiceUUID;
	tPredicateValues.referenceState=PKGPredicateReferenceStateEnabled;
	
	NSMutableArray * tDependentChoicesArray=[NSMutableArray arrayWithObject:tPredicateValues];
	
	while (tDependentChoicesArray.count>0)
	{
		NSDictionary * tStateDependencyDictionary=tDependentChoicesArray.firstObject;
		
		for(NSString * tKey in tAvailableDependenciesDictionary.allKeys)
		{
			PKGChoiceDependencyRecord * tDependencyRecord=tAvailableDependenciesDictionary[tKey];
			
			// Is it a Group or Not?
			
			if (tDependencyRecord.isGroup==NO)
			{
				// It's not a group, we need to inspect the selected dependencies too
				
				NSSet * tSelectedDependencies=tDependencyRecord.selectedDependencies;
				
				if (tSelectedDependencies!=nil)
				{
					if ([tSelectedDependencies containsObject:tStateDependencyDictionary]==YES)
					{
						tPredicateValues=[PKGChoiceDependencyPredicateValues new];
						tPredicateValues.choiceUUID=tKey;
						tPredicateValues.referenceState=PKGPredicateReferenceStateSelected;
						
						[tDependentChoicesArray addObject:tPredicateValues];
						
						// The Selected state of this item can't be used for dependency
						
						tDependencyRecord.selectedDependencySupported=NO;
					}
				}
			}
			
			NSSet * tEnabledDependencies=tDependencyRecord.enabledDependencies;
			
			if (tEnabledDependencies!=nil)
			{
				if ([tEnabledDependencies containsObject:tStateDependencyDictionary]==YES)
				{
					tPredicateValues=[PKGChoiceDependencyPredicateValues new];
					tPredicateValues.choiceUUID=tKey;
					tPredicateValues.referenceState=PKGPredicateReferenceStateEnabled;
					
					[tDependentChoicesArray addObject:tPredicateValues];
					
					// The Enabled state of this item can't be used for dependency
					
					tDependencyRecord.enabledDependencySupported=NO;
				}
			}
			
			// Can the item selected or enabled states be used for dependencies?
			
			if (tDependencyRecord.enabledDependencySupported==NO && tDependencyRecord.selectedDependencySupported==NO)
				[tAvailableDependenciesDictionary removeObjectForKey:tKey];
		}
		
		[tDependentChoicesArray removeObjectAtIndex:0];
	}
	
	return tAvailableDependenciesDictionary;
}

- (NSMutableDictionary *)availableDependenciesDictionaryForEnabledStateOfLeafNode:(PKGChoiceTreeNode *)inTreeNode skipEnabledIfConstant:(BOOL)inSkipEnabled
{
	NSMutableDictionary * tAvailableDependenciesDictionary=[[self allDependencyRecords] mutableCopy];
	
	if (tAvailableDependenciesDictionary==nil)
		return nil;
	
	NSString * tChoiceUUID=inTreeNode.choiceUUID;
	
	// Remove the leaf itself
	
	[tAvailableDependenciesDictionary removeObjectForKey:tChoiceUUID];
	
	// Remove the parents of this leaf
	
	NSMutableArray * tRemovedKeys=[NSMutableArray array];
	
	[tAvailableDependenciesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bUUID, PKGChoiceDependencyRecord * bDependencyRecord, BOOL *bOutStop) {
		
		if ([inTreeNode isDescendantOfNode:bDependencyRecord.choiceTreeNode]==YES)
			[tRemovedKeys addObject:bUUID];
	}];
	
	[tAvailableDependenciesDictionary removeObjectsForKeys:tRemovedKeys];
	
	// Remove the items creating a loop
	
	PKGChoiceDependencyPredicateValues * tPredicateValues=[PKGChoiceDependencyPredicateValues new];
	tPredicateValues.choiceUUID=tChoiceUUID;
	tPredicateValues.referenceState=PKGPredicateReferenceStateSelected;
	
	NSMutableArray * tDependentChoicesArray=[NSMutableArray arrayWithObject:tPredicateValues];
	
	if (inSkipEnabled==NO || [inTreeNode isEnabledStateConstant]==NO)
	{
		tPredicateValues=[PKGChoiceDependencyPredicateValues new];
		tPredicateValues.choiceUUID=tChoiceUUID;
		tPredicateValues.referenceState=PKGPredicateReferenceStateEnabled;
		
		[tDependentChoicesArray addObject:tPredicateValues];
	}
	
	// We need to take into account the parent choices of the item
	
	PKGChoiceTreeNode * tNode=(PKGChoiceTreeNode *) [inTreeNode parent];
	
	while (tNode!=nil)
	{
		tPredicateValues=[PKGChoiceDependencyPredicateValues new];
		tPredicateValues.choiceUUID=tNode.choiceUUID;
		tPredicateValues.referenceState=PKGPredicateReferenceStateEnabled;
		
		[tDependentChoicesArray addObject:tPredicateValues];
		
		tNode=(PKGChoiceTreeNode *) [tNode parent];
	}
	
	while (tDependentChoicesArray.count>0)
	{
		NSDictionary * tStateDependencyDictionary=tDependentChoicesArray.firstObject;
		
		for(NSString * tKey in tAvailableDependenciesDictionary.allKeys)
		{
			PKGChoiceDependencyRecord * tDependencyRecord=tAvailableDependenciesDictionary[tKey];
			
			// Is it a Group or Not?
			
			if (tDependencyRecord.isGroup==NO)
			{
				// It's not a group, we need to inspect the selected dependencies too
				
				NSSet * tSelectedDependencies=tDependencyRecord.selectedDependencies;
				
				if (tSelectedDependencies!=nil)
				{
					if ([tSelectedDependencies containsObject:tStateDependencyDictionary]==YES)
					{
						tPredicateValues=[PKGChoiceDependencyPredicateValues new];
						tPredicateValues.choiceUUID=tKey;
						tPredicateValues.referenceState=PKGPredicateReferenceStateSelected;
						
						[tDependentChoicesArray addObject:tPredicateValues];
						
						// The Selected state of this item can't be used for dependency
						
						tDependencyRecord.selectedDependencySupported=NO;
					}
				}
			}
			
			NSSet * tEnabledDependencies=tDependencyRecord.enabledDependencies;
			
			if (tEnabledDependencies!=nil)
			{
				if ([tEnabledDependencies containsObject:tStateDependencyDictionary]==YES)
				{
					tPredicateValues=[PKGChoiceDependencyPredicateValues new];
					tPredicateValues.choiceUUID=tKey;
					tPredicateValues.referenceState=PKGPredicateReferenceStateEnabled;
					
					[tDependentChoicesArray addObject:tPredicateValues];
					
					// The Enabled state of this item can't be used for dependency
					
					tDependencyRecord.enabledDependencySupported=NO;
				}
			}
			
			// Can the item selected or enabled states be used for dependencies?
			
			if (tDependencyRecord.enabledDependencySupported==NO && tDependencyRecord.selectedDependencySupported==NO)
				[tAvailableDependenciesDictionary removeObjectForKey:tKey];
		}
		
		[tDependentChoicesArray removeObjectAtIndex:0];
	}
	
	return tAvailableDependenciesDictionary;
}

- (NSMutableDictionary *)availableDependenciesDictionaryForEnabledStateOfLeafNode:(PKGChoiceTreeNode *)inTreeNode
{
	return [self availableDependenciesDictionaryForEnabledStateOfLeafNode:inTreeNode skipEnabledIfConstant:YES];
}

- (NSMutableDictionary *)availableDependenciesDictionaryForSelectedStateOfLeafNode:(PKGChoiceTreeNode *)inTreeNode
{
	return [self availableDependenciesDictionaryForEnabledStateOfLeafNode:inTreeNode];
}

@end
