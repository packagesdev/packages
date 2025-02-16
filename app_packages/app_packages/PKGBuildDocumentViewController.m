/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildDocumentViewController.h"

#import "PKGBuildEventTreeNode.h"
#import "PKGBuildEventItem+UI.h"

#import "PKGBuildSubtitledTableRowView.h"
#import "PKGConclusionTableRowView.h"

#import "PKGBuildSubtitledTableCellView.h"



#import "PKGInstallerApp.h"

@interface PKGBuildDocumentViewController () <NSOutlineViewDelegate>
{
	IBOutlet NSTextField * _statusLabel;
}

	@property (readwrite) IBOutlet NSOutlineView * outlineView;

@end

@implementation PKGBuildDocumentViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	self.outlineView.gridColor=self.outlineView.backgroundColor;
	
	self.outlineView.autoresizesOutlineColumn=NO;
}

#pragma mark - Copy

- (IBAction)copy:(id)sender
{
	NSInteger tSelectedRow=self.outlineView.selectedRow;
	
	if (tSelectedRow==-1)
		return;
	
	PKGBuildEventTreeNode * BuildEventTreeNode=[self.outlineView itemAtRow:tSelectedRow];
	
	PKGBuildEventItem * tBuildEventItem=[BuildEventTreeNode representedObject];
	
	NSPasteboard *tPasteboard = [NSPasteboard generalPasteboard];
	
	NSMutableString * tMutableString=[NSMutableString stringWithString:(tBuildEventItem.title!=nil) ? tBuildEventItem.title : @""];
	
	if (tBuildEventItem.subTitle!=nil)
		[tMutableString appendFormat:@"\n%@",tBuildEventItem.subTitle];
	
	
	[tPasteboard declareTypes:@[WBPasteboardTypeString] owner:nil];
	[tPasteboard setString:[NSString stringWithString:tMutableString] forType:WBPasteboardTypeString];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(copy:))
		return (self.outlineView.selectedRow!=-1);
	
	return YES;
}

#pragma mark - PKGBuildAndCleanObserverDataSourceDelegate

- (void)buildAndCleanObserverDataSource:(PKGBuildAndCleanObserverDataSource *)inBuildAndCleanObserverDataSource shouldReloadDataAndExpandItem:(id)inItem
{
	NSString * tStatusDescription=inBuildAndCleanObserverDataSource.statusDescription;
	
	_statusLabel.stringValue=(tStatusDescription!=nil) ? tStatusDescription : @"";
	
	[self.outlineView reloadData];
	
	if (inItem!=nil)
		[self.outlineView expandItem:inItem];
}

- (void)buildAndCleanObserverDataSource:(PKGBuildAndCleanObserverDataSource *)inBuildAndCleanObserverDataSource shouldReloadDataAndCollapseItem:(id)inItem
{
	NSString * tStatusDescription=inBuildAndCleanObserverDataSource.statusDescription;
	
	_statusLabel.stringValue=(tStatusDescription!=nil) ? tStatusDescription : @"";
	
	[self.outlineView reloadData];
	
	if (inItem!=nil)
		[self.outlineView collapseItem:inItem];
}

#pragma mark - NSOutlineViewDelegate

