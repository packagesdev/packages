
#import "PKGViewController.h"

#import "PKGDistributionRequirementMessagesDataSource.h"

@interface PKGDistributionRequirementBehaviorViewController : PKGViewController <PKGDistributionRequirementMessagesDataSourceDelegate,NSTableViewDelegate>

	@property (readonly) NSTableView * tableView;

	@property (nonatomic) PKGDistributionRequirementMessagesDataSource * dataSource;

@end
