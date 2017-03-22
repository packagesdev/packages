
#import "PKGDocumentViewController.h"

#import "PKGDistributionProjectSettings.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsDataSource.h"

@interface PKGDistributionProjectSettingsAdvancedOptionsViewController : PKGDocumentViewController <PKGDistributionProjectSettingsAdvancedOptionsDataSourceDelegate>

	@property (readonly) NSOutlineView * outlineView;

	@property (nonatomic) PKGDistributionProjectSettingsAdvancedOptionsDataSource * advancedOptionsDataSource;

	@property (nonatomic,readonly) CGFloat maximumViewHeight;

- (void)refreshHierarchy;

@end
