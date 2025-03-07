/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGMustCloseApplicationItemsDataSource.h"

NSString * const PKGMustCloseApplicationItemTransferPboardType=@"fr.whitebox.packages.transfer.package-component.must-close-application-items";

@interface PKGMustCloseApplicationItemsDataSource ()
{
	NSIndexSet * _internalDragData;
}

@end

@implementation PKGMustCloseApplicationItemsDataSource

+ (NSArray *)supportedDraggedTypes
{
	return @[NSFilenamesPboardType,PKGMustCloseApplicationItemTransferPboardType];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	return _mustCloseApplicationItems.count;
}

#pragma mark -

- (id)itemAtRow:(NSInteger)inRow
{
	if (inRow<0 || inRow>=_mustCloseApplicationItems.count)
		return nil;
	
	return _mustCloseApplicationItems[inRow];
}

- (NSArray *)itemsAtRowIndexes:(NSIndexSet *)inIndexSet
{
	if (inIndexSet==nil)
		return nil;
	
	if (inIndexSet.lastIndex>=_mustCloseApplicationItems.count)
		return nil;
	
	return [_mustCloseApplicationItems objectsAtIndexes:inIndexSet];
}

- (NSInteger)rowForItem:(id)inItem
{
	if (inItem==nil)
		return -1;
	
	NSInteger tIndex=[_mustCloseApplicationItems indexOfObjectIdenticalTo:inItem];
	
	return (tIndex==NSNotFound) ? -1 : tIndex;
}

#pragma mark -

- (void)addNewItem:(NSTableView *)inTableView
{
	PKGMustCloseApplicationItem * nMustCloseApplicationItem=[PKGMustCloseApplicationItem new];
	
	[_mustCloseApplicationItems addObject:nMustCloseApplicationItem];
	
	[inTableView reloadData];
	
	// Post Notification
	
	[self.delegate mustCloseApplicationItemsDataDidChange:self];
	
	NSUInteger tLastIndex=_mustCloseApplicationItems.count-1;
	
	[inTableView scrollRowToVisible:tLastIndex];
	
	[inTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tLastIndex] byExtendingSelection:NO];
}

- (void)tableView:(NSTableView *)inTableView setItem:(PKGMustCloseApplicationItem *)inMustCloseApplicationItem state:(BOOL)inState
{
	if (inTableView==nil || inMustCloseApplicationItem==nil)
		return;
	
	inMustCloseApplicationItem.enabled=inState;
	
	// Post Notification
	
	[self.delegate mustCloseApplicationItemsDataDidChange:self];
}

- (BOOL)tableView:(NSTableView *)inTableView shouldReplaceApplicationIDOfItem:(PKGMustCloseApplicationItem *)inMustCloseApplicationItem withString:(NSString *)inApplicationID
{
	if (inTableView==nil || inMustCloseApplicationItem==nil || inApplicationID==nil)
		return NO;
	
	NSString * tApplicationID=inMustCloseApplicationItem.applicationID;
	
	if ([tApplicationID compare:inApplicationID]==NSOrderedSame)
		return NO;
	
	NSUInteger tLength=inApplicationID.length;
	NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[self rowForItem:inMustCloseApplicationItem]];
	NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[inTableView columnWithIdentifier:@"applicationItem"]];
	
	if (tLength==0)
	{
		[inTableView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
		
		return NO;
	}
	
	if ([_mustCloseApplicationItems indexesOfObjectsPassingTest:^BOOL(PKGMustCloseApplicationItem * bMustCloseApplicationItem1,NSUInteger bIndex,BOOL * bOutStop){
		
		return ([bMustCloseApplicationItem1.applicationID compare:inApplicationID]==NSOrderedSame);
		
	}].count>0)
	{
		NSAlert * tAlert=[NSAlert new];
		tAlert.alertStyle=WBAlertStyleCritical;
		tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"The application ID \"%@\" is already listed.",@""),inApplicationID];
		tAlert.informativeText=NSLocalizedString(@"Please type a different application ID.",@"");
		
		[tAlert beginSheetModalForWindow:inTableView.window completionHandler:^(NSModalResponse bResponse){
			
			[inTableView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
			
			[inTableView editColumn:tReloadColumnIndexes.firstIndex row:tReloadRowIndexes.firstIndex withEvent:nil select:YES];
		}];
		
		return NO;
	}
	
	return YES;
}

