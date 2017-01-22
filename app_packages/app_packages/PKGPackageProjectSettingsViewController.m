
#import "PKGPackageProjectSettingsViewController.h"

#import "PKGApplicationPreferences.h"

@interface PKGPackageProjectSettingsViewController ()

@end

@implementation PKGPackageProjectSettingsViewController

- (NSString *)nibName
{
	return @"PKGPackageProjectSettingsViewController";
}

- (NSUInteger)tag
{
	return PKGPreferencesGeneralPackageProjectPaneProject;
}

- (NSString *)certificatePanelMessage
{
	return NSLocalizedString(@"Choose a certificate to be used to sign the package.",@"");
}

@end
