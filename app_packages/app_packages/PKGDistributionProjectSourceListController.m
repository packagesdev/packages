/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectSourceListController.h"

#import "PKGDistributionProjectSourceListTreeNode.h"

#import "PKGDistributionProjectSourceListProjectItem.h"
#import "PKGDistributionProjectSourceListGroupItem.h"
#import "PKGDistributionProjectSourceListPackageComponentItem.h"

#import "NSOutlineView+Selection.h"
#import "NSAlert+block.h"

#import "PKGPackageComponent+UI.h"

#import "PKGDocumentWindowController.h"

#import "PKGEvent.h"

#import "PKGProjectNameFormatter.h"

@interface PKGDistributionProjectSourceListController () <NSOutlineViewDelegate,NSTextFieldDelegate>
{
	IBOutlet NSView * _sourceListAuxiliaryView;
	
	IBOutlet NSButton * _addButton;
	
	PKGProjectNameFormatter * _cachedProjectNameFormatter;
}

	@property IBOutlet NSMenu * contextualMenu;

- (IBAction)showInFinder:(id)sender;
- (IBAction)duplicate:(id)sender;

- (IBAction)exportPackageAsProject:(id)sender;

- (IBAction)showProject:(id)sender;

- (IBAction)addPackage:(id)sender;

- (IBAction)addPackageReference:(id)sender;

- (IBAction)importPackage:(id)sender;

// Notifications

- (void)optionKeyDidChange:(NSNotification *)inNotification;

@end

@implementation PKGDistributionProjectSourceListController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		_cachedProjectNameFormatter=[PKGProjectNameFormatter new];
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
    [super WB_viewDidLoad];
	
	[self.outlineView registerForDraggedTypes:[PKGDistributionProjectSourceListDataSource supportedDraggedTypes]];
	
	// A COMPLETER
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	self.outlineView.dataSource=self.dataSource;
	
	
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	NSView * tLeftAccessoryView=((PKGDocumentWindowController *) self.view.window.windowController).leftAccessoryView;
	
	_sourceListAuxiliaryView.frame=tLeftAccessoryView.bounds;
	
	[tLeftAccessoryView addSubview:_sourceListAuxiliaryView];
	
	[self.outlineView reloadData];
	
	[self.outlineView expandItem:nil expandChildren:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionKeyDidChange:) name:PKGOptionKeyDidChangeStateNotification object:self.view.window];
	
	// A COMPLETER
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_sourceListAuxiliaryView removeFromSuperview];
	
	// A COMPLETER
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	// A COMPLETER
}

#pragma mark -

- (void)setDataSource:(id<NSOutlineViewDataSource>)inDataSource
{
	_dataSource=inDataSource;
	_dataSource.delegate=self;
	
	if (self.outlineView!=nil)
		self.outlineView.dataSource=_dataSource;
}

#pragma mark - Contextual Menu

- (IBAction)showInFinder:(id)sender
{
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
	
	[tSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
		
		PKGDistributionProjectSourceListTreeNode * tSourceListTreeNode=[self.outlineView itemAtRow:bIndex];
		PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem=tSourceListTreeNode.representedObject;
		
		[tSharedWorkspace selectFile:[tPackageComponentItem.packageComponent referencedPathUsingConverter:self.filePathConverter] inFileViewerRootedAtPath:@""];
	}];
}

- (IBAction)duplicate:(id)sender
{
	NSIndexSet * tIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	[self.dataSource outlineView:self.outlineView duplicateItems:[self.outlineView WB_itemsAtRowIndexes:tIndexSet]];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this package?",@"No comment") : NSLocalizedString(@"Do you really want to remove these packages?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert WB_beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self.dataSource outlineView:self.outlineView removeItems:[self.outlineView WB_itemsAtRowIndexes:tIndexSet]];
	}];
}

