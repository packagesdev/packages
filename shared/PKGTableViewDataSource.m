/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGTableViewDataSource.h"

#import "NSIndexSet+Analysis.h"

NSString * const PPKGTableViewDataSourceInternalPboardType=@"fr.whitebox.packages.internal.array";

@interface PKGTableViewDataSource ()
{
	NSIndexSet * _internalDragData;
}

	@property (readwrite) NSMutableArray * items;

@end

@implementation PKGTableViewDataSource

- (instancetype)initWithItems:(NSMutableArray *)inArray
{
	self=[super init];
	
	if (self!=nil)
	{
		_items=inArray;
	}
	
	return self;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView==nil)
		return 0;
	
	return self.items.count;
}

#pragma mark - Drag and Drop support

- (BOOL)tableView:(NSTableView *)inTableView writeRowsWithIndexes:(NSIndexSet *)inRowIndexes toPasteboard:(NSPasteboard *)inPasteboard;
{
	_internalDragData=inRowIndexes;	// A COMPLETER (Find how to empty it when the drag and drop is canceled)
	
	[inPasteboard declareTypes:@[PPKGTableViewDataSourceInternalPboardType] owner:self];
	
	[inPasteboard setData:[NSData data] forType:PPKGTableViewDataSourceInternalPboardType];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)inTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)inRow proposedDropOperation:(NSTableViewDropOperation)inDropOperation
{
	if (inDropOperation==NSTableViewDropOn)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	// Internal Drag
	
	if ([tPasteBoard availableTypeFromArray:@[PPKGTableViewDataSourceInternalPboardType]]!=nil && [info draggingSource]==inTableView)
	{
		if ([_internalDragData WB_containsOnlyOneRange]==YES)
		{
			NSUInteger tFirstIndex=_internalDragData.firstIndex;
			NSUInteger tLastIndex=_internalDragData.lastIndex;
			
			if (inRow>=tFirstIndex && inRow<=(tLastIndex+1))
				return NSDragOperationNone;
		}
		else
		{
			if ([_internalDragData containsIndex:(inRow-1)]==YES)
				return NSDragOperationNone;
		}
		
		return NSDragOperationMove;
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)inTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)inRow dropOperation:(NSTableViewDropOperation)inDropOperation
{
	if (inTableView==nil)
		return NO;
	
	// Internal drag and drop
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[PPKGTableViewDataSourceInternalPboardType]]!=nil && [info draggingSource]==inTableView)
	{
		NSArray * tObjects=[self.items objectsAtIndexes:_internalDragData];
		
		[self.items removeObjectsAtIndexes:_internalDragData];
		
		NSUInteger tIndex=[_internalDragData firstIndex];
		
		while (tIndex!=NSNotFound)
		{
			if (tIndex<inRow)
				inRow--;
			
			tIndex=[_internalDragData indexGreaterThanIndex:tIndex];
		}
		
		NSIndexSet * tNewIndexSet=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inRow, _internalDragData.count)];
		
		[self.items insertObjects:tObjects atIndexes:tNewIndexSet];
		
		_internalDragData=nil;
		
		[inTableView deselectAll:nil];
		
		[self.delegate dataDidChange:self];
		
		[inTableView reloadData];
		
		[inTableView selectRowIndexes:tNewIndexSet
				 byExtendingSelection:NO];
		
		return YES;
	}
	
	return NO;
}

#pragma mark -

- (NSInteger)tableView:(NSTableView *)inTableView rowForItem:(id)inItem
{
	if (inTableView==nil || inItem==nil)
		return -1;
	
	NSInteger tIndex=[self.items indexOfObjectIdenticalTo:inItem];
	
	return (tIndex==NSNotFound) ? -1 : tIndex;
}

- (id)tableView:(NSTableView *)inTableView itemAtRow:(NSInteger)inRow
{
	if (inTableView==nil)
		return nil;
	
	if (inRow<0 || inRow>=self.items.count)
		return nil;
	
	return self.items[inRow];
}

- (NSArray *)tableView:(NSTableView *)inTableView itemsAtRowIndexes:(NSIndexSet *)inIndexSet
{
	if (inTableView==nil || inIndexSet==nil)
		return nil;
	
	if (inIndexSet.lastIndex>=self.items.count)
		return nil;
	
	return [self.items objectsAtIndexes:inIndexSet];
}

- (void)tableView:(NSTableView *)inTableView addItem:(id)inItem
{
	if (inTableView==nil || inItem==nil)
		return;
	
	[self.items addObject:inItem];
	
	[inTableView deselectAll:self];
	
	[self.delegate dataDidChange:self];
	
	[inTableView reloadData];
	
	NSInteger tIndex=[self.items indexOfObjectIdenticalTo:inItem];
	
	if (tIndex!=NSNotFound)
		[inTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
}

- (void)tableView:(NSTableView *)inTableView replaceItemAtIndex:(NSUInteger)inIndex withItem:(id)inItem
{
	if (inTableView==nil || inItem==nil)
		return;
	
	if (inIndex>=self.items.count)
		return;
	
	[self.items replaceObjectAtIndex:inIndex withObject:inItem];
	
	[inTableView deselectAll:self];
	
	[self.delegate dataDidChange:self];
	
	[inTableView reloadData];
	
	NSInteger tIndex=[self.items indexOfObjectIdenticalTo:inItem];
	
	if (tIndex!=NSNotFound)
		[inTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
}

- (void)tableView:(NSTableView *)inTableView removeItems:(NSArray *)inItems
{
	if (inTableView==nil || inItems==nil)
		return;
	
	[self.items removeObjectsInArray:inItems];
	
	[inTableView deselectAll:self];
	
	[self.delegate dataDidChange:self];
	
	[inTableView reloadData];
}

@end
