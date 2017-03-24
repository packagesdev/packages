
#import "PKGDistributionProjectSettingsAdvancedOptionsViewController.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsTreeNode.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsItem.h"

#import "PKGTableGroupRowView.h"
#import "PKGCheckboxTableCellView.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsObject.h"
#import "PKGDistributionProjectSettingsAdvancedOptionsHeader.h"
#import "PKGDistributionProjectSettingsAdvancedOptionsBoolean.h"
#import "PKGDistributionProjectSettingsAdvancedOptionsString.h"
#import "PKGDistributionProjectSettingsAdvancedOptionsList.h"

@interface PKGDistributionProjectSettingsAdvancedOptionsViewController () <NSOutlineViewDelegate>
{
	BOOL _restoringDiscloseStates;
}

	@property (readwrite) IBOutlet NSOutlineView * outlineView;

- (IBAction)editWithEditor:(id)sender;

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionsViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];

	self.outlineView.doubleAction=@selector(editWithEditor:);
	
	// A COMPLETER
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	self.outlineView.dataSource=self.advancedOptionsDataSource;
	
	// A COMPLETER
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// A COMPLETER
	
	[self refreshHierarchy];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	// A COMPLETER
}

- (void)refreshHierarchy
{
	[self.outlineView reloadData];
	
	[self.outlineView expandItem:nil expandChildren:YES];	// A COMPLETER
	
	//[self restoreDisclosedStates];
}

#pragma mark -

- (IBAction)editWithEditor:(id)sender
{
	NSUInteger tClickedColumn=self.outlineView.clickedColumn;
	
	if (tClickedColumn!=[self.outlineView columnWithIdentifier:@"advanced.value"])
		return;
	
	NSLog(@"good column double-clicked");
	
	NSUInteger tClickedRow=self.outlineView.clickedRow;
	
	// A COMPLETER
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
	
	PKGDistributionProjectSettingsAdvancedOptionsObject * tObject=[self.advancedOptionsDataSource advancedOptionsObjectForItem:inAdvancedOptionsTreeNode];
	PKGDistributionProjectSettingsAdvancedOptionsItem * tRepresentedObject=[inAdvancedOptionsTreeNode representedObject];
	if ([inAdvancedOptionsTreeNode isLeaf]==NO)
	{
		PKGDistributionProjectSettingsAdvancedOptionsHeader * tHeader=(PKGDistributionProjectSettingsAdvancedOptionsHeader *)tObject;
		
		NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
		
		tView.backgroundStyle=NSBackgroundStyleDark;
		tView.textField.stringValue=NSLocalizedString(tHeader.title,@"");
		
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
		if ([tObject isKindOfClass:PKGDistributionProjectSettingsAdvancedOptionsBoolean.class]==YES)
		{
			PKGCheckboxTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"advanced.value.checkbox" owner:self];
			
			NSNumber * tNumberValue=self.advancedOptionsSettings[tRepresentedObject.itemID];
			
			if (tNumberValue==nil)
			{
				tView.checkbox.state=NSOffState;
				return tView;
			}

			if ([tNumberValue isKindOfClass:NSNumber.class]==NO)
			{
				NSLog(@"Invalid type of value (%@) for key \"%@\": NSNumber expected",NSStringFromClass([tNumberValue class]),tRepresentedObject.itemID);
				
				tView.checkbox.state=NSOffState;
			}
			else
			{
				tView.checkbox.state=[tNumberValue boolValue];
			}
			
			return tView;
		}
		
		if ([tObject isKindOfClass:PKGDistributionProjectSettingsAdvancedOptionsString.class]==YES)
		{
			NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"advanced.value.text" owner:self];
			
			NSString * tStringValue=self.advancedOptionsSettings[tRepresentedObject.itemID];
			
			if (tStringValue==nil)
			{
				tView.textField.stringValue=@"";
				return tView;
			}
			
			if ([tStringValue isKindOfClass:NSString.class]==NO)
			{
				NSLog(@"Invalid type of value (%@) for key \"%@\": NSString expected",NSStringFromClass([tStringValue class]),tRepresentedObject.itemID);
				
				tView.textField.stringValue=@"";
			}
			else
			{
				tView.textField.stringValue=tStringValue;
			}
			
			return tView;
		}
		
		if ([tObject isKindOfClass:PKGDistributionProjectSettingsAdvancedOptionsList.class]==YES)
		{
			NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"advanced.value.text" owner:self];
			
			NSArray * tArrayValue=self.advancedOptionsSettings[tRepresentedObject.itemID];
			
			if (tArrayValue==nil)
			{
				tView.textField.stringValue=@"";
				return tView;
			}

			if ([tArrayValue isKindOfClass:NSArray.class]==NO)
			{
				NSLog(@"Invalid type of value (%@) for key \"%@\": NSArray expected",NSStringFromClass([tArrayValue class]),tRepresentedObject.itemID);
				
				tView.textField.stringValue=@"";
			}
			else
			{
				NSUInteger tCount=tArrayValue.count;
				
				switch(tCount)
				{
					case 0:
						
						tView.textField.stringValue=@"";
						break;
						
					case 1:
						
						tView.textField.stringValue=tArrayValue[0];
						break;
						
					default:
						
						tView.textField.stringValue=[tArrayValue componentsJoinedByString:@" "];
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
	if (inOutlineView!=self.outlineView || inAdvancedOptionsTreeNode==nil)
		return NO;
	
	return ([inAdvancedOptionsTreeNode isLeaf]==NO);
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

#pragma mark - PKGDistributionProjectSettingsAdvancedOptionsDataSourceDelegate

- (void)advancedOptionsDataDidChange:(PKGDistributionProjectSettingsAdvancedOptionsDataSource *)inAdvancedOptionsDataSource
{
	// A COMPLETER
}

@end
