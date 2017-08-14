/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGChoicesForest+Edition.h"

#import "PKGChoiceTreeNode+UI.h"

#import "PKGChoiceDependencyTree+Edition.h"


@interface PKGChoicesForest (Edition_Private)

- (PKGChoiceTreeNode *)_embedChoiceTreeNodes:(NSArray *)inChoiceTreeNodes inChoiceGroupNamed:(NSString *)inItemName hideChildren:(BOOL)inHideChildren;

+ (void)_removeDependenciesOfChoices:(NSArray *)inChoiceTreeNodes toChoiceUUIDs:(NSArray *)inChoicesUUID;

@end

@implementation PKGChoicesForest (Edition)

- (PKGChoiceTreeNode *)_embedChoiceTreeNodes:(NSArray *)inChoiceTreeNodes inChoiceGroupNamed:(NSString *)inItemName hideChildren:(BOOL)inHideChildren
{
	if (inChoiceTreeNodes.count==0 || inItemName==nil)
		return nil;
	
	PKGChoiceTreeNode * tParentNode=(PKGChoiceTreeNode *)[inChoiceTreeNodes[0] parent];
	NSUInteger tInsertionIndex=0;
	
	PKGChoiceGroupItem * tChoiceGroupItem=[PKGChoiceGroupItem new];
	tChoiceGroupItem.localizedTitles[@"English"]=inItemName;
	
	tChoiceGroupItem.options.hideChildren=inHideChildren;
	tChoiceGroupItem.options.state=(inHideChildren==YES) ? PKGSelectedChoiceState : PKGEnabledChoiceGroupState;
	
	PKGChoiceTreeNode * tGroupTreeNode=[[PKGChoiceTreeNode alloc] initWithRepresentedObject:tChoiceGroupItem children:nil];
	
	if (tParentNode==nil)
	{
		tInsertionIndex=[self.rootNodes.array indexOfObjectIdenticalTo:inChoiceTreeNodes[0]];
		
		if (tInsertionIndex==NSNotFound)
		{
			NSLog(@"Unable to find index of first selected choice");
			return nil;
		}
		
		[self.rootNodes.array removeObjectsInArray:inChoiceTreeNodes];
		[self.rootNodes.array insertObject:tGroupTreeNode atIndex:tInsertionIndex];
	}
	else
	{
		tInsertionIndex=[tParentNode indexOfChildIdenticalTo:inChoiceTreeNodes[0]];
		
		if (tInsertionIndex==NSNotFound)
		{
			NSLog(@"Unable to find index of first selected choice");
			return nil;
		}
		
		[tParentNode removeChildrenInArray:inChoiceTreeNodes];
		[tParentNode insertChild:tGroupTreeNode atIndex:tInsertionIndex];
	}
	
	[tGroupTreeNode addChildren:inChoiceTreeNodes];
	
	if (inHideChildren==YES)
	{
		[inChoiceTreeNodes enumerateObjectsUsingBlock:^(PKGChoiceTreeNode * bTreeNode, NSUInteger idx, BOOL *stop) {
			
			PKGChoicePackageItem * tChoiceItem=[bTreeNode representedObject];
			
			tChoiceItem.options.state=PKGSelectedChoiceState;
			tChoiceItem.options.hidden=NO;
			tChoiceItem.options.stateDependencies=nil;
		}];
		
		NSArray * tAllChoiceUUIDs=[inChoiceTreeNodes WB_arrayByMappingObjectsUsingBlock:^id(PKGChoiceTreeNode * bChoiceTreeNode, NSUInteger bIndex) {
			
			PKGChoiceItem * tChoiceItem=bChoiceTreeNode.representedObject;
			
			return tChoiceItem.UUID;
		}];
		
		[PKGChoicesForest _removeDependenciesOfChoices:self.rootNodes.array toChoiceUUIDs:tAllChoiceUUIDs];
	}
	
	return tGroupTreeNode;
}

- (PKGChoiceTreeNode *)groupChoiceTreeNodes:(NSArray *)inChoiceTreeNodes inGroupNamed:(NSString *)inGroupName
{
	return [self _embedChoiceTreeNodes:inChoiceTreeNodes inChoiceGroupNamed:inGroupName hideChildren:NO];
}

