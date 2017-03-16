/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionRequirementSourceListDataSource.h"

#import "PKGDistributionRequirementSourceListForest.h"
#import "PKGDistributionRequirementSourceListTreeNode.h"
#import "PKGDistributionRequirementSourceListGroupItem.h"
#import "PKGDistributionRequirementSourceListRequirementItem.h"

#import "NSOutlineView+Selection.h"

#import "PKGDistributionRequirementPanel.h"

#import "PKGRequirementPluginsManager.h"

#import "PKGRequirement+UI.h"

#import "NSArray+UniqueName.h"

@interface PKGDistributionRequirementSourceListDataSource ()
{
	PKGDistributionRequirementSourceListForest * _forest;
}

- (void)outlineView:(NSOutlineView *)inOutlineView addRequirement:(PKGRequirement *)inRequirement;
- (void)outlineView:(NSOutlineView *)inOutlineView addRequirements:(NSArray *)inRequirements;

@end

@implementation PKGDistributionRequirementSourceListDataSource

- (void)setRequirements:(NSMutableArray *)inRequirements
{
	if (_requirements!=inRequirements)
	{
		_requirements=inRequirements;
		
		_forest=[[PKGDistributionRequirementSourceListForest alloc] initWithRequirements:_requirements];
	}
}

#pragma mark -

- (NSUInteger)numberOfItems
{
	return _forest.numberOfNodes;
}

#pragma mark - NSOutlineViewDataSource

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

#pragma mark - Drag and Drop support

// A COMPLETER

#pragma mark -

- (void)addRequirement:(NSOutlineView *)inOutlineView
{
	PKGRequirement * tNewRequirement=[PKGRequirement new];
	
	tNewRequirement.identifier=@"fr.whitebox.Packages.requirement.os";
	
	PKGDistributionRequirementPanel * tRequirementPanel=[PKGDistributionRequirementPanel distributionRequirementPanel];
	tRequirementPanel.prompt=NSLocalizedString(@"Add", @"");
	tRequirementPanel.requirement=tNewRequirement;
	
	[tRequirementPanel beginSheetModalForWindow:inOutlineView.window completionHandler:^(NSInteger bResult) {
		
		if (bResult==PKGPanelCancelButton)
			return;
		
		NSString * tBaseName=[[PKGRequirementPluginsManager defaultManager] localizedPluginNameForIdentifier:tNewRequirement.identifier];
		
		tNewRequirement.name=[self.requirements uniqueNameWithBaseName:tBaseName usingNameExtractor:^NSString *(PKGRequirement * bRequirement,NSUInteger bIndex) {
			
			return bRequirement.name;
		}];
		
		if (tNewRequirement.name==nil)
		{
			NSLog(@"Could not determine a unique name for the requirement");
			
			tNewRequirement.name=@"";
		}
		
		[self outlineView:inOutlineView addRequirement:tNewRequirement];
	}];
}

- (void)editRequirement:(NSOutlineView *)inOutlineView
{
	NSUInteger tIndex=inOutlineView.WB_selectedOrClickedRowIndexes.firstIndex;
	PKGDistributionRequirementSourceListTreeNode * tTreeNode=[inOutlineView itemAtRow:tIndex];
	PKGDistributionRequirementSourceListRequirementItem * tRequirementItem=(PKGDistributionRequirementSourceListRequirementItem *)[tTreeNode representedObject];
	PKGRequirement * tOriginalRequirement=tRequirementItem.requirement;
	PKGRequirement * tEditedRequirement=[tOriginalRequirement copy];

	PKGDistributionRequirementPanel * tRequirementPanel=[PKGDistributionRequirementPanel distributionRequirementPanel];

	tRequirementPanel.requirement=tEditedRequirement;

	[tRequirementPanel beginSheetModalForWindow:inOutlineView.window completionHandler:^(NSInteger bResult) {

		if (bResult==PKGPanelCancelButton)
				return;

		if ([tEditedRequirement isEqualToRequirement:tOriginalRequirement]==YES)
			return;

		NSUInteger tIndex=[self.requirements indexOfObjectIdenticalTo:tOriginalRequirement];
		
		if (tIndex==NSNotFound)
			return;
		
		PKGRequirementType tOriginalRequirementType=tOriginalRequirement.requirementType;
		PKGRequirementType tEditedRequirementType=tEditedRequirement.requirementType;
		
		if (tOriginalRequirementType==tEditedRequirementType)
		{
			[self.requirements replaceObjectAtIndex:tIndex withObject:tEditedRequirement];
			
			[tTreeNode setRepresentedObject:[[PKGDistributionRequirementSourceListRequirementItem alloc] initWithRequirement:tEditedRequirement]];
			
			[self.delegate sourceListDataDidChange:self];
			
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
		
			[self.requirements removeObject:tOriginalRequirement];
			
			PKGDistributionRequirementSourceListTreeNode * tParentNode=(PKGDistributionRequirementSourceListTreeNode *)[tTreeNode parent];
			
			[tTreeNode removeFromParent];
			
			if ([tParentNode numberOfChildren]==0)
				[_forest.rootNodes removeObject:tParentNode];
			
			[self outlineView:inOutlineView addRequirement:tEditedRequirement];
		});
	}];
}

