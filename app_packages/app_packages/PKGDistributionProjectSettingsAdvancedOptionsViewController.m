
#import "PKGDistributionProjectSettingsAdvancedOptionsViewController.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsTreeNode.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsItem.h"

#import "PKGTableGroupRowView.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsObject.h"
#import "PKGDistributionProjectSettingsAdvancedOptionsHeader.h"

@interface PKGDistributionProjectSettingsAdvancedOptionsViewController () <NSOutlineViewDelegate>
{
	BOOL _restoringDiscloseStates;
}

	@property (readwrite) IBOutlet NSOutlineView * outlineView;

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionsViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];

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
	
	//[self restoreDisclosedStates];
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
		NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:@"advanced.value.text" owner:self];
		
		tView.textField.stringValue=@"lorem ipsum";
		
		return tView;
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isGroupItem:(PKGDistributionProjectSettingsAdvancedOptionsTreeNode *)inAdvancedOptionsTreeNode
{
	if (inOutlineView!=self.outlineView || inAdvancedOptionsTreeNode==nil)
		return NO;
	
	// A COMPLETER
	
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
