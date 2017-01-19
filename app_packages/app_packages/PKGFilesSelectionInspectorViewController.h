
#import "PKGDocumentViewController.h"

@class PKGFilesSelectionInspectorViewController;

@protocol PKGFilesSelectionInspectorDelegate

- (void)filesSelectionInspectorViewController:(PKGFilesSelectionInspectorViewController *)inViewController didUpdateFileItems:(NSArray *)inArray;

@end

@interface PKGFilesSelectionInspectorViewController : PKGDocumentViewController

	@property (nonatomic) NSArray * selectedItems;

	@property (weak) id<PKGFilesSelectionInspectorDelegate> delegate;

- (void)refreshSingleSelection;
- (void)refreshMultipleSelection;

@end
