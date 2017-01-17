
#import "PKGDocumentViewController.h"

@interface PKGFilesSelectionInspectorViewController : PKGDocumentViewController

		@property (nonatomic) NSArray * selectedItems;

- (void)refreshSingleSelection;
- (void)refreshMultipleSelection;

@end
