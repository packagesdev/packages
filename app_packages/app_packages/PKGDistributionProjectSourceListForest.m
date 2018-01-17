/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectSourceListForest.h"

#import "PKGDistributionProjectSourceListProjectItem.h"
#import "PKGDistributionProjectSourceListGroupItem.h"
#import "PKGDistributionProjectSourceListPackageComponentItem.h"

@interface PKGDistributionProjectSourceListForest ()
{
	NSMutableArray * _packageComponents;
}

	@property (nonatomic,readwrite) NSMutableArray * rootNodes;

@end

@implementation PKGDistributionProjectSourceListForest

- (instancetype)initWithPackageComponents:(NSMutableArray *)inPackageComponents
{
	self=[super init];
	
	if (self!=nil)
	{
		_packageComponents=inPackageComponents;
		
		_rootNodes=[NSMutableArray array];
		
		PKGDistributionProjectSourceListTreeNode * tProjectTreeNode=[[PKGDistributionProjectSourceListTreeNode alloc] initWithRepresentedObject:[PKGDistributionProjectSourceListProjectItem new] children:nil];
		
		[_rootNodes addObject:tProjectTreeNode];
		
		PKGDistributionProjectSourceListTreeNode * tProjectPackagesGroupNode=[[PKGDistributionProjectSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionProjectSourceListGroupItem alloc] initWithGroupType:PKGPackageComponentTypeProject] children:nil];
		PKGDistributionProjectSourceListTreeNode * tProjectImportedGroupNode=[[PKGDistributionProjectSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionProjectSourceListGroupItem alloc] initWithGroupType:PKGPackageComponentTypeImported] children:nil];
		PKGDistributionProjectSourceListTreeNode * tProjectReferencedGroupNode=[[PKGDistributionProjectSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionProjectSourceListGroupItem alloc] initWithGroupType:PKGPackageComponentTypeReference] children:nil];
		
		for(PKGPackageComponent * tPackageComponent in inPackageComponents)
		{
			PKGDistributionProjectSourceListTreeNode * tPackageComponentTreeNode=[[PKGDistributionProjectSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionProjectSourceListPackageComponentItem alloc] initWithPackageComponent:tPackageComponent] children:nil];
			
			PKGDistributionProjectSourceListTreeNode * tGroupNode=nil;
			
			switch (tPackageComponent.type)
			{
				case PKGPackageComponentTypeProject:
					
					tGroupNode=tProjectPackagesGroupNode;
					break;
					
				case PKGPackageComponentTypeImported:
					
					tGroupNode=tProjectImportedGroupNode;
					break;
					
				case PKGPackageComponentTypeReference:
					
					tGroupNode=tProjectReferencedGroupNode;
					break;
					
				default:
					
					// A COMPLETER
					
					break;
			}
			
			[tGroupNode insertChild:tPackageComponentTreeNode sortedUsingComparator:^NSComparisonResult(PKGDistributionProjectSourceListTreeNode * bTreeNode1,PKGDistributionProjectSourceListTreeNode * bTreeNode2){
				
				PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem1=[bTreeNode1 representedObject];
				PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem2=[bTreeNode2 representedObject];
				
				return [tPackageComponentItem1.packageComponent.packageSettings.name compare:tPackageComponentItem2.packageComponent.packageSettings.name options:NSNumericSearch|NSForcedOrderingSearch];
			}];
		}
		
		[_rootNodes addObject:tProjectPackagesGroupNode];
		
		if ([tProjectImportedGroupNode numberOfChildren]>0)
			[_rootNodes addObject:tProjectImportedGroupNode];
		
		if ([tProjectReferencedGroupNode numberOfChildren]>0)
			[_rootNodes addObject:tProjectReferencedGroupNode];
	}
	
	return self;
}

#pragma mark -