- (void)ungroupChildrenOfGroup:(PKGChoiceTreeNode *)inGroupChoiceTreeNode
{
	if (inGroupChoiceTreeNode==nil)
		return;
	
	PKGChoiceTreeNode * tParentNode=(PKGChoiceTreeNode *)[inGroupChoiceTreeNode parent];
	NSUInteger tIndex=NSNotFound;
	
	if (tParentNode==nil)
		tIndex=[self.rootNodes.array indexOfObject:inGroupChoiceTreeNode];
	else
		tIndex=[tParentNode indexOfChildIdenticalTo:inGroupChoiceTreeNode];
	
	if (tIndex==NSNotFound)
	{
		// Uh oh
	}
	
	NSArray * tChildren=[inGroupChoiceTreeNode children];
	
	if (tParentNode==nil)
	{
		[self.rootNodes.array removeObjectAtIndex:tIndex];
		
		[self.rootNodes.array insertObjects:tChildren atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tIndex, tChildren.count)]];
		[tChildren makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	}
	else
	{
		[tParentNode removeChildAtIndex:tIndex];
		
		[tParentNode insertChildren:tChildren atIndex:tChildren];
	}
	
	// Remove dependencies to group
	
	[self removeDependendenciesToChoiceTreeNodes:@[inGroupChoiceTreeNode]];
}

- (PKGChoiceTreeNode *)mergeSiblings:(NSArray *)inChoiceTreeNodes asChoiceNamed:(NSString *)inChoiceName
{
	return [self _embedChoiceTreeNodes:inChoiceTreeNodes inChoiceGroupNamed:inChoiceName hideChildren:YES];
}

- (BOOL)containsChoiceForPackageComponentUUID:(NSString *)inPackageComponentUUID
{
	if (inPackageComponentUUID==nil)
		return NO;
	
	for(PKGChoiceTreeNode * tTreeNode in self.rootNodes.array)
	{
		__block BOOL tFound=NO;
		
		[tTreeNode enumerateRepresentedObjectsRecursivelyUsingBlock:^(PKGChoicePackageItem * bChoicePackageItem, BOOL *bOutStop) {
			
			if ([bChoicePackageItem isKindOfClass:PKGChoicePackageItem.class]==NO)
				return;
			
			tFound=[bChoicePackageItem.packageUUID isEqualToString:inPackageComponentUUID];
			
			if (tFound==YES)
				*bOutStop=YES;
		}];
		
		if (tFound==YES)
			return YES;
	}
	
	return NO;
}

- (NSArray *)choiceTreeNodesForPackageComponentUUIDs:(NSArray *)inPackageComponentUUIDs
{
	NSUInteger tCount=inPackageComponentUUIDs.count;
	
	if (tCount==0)
		return @[];
	
	NSMutableArray * tPackagesChoiceTreeNodes=[NSMutableArray array];
	__block NSUInteger tFoundCount=0;
	
	for(PKGChoiceTreeNode * tTreeNode in self.rootNodes.array)
	{
		if (tFoundCount==tCount)
			break;
		
		[tTreeNode enumerateNodesUsingBlock:^(PKGChoiceTreeNode * bPackageChoiceTreeNode, BOOL *bOutStop) {
			
			PKGChoicePackageItem * tChoicePackageItem=[bPackageChoiceTreeNode representedObject];
			
			if ([tChoicePackageItem isKindOfClass:PKGChoicePackageItem.class]==NO)
				return;
			
			if ([inPackageComponentUUIDs containsObject:tChoicePackageItem.packageUUID]==YES)
			{
				[tPackagesChoiceTreeNodes addObject:bPackageChoiceTreeNode];
				tFoundCount++;
				
				if (tFoundCount==tCount)
					*bOutStop=YES;
			}
		}];
	}
	
	return [tPackagesChoiceTreeNodes copy];
}

- (NSArray *)removeChoiceTreeNodes:(NSArray *)inChoiceTreeNodes
{
	NSMutableArray * tAdditionalTreeNodesRemoved=[NSMutableArray array];
	
	NSMutableArray * tMutableChoiceTreeNodes=[inChoiceTreeNodes mutableCopy];
	
	NSUInteger tCount=tMutableChoiceTreeNodes.count;
	
	for(NSUInteger tIndex=tCount;tIndex>0;tIndex--)
	{
		PKGTreeNode * tTreeNode=tMutableChoiceTreeNodes[tIndex-1];
		PKGChoiceTreeNode * tNodeParent=(PKGChoiceTreeNode *)[tTreeNode parent];
		
		if (tNodeParent==nil)
		{
			[self.rootNodes.array removeObject:tTreeNode];
		}
		else
		{
			[tNodeParent removeChild:tTreeNode];
			
			if ([tNodeParent numberOfChildren]==0)
			{
				PKGChoiceItem * tChoiceItem=tNodeParent.representedObject;
				
				if (tChoiceItem.options.hideChildren==YES)	// We also need to remove the parent node
				{
					[tMutableChoiceTreeNodes insertObject:tNodeParent atIndex:tIndex-1];
					[tAdditionalTreeNodesRemoved addObject:tNodeParent];
					tIndex++;
				}
			}
		}
	}
	
	return [tAdditionalTreeNodesRemoved copy];
}

