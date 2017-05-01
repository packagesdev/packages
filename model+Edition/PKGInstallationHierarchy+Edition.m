
#import "PKGInstallationHierarchy+Edition.h"

#import "PKGChoicesForest+Edition.h"

@implementation PKGInstallationHierarchy (Edition)

- (void)removeAllReferencesToPackageComponentUUIDs:(NSArray *)inPackageComponentsUUIDs
{
	if (inPackageComponentsUUIDs.count==0)
		return;
	
	
	[self.removedPackagesChoices removeObjectsForKeys:inPackageComponentsUUIDs];
	
	NSArray * tChoiceTreeNodes=[self.choicesForest choiceTreeNodesForPackageComponentUUIDs:inPackageComponentsUUIDs];
	
	NSArray * tAdditionalRemovedTreeNodes=[self.choicesForest removeChoiceTreeNodes:tChoiceTreeNodes];
	
	NSMutableArray * tMutableChoiceTreeNodes=[tChoiceTreeNodes mutableCopy];
	
	[tMutableChoiceTreeNodes addObjectsFromArray:tAdditionalRemovedTreeNodes];
	
	[self.choicesForest removeDependendenciesToChoiceTreeNodes:tMutableChoiceTreeNodes];
	
	// A COMPLETER
}

- (void)insertBackPackageComponentUUIDs:(NSArray *)inPackageComponentsUUIDs asChildrenOfNode:(PKGChoiceTreeNode *)inTreeNode index:(NSUInteger)inIndex
{
	if (inPackageComponentsUUIDs.count==0)
		return;
	
	NSMutableArray * tChoicesArray=[NSMutableArray array];
	
	for(NSString * tPackageComponentUUID in inPackageComponentsUUIDs)
	{
		PKGChoiceTreeNode * tChoiceTreeNode=self.removedPackagesChoices[tPackageComponentUUID];
		
		if (tChoiceTreeNode==nil)
		{
			NSLog(@"Choice for package component \"%@\" could not be found. Internal incoherency.",tPackageComponentUUID);
			
			return;
		}
		
		[tChoicesArray addObject:tChoiceTreeNode];
		
		[self.removedPackagesChoices removeObjectForKey:tPackageComponentUUID];
	}
	
	if (inTreeNode==nil)
	{
		[self.choicesForest.rootNodes insertObjects:tChoicesArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inIndex,tChoicesArray.count)]];
	}
	else
	{
		[inTreeNode insertChildren:tChoicesArray atIndex:inIndex];
	}
}

@end
