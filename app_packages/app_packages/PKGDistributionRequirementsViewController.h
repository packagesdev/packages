
#import "PKGDocumentViewController.h"

#import "PKGDistributionRequirementsDataSource.h"

@interface PKGDistributionRequirementsViewController : PKGDocumentViewController <PKGTableViewDataSourceDelegate>

	@property IBOutlet NSTableView * tableView;

	@property (nonatomic) PKGDistributionRequirementsDataSource * requirementsDataSource;

@end
