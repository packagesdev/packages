/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectSettingsAdvancedOptionsViewController.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsTreeNode.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsItem.h"

#import "PKGTableGroupRowView.h"
#import "PKGCheckboxTableCellView.h"

#import "PKGDistributionProjectSettingsAdvancedOptionObject.h"
#import "PKGDistributionProjectSettingsAdvancedOptionHeader.h"
#import "PKGDistributionProjectSettingsAdvancedOptionBoolean.h"
#import "PKGDistributionProjectSettingsAdvancedOptionString.h"
#import "PKGDistributionProjectSettingsAdvancedOptionList.h"

#import "PKGAdvancedOptionPanel.h"

#import "PKGReplaceableStringFormatter.h"

NSString * const  PKGDistributionProjectSettingsAdvancedOptionsDisclosedStatesKey=@"ui.project.settings.options.advanced.disclosed";

@interface PKGDistributionProjectSettingsAdvancedOptionsViewController () <NSOutlineViewDelegate>
{
	IBOutlet NSTextField * _advancedOptionsLabel;
	
	BOOL _restoringDiscloseStates;
    
    PKGReplaceableStringFormatter * _cachedReplaceableFormatter;
}

	@property (readwrite) IBOutlet NSOutlineView * outlineView;

- (void)refreshHierarchy;

- (IBAction)setBooleanOptionValue:(id)sender;
- (IBAction)setStringOptionValue:(id)sender;
- (IBAction)setListOptionValue:(id)sender;

- (IBAction)editWithEditor:(id)sender;

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionsViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_advancedOptionsLabel.stringValue=NSLocalizedString(@"Advanced Options", @"");
	
	self.outlineView.doubleAction=@selector(editWithEditor:);
	self.outlineView.target=self;
    
    _cachedReplaceableFormatter=[PKGReplaceableStringFormatter new];
    _cachedReplaceableFormatter.keysReplacer=self;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	self.outlineView.dataSource=self.advancedOptionsDataSource;
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self refreshHierarchy];
}

- (void)refreshHierarchy
{
	[self.outlineView reloadData];
	
	[self restoreDisclosedStates];
}

#pragma mark -

