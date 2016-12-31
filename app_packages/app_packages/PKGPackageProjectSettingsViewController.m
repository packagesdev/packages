
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

@end