- (void)addPackageComponent:(PKGPackageComponent *)inPackageComponent
{
	if (inPackageComponent==nil)
		return;
	
	NSUInteger tGroupIndex=[self.rootNodes indexOfObjectPassingTest:^BOOL(PKGDistributionProjectSourceListTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
	
		PKGDistributionProjectSourceListItem * tItem=[bTreeNode representedObject];
		
		if ([tItem isKindOfClass:PKGDistributionProjectSourceListGroupItem.class]==NO)
			return NO;
		
		return (((PKGDistributionProjectSourceListGroupItem *)tItem).groupType==inPackageComponent.type);
	}];
	
	PKGDistributionProjectSourceListTreeNode * tGroupNode=(tGroupIndex==NSNotFound) ? [[PKGDistributionProjectSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionProjectSourceListGroupItem alloc] initWithGroupType:inPackageComponent.type] children:nil] : self.rootNodes[tGroupIndex];
	
	if (tGroupNode==nil)
		return;
	
	[tGroupNode insertChild:[[PKGDistributionProjectSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionProjectSourceListPackageComponentItem alloc] initWithPackageComponent:inPackageComponent] children:nil] sortedUsingComparator:^NSComparisonResult(PKGDistributionProjectSourceListTreeNode * bTreeNode1,PKGDistributionProjectSourceListTreeNode * bTreeNode2){
		
		PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem1=[bTreeNode1 representedObject];
		PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem2=[bTreeNode2 representedObject];
		
		return [tPackageComponentItem1.packageComponent.packageSettings.name compare:tPackageComponentItem2.packageComponent.packageSettings.name options:NSNumericSearch|NSForcedOrderingSearch];
	}];
 
	if (tGroupIndex==NSNotFound)
	{
		if (inPackageComponent.type==PKGPackageComponentTypeReference)
			[self.rootNodes addObject:tGroupNode];
		else
			[self.rootNodes insertObject:tGroupNode atIndex:2];
	}
}

- (PKGDistributionProjectSourceListTreeNode *)treeNodeForPackageComponent:(PKGPackageComponent *)inPackageComponent
{
	if (inPackageComponent==nil)
		return nil;
	
	for(PKGDistributionProjectSourceListTreeNode * tTreeNode in self.rootNodes)
	{
		PKGDistributionProjectSourceListItem * tItem=[tTreeNode representedObject];
		
		if ([tItem isKindOfClass:PKGDistributionProjectSourceListGroupItem.class]==NO)
			continue;
		
		if (((PKGDistributionProjectSourceListGroupItem *)tItem).groupType==inPackageComponent.type)
		{
			return (PKGDistributionProjectSourceListTreeNode *)[tTreeNode childNodeMatching:^BOOL(PKGDistributionProjectSourceListTreeNode *bComponentTreeNode){
			
				PKGDistributionProjectSourceListPackageComponentItem * tComponentItem=[bComponentTreeNode representedObject];
				
				return (tComponentItem.packageComponent==inPackageComponent);
				
			}];
		}
	}
	
	return nil;
}

- (void)removeNode:(PKGDistributionProjectSourceListTreeNode *)inNode
{
	if (inNode==nil)
		return;
	
	[self removeNodes:@[inNode]];
}

- (void)removeNodes:(NSArray *)inNodes
{
	if (inNodes.count==0)
		return;
	
	// Remove the packages from the hierarchy
	
	for(PKGTreeNode * tTreeNode in inNodes)
	{
		[tTreeNode removeFromParent];
	}
	
	// Remove some groups if they don't have any descendant nodes
	
	NSMutableSet * tRemovableSet=[NSMutableSet set];
	
	for(PKGDistributionProjectSourceListTreeNode * tTreeNode in self.rootNodes)
	{
		PKGDistributionProjectSourceListGroupItem * tGroupItem=[tTreeNode representedObject];
		
		if ([tGroupItem isKindOfClass:PKGDistributionProjectSourceListGroupItem.class]==YES)
		{
			if (tTreeNode.numberOfChildren==0 && tGroupItem.groupType!=PKGPackageComponentTypeProject)
				[tRemovableSet addObject:tTreeNode];
		}
	}
	
	for(PKGDistributionProjectSourceListTreeNode * tTreeNode in tRemovableSet)
		[self.rootNodes removeObject:tTreeNode];
}

@end
