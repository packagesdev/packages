/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationInstallationTypeChoiceRequirementsDataSource.h"

#import "PKGRequirement.h"

#import "PKGPresentationChoiceRequirementPanel.h"

#import "PKGRequirementPluginsManager.h"
#import "PKGPluginsManager+AppKit.h"

#import "PKGRequirement+UI.h"

#import "NSArray+UniqueName.h"
#import "NSString+BaseName.h"

#import "NSIndexSet+Analysis.h"

#import "NSTableView+Selection.h"

NSString * const PKGInstallationTypeChoiceRequirementsInternalPboardType=@"fr.whitebox.packages.internal.presentation.installationType.choice.requirements";

NSString * const PKGInstallationTypeChoiceRequirementsTransferPboardType=@"fr.whitebox.packages.transfer.presentation.installationType.choice.requirements";

@interface PKGPresentationInstallationTypeChoiceRequirementsDataSource ()
{
	NSMutableArray * _requirements;
	
	NSIndexSet * _internalDragData;
}

- (void)tableView:(NSTableView *)inTableView addRequirement:(PKGRequirement *)inRequirement completionHandler:(void(^)(BOOL))handler;
- (void)tableView:(NSTableView *)inTableView addRequirements:(NSArray *)inRequirements completionHandler:(void(^)(BOOL))handler;

@end

@implementation PKGPresentationInstallationTypeChoiceRequirementsDataSource

+ (NSArray *)supportedDraggedTypes
{
	return @[NSFilenamesPboardType,PKGInstallationTypeChoiceRequirementsInternalPboardType];
}

- (void)setChoiceItem:(PKGChoiceItem *)inChoiceItem
{
	if (_choiceItem==inChoiceItem)
		return;
	
	_choiceItem=inChoiceItem;
	
	_requirements=_choiceItem.requirements;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	return _requirements.count;
}

#pragma mark - NSPasteboardOwner

- (void)pasteboard:(NSPasteboard *)inPasteboard provideDataForType:(NSString *)inType
{
	if (inPasteboard==nil || inType==nil)
		return;
	
	if (_internalDragData==nil)
		return;
	
	if ([inType isEqualToString:PKGInstallationTypeChoiceRequirementsTransferPboardType]==NO)
		return;
	
	NSArray * tRequirements=[_requirements objectsAtIndexes:_internalDragData];
	
	NSArray * tPasteboardArray=[tRequirements WB_arrayByMappingObjectsUsingBlock:^NSDictionary *(PKGRequirement * bRequirement, NSUInteger bIndex) {
		
		Class tPluginUIClass=[[PKGRequirementPluginsManager defaultManager] pluginUIClassForIdentifier:bRequirement.identifier];
		
		PKGRequirement * tRequirementCopy=[bRequirement copy];
		
		NSDictionary * tPasteboardSettingsRepresenation=[tPluginUIClass performSelector:@selector(pasteboardDictionaryFromDictionary:converter:) withObject:bRequirement.settingsRepresentation withObject:self.filePathConverter];
		
		tRequirementCopy.settingsRepresentation=tPasteboardSettingsRepresenation;
		
		return [tRequirementCopy representation];
	}];
	
	[inPasteboard setPropertyList:tPasteboardArray forType:PKGInstallationTypeChoiceRequirementsTransferPboardType];
}

#pragma mark - Drag and Drop support

- (void)tableView:(NSTableView *)inTableView draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:(NSDragOperation)inOperation
{
	_internalDragData=nil;
}

