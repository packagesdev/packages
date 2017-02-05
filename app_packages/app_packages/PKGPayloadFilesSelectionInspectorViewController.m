
#import "PKGPayloadFilesSelectionInspectorViewController.h"

#import "PKGPayloadTreeNode+UI.h"

#import "PKGPayloadBundleItem.h"

#import "PKGFilesSelectionInspectorAttributesViewController.h"

@interface PKGPayloadFilesSelectionInspectorViewController ()
{
	NSTabViewItem * _rulesTabViewItem;
	
	NSTabViewItem * _scriptsTabViewItem;
}

@end

@implementation PKGPayloadFilesSelectionInspectorViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_rulesTabViewItem=[tabView tabViewItemAtIndex:[tabView indexOfTabViewItemWithIdentifier:@"tabviewitem.rules"]];
	
	_scriptsTabViewItem=[tabView tabViewItemAtIndex:[tabView indexOfTabViewItemWithIdentifier:@"tabviewitem.scripts"]];
}

#pragma mark -

- (PKGFilesSelectionInspectorTabViewItemViewController *)attributesViewController
{
	return [[PKGFilesSelectionInspectorAttributesViewController alloc] init];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
}

#pragma mark -

- (void)refreshSingleSelection
{
	PKGPayloadTreeNode * tSelectedNode=[self.selectedItems lastObject];
	PKGFileItem * tSelectedItem=[tSelectedNode representedObject];
	
	if ([tSelectedItem isKindOfClass:[PKGPayloadBundleItem class]]==YES)
	{
		if ([tabView indexOfTabViewItem:_rulesTabViewItem]==NSNotFound)
			[tabView insertTabViewItem:_rulesTabViewItem atIndex:1];
		if ([tabView indexOfTabViewItem:_scriptsTabViewItem ]==NSNotFound)
			[tabView insertTabViewItem:_scriptsTabViewItem atIndex:2];
	}
	else
	{
		if ([tabView indexOfTabViewItem:_rulesTabViewItem]!=NSNotFound)
			[tabView removeTabViewItem:_rulesTabViewItem];
		if ([tabView indexOfTabViewItem:_scriptsTabViewItem]!=NSNotFound)
			[tabView removeTabViewItem:_scriptsTabViewItem];
	}
	
	[super refreshSingleSelection];
}

- (void)refreshMultipleSelection
{
	if ([tabView indexOfTabViewItem:_rulesTabViewItem]!=NSNotFound)
		[tabView removeTabViewItem:_rulesTabViewItem];
	if ([tabView indexOfTabViewItem:_scriptsTabViewItem]!=NSNotFound)
		[tabView removeTabViewItem:_scriptsTabViewItem];
	
	[super refreshMultipleSelection];
}

@end