- (NSTableRowView *)outlineView:(NSOutlineView *)inOutlineView rowViewForItem:(PKGBuildEventTreeNode *)inBuildEventTreeNode
{
	if (inOutlineView!=self.outlineView || inBuildEventTreeNode==nil)
		return nil;
	
	PKGBuildEventItem * tBuildEventItem=[inBuildEventTreeNode representedObject];
	
	switch(tBuildEventItem.type)
	{
		case PKGBuildEventItemProject:
		case PKGBuildEventItemDistributionScript:
		case PKGBuildEventItemDistributionPackageProject:
		case PKGBuildEventItemDistributionPackage:
		case PKGBuildEventItemPackage:
		{
			PKGBuildSubtitledTableRowView * tTableRowView=[inOutlineView makeViewWithIdentifier:PKGBuildSubtitledTableRowViewIdentifier owner:self];
			
			if (tTableRowView==nil)
			{
				tTableRowView=[[PKGBuildSubtitledTableRowView alloc] initWithFrame:NSZeroRect];
				tTableRowView.identifier=PKGBuildSubtitledTableRowViewIdentifier;
			}
			
			return tTableRowView;
		}
			
		case PKGBuildEventItemConclusion:
		{
			PKGConclusionTableRowView * tTableRowView=[inOutlineView makeViewWithIdentifier:PKGConclusionTableRowViewIdentifier owner:self];
			
			if (tTableRowView==nil)
			{
				tTableRowView=[[PKGConclusionTableRowView alloc] initWithFrame:NSZeroRect];
				tTableRowView.identifier=PKGConclusionTableRowViewIdentifier;
			}
			
			tTableRowView.state=tBuildEventItem.state;
			
			return tTableRowView;
		}
			
		default:
			
			return nil;
	}
	
	return nil;
}

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(PKGBuildEventTreeNode *)inBuildEventTreeNode
{
	if (inOutlineView!=self.outlineView || inBuildEventTreeNode==nil)
		return nil;
	
	PKGBuildEventItem * tBuildEventItem=[inBuildEventTreeNode representedObject];
	
	switch(tBuildEventItem.type)
	{
		case PKGBuildEventItemProject:
		case PKGBuildEventItemDistributionScript:
		case PKGBuildEventItemDistributionPackageProject:
		case PKGBuildEventItemDistributionPackage:
		case PKGBuildEventItemPackage:
		{
			PKGBuildSubtitledTableCellView* tTableCellView=[inOutlineView makeViewWithIdentifier:@"subtitledCell" owner:self];
		
			// Icon
			
			NSImage * tStepIcon=nil;
			NSImage * tStepStatusIcon=nil;
			
			switch(tBuildEventItem.type)
			{
				case PKGBuildEventItemProject:
					
					tStepIcon=[[PKGInstallerApp installerApp] iconForPackageType:self.dataSource.packageType];
					
					break;
					
				case PKGBuildEventItemDistributionScript:
					
					tStepIcon=[NSImage imageNamed:@"XML_File_32"];
					
					break;
					
				case PKGBuildEventItemDistributionPackageProject:
				case PKGBuildEventItemDistributionPackage:
					
					tStepIcon=[[PKGInstallerApp installerApp] iconForPackageType:PKGInstallerAppRawPackage];
					
					break;
					
				default:
					
					break;
			}
			
			switch(tBuildEventItem.state)
			{
				case PKGBuildEventItemStateSuccess:
				case PKGBuildEventItemStateFailure:
				case PKGBuildEventItemStateWarning:
					
					tStepStatusIcon=[tBuildEventItem stateIcon];
					break;
				
				default:
					
					break;
			}
			
			tTableCellView.imageView.image=[NSImage imageWithSize:NSMakeSize(32.0,32.0) flipped:NO drawingHandler:^BOOL(NSRect bRect) {
				
				[tStepIcon drawInRect:bRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
				
				if (tStepStatusIcon==nil)
					return YES;
				
				NSRect tBadgeRect={
					.origin=NSZeroPoint,
					.size=tStepStatusIcon.size
				};
				
				[NSGraphicsContext saveGraphicsState];
				
				[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
				
				[tStepStatusIcon drawInRect:NSMakeRect(NSMaxX(bRect)-NSWidth(tBadgeRect),NSMinY(bRect),NSWidth(tBadgeRect),NSHeight(tBadgeRect)) fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
				
				[NSGraphicsContext restoreGraphicsState];
				
				return YES;
			}];
			
			tTableCellView.textField.stringValue=(tBuildEventItem.title!=nil) ? tBuildEventItem.title : @"";
			
			tTableCellView.subtitleTextField.stringValue=(tBuildEventItem.subTitle!=nil) ? tBuildEventItem.subTitle : @"";
			
			return tTableCellView;
		}
			
		case PKGBuildEventItemStep:
		case PKGBuildEventItemStepParent:
		{
			NSTableCellView * tTableCellView=[inOutlineView makeViewWithIdentifier:@"titledCell" owner:self];
			
			tTableCellView.imageView.image=[tBuildEventItem stateIcon];
			tTableCellView.textField.stringValue=(tBuildEventItem.title!=nil) ? tBuildEventItem.title : @"";
			tTableCellView.textField.textColor=[NSColor labelColor];
			
			return tTableCellView;
		}
			
		case PKGBuildEventItemErrorDescription:
		case PKGBuildEventItemWarningDescription:
		{
			NSTableCellView * tTableCellView=[inOutlineView makeViewWithIdentifier:@"titledCell" owner:self];
			
			tTableCellView.imageView.image=nil;
			tTableCellView.textField.stringValue=(tBuildEventItem.title!=nil) ? tBuildEventItem.title : @"";
			
			tTableCellView.textField.textColor=(tBuildEventItem.type==PKGBuildEventItemErrorDescription) ? [NSColor redColor] : [NSColor orangeColor];
			
			return tTableCellView;
		}
			
		case PKGBuildEventItemConclusion:
		{
			PKGBuildSubtitledTableCellView* tTableCellView=[inOutlineView makeViewWithIdentifier:@"conclusionCell" owner:self];
			
			switch (tBuildEventItem.state)
			{
				case PKGBuildEventItemStateSuccess:
					
					tTableCellView.imageView.image=[NSImage imageNamed:@"Conclusion_Success_32"];
					
					break;
					
				case PKGBuildEventItemStateFailure:
					
					tTableCellView.imageView.image=[NSImage imageNamed:@"Conclusion_Failure_32"];
					
					break;
					
				default:
					
					break;
			}
			
			tTableCellView.textField.stringValue=(tBuildEventItem.title!=nil) ? tBuildEventItem.title : @"";
			
			tTableCellView.subtitleTextField.stringValue=(tBuildEventItem.subTitle!=nil) ? tBuildEventItem.subTitle : @"";
			
			return tTableCellView;
		}
	}
	
	return nil;
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
			
			return 35.0;
			
		case PKGBuildEventItemStep:
		case PKGBuildEventItemStepParent:
			
			return 15.0;
			
		case PKGBuildEventItemErrorDescription:
		case PKGBuildEventItemWarningDescription:
			
			// A COMPLETER (we probably should handle variable height)
			
			return 15.0;
			
		case PKGBuildEventItemConclusion:
			
			return 40.0;
	}
}

@end
