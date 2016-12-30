
#import "PKGDocumentViewController.h"

#import "PKGFileFiltersDataSource.h"

@interface PKGPayloadExclusionsViewController : PKGDocumentViewController <PKGFileFiltersDataSourceDelegate>

	@property (nonatomic) PKGFileFiltersDataSource * fileFiltersDataSource;

@end
