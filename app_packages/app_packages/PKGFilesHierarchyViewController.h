
#import "PKGDocumentViewController.h"

#import "PKGPayloadDataSource.h"

@interface PKGFilesHierarchyViewController : PKGDocumentViewController

	@property (nonatomic) PKGPayloadDataSource * hierarchyDatasource;

	@property BOOL canAddRootNodes;

	@property (nonatomic,copy) NSString * label;

- (BOOL)highlightExcludedItems;

- (void)refreshHierarchy;

@end