- (void)tableView:(NSTableView *)inTableView replaceApplicationIDOfItem:(PKGMustCloseApplicationItem *)inMustCloseApplicationItem withString:(NSString *)inApplicationID
{
	if (inTableView==nil || inMustCloseApplicationItem==nil || inApplicationID==nil)
		return;
	
	inMustCloseApplicationItem.applicationID=inApplicationID;
	
	[_mustCloseApplicationItems sortUsingComparator:^NSComparisonResult(PKGMustCloseApplicationItem * bMustCloseApplicationItem1,PKGMustCloseApplicationItem * bMustCloseApplicationItem2) {
		
		return [bMustCloseApplicationItem1.applicationID caseInsensitiveCompare:bMustCloseApplicationItem2.applicationID];
	}];
	
	[inTableView deselectAll:self];
	
	[inTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,_mustCloseApplicationItems.count)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[inTableView numberOfColumns])]];

	// Post Notification
	
	[self.delegate mustCloseApplicationItemsDataDidChange:self];
	
	// Update selection
	
	NSUInteger tIndex=[_mustCloseApplicationItems indexOfObject:inMustCloseApplicationItem];
	
	if (tIndex!=NSNotFound)
		[inTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
}

- (void)tableView:(NSTableView *)inTableView removeItemsAtIndexes:(NSIndexSet *)inIndexSet
{
	if (inTableView==nil || inIndexSet.count==0)
		return;
	
	// Remove the requirements
	
	[_mustCloseApplicationItems removeObjectsAtIndexes:inIndexSet];
	
	[inTableView deselectAll:nil];
	
	[inTableView reloadData];
	
	[self.delegate mustCloseApplicationItemsDataDidChange:self];
}

#pragma mark - NSPasteboardOwner

- (void)pasteboard:(NSPasteboard *)inPasteboard provideDataForType:(NSString *)inType
{
	if (inPasteboard==nil || inType==nil)
		return;
	
	if (_internalDragData==nil)
		return;
	
	if ([inType isEqualToString:PKGMustCloseApplicationItemTransferPboardType]==NO)
		return;
	
	NSArray * tSelectedItems=[_mustCloseApplicationItems objectsAtIndexes:_internalDragData];
	
	NSArray * tPasteboardArray=[tSelectedItems WB_arrayByMappingObjectsUsingBlock:^NSDictionary *(PKGMustCloseApplicationItem * bMustCloseApplicationItem, NSUInteger bIndex) {
		
		return [bMustCloseApplicationItem representation];
	}];
	
	[inPasteboard setPropertyList:tPasteboardArray forType:PKGMustCloseApplicationItemTransferPboardType];
}

#pragma mark - Drag and Drop support

- (void)tableView:(NSTableView *)inTableView draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:(NSDragOperation)inOperation
{
	_internalDragData=nil;
}

