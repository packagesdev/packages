/*
 Copyright (c) 2017-2019, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadFilesHierarchyViewController.h"

#import "PKGPackagePayloadDataSource.h"

#import "PKGPayloadTreeNode+UI.h"

#import "NSTableView+Selection.h"

#import "PKGApplicationPreferences.h"

NSString * const PKGFileNameColumnIdentifier=@"file.name";

@interface PKGPayloadFilesHierarchyViewController ()

- (IBAction)editDestinationName:(id)sender;

- (IBAction)resetDestinationName:(id)sender;

@end

@implementation PKGPayloadFilesHierarchyViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// Add menu items
	
	[self.outlineView.menu addItem:[NSMenuItem separatorItem]];
	
	NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Show Hidden Folders", @"") action:NSSelectorFromString(@"switchHiddenFolderTemplatesVisibility:") keyEquivalent:@""];
	[self.outlineView.menu addItem:tMenuItem];
	
	[self.outlineView.menu addItem:[NSMenuItem separatorItem]];
	
	tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Set as Default Location", @"") action:NSSelectorFromString(@"setDefaultDestination:") keyEquivalent:@""];
	
	[self.outlineView.menu addItem:tMenuItem];
	
	
	tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Set Destination Name", @"") action:@selector(editDestinationName:) keyEquivalent:@""];
	
	[self.outlineView.menu addItem:tMenuItem];
	
	tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reset Destination Name", @"") action:@selector(resetDestinationName:) keyEquivalent:@""];
	
	[self.outlineView.menu addItem:tMenuItem];
	
	
}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldDeleteItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems==nil)
		return NO;
	
	NSArray * tMinimumCover=[PKGTreeNode minimumNodeCoverFromNodesInArray:inItems];
	
	if (tMinimumCover.count==0)
		return NO;
	
	PKGPackagePayloadDataSource * tDataSource=(PKGPackagePayloadDataSource *) self.hierarchyDataSource;
	
	for(PKGPayloadTreeNode * tTreeNode in tMinimumCover)
	{
		if ([tTreeNode isTemplateNode]==YES)
			return NO;
		
		if (tTreeNode==tDataSource.installLocationNode)
			return NO;
		
		if ([tDataSource.installLocationNode isDescendantOfNode:tTreeNode]==YES)
			return NO;
	}
	
	return YES;
}

#pragma mark -

- (void)showHiddenFolderTemplates
{
	[((PKGPackagePayloadDataSource *) self.hierarchyDataSource) outlineView:self.outlineView showHiddenFolderTemplates:YES];
}

- (void)hideHiddenFolderTemplates
{
	[((PKGPackagePayloadDataSource *) self.hierarchyDataSource) outlineView:self.outlineView showHiddenFolderTemplates:NO];
}

#pragma mark -

- (IBAction)editDestinationName:(id)sender
{
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	NSInteger tSelectedCount=tSelectionIndexSet.count;
	
	if (tSelectedCount!=1)
		return;
	
	PKGPayloadTreeNode * tPayloadTreeNode=[self.outlineView itemAtRow:tSelectionIndexSet.firstIndex];
	
	if ([tPayloadTreeNode isFileSystemItemNode]==NO)
		return;
	
	NSInteger tClickedRow=self.outlineView.clickedRow;
	
	// Selection is not empty and no row was clicked
	
	if (tSelectionIndexSet.count>0 && tClickedRow==-1)
		tClickedRow=tSelectionIndexSet.firstIndex;
	
	if ([((PKGPackagePayloadDataSource *) self.hierarchyDataSource) outlineView:self.outlineView editDestinationNameForItem:tPayloadTreeNode]==NO)
		return;
	
	NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:tClickedRow];
	NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView columnWithIdentifier:PKGFileNameColumnIdentifier]];
	
	[self.outlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
	
	// Enter edition mode
	
	NSIndexSet * tSelectedRowIndexes=[self.outlineView selectedRowIndexes];
	
	if ([tSelectedRowIndexes containsIndex:tClickedRow]==YES)	// In order to refresh the Inspector (and make the Name: text field editable)
		[self.outlineView deselectAll:self];
	
	[self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tClickedRow] byExtendingSelection:NO];
		
	[self.outlineView editColumn:[self.outlineView columnWithIdentifier:PKGFileNameColumnIdentifier] row:tClickedRow withEvent:nil select:YES];
}

- (IBAction)resetDestinationName:(id)sender
{
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	NSInteger tSelectedCount=tSelectionIndexSet.count;
	
	if (tSelectedCount!=1)
		return;
	
	PKGPayloadTreeNode * tPayloadTreeNode=[self.outlineView itemAtRow:tSelectionIndexSet.firstIndex];
	
	if ([tPayloadTreeNode isFileSystemItemNode]==NO)
		return;
	
	NSInteger tClickedRow=self.outlineView.clickedRow;
	
	// Selection is not empty and no row was clicked
	
	if (tSelectionIndexSet.count>0 && tClickedRow==-1)
		tClickedRow=tSelectionIndexSet.firstIndex;
	
	PKGFileItem * tFileItem=[tPayloadTreeNode representedObject];
	
	
	NSString * tOriginalFileName=tFileItem.filePath.string.lastPathComponent;
	
	if ([tPayloadTreeNode.fileName compare:tOriginalFileName]!=NSOrderedSame)
	{
		// We rename it to its original name first
		// This prevents reverting to the original name if it's not possible (another item now is named like this)
		// This ensures the item will be moved to the appropriate location in the hierarchy
		
		if ([self.hierarchyDataSource outlineView:self.outlineView shouldRenameNewFolder:tPayloadTreeNode as:tOriginalFileName]==NO)
		{
			NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:tClickedRow];
			NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView columnWithIdentifier:PKGFileNameColumnIdentifier]];
			
			[self.outlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
			
			return;
		}
		
		if ([self.hierarchyDataSource outlineView:self.outlineView renameItem:tPayloadTreeNode as:tOriginalFileName]==YES)
			[[NSNotificationCenter defaultCenter] postNotificationName:PKGFilesHierarchyDidRenameItemNotification object:self.outlineView userInfo:@{@"NSObject":tPayloadTreeNode}];
		
		tClickedRow=[self.outlineView rowForItem:tPayloadTreeNode];
	}
	
	if ([((PKGPackagePayloadDataSource *) self.hierarchyDataSource) outlineView:self.outlineView resetDestinationNameForItem:tPayloadTreeNode]==NO)
		return;
	
	NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView rowForItem:tPayloadTreeNode]];
	NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView columnWithIdentifier:PKGFileNameColumnIdentifier]];
	
	[self.outlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
	
	NSIndexSet * tSelectedRowIndexes=[self.outlineView selectedRowIndexes];
	
	if ([tSelectedRowIndexes containsIndex:tClickedRow]==YES)	// In order to refresh the Inspector (and make the Name: text field editable)
	{
		[self.outlineView deselectAll:self];
	
		[self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tClickedRow] byExtendingSelection:NO];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tSelector=inMenuItem.action;
	
	if (tSelector==@selector(editDestinationName:) || tSelector==@selector(resetDestinationName:))
	{
		inMenuItem.hidden=YES;
		
		if (tSelector==@selector(editDestinationName:) && [PKGApplicationPreferences sharedPreferences].advancedMode==NO)
			return NO;
		
		NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
		
		NSInteger tSelectedCount=tSelectionIndexSet.count;
		
		if (tSelectedCount!=1)
			return NO;
		
		PKGPayloadTreeNode * tPayloadTreeNode=[self.outlineView itemAtRow:tSelectionIndexSet.firstIndex];
		
		if ([tPayloadTreeNode isFileSystemItemNode]==NO)
			return NO;
		
		PKGFileItem * tFileItem=tPayloadTreeNode.representedObject;
		
		if (tSelector==@selector(editDestinationName:))
		{
			if (tFileItem.payloadFileName!=nil)
				return NO;
			
			inMenuItem.hidden=NO;
		}
		else if (tSelector==@selector(resetDestinationName:))
		{
			if (tFileItem.payloadFileName==nil)
				return NO;
			
			inMenuItem.hidden=NO;
		}
		
		return YES;
	}
	
	return [super validateMenuItem:inMenuItem];
}

#pragma mark -

- (NSIndexSet *)outlineView:(NSOutlineView *)inOutlineView selectionIndexesForProposedSelection:(NSIndexSet *)inProposedSelectionIndexes
{
	if (self.outlineView!=inOutlineView || inProposedSelectionIndexes.count!=1)
		return inProposedSelectionIndexes;
	
	[((PKGPackagePayloadDataSource *) self.hierarchyDataSource) outlineView:self.outlineView transformItemIfNeeded:[inOutlineView itemAtRow:inProposedSelectionIndexes.firstIndex]];
	
	return inProposedSelectionIndexes;
}

@end
