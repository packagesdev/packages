
#import "PKGSegmentViewController.h"

#import "PKGDistributionProject.h"

#import "PKGDistributionProjectPresentationSettings.h"

@interface PKGDistributionPresentationViewController : PKGSegmentViewController

	@property (nonatomic) PKGDistributionProject * distributionProject;

	@property (nonatomic) PKGDistributionProjectPresentationSettings * presentationSettings;

@end
