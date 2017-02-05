
#import "PKGDocumentViewController.h"

#import "PKGFilesSelectionInspectorDelegate.h"

#import "PKGFilesSelectionInspectorTabViewItemViewController.h"

@interface PKGFilesSelectionInspectorViewController : PKGDocumentViewController
{
	IBOutlet NSTabView * tabView;
}

	@property (nonatomic) NSArray * selectedItems;

	@property (nonatomic,weak) id<PKGFilesSelectionInspectorDelegate> delegate;

	@property (readonly) NSMutableArray * tabViewItemViewControllers;

- (PKGFilesSelectionInspectorTabViewItemViewController *)attributesViewController;

- (void)refreshSingleSelection;
- (void)refreshMultipleSelection;

@end
