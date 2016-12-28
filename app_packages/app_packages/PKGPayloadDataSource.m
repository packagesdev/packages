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

#import "PKGApplicationPreferences.h"

#import "PKGOwnershipAndReferenceStylePanel.h"

#import "PKGFileItem+UI.h"
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

- (BOOL)_expandItem:(PKGPayloadTreeNode *)inPayloadTreeNode atPath:(NSString *)inAbsolutePath options:(PKGPayloadExpandOptions)inOptions;

@end

@implementation PKGPayloadDataSource

+ (NSArray *)supportedDraggedTypes
{
	return @[NSFilenamesPboardType,PKGPayloadItemsPboardType,PKGPayloadItemsInternalPboardType];
}

- (PKGFileAttributesOptions)managedAttributes
{
	return 0;
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

- (BOOL)_expandItem:(PKGPayloadTreeNode *)inPayloadTreeNode atPath:(NSString *)inAbsolutePath options:(PKGPayloadExpandOptions)inOptions
{
	if (inPayloadTreeNode==nil || inAbsolutePath==nil)
		return NO;
	
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	NSArray * tContents=[tFileManager contentsOfDirectoryAtPath:inAbsolutePath error:NULL];
	
	if (tContents==nil)
		return NO;
	
	PKGFileItem * tFileItem=(PKGFileItem *)inPayloadTreeNode.representedObject;
	
	PKGFilePathType tPathType=tFileItem.filePath.type;
	uid_t tItemUid=tFileItem.uid;
	gid_t tItemGid=tFileItem.gid;
	
	__block BOOL tSuccessful=YES;
	
	[tContents enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * bPathComponent,NSUInteger bIndex,BOOL *bOutStop){	// Reverse to speed up the insertion
		
		NSString * tAbsolutePath=[inAbsolutePath stringByAppendingPathComponent:bPathComponent];
		
		PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:tAbsolutePath type:tPathType];
		
		if (tFilePath==nil)
			return;
		
		uid_t tUid=0;
		gid_t tGid=0;
		mode_t tPosixPermissions;
		
		NSError * tError=nil;
		NSDictionary * tFileAttributes=[tFileManager attributesOfItemAtPath:tAbsolutePath error:&tError];
		
		if (tFileAttributes==nil)
		{
			if (tError!=nil)
			{
				// A COMPLETER
			}
			
			tSuccessful=NO;
			*bOutStop=YES;
		}
		
		if ((inOptions & PKGPayloadExpandKeepOwnership)!=0)
		{
			tUid=(uid_t)((NSNumber *)tFileAttributes[NSFileOwnerAccountID]).unsignedIntegerValue;
			tGid=(gid_t)((NSNumber *)tFileAttributes[NSFileGroupOwnerAccountID]).unsignedIntegerValue;
		}
		else
		{
			tUid=tItemUid;
			tGid=tItemGid;
		}
		
		tPosixPermissions=(mode_t)((NSNumber *)tFileAttributes[NSFilePosixPermissions]).unsignedIntegerValue;
		
		PKGFileItem * nFileItem=[PKGFileItem fileSystemItemWithFilePath:tFilePath uid:tUid gid:tGid permissions:tPosixPermissions];
		
		PKGPayloadTreeNode * nFileSystemItemNode=[[PKGPayloadTreeNode alloc] initWithRepresentedObject:nFileItem children:nil];
		
		if (nFileSystemItemNode==nil)
			return;
		
		[inPayloadTreeNode insertChild:nFileSystemItemNode sortedUsingSelector:@selector(compareName:)];
		
		if ((inOptions & PKGPayloadExpandRecursively)!=0 && [tFileAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]==YES)
		{
			if ([self _expandItem:nFileSystemItemNode atPath:tAbsolutePath options:inOptions]==NO)
			{
				tSuccessful=NO;
				*bOutStop=YES;
			}
		}
	}];
	
	tFileItem.contentsDisclosed=YES;
	
	return tSuccessful;
}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldDrawBadgeInTableColum:(NSTableColumn *)inTableColumn forItem:(id)inItem
{
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView addFileNames:(NSArray *)inPaths referenceType:(PKGFilePathType)inReferenceType toParents:(NSArray *)inParents options:(PKGPayloadAddOptions)inOptions
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
		
		uid_t tUid=0;
		gid_t tGid=0;
		
		if ((inOptions & PKGPayloadAddKeepOwnership)==PKGPayloadAddKeepOwnership)
		{
			tUid=tStat.st_uid;
			tGid=tStat.st_gid;
		}
		else
		{
			if (tParentNode!=nil)
			{
				PKGFileItem * tParentFileItem=(PKGFileItem *)tParentNode.representedObject;
				
				tUid=tParentFileItem.uid;
				tGid=tParentFileItem.gid;
			}
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

- (void)outlineView:(NSOutlineView *)inOutlineView expandItem:(PKGPayloadTreeNode *)inPayloadTreeNode options:(PKGPayloadExpandOptions)inOptions
{
	if (inOutlineView==nil || inPayloadTreeNode==nil)
		return;
	
	if (inPayloadTreeNode.isFileSystemItemNode==NO)
		return;
	
	if (inPayloadTreeNode.isReferencedItemMissing==YES)
		return;
	
	if ([self _expandItem:inPayloadTreeNode atPath:[inPayloadTreeNode referencedPathUsingConverter:self.filePathConverter] options:inOptions]==NO)
	{
		[inPayloadTreeNode removeChildren];
		
		NSBeep();
		
		return;
	}
	
	[inOutlineView deselectAll:nil];
	
	[self.delegate payloadDataDidChange:self];
	
	[inOutlineView reloadData];
	
	NSInteger tRow=[inOutlineView rowForItem:inPayloadTreeNode];
	
	[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRow] byExtendingSelection:NO];
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
	
	_internalDragData=[PKGTreeNode minimumNodeCoverFromNodesInArray:inItems];	// A COMPLETER (Find how to empty it when the drag and drop is done)
	
	[inPasteboard declareTypes:@[PKGPayloadItemsInternalPboardType,PKGPayloadItemsPboardType] owner:self];		// Make the external drag a promised case since it will be less usual IMHO
	
	[inPasteboard setData:[NSData data] forType:PKGPayloadItemsInternalPboardType];
	
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView*)inOutlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(PKGPayloadTreeNode *)inProposedTreeNode proposedChildIndex:(NSInteger)inChildIndex
{
	if (inProposedTreeNode==nil && self.editableRootNodes==NO)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];

	// Filenames
	
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
	
	BOOL (^validateFileNames)(NSArray *,NSArray *)=^BOOL(NSArray * bFilesNamesArray,NSArray * bExternalFilesNamesArray){
	
		// Check that there are no duplicates in the array
		
		NSCountedSet * tCountedSet=[[NSCountedSet alloc] initWithArray:bFilesNamesArray];
		
		for(id tObject in tCountedSet)
		{
			if ([tCountedSet countForObject:tObject]>1)
				return NO;
		}
		
		// Check that none of the names is already the one of a child of the proposed node
		
		if (inProposedTreeNode==nil)
		{
			for(NSString * tFileName in bExternalFilesNamesArray)
			{
				if ([self.rootNodes indexOfObjectPassingTest:^BOOL(PKGPayloadTreeNode * bTreeNode,NSUInteger bIndex,BOOL *bOutStop) {
					
					return ([tFileName caseInsensitiveCompare:bTreeNode.fileName]==NSOrderedSame);
					
				}]!=NSNotFound)
					return NO;
			}
		}
		else
		{
			for(NSString * tFileName in bExternalFilesNamesArray)
			{
				if ([inProposedTreeNode indexOfChildMatching:^BOOL(PKGPayloadTreeNode * bTreeNode) {
					
					return ([tFileName caseInsensitiveCompare:bTreeNode.fileName]==NSOrderedSame);
					
				}]!=NSNotFound)
					return NO;
			}
		}
		
		// Update the drop location based on the first name
		
		NSString * tFirstName=bFilesNamesArray[0];
		
		NSUInteger tInsertionIndex=NSNotFound;
		
		if (inProposedTreeNode==nil)
		{
			tInsertionIndex=[self.rootNodes indexOfObjectPassingTest:^BOOL(PKGPayloadTreeNode * bTreeNode,NSUInteger bIndex,BOOL *bOutStop) {
				
				return ([tFirstName caseInsensitiveCompare:bTreeNode.fileName]==NSOrderedSame);
				
			}];
		}
		else
		{
			tInsertionIndex=[inProposedTreeNode indexOfChildMatching:^BOOL(PKGPayloadTreeNode * bTreeNode) {
				
				return ([tFirstName caseInsensitiveCompare:bTreeNode.fileName]!=NSOrderedDescending);
			}];
		}
		
		[inOutlineView setDropItem:inProposedTreeNode dropChildIndex:(tInsertionIndex!=NSNotFound) ? tInsertionIndex : [inProposedTreeNode numberOfChildren]];
		
		return NSDragOperationCopy;
	
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
		
		NSArray * tFileNamesArray=[tArray WB_arrayByMappingObjectsUsingBlock:^NSString *(NSString * bFilePath,NSUInteger bIndex){
		
			return [bFilePath lastPathComponent];
		}];
		
		return (validateFileNames(tFileNamesArray,tFileNamesArray)==YES) ? NSDragOperationCopy : NSDragOperationNone;
	}
	
	// Internal Drag
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPayloadItemsInternalPboardType]]!=nil && [info draggingSource]==inOutlineView)
	{
		if (inProposedTreeNode!=nil)
		{
			if ([_internalDragData containsObject:inProposedTreeNode]==YES)
				return NSDragOperationNone;
		
			if ([inProposedTreeNode isDescendantOfNodeInArray:_internalDragData]==YES)
				return NSDragOperationNone;
		}
		
		
		NSMutableArray * tFileNamesArray=[NSMutableArray array];
		NSMutableArray * tExternalFileNamesArray=[NSMutableArray array];
		
		for(PKGPayloadTreeNode * tTreeNode in _internalDragData)
		{
			NSString * tFileName=tTreeNode.fileName;
			
			[tFileNamesArray addObject:tFileName];
			
			if (tTreeNode.parent!=inProposedTreeNode)
				[tExternalFileNamesArray addObject:tFileName];
		}
		
		return (validateFileNames(tFileNamesArray,tExternalFileNamesArray)==YES) ? NSDragOperationGeneric : NSDragOperationNone;
	}
	
	// Inter-documents Drag and Drop
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPayloadItemsPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:PKGPayloadItemsPboardType];
		
		if (tArray==nil || [tArray isKindOfClass:[NSArray class]]==NO || tArray.count==0)
		{
			// We were provided invalid data
			
			// A COMPLETER
			
			return NSDragOperationNone;
		}
		
		NSArray * tFileNamesArray=[tArray WB_arrayByMappingObjectsUsingBlock:^NSString *(NSDictionary * bRepresentation,NSUInteger bIndex){
			
			return [PKGFilePath lastPathComponentFromRepresentation:bRepresentation];
		}];
		
		return (validateFileNames(tFileNamesArray,tFileNamesArray)==YES) ? NSDragOperationCopy : NSDragOperationNone;
	}
	
	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView*)inOutlineView acceptDrop:(id <NSDraggingInfo>)info item:(PKGPayloadTreeNode *)inProposedTreeNode childIndex:(NSInteger)inChildIndex
{
	if (inOutlineView==nil)
		return NO;
	
	if (inProposedTreeNode==nil && self.editableRootNodes==NO)
		return NSDragOperationNone;
	
	// Internal drag and drop
	
	if ([info draggingSource]==inOutlineView)
	{
		for(PKGTreeNode * tPayloadTreeNode in _internalDragData)
		{
			[tPayloadTreeNode removeFromParent];
			
			[inProposedTreeNode insertChild:tPayloadTreeNode sortedUsingSelector:@selector(compareName:)];
		}
		
		[inOutlineView deselectAll:nil];
		
		[self.delegate payloadDataDidChange:self];
		
		[inOutlineView reloadData];
		
		if ([inOutlineView isItemExpanded:inProposedTreeNode]==NO)
			[inOutlineView expandItem:inProposedTreeNode];
		
		NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
		
		for(id tItem in _internalDragData)
			[tMutableIndexSet addIndex:[inOutlineView rowForItem:tItem]];
		
		[inOutlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
		
		return YES;
	}
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	// Filenames
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==NO)
		{
			PKGPayloadAddOptions tOptions=0;
			
			tOptions|=(inChildIndex==NSOutlineViewDropOnItemIndex) ? PKGPayloadAddReplaceParents : 0;
			tOptions|=([PKGApplicationPreferences sharedPreferences].keepOwnership==YES) ? PKGPayloadAddKeepOwnership : 0;

			return [self outlineView:inOutlineView
						addFileNames:tArray
					   referenceType:[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle
						   toParents:@[inProposedTreeNode]
							 options:tOptions];
		}
		
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		
		tPanel.canChooseOwnerAndGroupOptions=((self.managedAttributes&PKGFileAttributesOwnerAndGroup)!=0);
		tPanel.keepOwnerAndGroup=[PKGApplicationPreferences sharedPreferences].keepOwnership;
		tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		[tPanel beginSheetModalForWindow:inOutlineView.window completionHandler:^(NSInteger bReturnCode){
			
			if (bReturnCode==PKGOwnershipAndReferenceStylePanelCancelButton)
				return;
			
			PKGPayloadAddOptions tOptions=0;
			
			tOptions|=(inChildIndex==NSOutlineViewDropOnItemIndex) ? PKGPayloadAddReplaceParents : 0;
			if (tPanel.canChooseOwnerAndGroupOptions==YES)
				tOptions|=(tPanel.keepOwnerAndGroup==YES) ? PKGPayloadAddKeepOwnership : 0;
			
			[self outlineView:inOutlineView
				 addFileNames:tArray
				referenceType:tPanel.referenceStyle
					toParents:@[inProposedTreeNode]
					  options:tOptions];
		}];
		
		return YES;		// It may at the end not be accepted by the completion handler from the sheet
	}
	
	// Inter-documents Drag and Drop
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPayloadItemsPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:PKGPayloadItemsPboardType];
		
		BOOL (^insertNewItems)(PKGFilePathType)=^BOOL(PKGFilePathType inPathType){
		
			NSMutableArray * tNewSelectionArray=[NSMutableArray array];
			
			for(NSDictionary * tRepresentation in tArray)
			{
				PKGPayloadTreeNode * tPayloadTreeNode=[[PKGPayloadTreeNode alloc] initWithRepresentation:tRepresentation error:NULL];
				
				if (tPayloadTreeNode==nil)
					return NO;
				
				[self _switchFilePathOfItem:tPayloadTreeNode toType:inPathType recursively:YES];
				
				[inProposedTreeNode insertChild:tPayloadTreeNode sortedUsingSelector:@selector(compareName:)];
				
				[tNewSelectionArray addObject:tPayloadTreeNode];
			}
			
			[inOutlineView deselectAll:nil];
			
			[self.delegate payloadDataDidChange:self];
			
			[inOutlineView reloadData];
			
			if ([inOutlineView isItemExpanded:inProposedTreeNode]==NO)
				[inOutlineView expandItem:inProposedTreeNode];
			
			NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
			
			for(id tItem in tNewSelectionArray)
				[tMutableIndexSet addIndex:[inOutlineView rowForItem:tItem]];
			
			[inOutlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
			
			return YES;
		};
			
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==NO)
		{
			return insertNewItems([PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle);
		}
		
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		
		tPanel.canChooseOwnerAndGroupOptions=NO;
		tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		[tPanel beginSheetModalForWindow:inOutlineView.window completionHandler:^(NSInteger bReturnCode){
			
			if (bReturnCode==PKGOwnershipAndReferenceStylePanelCancelButton)
				return;
			
			insertNewItems(tPanel.referenceStyle);
		}];
		
		return YES;		// It may at the end not be accepted by the completion handler from the sheet
	}
	
	return NO;
}

@end