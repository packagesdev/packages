/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGInstallationHierarchyDataSource.h"

#import "PKGChoiceItem.h"

#import "NSOutlineView+Selection.h"

#import "PKGPackageComponent+UI.h"

#import "PKGChoiceTreeNode+UI.h"

#import "PKGChoicesForest+Edition.h"
#import "PKGInstallationHierarchy+Edition.h"

#import "NSObject+Conformance.h"

NSString * const PKGInstallationHierarchyChoicesInternalPboardType=@"fr.whitebox.packages.internal.installation.hierarchy.choices";
NSString * const PKGInstallationHierarchyHiddenPackagesInternalPboardType=@"fr.whitebox.packages.internal.installation.hierarchy.hidden.packages";
NSString * const PKGInstallationHierarchyChoicesUUIDsPboardType=@"fr.whitebox.packages.internal.installation.hierarchy.choiceUUIDs";

@interface PKGInstallationHierarchyDataSource ()
{
	PKGChoicesForest * _forest;
	
	NSArray * _internalDragData;
}

@end

@implementation PKGInstallationHierarchyDataSource

+ (NSArray *)supportedDraggedTypes
{
	return @[PKGInstallationHierarchyChoicesInternalPboardType,PKGInstallationHierarchyHiddenPackagesInternalPboardType,PKGPackageComponentUUIDsPboardType];
}

- (void)dealloc
{
	_internalDragData=nil;
}

#pragma mark -

- (void)setInstallationHierarchy:(PKGInstallationHierarchy *)inInstallationHierarchy
{
	if (_installationHierarchy!=inInstallationHierarchy)
	{
		_installationHierarchy=inInstallationHierarchy;
		
		_forest=inInstallationHierarchy.choicesForest;
	}
}

- (void)setDelegate:(id<PKGInstallationHierarchyDataSourceDelegate>)inDelegate
{
	if (_delegate==inDelegate)
		return;
	
	if (inDelegate==nil)
	{
		_delegate=nil;
		return;
	}
	
	if ([((NSObject *)inDelegate) WB_doesReallyConformToProtocol:@protocol(PKGInstallationHierarchyDataSourceDelegate)]==NO)
		return;
	
	_delegate=inDelegate;
}

#pragma mark -

- (id)itemWithChoiceUUID:(NSString *)inChoiceUUID
{
	__block BOOL (^_compareUUID)(PKGChoiceTreeNode *)=^BOOL(PKGChoiceTreeNode * bTreeNode)
	{
		PKGChoiceItem * tChoiceItem=bTreeNode.representedObject;
		
		return [tChoiceItem.UUID isEqualToString:inChoiceUUID];
	};
	
	for(PKGChoiceTreeNode * tTreeNode in _forest.rootNodes)
	{
		if (_compareUUID(tTreeNode)==YES)
			return tTreeNode;
		
		PKGChoiceTreeNode * tMatchingTreeNode=(PKGChoiceTreeNode *)[tTreeNode childNodeMatching:_compareUUID];
		
		if (tMatchingTreeNode!=nil)
			return tMatchingTreeNode;
	}
	
	return nil;
}