- (IBAction)exportPackageAsProject:(id)sender
{
	NSSavePanel * tExportPanel=[NSSavePanel savePanel];
	
	// A COMPLETER
	
	tExportPanel.prompt=NSLocalizedString(@"Export", @"");
	
	[tExportPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult!=NSFileHandlingPanelOKButton)
			return;

		// A COMPLETER
	}];
}

#pragma mark -

- (IBAction)showProject:(id)sender
{
	[self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (IBAction)addPackage:(id)sender
{
	[self.dataSource addProjectPackageComponent:self.outlineView];
}

- (IBAction)addPackageReference:(id)sender
{
	[self.dataSource addReferencePackageComponent:self.outlineView];
}

- (IBAction)importPackage:(id)sender
{
	[self.dataSource importPackageComponent:self.outlineView];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	typedef BOOL (^packageComponentItemFilter)(PKGDistributionProjectSourceListPackageComponentItem *);
	
	BOOL (^validateSelection)(NSIndexSet *,packageComponentItemFilter) = ^BOOL(NSIndexSet * bSelectionIndex,packageComponentItemFilter bFilter)
	{
		__block BOOL tValidationFailed=NO;
		
		[bSelectionIndex enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
			
			PKGDistributionProjectSourceListTreeNode * tSourceListTreeNode=[self.outlineView itemAtRow:bIndex];
			PKGDistributionProjectSourceListPackageComponentItem * tSourceListItem=tSourceListTreeNode.representedObject;
			
			if ([tSourceListItem isKindOfClass:PKGDistributionProjectSourceListPackageComponentItem.class]==NO)
			{
				tValidationFailed=YES;
				*bOutStop=YES;
				return;
			}
			
			if (bFilter!=nil && bFilter(tSourceListItem)==NO)
			{
				tValidationFailed=YES;
				*bOutStop=YES;
				return;
			}
		}];
		
		return (tValidationFailed==NO);
	};
	
	if (tAction==@selector(showInFinder:))
	{
		return validateSelection(tSelectionIndexSet,^BOOL(PKGDistributionProjectSourceListPackageComponentItem * bPackageComponentItem){
		
			return (bPackageComponentItem.packageComponent.type==PKGPackageComponentTypeImported);
		});
	}
	
	if (tAction==@selector(exportPackageAsProject:))
	{
		if (tSelectionIndexSet.count!=1)
			return NO;
		
		return validateSelection(tSelectionIndexSet,^BOOL(PKGDistributionProjectSourceListPackageComponentItem * bPackageComponentItem){
			
			return (bPackageComponentItem.packageComponent.type==PKGPackageComponentTypeProject);
		});
	}
	
	if (tAction==@selector(duplicate:))
	{
		return validateSelection(tSelectionIndexSet,^BOOL(PKGDistributionProjectSourceListPackageComponentItem * bPackageComponentItem){
			
			return (bPackageComponentItem.packageComponent.type==PKGPackageComponentTypeProject);
		});
	}
	
	if (tAction==@selector(delete:))
	{
		return validateSelection(tSelectionIndexSet,nil);
	}
	
	return YES;
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
	control.formatter=_cachedProjectNameFormatter;
	
	return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	control.formatter=nil;
	
	return YES;
}

- (void)control:(NSControl *)inControl didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)inError
{
	NSBeep();
}

