/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGInstallationHierarchy+Edition.h"

#import "PKGChoicesForest+Edition.h"

#import "PKGPackageComponent.h"

@implementation PKGInstallationHierarchy (Edition)

- (void)addChoicesForPackageComponents:(NSArray *)inPackageComponents
{
	if (inPackageComponents.count==0)
		return;
	
	[inPackageComponents enumerateObjectsUsingBlock:^(PKGPackageComponent * bPackageComponent, NSUInteger idx, BOOL *stop) {
		
		PKGChoicePackageItem * tChoicePackageItem=[[PKGChoicePackageItem alloc] initWithPackageComponent:bPackageComponent];
		
		PKGChoiceTreeNode * tChoiceTreeNode=[[PKGChoiceTreeNode alloc] initWithRepresentedObject:tChoicePackageItem children:nil];
		
		[self.choicesForest.rootNodes addObject:tChoiceTreeNode];
	}];
}

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

- (NSArray *)insertBackPackageComponentUUIDs:(NSArray *)inPackageComponentsUUIDs asChildrenOfNode:(PKGChoiceTreeNode *)inTreeNode index:(NSUInteger)inIndex
{
	if (inPackageComponentsUUIDs.count==0)
		return @[];
	
	NSMutableArray * tChoicesArray=[NSMutableArray array];
	
	for(NSString * tPackageComponentUUID in inPackageComponentsUUIDs)
	{
		PKGChoiceTreeNode * tChoiceTreeNode=self.removedPackagesChoices[tPackageComponentUUID];
		
		if (tChoiceTreeNode==nil)
		{
			NSLog(@"Choice for package component \"%@\" could not be found. Internal incoherency.",tPackageComponentUUID);
			
			return @[];
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
	
	return tChoicesArray;
}

@end
