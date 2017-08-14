/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectSettingsAdvancedOptionsDataSource.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsTree.h"
#import "PKGDistributionProjectSettingsAdvancedOptionsTreeNode.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsItem.h"

#import "NSOutlineView+Selection.h"

#import "PKGDistributionProjectSettingsAdvancedOptionObject.h"

NSString * const PKGDistributionProjectSettingsAdvancedOptionsTreeKey=@"OPTIONS_TREE";

NSString * const PKGDistributionProjectSettingsAdvancedOptionsDescriptionsKey=@"OPTIONS_DESCRIPTION";

@interface PKGDistributionProjectSettingsAdvancedOptionsDataSource ()
{
	PKGDistributionProjectSettingsAdvancedOptionsTree * _tree;
	
	NSDictionary * _advancedOptionsDescriptions;
}

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionsDataSource

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		NSString * tPath=[[NSBundle mainBundle] pathForResource:@"AdvancedOptions" ofType:@"plist"];
		
		if (tPath==nil)
		{
			// A COMPLETER
			
			return nil;
		}
		
		NSError * tError=nil;
		
		NSData * tData=[NSData dataWithContentsOfFile:tPath options:0 error:&tError];
		
		if (tData==nil)
		{
			// A COMPLETER
			
			return nil;
		}
		
		NSDictionary * tDictionary=[NSPropertyListSerialization propertyListWithData:tData options:NSPropertyListImmutable format:NULL error:&tError];
		
		if (tDictionary==nil)
		{
			// A COMPLETER
			
			return nil;
		}
		
		if ([tDictionary isKindOfClass:NSDictionary.class]==NO)
		{
			// A COMPLETER
			
			return nil;
		}
		
		_tree=[[PKGDistributionProjectSettingsAdvancedOptionsTree alloc] initWithRepresentation:tDictionary[PKGDistributionProjectSettingsAdvancedOptionsTreeKey] error:&tError];
		
		if (_tree==nil)
		{
			// A COMPLETER
			
			return nil;
		}
		
		_advancedOptionsDescriptions=[PKGDistributionProjectSettingsAdvancedOptionObject advancedOptionsRegistryWithRepresentation:tDictionary[PKGDistributionProjectSettingsAdvancedOptionsDescriptionsKey] error:&tError];
		
		if (_advancedOptionsDescriptions==nil)
		{
			// A COMPLETER
			
			return nil;
		}
	}
	
	return self;
}

#pragma mark -

- (id)rootNode
{
	return _tree.rootNode;
}

- (NSUInteger)numberOfItems
{
	return _tree.rootNode.numberOfNodes;
}

- (id)advancedOptionsObjectForItem:(PKGDistributionProjectSettingsAdvancedOptionsTreeNode *)inNode
{
	if (inNode==nil)
		return nil;
	
	PKGDistributionProjectSettingsAdvancedOptionsItem * tItem=[inNode representedObject];
	
	if (tItem==nil || tItem.itemID==nil)
		return nil;
	
	return _advancedOptionsDescriptions[tItem.itemID];
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _tree.rootNodes.array.count;
	
	return inTreeNode.numberOfChildren;
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)inIndex ofItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _tree.rootNodes.array[inIndex];
	
	return [inTreeNode childNodeAtIndex:inIndex];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(PKGTreeNode *)inTreeNode
{
	return ([inTreeNode isLeaf]==NO);
}

@end