- (IBAction)setBooleanOptionValue:(NSButton *)sender
{
	NSUInteger tEditedRow=[self.outlineView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGDistributionProjectSettingsAdvancedOptionsTreeNode * tAdvancedOptionsTreeNode=[self.outlineView itemAtRow:tEditedRow];
	PKGDistributionProjectSettingsAdvancedOptionsItem * tRepresentedObject=[tAdvancedOptionsTreeNode representedObject];
	
	NSNumber * tNewValue=@(sender.state==WBControlStateValueOn);
	
	if ([self.advancedOptionsSettings[tRepresentedObject.itemID] isEqual:tNewValue]==YES)
		return;
	
	self.advancedOptionsSettings[tRepresentedObject.itemID]=tNewValue;
	
	[self noteDocumentHasChanged];
}

- (IBAction)setStringOptionValue:(NSTextField *)sender
{
	NSUInteger tEditedRow=[self.outlineView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGDistributionProjectSettingsAdvancedOptionsTreeNode * tAdvancedOptionsTreeNode=[self.outlineView itemAtRow:tEditedRow];
	PKGDistributionProjectSettingsAdvancedOptionsItem * tRepresentedObject=[tAdvancedOptionsTreeNode representedObject];
	
	NSString * tNewValue=sender.objectValue;
	
	if (tNewValue.length==0)
		tNewValue=nil;
	
	if (self.advancedOptionsSettings[tRepresentedObject.itemID]==tNewValue)
		return;
	
	if ([self.advancedOptionsSettings[tRepresentedObject.itemID] isEqual:tNewValue]==YES)
		return;
	
	if (tNewValue==nil)
		[self.advancedOptionsSettings removeObjectForKey:tRepresentedObject.itemID];
	else
		self.advancedOptionsSettings[tRepresentedObject.itemID]=tNewValue;
	
	[self noteDocumentHasChanged];
}

- (IBAction)setListOptionValue:(NSTextField *)sender
{
	NSUInteger tEditedRow=[self.outlineView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGDistributionProjectSettingsAdvancedOptionsTreeNode * tAdvancedOptionsTreeNode=[self.outlineView itemAtRow:tEditedRow];
	PKGDistributionProjectSettingsAdvancedOptionsItem * tRepresentedObject=[tAdvancedOptionsTreeNode representedObject];
	
	NSArray * tNewValue=[sender.stringValue componentsSeparatedByString:@" "];
	
	if (tNewValue.count==0)
		tNewValue=nil;
	
	if (tNewValue.count==1 && ((NSString *)tNewValue.firstObject).length==0)
		tNewValue=nil;
	
	if (self.advancedOptionsSettings[tRepresentedObject.itemID]==tNewValue)
		return;
	
	if ([self.advancedOptionsSettings[tRepresentedObject.itemID] isEqual:tNewValue]==YES)
		return;
	
	if (tNewValue==nil)
		[self.advancedOptionsSettings removeObjectForKey:tRepresentedObject.itemID];
	else
		self.advancedOptionsSettings[tRepresentedObject.itemID]=tNewValue;
	
	[self noteDocumentHasChanged];
}

- (IBAction)editWithEditor:(id)sender
{
	NSUInteger tClickedColumn=self.outlineView.clickedColumn;
	
	if (tClickedColumn!=[self.outlineView columnWithIdentifier:@"advanced.key"])
		return;
	
	NSUInteger tClickedRow=self.outlineView.clickedRow;
	
	PKGDistributionProjectSettingsAdvancedOptionsTreeNode * tAdvancedOptionsTreeNode=[self.outlineView itemAtRow:tClickedRow];
	
	PKGDistributionProjectSettingsAdvancedOptionObject * tObject=[self.advancedOptionsDataSource advancedOptionsObjectForItem:tAdvancedOptionsTreeNode];
	
	if (tObject.supportsAdvancedEditor==NO)
		return;
	
	PKGDistributionProjectSettingsAdvancedOptionsItem * tRepresentedObject=[tAdvancedOptionsTreeNode representedObject];
	
	PKGAdvancedOptionPanel * tAdvancedOptionPanel=[PKGAdvancedOptionPanel advancedOptionPanel];
	
	tAdvancedOptionPanel.optionValue=self.advancedOptionsSettings[tRepresentedObject.itemID];
	tAdvancedOptionPanel.advancedOptionObject=tObject;
	
	[tAdvancedOptionPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult) {
		
		if (bResult==PKGPanelCancelButton)
			return;
		
		id tOptionValue=tAdvancedOptionPanel.optionValue;
		
		// Compare the old and new optionValue
		
		if (self.advancedOptionsSettings[tRepresentedObject.itemID]!=tOptionValue)
		{
			if (tOptionValue==nil)
			{
				[self.advancedOptionsSettings removeObjectForKey:tRepresentedObject.itemID];
			}
			else
			{
				if ([self.advancedOptionsSettings[tRepresentedObject.itemID] isEqual:tOptionValue]==YES)
					return;
				
				self.advancedOptionsSettings[tRepresentedObject.itemID]=tOptionValue;
			}
			
			// Reload row
			
			NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:tClickedRow];
			NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[self.outlineView columnWithIdentifier:@"advanced.value"]];
			
			[self.outlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
			
			[self noteDocumentHasChanged];
		}
	}];
}

#pragma mark -

- (void)setAdvancedOptionsDataSource:(id<NSOutlineViewDataSource>)inDataSource
{
	_advancedOptionsDataSource=inDataSource;
	_advancedOptionsDataSource.delegate=self;
	
	if (self.outlineView!=nil)
		self.outlineView.dataSource=_advancedOptionsDataSource;
}

- (CGFloat)maximumViewHeight
{
	NSUInteger tNumberOfRows=self.advancedOptionsDataSource.numberOfItems;
	
	if (tNumberOfRows<3)
		tNumberOfRows=3;
	
	CGFloat tRowHeight=self.outlineView.rowHeight;
	NSSize tIntercellSpacing=self.outlineView.intercellSpacing;
	
	return NSHeight(self.view.frame)-NSHeight(self.outlineView.enclosingScrollView.frame)+tRowHeight*tNumberOfRows+(tNumberOfRows-1)*tIntercellSpacing.height+4.0;
}

#pragma mark - Restoration

- (void)restoreDisclosedStates
{
	NSDictionary * tDictionary=self.documentRegistry[PKGDistributionProjectSettingsAdvancedOptionsDisclosedStatesKey];
	
	if (tDictionary.count==0)
	{
		[self.outlineView expandItem:nil expandChildren:YES];
		
		return;
	}
	
	__block __weak void (^_weakDiscloseNodeAndDescendantsIfNeeded)(PKGDistributionProjectSettingsAdvancedOptionsTreeNode *);
	__block void(^_discloseNodeAndDescendantsIfNeeded)(PKGDistributionProjectSettingsAdvancedOptionsTreeNode *);
	
	_discloseNodeAndDescendantsIfNeeded = ^(PKGDistributionProjectSettingsAdvancedOptionsTreeNode * bTreeNode)
	{
		if (bTreeNode==nil)
			return;
		
		if ([bTreeNode isLeaf]==YES)
			return;
		
		PKGDistributionProjectSettingsAdvancedOptionsItem * tRepresentedObject=[bTreeNode representedObject];
		
		NSString * tFilePath=tRepresentedObject.itemID;
		
		[self.outlineView expandItem:bTreeNode];
		
		// Check children
		
		NSArray * tChildren=[bTreeNode children];
		
		for(PKGDistributionProjectSettingsAdvancedOptionsTreeNode * tTreeNode in tChildren)
			_weakDiscloseNodeAndDescendantsIfNeeded(tTreeNode);
		
		if (tDictionary[tFilePath]==nil)
			[self.outlineView collapseItem:bTreeNode];
	};
	
	_weakDiscloseNodeAndDescendantsIfNeeded = _discloseNodeAndDescendantsIfNeeded;
	
	_restoringDiscloseStates=YES;
	
	_discloseNodeAndDescendantsIfNeeded(_advancedOptionsDataSource.rootNode);
	
	_restoringDiscloseStates=NO;
}

#pragma mark - NSOutlineViewDelegate

- (NSTableRowView *)outlineView:(NSOutlineView *)inOutlineView rowViewForItem:(PKGDistributionProjectSettingsAdvancedOptionsTreeNode *)inAdvancedOptionsTreeNode
{
	if (inOutlineView!=self.outlineView || inAdvancedOptionsTreeNode==nil)
		return nil;
	
	if ([inAdvancedOptionsTreeNode isLeaf]==YES)
		return nil;
	
	PKGTableGroupRowView * tGroupView=[inOutlineView makeViewWithIdentifier:PKGTableGroupRowViewIdentifier owner:self];
	
	if (tGroupView!=nil)
		return tGroupView;
	
	tGroupView=[[PKGTableGroupRowView alloc] initWithFrame:NSZeroRect];
	tGroupView.identifier=PKGTableGroupRowViewIdentifier;
	
	return tGroupView;
}

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(PKGDistributionProjectSettingsAdvancedOptionsTreeNode *)inAdvancedOptionsTreeNode
{
	if (inOutlineView!=self.outlineView || inAdvancedOptionsTreeNode==nil)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	
	PKGDistributionProjectSettingsAdvancedOptionObject * tObject=[self.advancedOptionsDataSource advancedOptionsObjectForItem:inAdvancedOptionsTreeNode];
	PKGDistributionProjectSettingsAdvancedOptionsItem * tRepresentedObject=[inAdvancedOptionsTreeNode representedObject];
	if ([inAdvancedOptionsTreeNode isLeaf]==NO)
	{
		PKGDistributionProjectSettingsAdvancedOptionHeader * tHeader=(PKGDistributionProjectSettingsAdvancedOptionHeader *)tObject;
		
		NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
		
		//tView.backgroundStyle=WBBackgroundStyleEmphasized;
		if ([tTableColumnIdentifier isEqualToString:@"advanced.value"]==YES)
		{
			tView.textField.stringValue=@"";
		}
		else
		{
			tView.textField.stringValue=NSLocalizedString(tHeader.title,@"");
			tView.textField.textColor=[NSColor whiteColor];
		}
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"advanced.key"]==YES)
	{
		NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		tView.textField.stringValue=NSLocalizedString(tObject.title,@"");
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"advanced.value"]==YES)
	{
		if ([tObject isKindOfClass:PKGDistributionProjectSettingsAdvancedOptionBoolean.class]==YES)
		{
			PKGCheckboxTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"advanced.value.checkbox" owner:self];
			tView.checkbox.action=@selector(setBooleanOptionValue:);
			tView.checkbox.target=self;
			
			NSNumber * tNumberValue=self.advancedOptionsSettings[tRepresentedObject.itemID];
			
			if (tNumberValue==nil)
			{
				tView.checkbox.state=WBControlStateValueOff;
				return tView;
			}

			if ([tNumberValue isKindOfClass:NSNumber.class]==NO)
			{
				NSLog(@"Invalid type of value (%@) for key \"%@\": NSNumber expected",NSStringFromClass([tNumberValue class]),tRepresentedObject.itemID);
				
				tView.checkbox.state=WBControlStateValueOff;
			}
			else
			{
				tView.checkbox.state=[tNumberValue boolValue];
			}
			
			return tView;
		}
		
		if ([tObject isKindOfClass:PKGDistributionProjectSettingsAdvancedOptionString.class]==YES)
		{
			NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"advanced.value.text" owner:self];
			tView.textField.action=@selector(setStringOptionValue:);
			tView.textField.target=self;
            tView.textField.formatter=_cachedReplaceableFormatter;
            
			NSString * tStringValue=self.advancedOptionsSettings[tRepresentedObject.itemID];
			
			tView.textField.objectValue=@"";    // Hack to make sure the textfield is refreshed when the user defined settings are modified
            
            if (tStringValue==nil)
                return tView;
			
			if ([tStringValue isKindOfClass:NSString.class]==NO)
			{
				NSLog(@"Invalid type of value (%@) for key \"%@\": NSString expected",NSStringFromClass([tStringValue class]),tRepresentedObject.itemID);
			}
			else
			{
				tView.textField.objectValue=tStringValue;
			}
			
			return tView;
		}
		
		if ([tObject isKindOfClass:PKGDistributionProjectSettingsAdvancedOptionList.class]==YES)
		{
			NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"advanced.value.text" owner:self];
			tView.textField.action=@selector(setListOptionValue:);
			tView.textField.target=self;
			tView.textField.formatter=_cachedReplaceableFormatter;
            
			NSArray * tArrayValue=self.advancedOptionsSettings[tRepresentedObject.itemID];
			
			if (tArrayValue==nil)
			{
				tView.textField.objectValue=@"";
				return tView;
			}

			if ([tArrayValue isKindOfClass:NSArray.class]==NO)
			{
				NSLog(@"Invalid type of value (%@) for key \"%@\": NSArray expected",NSStringFromClass([tArrayValue class]),tRepresentedObject.itemID);
				
				tView.textField.objectValue=@"";
			}
			else
			{
				NSUInteger tCount=tArrayValue.count;
				
				switch(tCount)
				{
					case 0:
						
						tView.textField.objectValue=@"";
						break;
						
					case 1:
						
						tView.textField.objectValue=tArrayValue[0];
						break;
						
					default:
						
						tView.textField.objectValue=[tArrayValue componentsJoinedByString:@" "];
						break;
				}
			}
			
			return tView;
		}
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isGroupItem:(PKGDistributionProjectSettingsAdvancedOptionsTreeNode *)inAdvancedOptionsTreeNode
{
	return NO;
}

