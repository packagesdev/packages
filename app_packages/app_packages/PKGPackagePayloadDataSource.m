/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackagePayloadDataSource.h"

#import "PKGSmartLocationDetector.h"

#import "PKGPayloadTreeNode+UI.h"
#import "PKGPayloadBundleItem.h"

#import "NSOutlineView+Selection.h"

#import "PKGApplicationPreferences.h"

#import "PKGOwnershipAndReferenceStylePanel.h"

#import "PKGPayloadDropView.h"
#import "PKGPayloadTreeNode+Bundle.h"


@interface PKGPackagePayloadDataSource ()

	@property (nonatomic,readonly) PKGTreeNode * cachedHiddenTemplateFoldersTree;
	@property (nonatomic,readonly) NSUInteger hiddenTemplateFoldersTreeHeight;

@end

@implementation PKGPackagePayloadDataSource

@synthesize cachedHiddenTemplateFoldersTree=_cachedHiddenTemplateFoldersTree;
@synthesize hiddenTemplateFoldersTreeHeight=_hiddenTemplateFoldersTreeHeight;

#pragma mark -

- (PKGFileAttributesOptions)managedAttributes
{
	return PKGFileAttributesOwnerAndGroup|PKGFileAttributesPOSIXPermissions;
}

#pragma mark -

- (PKGTreeNode *)cachedHiddenTemplateFoldersTree
{
	if (_cachedHiddenTemplateFoldersTree==nil)
	{
		NSString * tPath=[[NSBundle mainBundle] pathForResource:@"InvisibleHierarchy" ofType:@"plist"];
		
		if (tPath==nil)
			return nil;
		
		NSDictionary * tDictionary=[[NSDictionary alloc] initWithContentsOfFile:tPath];
		
		NSError * tError;
		_cachedHiddenTemplateFoldersTree=[[PKGPayloadTreeNode alloc] initWithRepresentation:tDictionary error:&tError];
		
		if (_cachedHiddenTemplateFoldersTree==nil)
		{
			// A COMPLETER
			
			return nil;
		}
		
		_hiddenTemplateFoldersTreeHeight=[_cachedHiddenTemplateFoldersTree height];
	}
	
	return _cachedHiddenTemplateFoldersTree;
}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldDrawTargetCrossForItem:(id)inItem
{
	return (self.installLocationNode==inItem);
}

#pragma mark -

- (void)outlineView:(NSOutlineView *)inOutlineView transformItemIfNeeded:(PKGPayloadTreeNode *)inTreeNode
{
	PKGFileItem * tRepresentedObject=inTreeNode.representedObject;
	
	if (tRepresentedObject.type<PKGFileItemTypeNewFolder)
		return;
	
	PKGTriboolean tIsBundle=[inTreeNode isBundleWithFilePathConverter:self.filePathConverter bundleIdentifier:NULL];
	
	if (tIsBundle==INDETERMINED_value)
		return;
	
	if (tIsBundle==NO_value && [tRepresentedObject isMemberOfClass:[PKGPayloadBundleItem class]]==YES)
	{
		// We need to revert to a PKGFileItem
		
		PKGFileItem * tConvertedFileItem=[(PKGPayloadBundleItem *) tRepresentedObject fileItem];
		
		if (tConvertedFileItem==nil)
		{
			NSLog(@"<0x%lx> Conversion from PKGFileItem to PKGPayloadBundleItem failed",(unsigned long)tConvertedFileItem);
			return;
		}
		
		[inTreeNode setRepresentedObject:tConvertedFileItem];
	}
	else if (tIsBundle==YES_value && [tRepresentedObject isMemberOfClass:[PKGFileItem class]]==YES)
	{
		// We shall investigate whether this shall not become a PKGPayloadBundleItem
		
		PKGPayloadBundleItem * tConvertedBundleItem=[[PKGPayloadBundleItem alloc] initWithFileItem:tRepresentedObject];
		
		if (tConvertedBundleItem==nil)
		{
			NSLog(@"<0x%lx> Conversion from PKGPayloadBundleItem to PKGFileItem failed",(unsigned long)tConvertedBundleItem);
			return;
		}
		
		[inTreeNode setRepresentedObject:tConvertedBundleItem];
	}
}

#pragma mark -

