
#import "PKGAdvancedOptionListEditorViewController.h"

#import "PKGCheckboxTableCellView.h"

#import "PKGTableViewDataSource.h"

#import "NSTableView+Geometry.h"

NSString * const PKGAdvancedOptionListLabelKey=@"LABEL";
NSString * const PKGAdvancedOptionListItemsKey=@"ITEMS";
NSString * const PKGAdvancedOptionListItemLabelKey=@"LABEL";
NSString * const PKGAdvancedOptionListItemValueKey=@"VALUE";

@interface PKGAdvancedOptionListItem : NSObject

	@property BOOL selected;

	@property (copy,readonly) NSString * label;

	@property (copy,readonly) NSString * value;

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation;

@end


@implementation PKGAdvancedOptionListItem

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation
{
	if (inRepresentation==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_selected=NO;
		
		_label=[inRepresentation[PKGAdvancedOptionListItemLabelKey] copy];
		
		_value=[inRepresentation[PKGAdvancedOptionListItemValueKey] copy];
	}
	
	return self;
}

@end



@interface PKGAdvancedOptionListEditorViewController () <NSTableViewDelegate>
{
	IBOutlet NSTextField * _label;
	
	NSString * _labelString;
	
	PKGTableViewDataSource * _dataSource;
}

	@property (readwrite) IBOutlet NSTableView * tableView;

- (IBAction)switchSelectedState:(id)sender;

@end

@implementation PKGAdvancedOptionListEditorViewController

- (id)optionValue
{
	NSMutableArray * tComponents=[NSMutableArray array];
	
	for(PKGAdvancedOptionListItem * tOptionListItem in _dataSource.items)
	{
		if (tOptionListItem.selected==YES)
			[tComponents addObject:tOptionListItem.value];
	}
	
	if (tComponents.count==0)
		return nil;
	
	return [tComponents copy];
}

- (void)setOptionValue:(id)inOptionValue
{
	if ([inOptionValue isKindOfClass:NSArray.class]==NO)
		return;
	
	[super setOptionValue:inOptionValue];
	
	[self refreshUI];
}

- (void)setEditorRepresentation:(NSDictionary *)inRepresentation
{
	[super setEditorRepresentation:inRepresentation];
	
	if (inRepresentation==nil)
		return;
	
	[self refreshUI];
}

#pragma mark -

- (void)WB_viewDidLoad
{
    NSTableView * tTableView=self.tableView;
    
    if (NSAppKitVersionNumber>=2022)    // NSAppKitVersionNumber11_0: deal with stupid metrics probably due to the pot Catalystic pointless API.
    {
        NSRect tFrame=tTableView.enclosingScrollView.frame;
        
        tFrame.size.height+=20.0;
        tFrame.origin.y-=20;
        
        tTableView.enclosingScrollView.frame=tFrame;
    }

    tTableView.backgroundColor=[NSColor clearColor];
}

- (void)WB_viewDidAppear
{
	[self refreshUI];
}

- (void)refreshUI
{
	if (self.tableView==nil || self.editorRepresentation==nil)
		return;
	
	// Update UI
	
	// Label
	
	NSString * tString=self.editorRepresentation[PKGAdvancedOptionListLabelKey];
	
    if (tString.length>0)
        tString=NSLocalizedString(tString,@"");
    
    
	_label.stringValue=(tString!=nil)? tString : @"";
	[_label sizeToFit];
	
	// List of items
	
	NSArray * tItemsArrayRepresentation=self.editorRepresentation[PKGAdvancedOptionListItemsKey];
	
	NSArray * tItemsArray=[tItemsArrayRepresentation WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bItemRepresentation, NSUInteger bIndex) {
		
		return [[PKGAdvancedOptionListItem alloc] initWithRepresentation:bItemRepresentation];
	}];
	
	NSArray * tSelectedOptionValues=[super optionValue];
	
	for(PKGAdvancedOptionListItem * tOptionListItem in tItemsArray)
		tOptionListItem.selected=[tSelectedOptionValues containsObject:tOptionListItem.value];
	
	_dataSource=[[PKGTableViewDataSource alloc] initWithItems:[tItemsArray mutableCopy]];
	self.tableView.dataSource=_dataSource;
	
	CGFloat tCurrentHeight=NSHeight(self.tableView.enclosingScrollView.frame);
	CGFloat tHeight=[self.tableView enclosingScrollViewHeightForNumberOfRows:_dataSource.items.count];
	
	NSRect tViewFrame=self.view.frame;
	
	NSSize tSize={
		.width=NSWidth(tViewFrame),
		.height=NSHeight(tViewFrame)+(tHeight-tCurrentHeight)
	};
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGAdvancedOptionEditorViewSizeShallChangeNotification object:self.view userInfo:@{@"Size":NSStringFromSize(tSize)}];
	
	[self.tableView reloadData];
}

#pragma mark -

- (IBAction)switchSelectedState:(NSButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGAdvancedOptionListItem * tItem=[_dataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	tItem.selected=(sender.state==WBControlStateValueOn);
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	PKGAdvancedOptionListItem * tItem=[_dataSource tableView:self.tableView itemAtRow:inRow];
	
	if ([tTableColumnIdentifier isEqualToString:@"item.value"]==YES)
	{
		PKGCheckboxTableCellView * tCheckBoxView=(PKGCheckboxTableCellView *)tTableCellView;
		
		tCheckBoxView.checkbox.state=(tItem.selected==YES) ? WBControlStateValueOn : WBControlStateValueOff;
		tCheckBoxView.checkbox.title=tItem.label;
		
		return tCheckBoxView;
	}
	
	return nil;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	return [NSIndexSet indexSet];
}

@end