- (NSIndexSet *)outlineView:(NSOutlineView *)inOutlineView selectionIndexesForProposedSelection:(NSIndexSet *)inProposedSelectionIndexes
{
	if (inOutlineView!=self.outlineView)
		return inProposedSelectionIndexes;
	
	return [inProposedSelectionIndexes indexesPassingTest:^BOOL(NSUInteger bIndex, BOOL *bOutStop) {
		
		PKGDistributionProjectSettingsAdvancedOptionsTreeNode * tNode=[inOutlineView itemAtRow:bIndex];
		
		return [tNode isLeaf];
	}];
}

- (void)outlineViewItemDidExpand:(NSNotification *)inNotification
{
	if (_restoringDiscloseStates==YES)
		return;
	
	if (inNotification.object!=self.outlineView)
		return;
	
	NSDictionary * tUserInfo=inNotification.userInfo;
	if (tUserInfo==nil)
		return;
	
	PKGDistributionProjectSettingsAdvancedOptionsTreeNode * tTreeNode=(PKGDistributionProjectSettingsAdvancedOptionsTreeNode *) tUserInfo[@"NSObject"];
	if (tTreeNode==nil)
		return;
	
	PKGDistributionProjectSettingsAdvancedOptionsItem * tRepresentedObject=[tTreeNode representedObject];
	NSString * tNodePath=tRepresentedObject.itemID;
	
	NSMutableDictionary * tDisclosedDictionary=self.documentRegistry[PKGDistributionProjectSettingsAdvancedOptionsDisclosedStatesKey];
	
	if (tDisclosedDictionary==nil)
	{
		tDisclosedDictionary=[NSMutableDictionary dictionary];
		self.documentRegistry[PKGDistributionProjectSettingsAdvancedOptionsDisclosedStatesKey]=tDisclosedDictionary;
	}
	
	tDisclosedDictionary[tNodePath]=@(YES);
}