- (void)outlineView:(NSOutlineView *)inOutlineView showHiddenFolderTemplates:(BOOL)inShowsHiddenFolders
{
	if (inOutlineView==nil)
		return;
	
	// Save selection
	
	NSArray * tSavedSelectedItems=[inOutlineView WB_selectedItems];
	
	if (inShowsHiddenFolders==YES)
	{
		if ([self.rootNodes[0] addUnmatchedDescendantsOfNode:[self.cachedHiddenTemplateFoldersTree deepCopy] usingSelector:@selector(compareName:)]==NO)
			return;
	}
	else
	{
		NSMutableArray * tMutableArray=self.rootNodes;
		NSUInteger tCount=tMutableArray.count;
		
		for(NSUInteger tIndex=tCount;tIndex>0;tIndex--)
		{
			PKGPayloadTreeNode * tRootNode=(PKGPayloadTreeNode *)[tMutableArray[tIndex-1] filterRecursivelyUsingBlock:^BOOL(PKGPayloadTreeNode * bPayloadTreeNode){
			
				return (bPayloadTreeNode.isHiddenTemplateNode==NO || bPayloadTreeNode==self.installLocationNode || [bPayloadTreeNode numberOfChildren]>0);
			
			}
																										 maximumDepth:(self.hiddenTemplateFoldersTreeHeight==0) ? NSNotFound : self.hiddenTemplateFoldersTreeHeight];
			
			if (tRootNode==nil)
				[tMutableArray removeObjectAtIndex:tIndex-1];
		}
	}
	
	[inOutlineView deselectAll:nil];
	
	[inOutlineView reloadData];
	
	// Restore selection
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	for(id tItem in tSavedSelectedItems)
	{
		NSInteger tRow=[inOutlineView rowForItem:tItem];
		
		if (tRow!=-1)
			[tMutableIndexSet addIndex:tRow];
	}
	
	[inOutlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
	
	[self.delegate payloadDataDidChange:self];
}

- (void)outlineView:(NSOutlineView *)inOutlineView restoreExpansionsState:(id)object
{
	if (object!=nil)
	{
		[super outlineView:inOutlineView restoreExpansionsState:object];
		return;
	}
	
	// Expand the ancestors of file system items or new folder items
	
	NSNull * tNull=[NSNull null];
	
	__block __weak void (^_weakExpandAncestorsOfItemsIfNeeded)(NSArray *,NSMutableArray *);
	__block void(^_expandAncestorsOfItemsIfNeeded)(NSArray *,NSMutableArray *);
	__block BOOL tFoundNonTemplateNodes=NO;
	
	_expandAncestorsOfItemsIfNeeded = ^(NSArray * bItems,NSMutableArray * bExpansionStack)
	{
		for(PKGPayloadTreeNode * tItem in bItems)
		{
			if ([tItem isTemplateNode]==YES)
			{
				[bExpansionStack addObject:tItem];
				
				_weakExpandAncestorsOfItemsIfNeeded([tItem children],bExpansionStack);
				
				[bExpansionStack removeLastObject];
			}
			else
			{
				tFoundNonTemplateNodes=YES;
				
				// Expand Ancestors
				
				NSUInteger tCount=bExpansionStack.count;
				
				for(NSUInteger tIndex=0;tIndex<tCount;tIndex++)
				{
					id tAncestor=bExpansionStack[tIndex];
					
					if (tAncestor!=tNull)
					{
						[inOutlineView expandItem:tAncestor];
						
						bExpansionStack[tIndex]=tNull;
					}
				}
			}
		}
	};
	
	_weakExpandAncestorsOfItemsIfNeeded = _expandAncestorsOfItemsIfNeeded;
	
	_expandAncestorsOfItemsIfNeeded(self.rootNodes,[NSMutableArray array]);
	
	if (tFoundNonTemplateNodes==NO)
	{
		// expand / and /Library
		
		PKGPayloadTreeNode * tRootNode=[self.rootNodes lastObject];
		
		[inOutlineView expandItem:tRootNode];
		
		PKGPayloadTreeNode *tLibraryNode=[tRootNode descendantNodeAtPath:@"/Library"];
		
		if (tLibraryNode!=nil)
			[inOutlineView expandItem:tLibraryNode];
	}
}


#pragma mark - PKGFileDeadDropViewDelegate

- (BOOL)fileDeadDropView:(PKGPayloadDropView *)inView validateDropFiles:(NSArray *)inFilenames
{
	if (inFilenames==nil)
		return NO;
	
	PKGPayloadTreeNode * tRootNode=[self.rootNodes lastObject];
	
	for(NSString * tPath in inFilenames)
	{
		NSArray * tPotentialDirectories=[PKGSmartLocationDetector potentialInstallationDirectoriesForFileAtPath:tPath];
		
		if (tPotentialDirectories==nil)
			return NO;
		
		NSString * tDirectory=nil;
		
		for(tDirectory in tPotentialDirectories)
		{
			PKGPayloadTreeNode * tPayloadTreeNode=[tRootNode descendantNodeAtPath:tDirectory];
			
			if (tPayloadTreeNode==nil)
			{
				if ([PKGSmartLocationDetector canCreateDirectoryPath:tDirectory]==YES)
					break;
			}
			else
			{
				NSString * tLastPathComponent=[tPath lastPathComponent];
				
				if ([tPayloadTreeNode indexOfChildMatching:^BOOL(PKGPayloadTreeNode *bTreeNode){
					
					return ([tLastPathComponent caseInsensitiveCompare:bTreeNode.fileName]==NSOrderedSame);
					
					
				}]==NSNotFound)
					break;
			}
		}
		
		if (tDirectory==nil)
			return NO;
	}

	return YES;
}

- (BOOL)fileDeadDropView:(PKGPayloadDropView *)inView acceptDropFiles:(NSArray *)inFilenames
{
	if (inFilenames==nil)
		return NO;
	
	PKGPayloadTreeNode * tRootNode=[self.rootNodes lastObject];
	
	NSMutableArray * tParentsArray=[NSMutableArray array];
	
	for(NSString * tPath in inFilenames)
	{
		NSArray * tPotentialDirectories=[PKGSmartLocationDetector potentialInstallationDirectoriesForFileAtPath:tPath];
		
		if (tPotentialDirectories==nil)
			return NO;
		
		NSString * tDirectory=nil;
		
		for(tDirectory in tPotentialDirectories)
		{
			PKGPayloadTreeNode * tPayloadTreeNode=[tRootNode descendantNodeAtPath:tDirectory];
			
			if (tPayloadTreeNode==nil)
			{
				if ([PKGSmartLocationDetector canCreateDirectoryPath:tDirectory]==YES)
				{
					tPayloadTreeNode=[tRootNode createMissingDescendantsForPath:tDirectory];
					
					[tParentsArray addObject:tPayloadTreeNode];
					
					break;
				}
			}
			else
			{
				NSString * tLastPathComponent=[tPath lastPathComponent];
				
				if ([tPayloadTreeNode indexOfChildMatching:^BOOL(PKGPayloadTreeNode *bTreeNode){
					
					return ([tLastPathComponent caseInsensitiveCompare:bTreeNode.fileName]==NSOrderedSame);
					
					
				}]==NSNotFound)
				{
					[tParentsArray addObject:tPayloadTreeNode];
					
					break;
				}
			}
		}
		
		if (tDirectory==nil)
			return NO;
	}
	
	for(PKGPayloadTreeNode * bParentTreeNode in tParentsArray)
		[self outlineView:inView.fileHierarchyOutlineView discloseItemIfNeeded:bParentTreeNode];
	
	if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==NO)
	{
		PKGPayloadAddOptions tOptions=0;
		
		tOptions|=([PKGApplicationPreferences sharedPreferences].keepOwnership==YES) ? PKGPayloadAddKeepOwnership : 0;
		
		return [self outlineView:inView.fileHierarchyOutlineView
					addFileNames:inFilenames
				   referenceType:[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle
					   toParents:tParentsArray
						 options:tOptions];
	}
	
	PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
	
	tPanel.canChooseOwnerAndGroupOptions=((self.managedAttributes&PKGFileAttributesOwnerAndGroup)!=0);
	tPanel.keepOwnerAndGroup=[PKGApplicationPreferences sharedPreferences].keepOwnership;
	tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	[tPanel beginSheetModalForWindow:inView.fileHierarchyOutlineView.window completionHandler:^(NSInteger bReturnCode){
		
		if (bReturnCode==PKGOwnershipAndReferenceStylePanelCancelButton)
			return;
		
		PKGPayloadAddOptions tOptions=0;
		
		if (tPanel.canChooseOwnerAndGroupOptions==YES)
			tOptions|=(tPanel.keepOwnerAndGroup==YES) ? PKGPayloadAddKeepOwnership : 0;
		
		[self outlineView:inView.fileHierarchyOutlineView
			 addFileNames:inFilenames
			referenceType:tPanel.referenceStyle
				toParents:tParentsArray
				  options:tOptions];
	}];
	
	return YES;
}

@end