- (BOOL)tableView:(NSTableView *)inTableView writeRowsWithIndexes:(NSIndexSet *)inRowIndexes toPasteboard:(NSPasteboard *)inPasteboard;
{
	_internalDragData=inRowIndexes;
	
	[inPasteboard declareTypes:@[PKGInstallationTypeChoiceRequirementsInternalPboardType,PKGInstallationTypeChoiceRequirementsTransferPboardType] owner:self];		// Make the external drag a promised case since it will be less usual IMHO
	
	[inPasteboard setData:[NSData data] forType:PKGInstallationTypeChoiceRequirementsInternalPboardType];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)inTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)inRow proposedDropOperation:(NSTableViewDropOperation)inDropOperation
{
	if (inDropOperation==NSTableViewDropOn)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	// Internal Drag
	
	if ([tPasteBoard availableTypeFromArray:@[PKGInstallationTypeChoiceRequirementsInternalPboardType]]!=nil && [info draggingSource]==inTableView)
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
	
	// External Drag and Drop
	
	if ([tPasteBoard availableTypeFromArray:@[PKGInstallationTypeChoiceRequirementsTransferPboardType]]!=nil)
	{
		if (inDropOperation!=NSTableViewDropAbove)
			return NSDragOperationNone;
		
		if (_requirements.count==0)
			[inTableView setDropRow:-1 dropOperation:NSTableViewDropOn];

		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)inTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)inRow dropOperation:(NSTableViewDropOperation)inDropOperation
{
	if (inTableView==nil)
		return NO;
	
	// Internal drag and drop
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[PKGInstallationTypeChoiceRequirementsInternalPboardType]]!=nil && [info draggingSource]==inTableView)
	{
		NSArray * tObjects=[_requirements objectsAtIndexes:_internalDragData];
		
		[_requirements removeObjectsAtIndexes:_internalDragData];
		
		NSUInteger tIndex=[_internalDragData firstIndex];
		
		while (tIndex!=NSNotFound)
		{
			if (tIndex<inRow)
				inRow--;
			
			tIndex=[_internalDragData indexGreaterThanIndex:tIndex];
		}
		
		NSIndexSet * tNewIndexSet=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inRow, _internalDragData.count)];
		
		[_requirements insertObjects:tObjects atIndexes:tNewIndexSet];
		
		[inTableView deselectAll:nil];
		
		[self.delegate requirementsDataDidChange:self];
		
		[inTableView reloadData];
		
		[inTableView selectRowIndexes:tNewIndexSet
				 byExtendingSelection:NO];
		
		return YES;
	}
	
	// External Drag and Drop
	
	if ([tPasteBoard availableTypeFromArray:@[PKGInstallationTypeChoiceRequirementsTransferPboardType]]!=nil)
	{
		NSArray * tObjects=(NSArray *) [tPasteBoard propertyListForType:PKGInstallationTypeChoiceRequirementsTransferPboardType];
		
		NSArray * tNewRequirements=[tObjects WB_arrayByMappingObjectsUsingBlock:^PKGRequirement *(NSDictionary * bRequirementRepresentation, NSUInteger bIndex) {
			
			NSError * tError=nil;
			
			PKGRequirement * tNewRequirement=[[PKGRequirement alloc] initWithRepresentation:bRequirementRepresentation error:&tError];
			
			if (tNewRequirement==nil)
			{
				if (tError!=nil)
				{
					// A COMPLETER
				}
				
				return nil;
			}
			
			Class tPluginUIClass=[[PKGRequirementPluginsManager defaultManager] pluginUIClassForIdentifier:tNewRequirement.identifier];
			
			NSDictionary * tSettingsRepresenation=[tPluginUIClass performSelector:@selector(dictionaryFromPasteboardDictionary:converter:) withObject:tNewRequirement.settingsRepresentation withObject:self.filePathConverter];
			
			if (self->_choiceItem.options.isHidden==YES)
				tNewRequirement.failureBehavior=PKGRequirementOnFailureBehaviorDeselectAndDisableChoice;
			
			tNewRequirement.settingsRepresentation=tSettingsRepresenation;
			
			return tNewRequirement;
		}];
		
		if (tNewRequirements==nil)
			return NO;
		
		if (inRow==-1)
			inRow=_requirements.count;
		
		NSIndexSet * tIndexSet=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inRow,tNewRequirements.count)];
		
		[_requirements insertObjects:tNewRequirements atIndexes:tIndexSet];
		
		[inTableView deselectAll:nil];
		
		[self.delegate requirementsDataDidChange:self];
		
		[inTableView reloadData];
		
		[inTableView selectRowIndexes:tIndexSet
				 byExtendingSelection:NO];
		
		return YES;
	}
	
	return NO;
}

#pragma mark -