- (void)controlTextDidEndEditing:(NSNotification *)inNotification
{
	NSTextField * tTextField=inNotification.object;
	
	if ([tTextField isKindOfClass:NSTextField.class]==NO)
		return;
	
	NSInteger tEditedRow=[self.outlineView rowForView:tTextField];
	
	if (tEditedRow==-1)
		return;
	
	PKGDistributionProjectSourceListTreeNode * tEditedNode=[self.outlineView itemAtRow:tEditedRow];
	
	if ([self.dataSource outlineView:self.outlineView shouldRenamePackageComponent:tEditedNode as:tTextField.stringValue]==NO)
	{
		NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView rowForItem:tEditedNode]];
		NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView columnWithIdentifier:@"sourcelist.name"]];
		
		[self.outlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
		
		return;
	}
	
	if ([self.dataSource outlineView:self.outlineView renamePackageComponent:tEditedNode as:tTextField.stringValue]==YES)
		;//[[NSNotificationCenter defaultCenter] postNotificationName:PKGFilesHierarchyDidRenameFolderNotification object:self.outlineView userInfo:@{@"NSObject":tEditedNode}];
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(PKGDistributionProjectSourceListTreeNode *)inSourceListTreeNode
{
	if (inOutlineView!=self.outlineView)
		return nil;
	
	PKGDistributionProjectSourceListItem * tSourceListItem=inSourceListTreeNode.representedObject;
		
	if ([tSourceListItem isKindOfClass:PKGDistributionProjectSourceListProjectItem.class]==YES)
	{
		NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"DataCell" owner:self];
		
		tView.imageView.image=tSourceListItem.icon;
		tView.textField.stringValue=tSourceListItem.label;
		tView.textField.delegate=nil;
		
		return tView;
	}
	
	if ([tSourceListItem isKindOfClass:PKGDistributionProjectSourceListGroupItem.class]==YES)
	{
		NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
		
		tView.textField.stringValue=tSourceListItem.label;
		tView.textField.controlSize=NSMiniControlSize;
		
		return tView;
	}
	
	if ([tSourceListItem isKindOfClass:PKGDistributionProjectSourceListPackageComponentItem.class]==YES)
	{
		NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"DataCell" owner:self];
		
		tView.imageView.image=tSourceListItem.icon;
		tView.textField.stringValue=tSourceListItem.label;
		tView.textField.editable=tSourceListItem.editable;
		tView.textField.delegate=self;
		
		return tView;
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isGroupItem:(PKGDistributionProjectSourceListTreeNode *)inSourceListTreeNode
{
	//return NO;
	
	if (inOutlineView!=self.outlineView)
		return nil;
	
	return ([inSourceListTreeNode.representedObject isKindOfClass:PKGDistributionProjectSourceListGroupItem.class]==YES);
}

- (NSIndexSet *)outlineView:(NSOutlineView *)inOutlineView selectionIndexesForProposedSelection:(NSIndexSet *)inProposedSelectionIndexes
{
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	[inProposedSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger bIndex,BOOL * bOutStop){
	
		PKGDistributionProjectSourceListTreeNode * tSourceListTreeNode=[inOutlineView itemAtRow:bIndex];
		
		PKGDistributionProjectSourceListItem * tSourceListItem=[tSourceListTreeNode representedObject];
		
		if ([tSourceListItem isKindOfClass:PKGDistributionProjectSourceListGroupItem.class]==YES)
			return;
		
		[tMutableIndexSet addIndex:bIndex];
	}];
	
	return [tMutableIndexSet copy];
}

/*- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldShowOutlineCellForItem:(PKGDistributionProjectSourceListTreeNode *)inSourceListTreeNode
{
	return NO;
}*/

#pragma mark - PKGDistributionProjectSourceListDataSourceDelegate

- (void)sourceListDataDidChange:(PKGDistributionProjectSourceListDataSource *)inSourceListDataSource
{
	[self noteDocumentHasChanged];
}

#pragma mark - Notifications

- (void)optionKeyDidChange:(NSNotification *)inNotification
{
	if (inNotification==nil)
		return;
	
	NSNumber * tNumber=inNotification.userInfo[PKGOptionKeyState];
	
	if (tNumber==nil)
		return;
	
	if ([tNumber boolValue]==YES)
	{
		_addButton.image=[NSImage imageNamed:@"packageReferenceAdd"];
		_addButton.action=@selector(addPackageReference:);
	}
	else
	{
		_addButton.image=[NSImage imageNamed:@"NSAddTemplate"];
		_addButton.action=@selector(addPackage:);
	}
}

@end
