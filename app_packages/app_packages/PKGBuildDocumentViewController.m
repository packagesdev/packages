/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildDocumentViewController.h"

#import "PKGBuildEventTreeNode.h"

@interface PKGBuildDocumentViewController () <NSOutlineViewDelegate>

	@property (readwrite) IBOutlet NSOutlineView * outlineView;

@end

@implementation PKGBuildDocumentViewController


#pragma mark - PKGBuildAndCleanObserverDataSourceDelegate

- (void)buildAndCleanObserverDataSource:(PKGBuildAndCleanObserverDataSource *)inBuildAndCleanObserverDataSource shouldReloadDataAndExpandItem:(id)inItem
{
	[self.outlineView reloadData];
	
	if (inItem!=nil)
		[self.outlineView expandItem:inItem];
}

- (void)buildAndCleanObserverDataSource:(PKGBuildAndCleanObserverDataSource *)inBuildAndCleanObserverDataSource shouldReloadDataAndCollapseItem:(id)inItem
{
	[self.outlineView reloadData];
	
	if (inItem!=nil)
		[self.outlineView collapseItem:inItem];
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(PKGBuildEventTreeNode *)inBuildEventTreeNode
{
	if (inOutlineView!=self.outlineView || inBuildEventTreeNode==nil)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	NSTableCellView * tTableCellView=[inOutlineView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	PKGBuildEventItem * tBuildEventItem=[inBuildEventTreeNode representedObject];
	
	tTableCellView.textField.stringValue=tBuildEventItem.title;
	
	return tTableCellView;
}

- (CGFloat)outlineView:(NSOutlineView *) inOutlineView heightOfRowByItem:(PKGBuildEventTreeNode *)inBuildEventTreeNode
{
	if (inOutlineView!=self.outlineView)
		return 17.0;
	
	PKGBuildEventItem * tBuildEventItem=[inBuildEventTreeNode representedObject];
	
	switch(tBuildEventItem.type)
	{
		case PKGBuildEventItemProject:
		case PKGBuildEventItemDistributionScript:
		case PKGBuildEventItemDistributionPackageProject:
		case PKGBuildEventItemDistributionPackage:
		case PKGBuildEventItemPackage:
			
			return 34.0;
			
		case PKGBuildEventItemStep:
		case PKGBuildEventItemStepParent:
		case PKGBuildEventItemErrorDescription:
		case PKGBuildEventItemWarningDescription:
			
			return 15.0;
			
		case PKGBuildEventItemConclusion:
			
			return 40.0;
	}
}

@end