- (void)outlineView:(NSOutlineView *)inOutlineView removeItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems.count==0)
		return;
	
	// Save the selection (if it's a control-click outside the selection)
	
	NSArray * tSavedSelectedItems=nil;
	
	if (inItems.count==1)
	{
		if ([inOutlineView isRowSelected:[inOutlineView rowForItem:inItems[0]]]==NO)
			tSavedSelectedItems=[inOutlineView WB_selectedItems];
	}
	
	NSArray * tMinimumCover=[PKGTreeNode minimumNodeCoverFromNodesInArray:inItems];
	
	NSMutableArray * tAllTreeNodes=[NSMutableArray array];
	
	for(PKGChoiceTreeNode * tTreeNode in tMinimumCover)
	{
		[tTreeNode enumerateNodesUsingBlock:^(PKGChoiceTreeNode * bChoiceTreeNode, BOOL *bOutStop) {
			[tAllTreeNodes addObject:bChoiceTreeNode];
		}];
	}
	
	NSArray * tAdditionalRemovedTreeNodes=[_forest removeChoiceTreeNodes:tMinimumCover];
	
	if (tAdditionalRemovedTreeNodes.count>0)
		[tAllTreeNodes addObjectsFromArray:tAdditionalRemovedTreeNodes];
	

	NSMutableDictionary * tDisclosedStateDictionary=[self.delegate disclosedDictionary];
	
	// Remove all dependencies
	
	[_forest removeDependendenciesToChoiceTreeNodes:tAllTreeNodes];
	
	// Update the Removed list
	
	[tAllTreeNodes enumerateObjectsUsingBlock:^(PKGChoiceTreeNode * bChoiceTreeNode, NSUInteger idx, BOOL *stop){
		
		PKGChoiceItem * tChoiceItem=bChoiceTreeNode.representedObject;
		
		if (tChoiceItem.type!=PKGChoiceItemTypePackage)
		{
			// Remove the items from the disclosed state if needed
			
			[tDisclosedStateDictionary removeObjectForKey:tChoiceItem.UUID];
			
			return;
		}
		
		PKGChoicePackageItem * tChoicePackageItem=(PKGChoicePackageItem *)tChoiceItem;
		
		tChoicePackageItem.options.state=PKGSelectedChoiceState;
		tChoicePackageItem.options.stateDependencies=nil;
		
		self.installationHierarchy.removedPackagesChoices[tChoicePackageItem.packageUUID]=bChoiceTreeNode;
		
	}];
	
	[self.delegate installationHierarchyDataDidChange:self];
	
	[inOutlineView deselectAll:nil];
	
	[inOutlineView reloadData];
	
	// Restore the selection (if ctrl click outside the selection)
	
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
}

- (void)outlineView:(NSOutlineView *)inOutlineView groupItems:(NSArray *)inItems
{
	PKGChoiceTreeNode * tNewGroupChoiceTreeNode=[_forest groupChoiceTreeNodes:inItems inGroupNamed:@"untitled group"];
	
	if (tNewGroupChoiceTreeNode==nil)
		return;
	
	[self.delegate installationHierarchyDataDidChange:self];
	
	[inOutlineView deselectAll:nil];
	
	[inOutlineView reloadData];
	
	// Select new group
	
	NSUInteger tRowIndex=[inOutlineView rowForItem:tNewGroupChoiceTreeNode];
	
	[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRowIndex] byExtendingSelection:NO];
}

- (void)outlineView:(NSOutlineView *)inOutlineView ungroupItemsInGroup:(PKGChoiceTreeNode *)inGroupChoiceTreeNode
{
	if (inOutlineView==nil || inGroupChoiceTreeNode==nil)
		return;
	
	NSArray * tChildren=[inGroupChoiceTreeNode children];
	
	[_forest ungroupChildrenOfGroup:inGroupChoiceTreeNode];
	
	// Remove the item from the disclosed item if needed
	
	PKGChoiceItem * tChoiceItem=inGroupChoiceTreeNode.representedObject;
	
	NSMutableDictionary * tDisclosedStateDictionary=[self.delegate disclosedDictionary];
	
	[tDisclosedStateDictionary removeObjectForKey:tChoiceItem.UUID];
	
	
	[self.delegate installationHierarchyDataDidChange:self];
	
	[inOutlineView deselectAll:nil];
	
	[inOutlineView reloadData];
	
	// Update selection
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	for(id tItem in tChildren)
	{
		NSInteger tIndex=[inOutlineView rowForItem:tItem];
		
		if (tIndex!=-1)
			[tMutableIndexSet addIndex:tIndex];
	}
	
	[inOutlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
}

- (void)outlineView:(NSOutlineView *)inOutlineView mergeItems:(NSArray *)inItems
{
	PKGChoiceTreeNode * tNewGroupChoiceTreeNode=[_forest mergeSiblings:inItems asChoiceNamed:@"untitled choice"];
	
	if (tNewGroupChoiceTreeNode==nil)
		return;
	
	[self.delegate installationHierarchyDataDidChange:self];
	
	[inOutlineView deselectAll:nil];
	
	[inOutlineView reloadData];
	
	// Select new group
	
	NSUInteger tRowIndex=[inOutlineView rowForItem:tNewGroupChoiceTreeNode];
	
	[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRowIndex] byExtendingSelection:NO];
}

