/*
 Copyright (c) 2016-2018, Stephane Sudre
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

#import "PKGFilePathConverter+Edition.h"

#import "NSOutlineView+Selection.h"

#include <sys/stat.h>

#import "NSObject+Conformance.h"

#import "NSFileManager+SortedContents.h"

NSString * const PKGPayloadItemsPboardType=@"fr.whitebox.packages.payload.items";
NSString * const PKGPayloadItemsInternalPboardType=@"fr.whitebox.packages.internal.payload.items";

@interface PKGPayloadDataSource ()
{
	NSArray * _internalDragData;
    
    NSComparator _comparator;
}

- (BOOL)_expandItem:(PKGPayloadTreeNode *)inPayloadTreeNode atPath:(NSString *)inAbsolutePath options:(PKGPayloadExpandOptions)inOptions;

@end

@implementation PKGPayloadDataSource

+ (NSArray *)supportedDraggedTypes
{
	return @[NSFilenamesPboardType,PKGPayloadItemsPboardType,PKGPayloadItemsInternalPboardType];
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        char tCFakeSeparator[2]={0x01,0x00};
        _fakeFileSeparator=[[NSString alloc] initWithCString:tCFakeSeparator encoding:NSASCIIStringEncoding];
        
        _comparator=^NSComparisonResult(PKGPayloadTreeNode * obj1, PKGPayloadTreeNode * obj2) {
            
            PKGFileItem * tFileItem=(PKGFileItem *)obj1.representedObject;
            NSString * tName=nil;
            
            if (tFileItem.type==PKGFileItemTypeNewElasticFolder)
                tName=[tFileItem.fileName componentsSeparatedByString:@"/"].firstObject;
            else
                tName=tFileItem.fileName;
            
            if (tFileItem.type==PKGFileItemTypeNewElasticFolder ||
                tFileItem.type==PKGFileItemTypeNewFolder)
            {
                if (self.keysReplacer!=nil)
                    tName=[self.keysReplacer stringByReplacingKeysInString:tName];
            }
            
            PKGFileItem * tOtherFileItem=(PKGFileItem *)obj2.representedObject;
            NSString * tOtherName=nil;
            
            if (tOtherFileItem.type==PKGFileItemTypeNewElasticFolder)
                tOtherName=[tOtherFileItem.fileName componentsSeparatedByString:@"/"].firstObject;
            else
                tOtherName=tOtherFileItem.fileName;
            
            if (tOtherFileItem.type==PKGFileItemTypeNewElasticFolder ||
                tOtherFileItem.type==PKGFileItemTypeNewFolder)
            {
                if (self.keysReplacer!=nil)
                    tName=[self.keysReplacer stringByReplacingKeysInString:tName];
            }
            
            return [tName compare:tOtherName options:NSCaseInsensitiveSearch|NSNumericSearch|NSForcedOrderingSearch];
        };
    }
    
    return self;
}

#pragma mark -

- (void)setDelegate:(id<PKGPayloadDataSourceDelegate>)inDelegate
{
	if (_delegate==inDelegate)
		return;
	
	if (inDelegate==nil)
	{
		_delegate=nil;
		return;
	}
	
	if ([((NSObject *)inDelegate) WB_doesReallyConformToProtocol:@protocol(PKGPayloadDataSourceDelegate)]==NO)
		return;
	
	_delegate=inDelegate;
}

#pragma mark -

- (PKGFileAttributesOptions)managedAttributes
{
	return 0;
}

- (id)itemAtPath:(NSString *)inPath separator:(NSString *)inSeparator
{
	if (inPath==nil || inSeparator.length==0)
		return nil;
	
	NSMutableArray * tComponents=nil;
	NSUInteger tCount=0;
	
	if ([inPath isEqualToString:@"/"]==YES)
	{
		tComponents=[@[@"/"] mutableCopy];
		tCount=1;
	}
	else
	{
		tComponents=[[inPath componentsSeparatedByString:inSeparator] mutableCopy];
		
		tCount=tComponents.count;
		
		if (tCount==0)
			return nil;
		
		if ([inPath hasPrefix:@"/"]==YES)
		{
			[tComponents replaceObjectAtIndex:0 withObject:@"/"];
		}
	}
	
	NSString * tComponent=tComponents.firstObject;
	
	NSUInteger tIndex=[self.rootNodes indexOfObjectPassingTest:^BOOL(PKGPayloadTreeNode * bTreeNode, NSUInteger bIndex, BOOL *bOutStop) {
		
		return [bTreeNode.fileName isEqualToString:tComponent];
	}];
	
	if (tIndex==NSNotFound)
		return nil;
	
	PKGPayloadTreeNode * tTreeNode=self.rootNodes[tIndex];
	
	if (tCount==1)
		return tTreeNode;
	
	[tComponents removeObjectAtIndex:0];
	
	for(NSString * tComponent in tComponents)
	{
		tTreeNode=(PKGPayloadTreeNode *)[tTreeNode childNodeMatching:^BOOL(PKGPayloadTreeNode * bTreeNode) {
					
			return [bTreeNode.fileName isEqualToString:tComponent];
		}];
		
		if (tTreeNode==nil)
			return nil;
	}
	
	return tTreeNode;
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

#pragma mark -

- (void)outlineView:(NSOutlineView *)inOutlineView reloadDataForItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems==nil)
		return;
	
	NSMutableIndexSet * tRowIndexes=[NSMutableIndexSet indexSet];
	
	for(PKGPayloadTreeNode * tTreeNode in inItems)
	{
		NSInteger tRow=[inOutlineView rowForItem:tTreeNode];
		
		if (tRow!=-1)
			[tRowIndexes addIndex:tRow];
	}
	
	[inOutlineView reloadDataForRowIndexes:tRowIndexes columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,inOutlineView.numberOfColumns)]];
}

- (void)outlineView:(NSOutlineView *)inOutlineView discloseItemIfNeeded:(PKGPayloadTreeNode *)inTreeNode
{
	if (inOutlineView==nil || inTreeNode==nil)
		return;
	
	__block __weak void (^_weakDiscloseItemIfNeeded)(PKGPayloadTreeNode *);
	__block void (^_discloseItemIfNeeded)(PKGPayloadTreeNode *);
	
	_discloseItemIfNeeded = ^(PKGPayloadTreeNode * bTreeNode)
	{
		PKGPayloadTreeNode * tParentNode=(PKGPayloadTreeNode *)bTreeNode.parent;
		
		if (tParentNode!=nil)
			_weakDiscloseItemIfNeeded(tParentNode);
		
		if ([inOutlineView isItemExpanded:bTreeNode]==NO)
			[inOutlineView expandItem:bTreeNode];
	};
			
	_weakDiscloseItemIfNeeded = _discloseItemIfNeeded;
	
	_discloseItemIfNeeded(inTreeNode);
}

- (BOOL)_expandItem:(PKGPayloadTreeNode *)inPayloadTreeNode atPath:(NSString *)inAbsolutePath options:(PKGPayloadExpandOptions)inOptions
{
	if (inPayloadTreeNode==nil || inAbsolutePath==nil)
		return NO;
	
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	NSArray * tContents=[tFileManager WB_sortedContentsOfDirectoryAtPath:inAbsolutePath error:NULL];
	
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
		
		PKGFileItem * nFileItem=[[PKGPayloadTreeNode representedObjectClassForFileSystemItemAtPath:tAbsolutePath] fileSystemItemWithFilePath:tFilePath uid:tUid gid:tGid permissions:tPosixPermissions];
		
		PKGPayloadTreeNode * nFileSystemItemNode=[[PKGPayloadTreeNode alloc] initWithRepresentedObject:nFileItem children:nil];
		
		if (nFileSystemItemNode==nil)
			return;
		
		[inPayloadTreeNode insertChild:nFileSystemItemNode sortedUsingComparator:_comparator];
		
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

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldDrawTargetCrossForItem:(id)inItem
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
	
		NSString * tLastPathComponent=bAbsolutePath.lastPathComponent;
		
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
		
		PKGFileItem * tFileItem=[[PKGPayloadTreeNode representedObjectClassForFileSystemItemAtPath:bAbsolutePath] fileSystemItemWithFilePath:tFilePath uid:tUid gid:tGid permissions:tPosixPermissions];
		
		PKGPayloadTreeNode * nFileSystemItemNode=[[PKGPayloadTreeNode alloc] initWithRepresentedObject:tFileItem children:nil];
		
		if (nFileSystemItemNode==nil)
			return;
		
		if (tParentNode==nil)
			[nFileSystemItemNode insertAsSiblingOfChildren:(NSMutableArray *)tSiblings ofNode:tParentNode sortedUsingComparator:_comparator];
		else
			[tParentNode insertChild:nFileSystemItemNode sortedUsingComparator:_comparator];
		
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
        [inTreeNode insertAsSiblingOfChildren:(NSMutableArray *)tSiblings ofNode:inParent sortedUsingComparator:_comparator];
	}
	else
	{
		[inParent insertChild:inTreeNode sortedUsingComparator:_comparator];
		
		if ([inOutlineView isItemExpanded:inParent]==NO)
			[inOutlineView expandItem:inParent];
	}
	
	[inOutlineView deselectAll:nil];
	
	[self.delegate payloadDataDidChange:self];
	
	[inOutlineView reloadData];
	
	NSInteger tRow=[inOutlineView rowForItem:inTreeNode];
	
	[inOutlineView scrollRowToVisible:tRow];
	
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
		[tNewFolderNode insertAsSiblingOfChildren:(NSMutableArray *)tSiblings ofNode:inParent sortedUsingComparator:_comparator];
	}
	else
	{
		[inParent insertChild:tNewFolderNode sortedUsingComparator:_comparator];
		
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

- (BOOL)outlineView:(NSOutlineView *)inOutlineView addNewElasticFolderToParent:(PKGPayloadTreeNode *)inParent
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
    
    PKGPayloadTreeNode * tNewFolderNode=[PKGPayloadTreeNode newElasticFolderNodeWithParentNode:inParent siblings:tSiblings];
    
    if (tNewFolderNode==nil)
        return NO;
    
    if (inParent==nil)
    {
        [tNewFolderNode insertAsSiblingOfChildren:(NSMutableArray *)tSiblings ofNode:inParent sortedUsingComparator:_comparator];
    }
    else
    {
        [inParent insertChild:tNewFolderNode sortedUsingComparator:_comparator];
        
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

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldRenameNewFolder:(PKGPayloadTreeNode *)inTreeNode as:(NSString *)inNewName
{
	if (inOutlineView==nil || inTreeNode==nil || inNewName==nil)
		return NO;
	
	if ([inTreeNode.fileName compare:inNewName]==NSOrderedSame)
		return NO;
	
	if ([inTreeNode.fileName caseInsensitiveCompare:inNewName]!=NSOrderedSame)
	{
		NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[inOutlineView rowForItem:inTreeNode]];
		NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[inOutlineView columnWithIdentifier:@"file.name"]];
		
		void (^renameAlertBailOut)(NSString *,NSString *) = ^(NSString *bMessageText,NSString *bInformativeText)
		{
			NSAlert * tAlert=[NSAlert new];
			tAlert.alertStyle=WBAlertStyleCritical;
			tAlert.messageText=bMessageText;
			tAlert.informativeText=bInformativeText;
			
			[tAlert runModal];
		};
		
        PKGFileItem * tItem=[inTreeNode representedObject];
        
        NSArray * tComponents=nil;
        
        switch(tItem.type)
        {
            case PKGFileItemTypeNewFolder:
            case PKGFileItemTypeFileSystemItem:
                
                tComponents=@[inNewName];
                break;
                
            case PKGFileItemTypeNewElasticFolder:
                
                tComponents=[inNewName componentsSeparatedByString:@"/"];
                break;
            
            default:
                
                // Should not happen
                
                return NO;
        }
        
        for(NSString * tComponent in tComponents)
        {
            NSUInteger tLength=tComponent.length;
            
            if (tLength==0)
            {
                [inOutlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
                return NO;
            }
        
            if (tLength>=256)
            {
                renameAlertBailOut([NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" can't be used.",@""),tComponent],NSLocalizedString(@"Try using a name with fewer characters.",@""));
                
                return NO;
            }
		
            if ([tComponent isEqualToString:@".."]==YES ||
                [tComponent isEqualToString:@"."]==YES ||
                [tComponent rangeOfString:@"/"].location!=NSNotFound)
            {
                renameAlertBailOut([NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" can't be used.",@""),inNewName],NSLocalizedString(@"Try using a name with no punctuation marks.",@""));
                
                return NO;
            }
        }
        
		if ([[self siblingsOfItem:inTreeNode] indexesOfObjectsPassingTest:^BOOL(PKGPayloadTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
			
			return ([bTreeNode.fileName caseInsensitiveCompare:inNewName]==NSOrderedSame);
			
		}].count>0)
		{
			renameAlertBailOut([NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" is already taken.",@""),inNewName],NSLocalizedString(@"Please choose a different name.",@""));
			
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView renameItem:(PKGPayloadTreeNode *)inTreeNode as:(NSString *)inNewName
{
	NSMutableDictionary * tDisclosedDictionary=[self.delegate disclosedDictionary];
	NSArray * tAllKeys=tDisclosedDictionary.allKeys;
	
	NSString * tOldFilePath=[inTreeNode filePathWithSeparator:self.fakeFileSeparator];
	NSUInteger tLength=tOldFilePath.length;
	
    NSMutableArray * tMutableComponents=[[tOldFilePath componentsSeparatedByString:self.fakeFileSeparator] mutableCopy];
    [tMutableComponents removeLastObject];
    [tMutableComponents addObject:inNewName];
    NSString * tNewFilePath=[tMutableComponents componentsJoinedByString:self.fakeFileSeparator];
	
    NSNumber * tSharedNumber=@(YES);
	
	// Update the disclosed state dictionary
	
	for(NSString * tKey in tAllKeys)
	{
		if ([tKey hasPrefix:tOldFilePath]==YES)
		{
			[tDisclosedDictionary removeObjectForKey:tKey];
			
			NSString * tNewKey=[tNewFilePath stringByAppendingString:[tKey substringFromIndex:tLength]];
			
			tDisclosedDictionary[tNewKey]=tSharedNumber;
		}
	}
	
	[inTreeNode rename:inNewName];
	
	[self outlineView:inOutlineView transformItemIfNeeded:inTreeNode];	// We may have to tranform the item (if the extension is removed/added)
	
	// Sort and update selection
	
	PKGTreeNode * tParentNode=inTreeNode.parent;
	
	if (tParentNode!=nil)
		[inTreeNode removeFromParent];
	else
		[self.rootNodes removeObject:inTreeNode];
	
	return [self outlineView:inOutlineView addItem:inTreeNode toParent:tParentNode];
}

- (void)outlineView:(NSOutlineView *)inOutlineView removeItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems==nil)
		return;
	
	// Save the selection (if it's a control-click outside the selection)
	
	NSArray * tSavedSelectedItems=nil;
	
	if (inItems.count==1)
	{
		if ([inOutlineView isRowSelected:[inOutlineView rowForItem:inItems[0]]]==NO)
			tSavedSelectedItems=[inOutlineView WB_selectedItems];
	}
	
	NSMutableDictionary * tDisclosedDictionary=[self.delegate disclosedDictionary];
	NSMutableArray * tAllKeys=[tDisclosedDictionary.allKeys mutableCopy];
	
	NSArray * tMinimumCover=[PKGTreeNode minimumNodeCoverFromNodesInArray:inItems];
	
	for(PKGPayloadTreeNode * tTreeNode in tMinimumCover)
	{
		// Remove the appropriate entries from the disclosed state dictionary
		
		if ([tTreeNode isLeaf]==NO)
		{
			NSString * tFilePath=[tTreeNode filePathWithSeparator:_fakeFileSeparator];
			
			NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
			
			[tAllKeys enumerateObjectsUsingBlock:^(NSString * bKey, NSUInteger bIndex, BOOL *bOutStop) {
				
				if ([bKey hasPrefix:tFilePath]==YES)
				{
					[tMutableIndexSet addIndex:bIndex];
					[tDisclosedDictionary removeObjectForKey:bKey];
				}
			}];
			 
			[tAllKeys removeObjectsAtIndexes:tMutableIndexSet];
		}
		
		
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
		[inPayloadTreeNode removeAllChildren];
		
		NSBeep();
		
		return;
	}
	
	[inOutlineView deselectAll:nil];
	
	[self.delegate payloadDataDidChange:self];
	
	[inOutlineView reloadData];
	
	NSInteger tRow=[inOutlineView rowForItem:inPayloadTreeNode];
	
	[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRow] byExtendingSelection:NO];
}

- (void)outlineView:(NSOutlineView *)inOutlineView  expandAllItemsWithOptions:(PKGPayloadExpandOptions)inOptions
{
	if (inOutlineView==nil)
		return;
	
	__block __weak BOOL (^_weakExpandItems)(NSArray *,PKGPayloadExpandOptions);
	__block BOOL (^_expandItems)(NSArray *,PKGPayloadExpandOptions);
	__block NSMutableArray * tExpandedItems=[NSMutableArray array];
	
	_expandItems = ^BOOL(NSArray * bItems,PKGPayloadExpandOptions bOptions)
	{
		BOOL tDidExpand=NO;
		
		for(PKGPayloadTreeNode * tItem in bItems)
		{
			if (tItem.isFileSystemItemNode==NO && [tItem numberOfChildren]>0)
			{
				if (_weakExpandItems([tItem children],bOptions)==YES)
					tDidExpand=YES;
				
				continue;
			}
			
			if (tItem.isReferencedItemMissing==YES)
				continue;
			
			if (tItem.isContentsDisclosed==YES)
			{
				if ([tItem numberOfChildren]>0 && _weakExpandItems([tItem children],bOptions)==YES)
					tDidExpand=YES;
				
				continue;
			}
			
			if ([self _expandItem:tItem atPath:[tItem referencedPathUsingConverter:self.filePathConverter] options:PKGPayloadExpandRecursively]==NO)
			{
				[tItem removeAllChildren];
				continue;
			}
			
			tDidExpand=YES;
			[tExpandedItems addObject:tItem];
		}
		
		return tDidExpand;
	};
	
	_weakExpandItems = _expandItems;
	
	PKGPayloadExpandOptions tOptions=(inOptions|PKGPayloadExpandRecursively);
	
	if (_expandItems(self.rootNodes,tOptions)==YES)
	{
		// A COMPLETER
		
		[self.delegate payloadDataDidChange:self];
		
		[tExpandedItems enumerateObjectsUsingBlock:^(id bItem,NSUInteger bIndex,BOOL *bOutStop){
		
		
			[inOutlineView reloadItem:bItem];
		}];
	}
}

- (void)outlineView:(NSOutlineView *)inOutlineView contractItem:(PKGPayloadTreeNode *)inPayloadTreeNode
{
	if (inOutlineView==nil || inPayloadTreeNode==nil)
		return;
	
	[inOutlineView collapseItem:inPayloadTreeNode];
	
	[inPayloadTreeNode contract];
	
	NSMutableDictionary * tDisclosedStateDictionary=[self.delegate disclosedDictionary];
	NSString * tFilePath=[inPayloadTreeNode filePathWithSeparator:_fakeFileSeparator];
	
	for(NSString * tKey in [tDisclosedStateDictionary allKeys])
	{
		if ([tKey hasPrefix:tFilePath]==YES)
			[tDisclosedStateDictionary removeObjectForKey:tKey];
	}
	
	[self.delegate payloadDataDidChange:self];
	
	[inOutlineView reloadItem:inPayloadTreeNode];
}

- (void)expandByDefault:(NSOutlineView *)inOutlineView
{
}

- (void)outlineView:(NSOutlineView *)inOutlineView transformItemIfNeeded:(PKGPayloadTreeNode *)inTreeNode
{
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
	
	return [inTreeNode childNodeAtIndex:inIndex];
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
			
			PKGFilePathConverter * tFilePathConverter=[PKGFilePathConverter new];
			
			tFilePathConverter.referenceProjectPath=self.filePathConverter.referenceProjectPath;
			tFilePathConverter.referenceFolderPath=self.filePathConverter.referenceFolderPath;
			
			[tFilePathConverter switchPathsOfPayloadTreeNode:tTreeNodeCopy toType:PKGFilePathTypeAbsolute recursively:YES];
		
			return [tTreeNodeCopy representation];
		
		}];
		
		[inPasteboard setPropertyList:tRepresentedMinimumCover forType:PKGPayloadItemsPboardType];
	}
}

#pragma mark - Drag and Drop support

- (void)outlineView:(NSOutlineView *)inOutlineView draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:(NSDragOperation)inOperation
{
	_internalDragData=nil;
}

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

	// Filenames
	
	if (inChildIndex==NSOutlineViewDropOnItemIndex)
	{
		if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]==nil)
			return NSDragOperationNone;
		
		if (inProposedTreeNode.isTemplateNode==NO || inProposedTreeNode.parent==nil || [inProposedTreeNode containsNoTemplateDescendantNodes]==YES)
			return NSDragOperationNone;
		
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tArray==nil || [tArray isKindOfClass:NSArray.class]==NO)
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
				
				return ([tFirstName compare:bTreeNode.fileName options:NSCaseInsensitiveSearch|NSNumericSearch|NSForcedOrderingSearch]==NSOrderedSame);
				
			}];
		}
		else
		{
			tInsertionIndex=[inProposedTreeNode indexOfChildMatching:^BOOL(PKGPayloadTreeNode * bTreeNode) {
				
				return ([tFirstName compare:bTreeNode.fileName options:NSCaseInsensitiveSearch|NSNumericSearch|NSForcedOrderingSearch]!=NSOrderedDescending);
			}];
		}
		
		if (self.rootNodes.count==0)
			[inOutlineView setDropItem:nil dropChildIndex:NSOutlineViewDropOnItemIndex];
		else
			[inOutlineView setDropItem:inProposedTreeNode dropChildIndex:(tInsertionIndex!=NSNotFound) ? tInsertionIndex : ((inProposedTreeNode==nil) ? self.rootNodes.count : [inProposedTreeNode numberOfChildren])];
		
		return YES;
	
	};
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tArray==nil || [tArray isKindOfClass:NSArray.class]==NO || tArray.count==0)
		{
			// We were provided invalid data
			
			// A COMPLETER
			
			return NSDragOperationNone;
		}
		
		NSArray * tFileNamesArray=[tArray WB_arrayByMappingObjectsUsingBlock:^NSString *(NSString * bFilePath,NSUInteger bIndex){
		
			return bFilePath.lastPathComponent;
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
		
		if (tExternalFileNamesArray.count==0)
			return NSDragOperationNone;
		
		return (validateFileNames(tFileNamesArray,tExternalFileNamesArray)==YES) ? NSDragOperationGeneric : NSDragOperationNone;
	}
	
	// Inter-documents Drag and Drop
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPayloadItemsPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:PKGPayloadItemsPboardType];
		
		if (tArray==nil || [tArray isKindOfClass:NSArray.class]==NO || tArray.count==0)
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
		return NO;
	
	// Internal drag and drop
	
	if ([info draggingSource]==inOutlineView)
	{
		NSMutableDictionary * tDisclosedStateDictionary=[self.delegate disclosedDictionary];
		NSNumber * tSharedNumber=@(YES);

		for(PKGPayloadTreeNode * tPayloadTreeNode in _internalDragData)
		{
			NSMutableSet * tDisclosedNodesSet=[NSMutableSet set];
			
			// Save the disclosed nodes
			
			[tPayloadTreeNode enumerateNodesUsingBlock:^(PKGPayloadTreeNode * bPayloadTreeNode,BOOL * bOutStop){
			
				if ([bPayloadTreeNode isLeaf]==YES)
					return;
				
				NSString * tFilePath=[bPayloadTreeNode filePathWithSeparator:_fakeFileSeparator];
				
				if (tDisclosedStateDictionary[tFilePath]!=nil)
				{
					[tDisclosedNodesSet addObject:bPayloadTreeNode];
					
					[tDisclosedStateDictionary removeObjectForKey:tFilePath];
				}
			}];
			
			// Move the node
			
			if (tPayloadTreeNode.parent!=nil)
				[tPayloadTreeNode removeFromParent];
			else
				[self.rootNodes removeObject:tPayloadTreeNode];
			
			if (inProposedTreeNode!=nil)
				[inProposedTreeNode insertChild:tPayloadTreeNode sortedUsingComparator:_comparator];
			else
				[tPayloadTreeNode insertAsSiblingOfChildren:self.rootNodes ofNode:nil sortedUsingComparator:_comparator];
			
			// Add the disclosed nodes with the new key
			
			for(PKGPayloadTreeNode * tDisclosedNode in tDisclosedNodesSet)
				tDisclosedStateDictionary[[tDisclosedNode filePathWithSeparator:self.fakeFileSeparator]]=tSharedNumber;
		}
		
		[inOutlineView deselectAll:nil];
		
        [self.delegate dataSource:self didDragAndDropNodes:_internalDragData];
        
		[self.delegate payloadDataDidChange:self];
		
		[inOutlineView reloadData];
		
		if (inProposedTreeNode!=nil && [inOutlineView isItemExpanded:inProposedTreeNode]==NO)
			[inOutlineView expandItem:inProposedTreeNode];
		
		// Restore selection
		
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
			
			tOptions|=(inChildIndex==NSOutlineViewDropOnItemIndex && inProposedTreeNode!=nil) ? PKGPayloadAddReplaceParents : 0;
			tOptions|=([PKGApplicationPreferences sharedPreferences].keepOwnership==YES) ? PKGPayloadAddKeepOwnership : 0;

			return [self outlineView:inOutlineView
						addFileNames:tArray
					   referenceType:[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle
						   toParents:(inProposedTreeNode==nil) ? nil : @[inProposedTreeNode]
							 options:tOptions];
		}
		
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		
		tPanel.canChooseOwnerAndGroupOptions=((self.managedAttributes&PKGFileAttributesOwnerAndGroup)!=0);
		tPanel.keepOwnerAndGroup=[PKGApplicationPreferences sharedPreferences].keepOwnership;
		tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		[tPanel beginSheetModalForWindow:inOutlineView.window completionHandler:^(NSModalResponse response){
			
			if (response==PKGPanelCancelButton)
				return;
			
			PKGPayloadAddOptions tOptions=0;
			
			tOptions|=(inChildIndex==NSOutlineViewDropOnItemIndex && inProposedTreeNode!=nil) ? PKGPayloadAddReplaceParents : 0;
			if (tPanel.canChooseOwnerAndGroupOptions==YES)
				tOptions|=(tPanel.keepOwnerAndGroup==YES) ? PKGPayloadAddKeepOwnership : 0;
			
			[self outlineView:inOutlineView
				 addFileNames:tArray
				referenceType:tPanel.referenceStyle
					toParents:(inProposedTreeNode==nil) ? nil : @[inProposedTreeNode]
					  options:tOptions];
		}];
		
		return YES;		// It may at the end not be accepted by the completion handler from the sheet
	}
	
	// Inter-documents Drag and Drop
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPayloadItemsPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:PKGPayloadItemsPboardType];
		
		BOOL (^insertNewItems)(PKGFilePathType)=^BOOL(PKGFilePathType inPathType){
		
			PKGFilePathConverter * tFilePathConverter=[PKGFilePathConverter new];
			
			tFilePathConverter.referenceProjectPath=self.filePathConverter.referenceProjectPath;
			tFilePathConverter.referenceFolderPath=self.filePathConverter.referenceFolderPath;
			
			NSMutableArray * tNewSelectionArray=[NSMutableArray array];
			
			for(NSDictionary * tRepresentation in tArray)
			{
				PKGPayloadTreeNode * tPayloadTreeNode=[[PKGPayloadTreeNode alloc] initWithRepresentation:tRepresentation error:NULL];
				
				if (tPayloadTreeNode==nil)
					return NO;
				
				// Check whether it's a bundle or just a file
				
				[self outlineView:inOutlineView transformItemIfNeeded:tPayloadTreeNode];
				
				[tFilePathConverter switchPathsOfPayloadTreeNode:tPayloadTreeNode toType:inPathType recursively:YES];

				if (inProposedTreeNode!=nil)
					[inProposedTreeNode insertChild:tPayloadTreeNode sortedUsingComparator:_comparator];
				else
					[tPayloadTreeNode insertAsSiblingOfChildren:self.rootNodes ofNode:nil sortedUsingComparator:_comparator];
				
				[tNewSelectionArray addObject:tPayloadTreeNode];
			}
			
			[inOutlineView deselectAll:nil];
			
			[self.delegate payloadDataDidChange:self];
			
			[inOutlineView reloadData];
			
			if (inProposedTreeNode !=nil && [inOutlineView isItemExpanded:inProposedTreeNode]==NO)
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
			
			if (bReturnCode==PKGPanelCancelButton)
				return;
			
			insertNewItems(tPanel.referenceStyle);
		}];
		
		return YES;		// It may at the end not be accepted by the completion handler from the sheet
	}
	
	return NO;
}

@end
