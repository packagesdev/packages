
#import "PKGPayloadFilesSelectionInspectorScriptsViewController.h"

#import "PKGStackView.h"

#import "PKGPayloadTreeNode.h"
#import "PKGPayloadBundleItem.h"

@interface PKGPayloadFilesSelectionInspectorScriptsViewController ()

@end

@implementation PKGPayloadFilesSelectionInspectorScriptsViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
}

- (void)refreshSingleSelection
{
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
	
	if ([tBundleItem isKindOfClass:[PKGPayloadBundleItem class]]==NO)
		return;
}


@end
