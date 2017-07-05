/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGChoiceDependencyTree+Edition.h"

@implementation PKGChoiceDependencyPredicateValues

@end

@implementation PKGChoiceDependencyTree (Edition)

- (PKGChoiceDependencyTree *)removePredicatesForChoicesUUID:(NSArray *)inChoicesUUID
{
	if (inChoicesUUID.count==0)
		return self;
	
	__block PKGChoiceDependencyTreeNode * tRootNode=self.rootNode;
	
	__block __weak BOOL (^_weakRecursivelyRemovePredicatesForChoices)(PKGChoiceDependencyTreeNode *);
	__block BOOL(^_recursivelyRemovePredicatesForChoices)(PKGChoiceDependencyTreeNode *);
	
	_recursivelyRemovePredicatesForChoices = ^BOOL(PKGChoiceDependencyTreeNode * bTreeNode)
	{
		if (bTreeNode==nil)
			return NO;
		
		if ([bTreeNode isKindOfClass:PKGChoiceDependencyTreeLogicNode.class]==YES)
		{
			PKGChoiceDependencyTreeLogicNode * bLogicNode=(PKGChoiceDependencyTreeLogicNode *)bTreeNode;
			
			BOOL tRemovedTopBranch=_weakRecursivelyRemovePredicatesForChoices(bLogicNode.topChildNode);
			PKGChoiceDependencyTreeNode * tRemainingNode=nil;
			
			if (tRemovedTopBranch==YES)
			{
				bLogicNode.topChildNode=nil;
				tRemainingNode=bLogicNode.bottomChildNode;
			}
			
			BOOL tRemovedBottomBranch=_weakRecursivelyRemovePredicatesForChoices(bLogicNode.bottomChildNode);
			
			if (tRemovedBottomBranch==YES)
			{
				bLogicNode.bottomChildNode=nil;
				tRemainingNode=bLogicNode.topChildNode;
			}
			
			if (tRemovedTopBranch==YES && tRemovedBottomBranch==YES)
				return YES;
			
			if (tRemovedTopBranch==YES|| tRemovedBottomBranch==YES)
			{
				PKGChoiceDependencyTreeNode * tParentNode=bLogicNode.parentNode;
				
				if (tParentNode==nil)
				{
					tRootNode=tRemainingNode;
					
					return NO;
				}
				
				PKGChoiceDependencyTreeLogicNode * tLogicNode=(PKGChoiceDependencyTreeLogicNode *)tParentNode;
				
				if (tLogicNode.topChildNode==bLogicNode)
				{
					tLogicNode.topChildNode=tRemainingNode;
					
					return NO;
				}
				
				if (tLogicNode.bottomChildNode==bLogicNode)
				{
					tLogicNode.bottomChildNode=tRemainingNode;
					
					return NO;
				}
			}
			
			return NO;
		}
		
		if ([bTreeNode isKindOfClass:PKGChoiceDependencyTreePredicateNode.class]==YES)
		{
			PKGChoiceDependencyTreePredicateNode * bPredicateNode=(PKGChoiceDependencyTreePredicateNode *)bTreeNode;
			
			return ([inChoicesUUID containsObject:bPredicateNode.choiceUUID]==YES);
		}
		
		return NO;
	};
	
	_weakRecursivelyRemovePredicatesForChoices = _recursivelyRemovePredicatesForChoices;
	
	if (_recursivelyRemovePredicatesForChoices(self.rootNode)==YES)
		return nil;
	
	self.rootNode=tRootNode;
	
	return self;
}

- (void)removeNode:(PKGChoiceDependencyTreeNode *)inTreeNode
{
	// A COMPLETER
}

#pragma mark -

- (NSSet *)allDependenciesStates
{
	NSMutableSet * tMutableSet=[NSMutableSet set];
	
	[self.rootNode enumeratePredicatesNodesUsingBlock:^(PKGChoiceDependencyTreePredicateNode * bPredicateTreeNode,BOOL *bOutStop){
	
		PKGChoiceDependencyPredicateValues * tPredicateValues=[PKGChoiceDependencyPredicateValues new];
		tPredicateValues.choiceUUID=bPredicateTreeNode.choiceUUID;
		tPredicateValues.referenceState=bPredicateTreeNode.referenceState;
		
		[tMutableSet addObject:tPredicateValues];
	}];
	
	return [tMutableSet copy];
}

@end