- (void)outlineViewItemWillCollapse:(NSNotification *)inNotification
{
	if (_restoringDiscloseStates==YES)
		return;
	
	if (inNotification.object!=self.outlineView)
		return;
	
	NSDictionary * tUserInfo=inNotification.userInfo;
	if (tUserInfo==nil)
		return;
	
	PKGDistributionProjectSettingsAdvancedOptionsTreeNode * tTreeNode=(PKGDistributionProjectSettingsAdvancedOptionsTreeNode *) tUserInfo[@"NSObject"];
	if (tTreeNode==nil)
		return;
	
	PKGDistributionProjectSettingsAdvancedOptionsItem * tRepresentedObject=[tTreeNode representedObject];
	NSString * tNodePath=tRepresentedObject.itemID;
	
	NSMutableDictionary * tDisclosedDictionary=self.documentRegistry[PKGDistributionProjectSettingsAdvancedOptionsDisclosedStatesKey];
	
	if (tDisclosedDictionary==nil)
		return;
	
	// Check if the option key is down or not
	
	NSEvent * tCurrentEvent=[NSApp currentEvent];
	
	if (tCurrentEvent==nil || ((tCurrentEvent.modifierFlags & WBEventModifierFlagOption)==0))
	{
		if ([tNodePath isEqualToString:@"installer-script"]==NO)
		{
			// Check the parents state
			
			NSString * tParentPath=tNodePath;
			
			do
			{
				tParentPath=[tParentPath stringByDeletingPathExtension];
				
				NSNumber * tNumber=tDisclosedDictionary[tParentPath];
				
				if (tNumber==nil)	// Parent is hidden
					return;
				
				if ([tParentPath isEqualToString:@"installer-script"]==YES)
					break;
			}
			while (1);
		}
	}
	
	[tDisclosedDictionary removeObjectForKey:tNodePath];
}

#pragma mark - PKGDistributionProjectSettingsAdvancedOptionsDataSourceDelegate

- (void)advancedOptionsDataDidChange:(PKGDistributionProjectSettingsAdvancedOptionsDataSource *)inAdvancedOptionsDataSource
{
	// A COMPLETER
}

#pragma mark - Notifications

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
    
    [self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfRows)] columnIndexes:[NSIndexSet indexSetWithIndex:1]];
}

@end