- (BOOL)tableView:(NSTableView *)inTableView writeRowsWithIndexes:(NSIndexSet *)inRowIndexes toPasteboard:(NSPasteboard *)inPasteboard
{
	if (inTableView==nil || inRowIndexes==nil || inPasteboard==nil)
		return NO;
	
	_internalDragData=inRowIndexes;
	
	NSMutableArray * tPasteboardTypes=[NSMutableArray arrayWithObject:PKGMustCloseApplicationItemTransferPboardType];
	
	[inPasteboard declareTypes:tPasteboardTypes owner:self];		// Make the transfer drag a promised case since it will be less usual IMHO
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)inTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)inRow proposedDropOperation:(NSTableViewDropOperation)inDropOperation
{
	if (_mustCloseApplicationItems==nil)
		return NSDragOperationNone;
	
	if (inDropOperation==NSTableViewDropOn)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	NSString * tAvailableType=[tPasteBoard availableTypeFromArray:[PKGMustCloseApplicationItemsDataSource supportedDraggedTypes]];
	
	if (tAvailableType!=nil)
	{
		if ([tAvailableType isEqualToString:NSFilenamesPboardType]==YES)
		{
			NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
			
			for(NSString * tPath in tArray)
			{
				NSString * tBundleIdentifier=[NSBundle bundleWithPath:tPath].bundleIdentifier;
				
				if (tBundleIdentifier.length==0)
					return NSDragOperationNone;
				
				if ([_mustCloseApplicationItems indexOfObjectPassingTest:^BOOL(PKGMustCloseApplicationItem * bMustCloseApplicationItem, NSUInteger bIndex, BOOL *bOutStop) {
					
					return [bMustCloseApplicationItem.applicationID isEqualToString:tBundleIdentifier];
					
				}]!=NSNotFound)
					return NSDragOperationNone;
				
				[inTableView setDropRow:-1 dropOperation:NSTableViewDropOn];
					
				return NSDragOperationCopy;
			}
		}
		else
		{
			// Inter Document Drag and Drop
		
			if ([tAvailableType isEqualToString:PKGMustCloseApplicationItemTransferPboardType]==YES)
			{
				NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:PKGMustCloseApplicationItemTransferPboardType];
				
				for(NSDictionary * tRepresentation in tArray)
				{
					PKGMustCloseApplicationItem * tMustCloseApplicationItem=[[PKGMustCloseApplicationItem alloc] initWithRepresentation:tRepresentation error:NULL];
					
					if (tMustCloseApplicationItem==nil)
						return NSDragOperationNone;
					
					for(PKGMustCloseApplicationItem * tOtherMustCloseApplicationItem in _mustCloseApplicationItems)
					{
						if ([tMustCloseApplicationItem.applicationID isEqualToString:tOtherMustCloseApplicationItem.applicationID]==YES)
							return NSDragOperationNone;
					}
				}
				
				// A VOIR : If there's only one dragged item, maybe we could set the appropriate drop row
				
				[inTableView setDropRow:-1 dropOperation:NSTableViewDropOn];
				
				return NSDragOperationCopy;
			}
		}
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*) inTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)inRow dropOperation:(NSTableViewDropOperation)inOperation
{
	if (_mustCloseApplicationItems==nil)
		return NO;

	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	NSString * tAvailableType=[tPasteBoard availableTypeFromArray:[PKGMustCloseApplicationItemsDataSource supportedDraggedTypes]];
	
	if (tAvailableType!=nil)
	{
		NSArray * tNewMustCloseApplicationItems=nil;
		
		if ([tAvailableType isEqualToString:NSFilenamesPboardType]==YES)
		{
			NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
			
			tNewMustCloseApplicationItems=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^PKGMustCloseApplicationItem *(NSString * bPath, NSUInteger bIndex) {
				
				NSString * tBundleIdentifier=[NSBundle bundleWithPath:bPath].bundleIdentifier;
				
				if (tBundleIdentifier.length==0)
					return nil;
				
				PKGMustCloseApplicationItem * nMustCloseApplicationItem=[PKGMustCloseApplicationItem new];
				
				nMustCloseApplicationItem.applicationID=tBundleIdentifier;
				
				return nMustCloseApplicationItem;
			}];
		}
		else
		{
			// Inter Document Drag and Drop
			
			if ([tAvailableType isEqualToString:PKGMustCloseApplicationItemTransferPboardType]==YES)
			{
				NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:PKGMustCloseApplicationItemTransferPboardType];
				
				tNewMustCloseApplicationItems=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^PKGMustCloseApplicationItem *(NSDictionary * bRepresentation, NSUInteger bIndex) {
					
					PKGMustCloseApplicationItem * tMustCloseApplicationItem=[[PKGMustCloseApplicationItem alloc] initWithRepresentation:bRepresentation error:NULL];
					
					return tMustCloseApplicationItem;
				}];
			}
		}
		
		if (tNewMustCloseApplicationItems.count==0)
			return NO;
		
		[_mustCloseApplicationItems addObjectsFromArray:tNewMustCloseApplicationItems];
		
		
		[_mustCloseApplicationItems sortUsingComparator:^NSComparisonResult(PKGMustCloseApplicationItem * bMustCloseApplicationItem1,PKGMustCloseApplicationItem * bMustCloseApplicationItem2) {
			
			return [bMustCloseApplicationItem1.applicationID caseInsensitiveCompare:bMustCloseApplicationItem2.applicationID];
		}];
		
		[inTableView deselectAll:self];
		
		[inTableView reloadData];
		
		// Post Notification
		
		[self.delegate mustCloseApplicationItemsDataDidChange:self];
		
		// Update selection
		
		NSIndexSet * tIndexSet=[_mustCloseApplicationItems indexesOfObjectsPassingTest:^BOOL(PKGMustCloseApplicationItem * bMustCloseApplicationItem, NSUInteger bIndex, BOOL *bOutStop) {
			
			return [tNewMustCloseApplicationItems containsObject:bMustCloseApplicationItem];
			
		}];
		
		if (tIndexSet.count>0)
			[inTableView selectRowIndexes:tIndexSet byExtendingSelection:NO];
		
		return YES;
	}
	
	return NO;
}

@end