- (void)outlineView:(NSOutlineView *)inOutlineView separateItemsMergedAsItem:(PKGChoiceTreeNode *)inGroupChoiceTreeNode
{
	[self outlineView:inOutlineView ungroupItemsInGroup:inGroupChoiceTreeNode];
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
	
	return [inTreeNode childNodeAtIndex:inIndex];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(PKGTreeNode *)inTreeNode
{
	return ([inTreeNode isLeaf]==NO);
}

#pragma mark - Drag and Drop support


- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:(NSDragOperation)inOperation
{
	_internalDragData=nil;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView writeItems:(NSArray*)inItems toPasteboard:(NSPasteboard*)inPasteboard
{
	if (inOutlineView==nil)
		return NO;
	
	typedef NS_ENUM(NSUInteger, PKGHierarchyDataSourcePasteboardType)
	{
		PKGHierarchyDataSourceUnknownPasteboardType,
		PKGHierarchyDataSourceChoicesPasteboardType,
		PKGHierarchyDataSourceHiddenPackagesPasteboardType
	};
	
	_internalDragData=[PKGTreeNode minimumNodeCoverFromNodesInArray:inItems];
	
	__block PKGHierarchyDataSourcePasteboardType tPasteboardType=PKGHierarchyDataSourceUnknownPasteboardType;
	__block BOOL tCancelDrag=NO;
	
	NSMutableArray * tChoicesUUID=[NSMutableArray array];
	
	[_internalDragData enumerateObjectsUsingBlock:^(PKGChoiceTreeNode * bChoiceTreeNode, NSUInteger bIndex, BOOL *bOutstop) {
		
		PKGChoiceItem * tChoiceItem=[bChoiceTreeNode representedObject];
		
		if (tChoiceItem.type==PKGChoiceItemTypeUnknown)
		{
			// Something is really wrong
			
			*bOutstop=YES;
			tCancelDrag=YES;
			return;
		}
		
		if (tChoiceItem.type==PKGChoiceItemTypeGroup)
		{
			if (tPasteboardType==PKGHierarchyDataSourceHiddenPackagesPasteboardType)
			{
				*bOutstop=YES;
				return;
			}
			
			tPasteboardType=PKGHierarchyDataSourceChoicesPasteboardType;
			[tChoicesUUID addObject:tChoiceItem.UUID];
			
			return;
		}
		
		if (tChoiceItem.type==PKGChoiceItemTypePackage)
		{
			if (bChoiceTreeNode.isMergedIntoPackagesChoice==YES)
			{
				if (tPasteboardType==PKGHierarchyDataSourceChoicesPasteboardType)
				{
					*bOutstop=YES;
					tCancelDrag=YES;
					return;
				}
				
				tPasteboardType=PKGHierarchyDataSourceHiddenPackagesPasteboardType;
				
				return;
			}
			
			if (tPasteboardType==PKGHierarchyDataSourceHiddenPackagesPasteboardType)
			{
				*bOutstop=YES;
				tCancelDrag=YES;
				return;
			}
			
			tPasteboardType=PKGHierarchyDataSourceChoicesPasteboardType;
			[tChoicesUUID addObject:tChoiceItem.UUID];
			
			return;
		}
		
		*bOutstop=YES;
		tCancelDrag=YES;
	}];
	
	if (tCancelDrag==YES)
		return NO;
	
	if (tPasteboardType==PKGHierarchyDataSourceHiddenPackagesPasteboardType)
	{
		// Check that all the items share the same parent node
		
		if ([PKGTreeNode nodesAreSiblings:inItems]==NO)
			return NO;
	}
	
	if (tPasteboardType==PKGHierarchyDataSourceHiddenPackagesPasteboardType)
	{
		[inPasteboard declareTypes:@[PKGInstallationHierarchyHiddenPackagesInternalPboardType] owner:self];
		
		[inPasteboard setData:[NSData data] forType:PKGInstallationHierarchyHiddenPackagesInternalPboardType];
		
		return YES;
	}
	
	[inPasteboard declareTypes:@[PKGInstallationHierarchyChoicesInternalPboardType,PKGInstallationHierarchyChoicesUUIDsPboardType] owner:self];
	
	[inPasteboard setData:[NSData data] forType:PKGInstallationHierarchyChoicesInternalPboardType];
	
	[inPasteboard setPropertyList:tChoicesUUID forType:PKGInstallationHierarchyChoicesUUIDsPboardType];
	
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView*)inOutlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(PKGChoiceTreeNode *)inProposedTreeNode proposedChildIndex:(NSInteger)inChildIndex
{
	if (inOutlineView==nil)
		return NSDragOperationNone;
	
	if (inChildIndex==NSOutlineViewDropOnItemIndex)
		return NSDragOperationNone;
	
	// Prevent drag and drop when editing choices dependencies
	
	// A COMPLETER
	
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([[info draggingSource] window]!=inOutlineView.window)
		return NSDragOperationNone;
	
	// Package Components UUIDs
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPackageComponentUUIDsPboardType]]!=nil)
	{
		if (inChildIndex==NSOutlineViewDropOnItemIndex)
			return NSDragOperationNone;
		
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:PKGPackageComponentUUIDsPboardType];
		
		if (tArray==nil || [tArray isKindOfClass:NSArray.class]==NO || tArray.count==0)
		{
			// We were provided invalid data
			
			// A COMPLETER
			
			return NSDragOperationNone;
		}
		
		for(NSString * tPackageComponentUUI in tArray)
		{
			if ([_forest containsChoiceForPackageComponentUUID:tPackageComponentUUI]==YES)
				return NSDragOperationNone;
		}
		
		return NSDragOperationCopy;
	}
	
	// Internal Drag and Drop
	
	if ([info draggingSource]!=inOutlineView)
		return NSDragOperationNone;
	
	if ([tPasteBoard availableTypeFromArray:@[PKGInstallationHierarchyChoicesInternalPboardType]]!=nil)
	{
		if (_internalDragData.count==0)
			return NSDragOperationNone;
		
		if (inProposedTreeNode==nil)
		{
			// Drop at the root level
			
			if (_internalDragData.count>1)
				return NSDragOperationMove;
			
			PKGChoiceTreeNode * tDraggedChoiceTreeNode=_internalDragData[0];
			
			if ([tDraggedChoiceTreeNode parent]!=nil)
				return NSDragOperationMove;
			
			NSInteger tOriginalRow=[_forest.rootNodes indexOfObject:tDraggedChoiceTreeNode];
			
			if (tOriginalRow==NSNotFound)	// There's a problem as it should be a root node if its parent is nil
				return NSDragOperationNone;
			
			return (tOriginalRow!=inChildIndex && inChildIndex!=(tOriginalRow+1)) ? NSDragOperationMove : NSDragOperationNone;
		}
		
		PKGChoiceGroupItem * tChoiceGroupItem=[inProposedTreeNode representedObject];
		
		if ([tChoiceGroupItem isKindOfClass:PKGChoiceGroupItem.class]==NO)
			return NSDragOperationNone;
		
		PKGChoiceItemOptions * tOptions=tChoiceGroupItem.options;
		
		if (tOptions.hideChildren==YES)		// We can not drop in a merged packages choice
			return NSDragOperationNone;
		
		if ([_internalDragData containsObject:inProposedTreeNode]==YES ||
			[inProposedTreeNode isDescendantOfNodeInArray:_internalDragData]==YES)	// We can not drop inside an item which is part of the drag.
			return NSDragOperationNone;
		
		if (_internalDragData.count>1)
			return NSDragOperationMove;
		
		PKGChoiceTreeNode * tDraggedChoiceTreeNode=_internalDragData[0];
		PKGChoiceTreeNode * tDraggedChoiceParentNode=(PKGChoiceTreeNode *)[tDraggedChoiceTreeNode parent];
		
		if (tDraggedChoiceParentNode!=inProposedTreeNode)
			return NSDragOperationMove;
		
		NSInteger tOriginalRow=[inProposedTreeNode indexOfChildIdenticalTo:tDraggedChoiceTreeNode];
		
		if (tOriginalRow==NSNotFound)	// There's a problem as it should be a child node of the proposed drop node
			return NSDragOperationNone;
		
		return (tOriginalRow!=inChildIndex && inChildIndex!=(tOriginalRow+1)) ? NSDragOperationMove : NSDragOperationNone;
	}
	
	if ([tPasteBoard availableTypeFromArray:@[PKGInstallationHierarchyHiddenPackagesInternalPboardType]]!=nil)
	{
		if (_internalDragData.count==0)
			return NSDragOperationNone;
		
		PKGChoiceTreeNode * tFirstDraggedChoiceTreeNode=_internalDragData[0];
		PKGChoiceTreeNode * tDraggedChoiceParentNode=(PKGChoiceTreeNode *)[tFirstDraggedChoiceTreeNode parent];
		
		if (tDraggedChoiceParentNode!=inProposedTreeNode)	// We can only drag and drop within the same merged packages choice.
			return NSDragOperationNone;
		
		if (_internalDragData.count>1)
			return NSDragOperationMove;
		
		NSInteger tOriginalRow=[inProposedTreeNode indexOfChildIdenticalTo:tFirstDraggedChoiceTreeNode];
		
		if (tOriginalRow==NSNotFound)	// There's a problem as it should be a child node of the proposed drop node
			return NSDragOperationNone;
		
		return (tOriginalRow!=inChildIndex && inChildIndex!=(tOriginalRow+1)) ? NSDragOperationMove : NSDragOperationNone;
	}
	
	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView*)inOutlineView acceptDrop:(id <NSDraggingInfo>)info item:(PKGChoiceTreeNode *)inProposedTreeNode childIndex:(NSInteger)inChildIndex
{
	if (inOutlineView==nil)
		return NO;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	// Package Components UUIDs
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPackageComponentUUIDsPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:PKGPackageComponentUUIDsPboardType];
		
		if (tArray==nil || [tArray isKindOfClass:NSArray.class]==NO || tArray.count==0)
		{
			// We were provided invalid data
			
			// A COMPLETER
			
			return NO;
		}
		
		NSArray * tChoiceTreeNodes=[self.installationHierarchy insertBackPackageComponentUUIDs:tArray asChildrenOfNode:inProposedTreeNode index:inChildIndex];
		
		if (tChoiceTreeNodes.count==0)
			return NO;
		
		[self.delegate installationHierarchyDataDidChange:self];
		
		[inOutlineView deselectAll:nil];
		
		[inOutlineView reloadData];
		
		// Restore disclosed state
		
		// A COMPLETER
		
		// Select the inserted rows
		
		NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
		
		for(PKGChoiceTreeNode * tTreeNode in tChoiceTreeNodes)
		{
			NSInteger tIndex=[inOutlineView rowForItem:tTreeNode];
			
			if (tIndex==-1)
				NSLog(@"Row not found for %@",tTreeNode);
			else
				[tIndexSet addIndex:tIndex];
		}
		
		[inOutlineView selectRowIndexes:tIndexSet byExtendingSelection:NO];
		
		return YES;
	}
	
	// Internal Drag and Drop
	
	if ([tPasteBoard availableTypeFromArray:@[PKGInstallationHierarchyChoicesInternalPboardType,PKGInstallationHierarchyHiddenPackagesInternalPboardType]]!=nil)
	{
		if (_internalDragData.count==0)
			return NO;
		
		[_forest moveChoiceTreeNodes:_internalDragData asChildrenOf:inProposedTreeNode atIndex:inChildIndex];
		
		[self.delegate installationHierarchyDataDidChange:self];
		
		[inOutlineView deselectAll:nil];
		
		[inOutlineView reloadData];
		
		// Restore disclosed state
		
		// A COMPLETER
		
		// Set the selection
		
		NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
		
		for(PKGChoiceTreeNode * tTreeNode in _internalDragData)
		{
			NSInteger tIndex=[inOutlineView rowForItem:tTreeNode];
			
			if (tIndex==-1)
				NSLog(@"Row not found for %@",tTreeNode);
			else
				[tIndexSet addIndex:tIndex];
		}
		
		[inOutlineView selectRowIndexes:tIndexSet byExtendingSelection:NO];
		
		return YES;
	}
	
	return NO;
}

@end
