/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "PKGDistributionRequirementSourceListForest.h"

#import "PKGDistributionRequirementSourceListGroupItem.h"
#import "PKGDistributionRequirementSourceListRequirementItem.h"

#import "PKGRequirementPluginsManager.h"
#import "PKGRequirementConverter.h"

#import "PKGRequirement+UI.h"

@interface PKGDistributionRequirementSourceListForest ()
{
	NSMutableArray * _requirements;
}

	@property (nonatomic,readwrite) NSMutableArray * rootNodes;

@end

@implementation PKGDistributionRequirementSourceListForest

- (instancetype)initWithRequirements:(NSMutableArray *)inRequirements
{
	self=[super init];
	
	if (self!=nil)
	{
		_requirements=inRequirements;
		
		_rootNodes=[NSMutableArray array];
		
		PKGDistributionRequirementSourceListTreeNode * tInstallationGroupNode=[[PKGDistributionRequirementSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionRequirementSourceListGroupItem alloc] initWithGroupType:PKGRequirementTypeInstallation] children:nil];
		PKGDistributionRequirementSourceListTreeNode * tTargetGroupNode=[[PKGDistributionRequirementSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionRequirementSourceListGroupItem alloc] initWithGroupType:PKGRequirementTypeTarget] children:nil];
		
		for(PKGRequirement * tRequirement in inRequirements)
		{
			PKGDistributionRequirementSourceListTreeNode * tRequirementTreeNode=[[PKGDistributionRequirementSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionRequirementSourceListRequirementItem alloc] initWithRequirement:tRequirement] children:nil];
			
			PKGDistributionRequirementSourceListTreeNode * tGroupNode=nil;
			
			PKGRequirementType tRequirementType=tRequirement.requirementType;
			
			switch (tRequirementType)
			{
				case PKGRequirementTypeInstallation:
					
					tGroupNode=tInstallationGroupNode;
					break;
					
				case PKGRequirementTypeTarget:
					
					tGroupNode=tTargetGroupNode;
					break;
					
				default:
					
					// A COMPLETER
					
					break;
			}
			
			[tGroupNode addChild:tRequirementTreeNode];
		}
		
		if ([tInstallationGroupNode numberOfChildren]>0)
			[_rootNodes addObject:tInstallationGroupNode];
		
		if ([tTargetGroupNode numberOfChildren]>0)
			[_rootNodes addObject:tTargetGroupNode];
	}
	
	return self;
}

#pragma mark -

- (void)addRequirement:(PKGRequirement *)inRequirement
{
	if (inRequirement==nil)
		return;
	
	PKGRequirementType tRequirementType=inRequirement.requirementType;
	
	NSUInteger tGroupIndex=[self.rootNodes indexOfObjectPassingTest:^BOOL(PKGDistributionRequirementSourceListTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		PKGDistributionRequirementSourceListItem * tItem=[bTreeNode representedObject];
		
		if ([tItem isKindOfClass:PKGDistributionRequirementSourceListGroupItem.class]==NO)
			return NO;
		
		return (((PKGDistributionRequirementSourceListGroupItem *)tItem).groupType==tRequirementType);
	}];
	
	PKGDistributionRequirementSourceListTreeNode * tGroupNode=(tGroupIndex==NSNotFound) ? [[PKGDistributionRequirementSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionRequirementSourceListGroupItem alloc] initWithGroupType:inRequirement.type] children:nil] : self.rootNodes[tGroupIndex];
	
	if (tGroupNode==nil)
		return;
	
	[tGroupNode addChild:[[PKGDistributionRequirementSourceListTreeNode alloc] initWithRepresentedObject:[[PKGDistributionRequirementSourceListRequirementItem alloc] initWithRequirement:inRequirement] children:nil]];
 
	if (tGroupIndex==NSNotFound)
	{
		if (tRequirementType==PKGRequirementTypeTarget)
			[self.rootNodes addObject:tGroupNode];
		else
			[self.rootNodes insertObject:tGroupNode atIndex:0];
	}
}

- (PKGDistributionRequirementSourceListTreeNode *)treeNodeForRequirement:(PKGRequirement *)inRequirement
{
	if (inRequirement==nil)
		return nil;
	
	PKGRequirementType tRequirementType=inRequirement.requirementType;
	
	for(PKGDistributionRequirementSourceListTreeNode * tTreeNode in self.rootNodes)
	{
		PKGDistributionRequirementSourceListItem * tItem=[tTreeNode representedObject];
		
		if ([tItem isKindOfClass:PKGDistributionRequirementSourceListGroupItem.class]==NO)
			continue;
		
		if (((PKGDistributionRequirementSourceListGroupItem *)tItem).groupType==tRequirementType)
		{
			return (PKGDistributionRequirementSourceListTreeNode *)[tTreeNode descendantNodeMatching:^BOOL(PKGDistributionRequirementSourceListTreeNode *bComponentTreeNode){
				
				PKGDistributionRequirementSourceListRequirementItem * tRequirementItem=[bComponentTreeNode representedObject];
				
				return (tRequirementItem.requirement==inRequirement);
				
			}];
		}
	}
	
	return nil;
}

@end
