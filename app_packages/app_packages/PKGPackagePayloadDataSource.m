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

#import "PKGPayloadTreeNode+UI.h"

#import "NSOutlineView+Selection.h"

@interface PKGPackagePayloadDataSource ()

	@property (nonatomic,readonly) PKGTreeNode * cachedHiddenTemplateFoldersTree;
	@property (nonatomic,readonly) NSUInteger hiddenTemplateFoldersTreeHeight;

@end

@implementation PKGPackagePayloadDataSource

@synthesize cachedHiddenTemplateFoldersTree=_cachedHiddenTemplateFoldersTree;
@synthesize hiddenTemplateFoldersTreeHeight=_hiddenTemplateFoldersTreeHeight;

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

- (void)outlineView:(NSOutlineView *)inOutlineView showsHiddenFolders:(BOOL)inShowsHiddenFolders
{
	if (inOutlineView==nil)
		return;
	
	// Save selection
	
	NSArray * tSavedSelectedItems=[inOutlineView selectedItems];
	
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
			
				return (bPayloadTreeNode.isHiddenTemplateNode==NO || [bPayloadTreeNode numberOfChildren]>0);
			
			}
																										 maximumDepth:self.hiddenTemplateFoldersTreeHeight];
			
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

#pragma mark - PKGFileDeadDropViewDelegate

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView validateDropFiles:(NSArray *) inFilenames
{
	// A COMPLETER
	
	return YES;
}

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView acceptDropFiles:(NSArray *) inFilenames
{
	// A COMPLETER
	
	return YES;
}

@end
