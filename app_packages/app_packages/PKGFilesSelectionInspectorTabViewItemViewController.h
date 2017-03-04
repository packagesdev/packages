
#import "PKGDocumentViewController.h"

#import "PKGFilesSelectionInspectorDelegate.h"

@interface PKGFilesSelectionInspectorTabViewItemViewController : PKGDocumentViewController

	@property (weak) id<PKGFilesSelectionInspectorDelegate> delegate;

	@property (nonatomic) NSArray * selectedItems;

- (void)refreshSingleSelection;

- (void)refreshMultipleSelection;

@end
