
#import "PKGDocumentViewController.h"

#import "PKGPackageComponent.h"

@interface PKGDistributionPackageComponentViewController : PKGDocumentViewController

	@property PKGPackageComponent * packageComponent;

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender;

@end
