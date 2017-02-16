/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectSourceListDataSource.h"

#import "PKGDistributionProjectSourceListForest.h"
#import "PKGDistributionProjectSourceListTreeNode.h"
#import "PKGDistributionProjectSourceListGroupItem.h"
#import "PKGDistributionProjectSourceListPackageComponentItem.h"

#import "NSOutlineView+Selection.h"

@interface PKGDistributionProjectSourceListDataSource ()
{
	PKGDistributionProjectSourceListForest * _forest;
}

@end

@implementation PKGDistributionProjectSourceListDataSource

- (void)setPackageComponents:(NSMutableArray *)inPackageComponents
{
	if (_packageComponents!=inPackageComponents)
	{
		_packageComponents=inPackageComponents;
		
		_forest=[[PKGDistributionProjectSourceListForest alloc] initWithPackageComponents:inPackageComponents];
	}
}

#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _forest.rootNodes.count;
	
	return inTreeNode.numberOfChildren;
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)inIndex ofItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _forest.rootNodes[inIndex];
	
	return [inTreeNode descendantNodeAtIndex:inIndex];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(PKGTreeNode *)inTreeNode
{
	return ([inTreeNode isLeaf]==NO);
}

#pragma mark -

- (void)outlineView:(NSOutlineView *)inOutlineView removeItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems.count==0)
		return;
	
	// Save the selection if needed
	
	NSArray * tSavedSelectedItems=nil;
	
	if (inItems.count==1)
	{
		if ([inOutlineView isRowSelected:[inOutlineView rowForItem:inItems[0]]]==NO)
			tSavedSelectedItems=[inOutlineView WB_selectedItems];
	}
	
	NSInteger tFirstIndex=[inOutlineView rowForItem:inItems[0]];
	
	// Remove the packages
	
	for(PKGTreeNode * tTreeNode in inItems)
	{
		PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem=[tTreeNode representedObject];
		
		// A COMPLETER
		
		[_packageComponents removeObject:tPackageComponentItem.packageComponent];
		
		[tTreeNode removeFromParent];
	}
	
	// Remove some groups if they don't have any descendant nodes
	
	NSMutableSet * tRemovableSet=[NSMutableSet set];
	
	for(PKGDistributionProjectSourceListTreeNode * tTreeNode in _forest.rootNodes)
	{
		PKGDistributionProjectSourceListGroupItem * tGroupItem=[tTreeNode representedObject];
		
		if ([tGroupItem isKindOfClass:PKGDistributionProjectSourceListGroupItem.class]==YES)
		{
			if (tTreeNode.numberOfChildren==0 && tGroupItem.groupType!=PKGPackageComponentTypeProject)
				[tRemovableSet addObject:tTreeNode];
		}
	}
	
	for(PKGDistributionProjectSourceListTreeNode * tTreeNode in tRemovableSet)
		[_forest.rootNodes removeObject:tTreeNode];
	
	[self.delegate sourceListDataDidChange:self];
	
	inOutlineView.allowsEmptySelection=YES;
	
	[inOutlineView deselectAll:nil];
	
	[inOutlineView reloadData];
	
	if (tSavedSelectedItems!=nil)
	{
		NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
		
		for(id tItem in tSavedSelectedItems)
		{
			NSInteger tIndex=[inOutlineView rowForItem:tItem];
			
			if (tIndex!=-1)
				[tMutableIndexSet addIndex:tIndex];
		}
		
		[inOutlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
	}
	
	if (inOutlineView.numberOfSelectedRows==0)
	{
		NSInteger tNewSelectionIndex=tFirstIndex-1;
		
		for(;tNewSelectionIndex>=1;tNewSelectionIndex--)
		{
			PKGDistributionProjectSourceListTreeNode * tTreeNode=[inOutlineView itemAtRow:tNewSelectionIndex];
			
			if (tTreeNode==nil)
				continue;
			
			PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem=[tTreeNode representedObject];
			
			if ([tPackageComponentItem isKindOfClass:PKGDistributionProjectSourceListPackageComponentItem.class]==NO)
				continue;
			
			break;
		}
		
		[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tNewSelectionIndex] byExtendingSelection:NO];
	}
	
	inOutlineView.allowsEmptySelection=NO;
}

@end