+ (void)_removeDependenciesOfChoices:(NSArray *)inChoiceTreeNodes toChoiceUUIDs:(NSArray *)inChoicesUUID
{
	if (inChoicesUUID.count==0)
		return;
	
	for(PKGChoiceTreeNode * tTreeNode in inChoiceTreeNodes)
	{
		[tTreeNode enumerateRepresentedObjectsRecursivelyUsingBlock:^(PKGChoiceItem * bChoiceItem, BOOL *bOutStop) {
			
			PKGChoiceItemOptions * tOptions=bChoiceItem.options;
			PKGChoiceItemOptionsDependencies * tDependencies=tOptions.stateDependencies;
			
			if (tOptions.state==PKGDependentChoiceState || tOptions.state==PKGDependentChoiceGroupState)
			{
				tDependencies.enabledStateDependenciesTree=[tDependencies.enabledStateDependenciesTree removePredicatesForChoicesUUID:inChoicesUUID];
				
				if (tDependencies.enabledStateDependenciesTree==nil)
					tDependencies.enabledStateDependencyType=PKGEnabledStateDependencyTypeAlways;
			}
			
			if (tOptions.state==PKGDependentChoiceState)
			{
				tDependencies.selectedStateDependenciesTree=[tDependencies.selectedStateDependenciesTree removePredicatesForChoicesUUID:inChoicesUUID];
				
				if (tDependencies.selectedStateDependenciesTree==nil)
					tOptions.state=PKGSelectedChoiceState;
			}
		}];
	}
}

- (void)removeDependendenciesToChoiceTreeNodes:(NSArray *)inChoiceTreeNodes
{
	if (inChoiceTreeNodes.count==0)
		return;
	
	NSArray * tAllChoiceUUIDs=[inChoiceTreeNodes WB_arrayByMappingObjectsUsingBlock:^id(PKGChoiceTreeNode * bChoiceTreeNode, NSUInteger bIndex) {
		
		PKGChoiceItem * tChoiceItem=bChoiceTreeNode.representedObject;
		
		return tChoiceItem.UUID;
	}];
	
	[PKGChoicesForest _removeDependenciesOfChoices:self.rootNodes.array toChoiceUUIDs:tAllChoiceUUIDs];
}

- (BOOL)moveChoiceTreeNodes:(NSArray *)inChoiceTreeNodes asChildrenOf:(PKGChoiceTreeNode *)inParentChoiceTreeNode atIndex:(NSUInteger)inIndex
{
	if (inChoiceTreeNodes.count==0)
		return NO;
	
	for(PKGChoiceTreeNode * tChoiceTreeNode in inChoiceTreeNodes)
	{
		PKGChoiceTreeNode * tParentTreeNode=(PKGChoiceTreeNode *)[tChoiceTreeNode parent];
	
		if (tParentTreeNode==inParentChoiceTreeNode)
		{
			NSUInteger tIndex=NSNotFound;
			
			if (tParentTreeNode==nil)
				tIndex=[self.rootNodes.array indexOfObject:tChoiceTreeNode];
			else
				tIndex=[tParentTreeNode indexOfChildIdenticalTo:tChoiceTreeNode];
			
			if (tIndex==NSNotFound)
			{
				NSLog(@"Choice is not a child of its supposed parent. This makes no sense. Aborting move operation.");
				
				return NO;
			}
			
			if (inIndex>0 && inIndex>=tIndex)
				inIndex--;
		}
		
		if (tParentTreeNode==nil)
			[self.rootNodes.array removeObject:tChoiceTreeNode];
		else
			[tParentTreeNode removeChild:tChoiceTreeNode];
	}
	
	for(PKGChoiceTreeNode * tChoiceTreeNode in inChoiceTreeNodes)
	{
		if (inParentChoiceTreeNode==nil)
			[self.rootNodes.array insertObject:tChoiceTreeNode atIndex:inIndex];
		else
			[inParentChoiceTreeNode insertChild:tChoiceTreeNode atIndex:inIndex];
		
		inIndex++;
	}
	
	if (inParentChoiceTreeNode!=nil)
	{
		// We need to remove the dependencies to the new ancestors (to avoid dependency cycles)
		
		PKGChoiceTreeNode * tParentTreeNode=inParentChoiceTreeNode;
		NSMutableArray * tAncestorsChoiceUUIDs=[NSMutableArray array];
		
		do
		{
			PKGChoiceItem * tChoiceItem=[tParentTreeNode representedObject];
			
			[tAncestorsChoiceUUIDs addObject:tChoiceItem.UUID];
			 
			 tParentTreeNode=(PKGChoiceTreeNode *)[tParentTreeNode parent];
		}
		while (tParentTreeNode!=nil);
		
		[PKGChoicesForest _removeDependenciesOfChoices:inChoiceTreeNodes toChoiceUUIDs:tAncestorsChoiceUUIDs];
	}
	
	return YES;
}

@end
