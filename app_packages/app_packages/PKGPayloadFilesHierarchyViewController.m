/*
 Copyright (c) 2017, Stephane Sudre
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

@interface PKGPayloadFilesHierarchyViewController ()

- (IBAction)setInstallationLocation:(id)sender;

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

- (IBAction)setInstallationLocation:(id)sender
{
	// A COMPLETER
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tSelector=inMenuItem.action;
	
	// A COMPLETER
	
	if ([super validateMenuItem:inMenuItem]==NO)
		return NO;
	
	return YES;
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