- (void)tableView:(NSTableView *)inTableView addNewRequirementWithCompletionHandler:(void(^)(BOOL succeeded))handler
{
	PKGRequirement * tNewRequirement=[PKGRequirement new];
	
	tNewRequirement.identifier=@"fr.whitebox.Packages.requirement.os";
	tNewRequirement.failureBehavior=PKGRequirementOnFailureBehaviorDeselectAndHideChoice;
	
	PKGPresentationChoiceRequirementPanel * tRequirementPanel=[PKGPresentationChoiceRequirementPanel choiceRequirementPanel];
	tRequirementPanel.prompt=NSLocalizedString(@"Add", @"");
	tRequirementPanel.requirement=tNewRequirement;
	
	[tRequirementPanel beginSheetModalForWindow:inTableView.window completionHandler:^(NSInteger bResult) {
		
		if (bResult==PKGPanelCancelButton)
			return;
		
		NSString * tBaseName=[[PKGRequirementPluginsManager defaultManager] localizedPluginNameForIdentifier:tNewRequirement.identifier];
		
		tNewRequirement.name=[self->_requirements uniqueNameWithBaseName:tBaseName usingNameExtractor:^NSString *(PKGRequirement * bRequirement,NSUInteger bIndex) {
			
			return bRequirement.name;
		}];
		
		if (tNewRequirement.name==nil)
		{
			NSLog(@"Could not determine a unique name for the requirement");
			
			tNewRequirement.name=@"";
		}
		
		[self tableView:inTableView addRequirement:tNewRequirement completionHandler:handler];
	}];
}

- (void)editRequirement:(NSTableView *)inTableView
{
	NSUInteger tIndex=inTableView.WB_selectedOrClickedRowIndexes.firstIndex;
	if (tIndex==NSNotFound)	// Double-click with no requirements in list for example
		return;
	
	PKGRequirement * tOriginalRequirement=_requirements[tIndex];
	PKGRequirement * tEditedRequirement=[tOriginalRequirement copy];
	
	PKGPresentationChoiceRequirementPanel * tRequirementPanel=[PKGPresentationChoiceRequirementPanel choiceRequirementPanel];
	
	tRequirementPanel.requirement=tEditedRequirement;
	
	[tRequirementPanel beginSheetModalForWindow:inTableView.window completionHandler:^(NSInteger bResult) {
		
		if (bResult==PKGPanelCancelButton)
			return;
		
		if ([tEditedRequirement isEqualToRequirement:tOriginalRequirement]==YES)
			return;
		
		NSUInteger tIndex=[self->_requirements indexOfObjectIdenticalTo:tOriginalRequirement];
		
		if (tIndex==NSNotFound)
			return;
		
		[self->_requirements replaceObjectAtIndex:tIndex withObject:tEditedRequirement];
			
		[self.delegate requirementsDataDidChange:self];
	}];
}

- (void)tableView:(NSTableView *)inTableView setItem:(PKGRequirement *)inRequirementItem state:(BOOL)inState
{
	if (inTableView==nil || inRequirementItem==nil)
		return;
	
	if (inRequirementItem.isEnabled==inState)
		return;
	
	inRequirementItem.enabled=inState;
	
	[self.delegate requirementsDataDidChange:self];
}

#pragma mark -

- (id)itemAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=_requirements.count)
		return nil;
	
	return _requirements[inIndex];
}

- (NSArray *)itemsAtIndexes:(NSIndexSet *)inIndexSet
{
	return [_requirements objectsAtIndexes:inIndexSet];
}

- (NSInteger)rowForItem:(id)inItem
{
	if (inItem==nil)
		return -1;
	
	NSUInteger tIndex=[_requirements indexOfObject:inItem];
	
	return (tIndex==NSNotFound) ? -1 : tIndex;
}

- (void)tableView:(NSTableView *)inTableView addRequirement:(PKGRequirement *)inRequirement completionHandler:(void(^)(BOOL))handler
{
	if (inRequirement==nil)
		return;
	
	[self tableView:inTableView addRequirements:@[inRequirement] completionHandler:handler];
}

