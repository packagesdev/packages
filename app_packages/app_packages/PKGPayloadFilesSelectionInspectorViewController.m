
#import "PKGPayloadFilesSelectionInspectorViewController.h"

#import "PKGPayloadTreeNode+UI.h"

#import "PKGPayloadBundleItem.h"

#import "PKGFilesSelectionInspectorAttributesViewController.h"
#import "PKGFilesSelectionInspectorRulesViewController.h"
#import "PKGFilesSelectionInspectorScriptsViewController.h"

@interface PKGPayloadFilesSelectionInspectorViewController ()
{
	NSTabViewItem * _rulesTabViewItem;
	
	NSTabViewItem * _scriptsTabViewItem;
	
	PKGFilesSelectionInspectorRulesViewController * _rulesViewController;
	
	PKGFilesSelectionInspectorScriptsViewController * _scriptsViewController;
}

@end

@implementation PKGPayloadFilesSelectionInspectorViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// Rules
	
	NSUInteger tIndex=[tabView indexOfTabViewItemWithIdentifier:@"tabviewitem.rules"];
	
	if (tIndex==NSNotFound)
	{
		// A COMPLETER
		
		return;
	}
	
	_rulesTabViewItem=[tabView tabViewItemAtIndex:tIndex];
	
	NSView * tView=_rulesTabViewItem.view;
	
	PKGFilesSelectionInspectorTabViewItemViewController * tTabViewItemViewController=[PKGFilesSelectionInspectorRulesViewController new];
	
	if (tTabViewItemViewController==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	tTabViewItemViewController.delegate=self.delegate;
	
	[self.tabViewItemViewControllers addObject:tTabViewItemViewController];
	
	tTabViewItemViewController.view.frame=tView.bounds;
	
	[tView addSubview:tTabViewItemViewController.view];
	
	// Scripts
	
	tIndex=[tabView indexOfTabViewItemWithIdentifier:@"tabviewitem.scripts"];
	
	if (tIndex==NSNotFound)
	{
		// A COMPLETER
		
		return;
	}
	
	_scriptsTabViewItem=[tabView tabViewItemAtIndex:tIndex];
	
	tView=_rulesTabViewItem.view;
	
	tTabViewItemViewController=[PKGFilesSelectionInspectorScriptsViewController new];
	
	if (tTabViewItemViewController==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	tTabViewItemViewController.delegate=self.delegate;
	
	[self.tabViewItemViewControllers addObject:tTabViewItemViewController];
	
	tTabViewItemViewController.view.frame=tView.bounds;
	
	[tView addSubview:tTabViewItemViewController.view];
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
