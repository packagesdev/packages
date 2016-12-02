
#import "PKGDocumentViewController.h"

@interface PKGFilesHierarchyViewController : PKGDocumentViewController

	@property (nonatomic) id<NSOutlineViewDataSource> hierarchyDatasource;

	@property (nonatomic,copy) NSString * label;

- (void)refreshHierarchy;

@end
