/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadDataSource.h"

#import "PKGPayloadTreeNode+UI.h"

#import "NSOutlineView+Selection.h"

#include <sys/stat.h>

NSString * const PKGPayloadItemsPboardType=@"fr.whitebox.packages.payload.items";
NSString * const PKGPayloadItemsInternalPboardType=@"fr.whitebox.packages.internal.payload.items";

@interface PKGPayloadDataSource ()
{
	NSArray * _internalDragData;
}

- (void)_switchFilePathOfItem:(PKGPayloadTreeNode *)inTreeNode toType:(PKGFilePathType)inType recursively:(BOOL)inRecursively;

@end

@implementation PKGPayloadDataSource

+ (NSArray *)supportedDraggedTypes
{
	return @[NSFilenamesPboardType,PKGPayloadItemsPboardType,PKGPayloadItemsInternalPboardType];
}

- (id)surrogateItemForItem:(id)inItem
{
	return nil;
}

- (NSArray *)siblingsOfItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode.parent==nil)
		return [self.rootNodes copy];
	
	return inTreeNode.parent.children;
}

- (void)_switchFilePathOfItem:(PKGPayloadTreeNode *)inTreeNode toType:(PKGFilePathType)inType recursively:(BOOL)inRecursively
{
	if (inTreeNode==nil)
		return;
	
	PKGFileItem * tFileItem=inTreeNode.representedObject;
	
	if (tFileItem==nil)
		return;
	
	if (tFileItem.type==PKGFileItemTypeFileSystemItem)
		[self.filePathConverter shiftTypeOfFilePath:tFileItem.filePath toType:inType];
	
	if (inRecursively==NO)
		return;
	
	for(PKGPayloadTreeNode * tChild in inTreeNode.children)
		[self _switchFilePathOfItem:tChild toType:inType recursively:inRecursively];
}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldDrawBadgeInTableColum:(NSTableColumn *)inTableColumn forItem:(id)inItem
{
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView addFileSystemItemsAtPaths:(NSArray *)inPaths referenceType:(PKGFilePathType)inReferenceType toParents:(NSArray *)inParents options:(PKGPayloadAddOptions)inOptions
{
	if (inOutlineView==nil)
		return NO;
	
	if (inPaths==nil)
		return NO;
	
	// The code works also with inParents==nil
	
	BOOL tSingleParent=(inParents.count==1);
	
	PKGTreeNode * tSharedParentNode=nil;
	
	if ((inOptions&PKGPayloadAddReplaceParents)==PKGPayloadAddReplaceParents)
	{
		// This is supported only for a template node (and not /)
		
		if (inParents.count!=1)
			return NO;
		
		PKGPayloadTreeNode * tPayloadTreeNode=inParents[0];
		
		if (tPayloadTreeNode.isTemplateNode==NO || tPayloadTreeNode.parent==nil)
			return NO;
		
		tSharedParentNode=tPayloadTreeNode.parent;
		[tPayloadTreeNode removeFromParent];
	}
	else
	{
		if (inParents.count==1)
			tSharedParentNode=inParents[0];
	}
	
	NSMutableArray * tNewSelectionArray=[NSMutableArray array];
	
	[inPaths enumerateObjectsUsingBlock:^(NSString * bAbsolutePath,NSUInteger bIndex,BOOL *bOutStop){
	
		NSString * tLastPathComponent=[bAbsolutePath lastPathComponent];
		
		PKGPayloadTreeNode * tParentNode;
		NSArray * tSiblings;
		
		if (inParents==nil)
		{
			tParentNode=nil;
			tSiblings=self.rootNodes;
		}
		else
		{
			tParentNode=(PKGPayloadTreeNode *)((tSingleParent==YES) ? tSharedParentNode : inParents[bIndex]);
			tSiblings=tParentNode.children;
		}
		
		if ([tSiblings indexOfObjectPassingTest:^BOOL(PKGPayloadTreeNode * bChild,NSUInteger bIndex,BOOL * bOutStop){
		
			return ([bChild.fileName caseInsensitiveCompare:tLastPathComponent]==NSOrderedSame);
			
		}]!=NSNotFound)
			return;
		
		struct stat tStat;
		
		if (lstat([bAbsolutePath fileSystemRepresentation], &tStat)!=0)
			return;
		
		uid_t tUid=tStat.st_uid;
		gid_t tGid=tStat.st_gid;
		
		if (tParentNode!=nil && (inOptions&PKGPayloadAddKeepOwnership)==PKGPayloadAddKeepOwnership)
		{
			PKGFileItem * tParentFileItem=(PKGFileItem *)tParentNode.representedObject;
			
			tUid=tParentFileItem.uid;
			tGid=tParentFileItem.gid;
		}
		
		mode_t tPosixPermissions=(tStat.st_mode & ALLPERMS);
		
		PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:bAbsolutePath type:inReferenceType];
		
		if (tFilePath==nil)
			return;
		
		PKGFileItem * tFileItem=[PKGFileItem fileSystemItemWithFilePath:tFilePath uid:tUid gid:tGid permissions:tPosixPermissions];
		
		PKGPayloadTreeNode * nFileSystemItemNode=[[PKGPayloadTreeNode alloc] initWithRepresentedObject:tFileItem children:nil];
		
		if (nFileSystemItemNode==nil)
			return;
		
		if (tParentNode==nil)
		{
			[nFileSystemItemNode insertAsSiblingOfChildren:(NSMutableArray *)tSiblings ofNode:tParentNode sortedUsingSelector:@selector(compareName:)];
		}
		else
		{
			[tParentNode insertChild:nFileSystemItemNode sortedUsingSelector:@selector(compareName:)];
		}
		
		[tNewSelectionArray addObject:nFileSystemItemNode];
	}];
	
	[inOutlineView deselectAll:nil];
	
	[self.delegate payloadDataDidChange:self];
	
	[inOutlineView reloadData];
	
	for(PKGPayloadTreeNode * tParentTreeNode in inParents)
	{
		if ([inOutlineView isItemExpanded:tParentTreeNode]==NO)
			[inOutlineView expandItem:tParentTreeNode];
	}
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	for(PKGPayloadTreeNode * tItem in tNewSelectionArray)
		[tMutableIndexSet addIndex:[inOutlineView rowForItem:tItem]];
	
	[inOutlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
	
	//[self updateFiles:IBoutlineView_];
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView addItem:(PKGPayloadTreeNode *)inTreeNode toParent:(PKGPayloadTreeNode *)inParent
{
	if (inOutlineView==nil)
		return NO;
	
	if (inTreeNode==nil)
		return NO;
	
	NSArray * tSiblings=self.rootNodes;
	
	if (inParent!=nil)
	{
		if (inParent.isLeaf==YES)
		{
			inParent=(PKGPayloadTreeNode *)inParent.parent;
			
			if (inParent!=nil)
				tSiblings=inParent.children;
		}
		else
		{
			tSiblings=inParent.children;
		}
	}
	
	if (inParent==nil)
	{
		[inTreeNode insertAsSiblingOfChildren:(NSMutableArray *)tSiblings ofNode:inParent sortedUsingSelector:@selector(compareName:)];
	}
	else
	{
		[inParent insertChild:inTreeNode sortedUsingSelector:@selector(compareName:)];
		
		if ([inOutlineView isItemExpanded:inParent]==NO)
			[inOutlineView expandItem:inParent];
	}
	
	[inOutlineView deselectAll:nil];
	
	[self.delegate payloadDataDidChange:self];
	
	[inOutlineView reloadData];
	
	NSInteger tRow=[inOutlineView rowForItem:inTreeNode];
	
	[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRow] byExtendingSelection:NO];
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView addNewFolderToParent:(PKGPayloadTreeNode *)inParent
{
	if (inOutlineView==nil)
		return NO;
	
	NSArray * tSiblings=self.rootNodes;
	
	if (inParent!=nil)
	{
		if (inParent.isLeaf==YES)
		{
			inParent=(PKGPayloadTreeNode *)inParent.parent;
			
			if (inParent!=nil)
				tSiblings=inParent.children;
		}
		else
		{
			tSiblings=inParent.children;
		}
	}
	
	PKGPayloadTreeNode * tNewFolderNode=[PKGPayloadTreeNode newFolderNodeWithParentNode:inParent siblings:tSiblings];
	
	if (tNewFolderNode==nil)
		return NO;
	
	if (inParent==nil)
	{
		[tNewFolderNode insertAsSiblingOfChildren:(NSMutableArray *)tSiblings ofNode:inParent sortedUsingSelector:@selector(compareName:)];
	}
	else
	{
		[inParent insertChild:tNewFolderNode sortedUsingSelector:@selector(compareName:)];
		
		if ([inOutlineView isItemExpanded:inParent]==NO)
			[inOutlineView expandItem:inParent];
	}
	
	[inOutlineView deselectAll:nil];
	
	[self.delegate payloadDataDidChange:self];
	
	[inOutlineView reloadData];
	
	NSInteger tRow=[inOutlineView rowForItem:tNewFolderNode];
	
	[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRow] byExtendingSelection:NO];
	
	return YES;
}

- (void)outlineView:(NSOutlineView *)inOutlineView removeItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems==nil)
		return;
	
	// Save the selection if needed
	
	NSArray * tSavedSelectedItems=nil;
	
	if (inItems.count==1)
	{
		if ([inOutlineView isRowSelected:[inOutlineView rowForItem:inItems[0]]]==NO)
			tSavedSelectedItems=[inOutlineView WB_selectedItems];
	}
	
	NSArray * tMinimumCover=[PKGTreeNode minimumNodeCoverFromNodesInArray:inItems];
	
	for(PKGTreeNode * tTreeNode in tMinimumCover)
	{
		PKGTreeNode * tParentNode=tTreeNode.parent;
		
		// Replace the node with another one if needed
		
		PKGTreeNode * tSurrogateNode=[self surrogateItemForItem:tTreeNode];
		
		if (tSurrogateNode!=nil)
		{
			if (tTreeNode.parent!=nil)
			{
				NSUInteger tIndex=[tParentNode indexOfChildIdenticalTo:tTreeNode];
				
				if (tIndex!=NSNotFound)
					[tParentNode insertChild:tSurrogateNode atIndex:tIndex];
			}
			else
			{
				NSUInteger tIndex=[self.rootNodes indexOfObjectIdenticalTo:tTreeNode];
				
				if (tIndex!=NSNotFound)
					[self.rootNodes insertObject:tSurrogateNode atIndex:tIndex];
			}
		}
		
		if (tParentNode!=nil)
			[tTreeNode removeFromParent];
		else
			[self.rootNodes removeObject:tTreeNode];
	}
	
	[self.delegate payloadDataDidChange:self];
	
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
	
	// A COMPLETER (mise a jour de la selection si clicked en dehors de la selection)
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return self.rootNodes.count;
	
	return inTreeNode.numberOfChildren;
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)inIndex ofItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return self.rootNodes[inIndex];
	
	return [inTreeNode descendantNodeAtIndex:inIndex];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(PKGTreeNode *)inTreeNode
{
	return ([inTreeNode isLeaf]==NO);
}

