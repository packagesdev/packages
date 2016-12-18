
#import "PKGPayloadFilesHierarchyViewController.h"

#import "PKGPackagePayloadDataSource.h"

@interface PKGPayloadFilesHierarchyViewController ()

@end

@implementation PKGPayloadFilesHierarchyViewController

- (void)showHiddenFolderTemplates
{
	[((PKGPackagePayloadDataSource *) self.hierarchyDatasource) outlineView:self.outlineView showsHiddenFolders:YES];
}

- (void)hideHiddenFolderTemplates
{
	[((PKGPackagePayloadDataSource *) self.hierarchyDatasource) outlineView:self.outlineView showsHiddenFolders:NO];
}

@end