- (void)tableView:(NSTableView *)inTableView addRequirements:(NSArray *)inRequirements completionHandler:(void(^)(BOOL))handler
{
	if (inTableView==nil || inRequirements.count==0)
	{
		if (handler!=nil)
			handler(NO);
		
		return;
	}
	
	NSMutableSet * tMutableSet=[NSMutableSet set];
	
	for(PKGRequirement * tRequirement in inRequirements)
	{
		if ([_requirements containsObject:tRequirement]==YES)
		{
			// A COMPLETER
			
			continue;
		}
		
		[_requirements addObject:tRequirement];
		
		[tMutableSet addObject:tRequirement];
	}
	
	if (tMutableSet.count==0)
	{
		if (handler!=nil)
			handler(NO);
		
		return;
	}
	
	[inTableView reloadData];
	
	// Post Notification
	
	[self.delegate requirementsDataDidChange:self];
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	for(PKGRequirement * tRequirement in tMutableSet)
	{
		NSInteger tSelectedRow=[self rowForItem:tRequirement];
		
		if (tSelectedRow==-1)
			tSelectedRow=0;
		
		[tMutableIndexSet addIndex:tSelectedRow];
	}
	
	[inTableView scrollRowToVisible:(tMutableIndexSet.firstIndex==NSNotFound) ? 0 : tMutableIndexSet.firstIndex];
	
	[inTableView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
	
	if (handler!=nil)
		handler(YES);
}

- (BOOL)tableView:(NSTableView *)inTableView shouldRenameRequirement:(PKGRequirement *)inRequirement as:(NSString *)inNewName
{
	if (inTableView==nil || inRequirement==nil || inNewName==nil)
		return NO;
	
	NSString * tName=inRequirement.name;
	
	if ([tName compare:inNewName]==NSOrderedSame)
		return NO;
	
	if ([tName caseInsensitiveCompare:inNewName]!=NSOrderedSame)
	{
		NSUInteger tLength=inNewName.length;
		NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[_requirements indexOfObjectIdenticalTo:inRequirement]];
		NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[inTableView columnWithIdentifier:@"requirement"]];
		
		if (tLength==0)
		{
			[inTableView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)tableView:(NSTableView *)inTableView renameRequirement:(PKGRequirement *)inRequirement as:(NSString *)inNewName
{
	if (inTableView==nil || inRequirement==nil || inNewName==nil)
		return NO;
	
	inRequirement.name=inNewName;
	
	[inTableView reloadData];
	
	[self.delegate requirementsDataDidChange:self];
	
	return YES;
}

- (void)tableView:(NSTableView *)inTableView duplicateItems:(NSArray *)inItems
{
	if (inTableView==nil || inItems.count==0)
		return;
	
	__block NSMutableArray * tTemporaryComponents=[_requirements mutableCopy];
	
	NSArray * tDuplicatedPackageComponents=[inItems WB_arrayByMappingObjectsLenientlyUsingBlock:^PKGRequirement *(PKGRequirement * bOriginalRequirement, NSUInteger bIndex) {
		
		PKGRequirement * tNewRequirement=[bOriginalRequirement copy];
		
		// Unique Name
		
		NSString * tBaseName=[tNewRequirement.name PKG_baseName];
		
		NSString * tNewName=[tTemporaryComponents uniqueNameWithBaseName:[tBaseName stringByAppendingString:NSLocalizedString(@" copy", @"")]
													  usingNameExtractor:^NSString *(PKGRequirement * bRequirement, NSUInteger bIndex) {
														  return bRequirement.name;
													  }];
		
		if (tNewName!=nil)
			tNewRequirement.name=tNewName;
		
		
		[tTemporaryComponents addObject:tNewRequirement];
		
		return tNewRequirement;
	}];
	
	[self tableView:inTableView addRequirements:tDuplicatedPackageComponents completionHandler:nil];
}

- (void)tableView:(NSTableView *)inTableView removeItems:(NSArray *)inItems
{
	if (inTableView==nil || inItems.count==0)
		return;
	
	// Remove the requirements
	
	[_requirements removeObjectsInArray:inItems];
	
	[inTableView deselectAll:nil];
	
	[inTableView reloadData];
	
	[self.delegate requirementsDataDidChange:self];
}

@end