#pragma mark - NSPasteboardOwner

- (void)pasteboard:(NSPasteboard *)inPasteboard provideDataForType:(NSString *)inType
{
	if (inPasteboard==nil || inType==nil)
		return;
	
	if (_internalDragData==nil)
		return;
	
	if ([inType isEqualToString:PKGPayloadItemsPboardType]==YES)
	{
		NSArray * tRepresentedMinimumCover=[_internalDragData WB_arrayByMappingObjectsUsingBlock:^NSDictionary *(PKGPayloadTreeNode * bTreeNode,NSUInteger bIndex){
		
			PKGPayloadTreeNode * tTreeNodeCopy=(PKGPayloadTreeNode *)[bTreeNode deepCopy];
		
			// Convert all the file paths to absolute paths
			
			[self _switchFilePathOfItem:tTreeNodeCopy toType:PKGFilePathTypeAbsolute recursively:YES];
		
			return [tTreeNodeCopy representation];
		
		}];
		
		[inPasteboard setPropertyList:tRepresentedMinimumCover forType:PKGPayloadItemsPboardType];
	}
}

#pragma mark - Drag and Drop support

- (BOOL)outlineView:(NSOutlineView *)inOutlineView writeItems:(NSArray*)inItems toPasteboard:(NSPasteboard*)inPasteboard
{
	for(PKGPayloadTreeNode * tTreeNode in inItems)
	{
		if ([tTreeNode isTemplateNode]==YES)
			return NO;
	}
	
	_internalDragData=[PKGTreeNode minimumNodeCoverFromNodesInArray:inItems];
	
	[inPasteboard declareTypes:@[PKGPayloadItemsInternalPboardType,PKGPayloadItemsPboardType] owner:self];		// Make the external drag a promised case since it will be less usual IMHO
	
	[inPasteboard setData:[NSData data] forType:PKGPayloadItemsInternalPboardType];
	
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView*)inOutlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(PKGPayloadTreeNode *)inProposedTreeNode proposedChildIndex:(NSInteger)inChildIndex
{
	if (inProposedTreeNode==nil && self.editableRootNodes==NO)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];

	if (inChildIndex==NSOutlineViewDropOnItemIndex)
	{
		if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]==nil)
			return NSDragOperationNone;
		
		if (inProposedTreeNode.isTemplateNode==NO || inProposedTreeNode.parent==nil || [inProposedTreeNode containsNoTemplateDescendantNodes]==YES)
			return NSDragOperationNone;
		
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tArray==nil || [tArray isKindOfClass:[NSArray class]]==NO)
		{
			// We were provided invalid data
			
			// A COMPLETER
			
			return NSDragOperationNone;
		}
		
		if (tArray.count!=1)
			return NSDragOperationNone;
		
		NSString * tPath=tArray[0];
		
		if ([[tPath lastPathComponent] compare:inProposedTreeNode.fileName]==NSOrderedSame)	// We want an exact match
			return NSDragOperationCopy;
		
		return NSDragOperationNone;
	}
	
	NSUInteger (^indexOfChildWithName)(NSString *) = ^NSUInteger(NSString *inName){
	
		if (inProposedTreeNode==nil)
		{
			return [self.rootNodes indexOfObjectPassingTest:^BOOL(PKGPayloadTreeNode * bTreeNode,NSUInteger bIndex,BOOL *bOutStop) {
				
				return ([inName caseInsensitiveCompare:bTreeNode.fileName]==NSOrderedSame);
				
			}];
		}
		
		return [inProposedTreeNode indexOfChildMatching:^BOOL(PKGPayloadTreeNode * bTreeNode) {
				
				return ([inName caseInsensitiveCompare:bTreeNode.fileName]==NSOrderedSame);
				
		}];
	};
	
	void (^updateDropLocation)(NSString *) = ^void(NSString * bFirstItemName) {
		
		NSUInteger tInsertionIndex=NSNotFound;
		
		if (inProposedTreeNode==nil)
		{
			tInsertionIndex=[self.rootNodes indexOfObjectPassingTest:^BOOL(PKGPayloadTreeNode * bTreeNode,NSUInteger bIndex,BOOL *bOutStop) {
				
				return ([bFirstItemName caseInsensitiveCompare:bTreeNode.fileName]==NSOrderedSame);
				
			}];
		}
		else
		{
			tInsertionIndex=[inProposedTreeNode indexOfChildMatching:^BOOL(PKGPayloadTreeNode * bTreeNode) {
				
				return ([bFirstItemName caseInsensitiveCompare:bTreeNode.fileName]!=NSOrderedDescending);
			}];
		}
		
		[inOutlineView setDropItem:inProposedTreeNode dropChildIndex:(tInsertionIndex!=NSNotFound) ? tInsertionIndex : [inProposedTreeNode numberOfChildren]];
	};
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tArray==nil || [tArray isKindOfClass:[NSArray class]]==NO || tArray.count==0)
		{
			// We were provided invalid data
			
			// A COMPLETER
			
			return NSDragOperationNone;
		}
		
		for(NSString * tDroppedFilePath in tArray)
		{
			NSString * tFileName=[tDroppedFilePath lastPathComponent];
			
			if (indexOfChildWithName(tFileName)!=NSNotFound)
				return NSDragOperationNone;
		}
		
		updateDropLocation([tArray[0] lastPathComponent]);
		
		return NSDragOperationCopy;//[info draggingSourceOperationMask];
	}
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPayloadItemsInternalPboardType]]!=nil && [info draggingSource]==inOutlineView)
	{
		if (inProposedTreeNode!=nil)
		{
			if ([_internalDragData containsObject:inProposedTreeNode]==YES)
				return NSDragOperationNone;
		
			if ([inProposedTreeNode isDescendantOfNodeInArray:_internalDragData]==YES)
				return NSDragOperationNone;
		}
		
		// We need to check the names and eventually switch the drop location
		
		for(PKGPayloadTreeNode * tTreeNode in _internalDragData)
		{
			NSString * tFileName=tTreeNode.fileName;
			
			if (indexOfChildWithName(tFileName)!=NSNotFound)
				return NSDragOperationNone;
		}
		
		updateDropLocation(((PKGPayloadTreeNode *)_internalDragData[0]).fileName);
		
		return NSDragOperationGeneric;
	}
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPayloadItemsPboardType]]!=nil)
	{
		// A COMPLETER
		
		return NSDragOperationNone;
	}
	
	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView*)inOutlineView acceptDrop:(id <NSDraggingInfo>)info item:(PKGPayloadTreeNode *)targetItem childIndex:(NSInteger)childIndex
{
	// A COMPLETER
	
	return YES;
}

@end