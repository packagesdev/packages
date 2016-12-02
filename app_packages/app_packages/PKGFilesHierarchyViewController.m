
#import "PKGFilesHierarchyViewController.h"

#import "PKGPayloadTreeNode.h"
#import "PKGFileItem+UI.h"

@interface PKGFilesHierarchyViewController ()
{
	IBOutlet NSTextField * _viewLabel;
	
	IBOutlet NSOutlineView * _outlineView;
	
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
}

@end

@implementation PKGFilesHierarchyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark -

- (void)WB_viewWillAdd
{
	_viewLabel.stringValue=_label;
	_outlineView.dataSource=_hierarchyDatasource;
	// A COMPLETER
}

- (void)WB_viewWillRemove
{
	// A COMPLETER
}

- (void)refreshHierarchy
{
	[_outlineView reloadData];
}

#pragma mark -

- (void)setHierarchyDatasource:(id<NSOutlineViewDataSource>)inDataSource
{
	_hierarchyDatasource=inDataSource;
	
	if (_outlineView!=nil)
		_outlineView.dataSource=_hierarchyDatasource;
}

- (void)setLabel:(NSString *)inLabel
{
	_label=[inLabel copy];
	
	if (_viewLabel!=nil)
		_viewLabel.stringValue=_label;
}

#pragma mark -

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(id)inItem
{
	if (inOutlineView!=_outlineView)
		return nil;
	
	NSString * tTableColumnIdentifier=[inTableColumn identifier];
	NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	PKGPayloadTreeNode * tTreeNode=(PKGPayloadTreeNode *)inItem;
	PKGFileItem * tFileItem=(PKGFileItem *)tTreeNode.representedObject;
	
	if ([tTableColumnIdentifier isEqualToString:@"file.name"]==YES)
	{
		tView.textField.stringValue=tFileItem.fileName;
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"file.owner"]==YES)
	{
		tView.textField.stringValue=@"tutu";
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"file.group"]==YES)
	{
		tView.textField.stringValue=@"tutu";
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"file.permissions"]==YES)
	{
		tView.textField.stringValue=@"tutu";
		
		return tView;
	}
	
	return nil;
}

@end