- (void)outlineView:(NSOutlineView *)inOutlineView setItem:(PKGDistributionRequirementSourceListTreeNode *)inRequirementTreeNode state:(BOOL)inState
{
	if (inOutlineView==nil || inRequirementTreeNode==nil)
		return;
	
	PKGDistributionRequirementSourceListRequirementItem * tRequirementItem=[inRequirementTreeNode representedObject];
	PKGRequirement * tRequirement=tRequirementItem.requirement;
	
	if (tRequirement.isEnabled==inState)
		return;
	
	tRequirement.enabled=inState;
	
	[self.delegate sourceListDataDidChange:self];
}

- (void)outlineView:(NSOutlineView *)inOutlineView addRequirement:(PKGRequirement *)inRequirement
{
	if (inRequirement==nil)
		return;
	
	[self outlineView:inOutlineView addRequirements:@[inRequirement]];
}

- (void)outlineView:(NSOutlineView *)inOutlineView addRequirements:(NSArray *)inRequirements
{
	if (inOutlineView==nil || inRequirements.count==0)
		return;
	
	NSMutableSet * tMutableSet=[NSMutableSet set];
	
	for(PKGRequirement * tRequirement in inRequirements)
	{
		if ([self.requirements containsObject:tRequirement]==YES)
		{
			// A COMPLETER
			
			continue;
		}
		
		[self.requirements addObject:tRequirement];
		
		[_forest addRequirement:tRequirement];
		
		[tMutableSet addObject:tRequirement];
	}
	
	if (tMutableSet.count==0)
		return;
	
	
	
	// Post Notification
	
	// A COMPLETER
	
	[inOutlineView reloadData];
	
	[self.delegate sourceListDataDidChange:self];
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	for(PKGRequirement * tRequirement in tMutableSet)
	{
		PKGDistributionRequirementSourceListTreeNode * tTreeNode=[_forest treeNodeForRequirement:tRequirement];
		
		if ([inOutlineView isItemExpanded:tTreeNode.parent]==NO)
			[inOutlineView expandItem:tTreeNode.parent];
		
		NSInteger tSelectedRow=(tTreeNode==nil) ? 0 : [inOutlineView rowForItem:tTreeNode];
		
		if (tSelectedRow==-1)
			tSelectedRow=0;
		
		[tMutableIndexSet addIndex:tSelectedRow];
	}
	
	[inOutlineView scrollRowToVisible:(tMutableIndexSet.firstIndex==NSNotFound) ? 0 : tMutableIndexSet.firstIndex];
	
	[inOutlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldRenameRequirement:(PKGDistributionRequirementSourceListTreeNode *)inRequirementTreeNode as:(NSString *)inNewName
{
	if (inOutlineView==nil || inRequirementTreeNode==nil || inNewName==nil)
		return NO;
	
	PKGRequirement * tRequirement=((PKGDistributionRequirementSourceListRequirementItem *) [inRequirementTreeNode representedObject]).requirement;
	NSString * tName=tRequirement.name;
	
	if ([tName compare:inNewName]==NSOrderedSame)
		return NO;
	
	if ([tName caseInsensitiveCompare:inNewName]!=NSOrderedSame)
	{
		NSUInteger tLength=inNewName.length;
		NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[inOutlineView rowForItem:inRequirementTreeNode]];
		NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[inOutlineView columnWithIdentifier:@"requirement"]];
		
		if (tLength==0)
		{
			[inOutlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView renameRequirement:(PKGDistributionRequirementSourceListTreeNode *)inRequirementTreeNode as:(NSString *)inNewName
{
	if (inOutlineView==nil || inRequirementTreeNode==nil || inNewName==nil)
		return NO;
	
	PKGRequirement * tRequirement=((PKGDistributionRequirementSourceListRequirementItem *) [inRequirementTreeNode representedObject]).requirement;
	
	tRequirement.name=inNewName;
	
	[inOutlineView reloadData];
	
	[self.delegate sourceListDataDidChange:self];
	
	NSInteger tSelectedRow=[inOutlineView rowForItem:inRequirementTreeNode];
	
	if (tSelectedRow!=-1)
	{
		[inOutlineView scrollRowToVisible:tSelectedRow];
		[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tSelectedRow] byExtendingSelection:NO];
	}
	
	return YES;
}

- (void)outlineView:(NSOutlineView *)inOutlineView duplicateItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems.count==0)
		return;
	
	__block NSMutableArray * tTemporaryComponents=[self.requirements mutableCopy];
	
	NSArray * tDuplicatedPackageComponents=[inItems WB_arrayByMappingObjectsLenientlyUsingBlock:^PKGRequirement *(PKGDistributionRequirementSourceListTreeNode * bSourceListTreeNode, NSUInteger bIndex) {
		
		PKGDistributionRequirementSourceListRequirementItem * tRequirementItem=[bSourceListTreeNode representedObject];
		
		PKGRequirement * tNewRequirement=[tRequirementItem.requirement copy];
		
		// Unique Name
		
		__block NSString * tBaseName=tNewRequirement.name;
		
		NSString * tPattern=[NSString stringWithFormat:@"%@ ?[0-9]*$",NSLocalizedString(@" copy", @"")];
		
		NSRegularExpression * tRegularExpression=[NSRegularExpression regularExpressionWithPattern:tPattern options:NSRegularExpressionCaseInsensitive error:NULL];
		
		[tRegularExpression enumerateMatchesInString:tBaseName options:NSMatchingReportCompletion range:NSMakeRange(0,tBaseName.length) usingBlock:^(NSTextCheckingResult * bResult, NSMatchingFlags bFlags, BOOL * bOutStop) {
			
			if (bResult.resultType!=NSTextCheckingTypeRegularExpression)
				return;
			
			tBaseName=[tBaseName substringToIndex:bResult.range.location];
			
			*bOutStop=YES;
		}];
		
		NSString * tNewName=[tTemporaryComponents uniqueNameWithBaseName:[tBaseName stringByAppendingString:NSLocalizedString(@" copy", @"")]
													  usingNameExtractor:^NSString *(PKGRequirement * bRequirement, NSUInteger bIndex) {
														  return bRequirement.name;
													  }];
		
		if (tNewName!=nil)
			tNewRequirement.name=tNewName;
		
		
		[tTemporaryComponents addObject:tNewRequirement];
		
		return tNewRequirement;
	}];
	
	[self outlineView:inOutlineView addRequirements:tDuplicatedPackageComponents];
}

- (void)outlineView:(NSOutlineView *)inOutlineView removeItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems.count==0)
		return;
	
	// Remove the requirements
	
	for(PKGTreeNode * tTreeNode in inItems)
	{
		PKGDistributionRequirementSourceListRequirementItem * tRequirementItem=[tTreeNode representedObject];
		
		// A COMPLETER
		
		[_requirements removeObject:tRequirementItem.requirement];
		
		[tTreeNode removeFromParent];
	}
	
	// Remove some groups if they don't have any descendant nodes
	
	NSMutableSet * tRemovableSet=[NSMutableSet set];
	
	for(PKGDistributionRequirementSourceListTreeNode * tTreeNode in _forest.rootNodes)
	{
		PKGDistributionRequirementSourceListGroupItem * tGroupItem=[tTreeNode representedObject];
		
		if ([tGroupItem isKindOfClass:PKGDistributionRequirementSourceListGroupItem.class]==YES)
		{
			if (tTreeNode.numberOfChildren==0)
				[tRemovableSet addObject:tTreeNode];
		}
	}
	
	for(PKGDistributionRequirementSourceListTreeNode * tTreeNode in tRemovableSet)
		[_forest.rootNodes removeObject:tTreeNode];
	
	[inOutlineView deselectAll:nil];
	
	[inOutlineView reloadData];
	
	[self.delegate sourceListDataDidChange:self];
}

@end
