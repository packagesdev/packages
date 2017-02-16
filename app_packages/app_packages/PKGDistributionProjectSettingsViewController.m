
#import "PKGDistributionProjectSettingsViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGDistributionProjectSettings.h"

@interface PKGDistributionProjectSettingsViewController ()
{
	IBOutlet NSPopUpButton * _buildFormatPopUpButton;
}

- (IBAction)setBuildFormat:(id)sender;

@end

@implementation PKGDistributionProjectSettingsViewController

- (NSString *)nibName
{
	return @"PKGDistributionProjectSettingsViewController";
}

- (NSUInteger)tag
{
	return PKGPreferencesGeneralDistributionProjectPaneSettings;
}

- (NSString *)certificatePanelMessage
{
	return NSLocalizedString(@"Choose a certificate to be used for signing the distribution.",@"");
}

#pragma mark -

- (void)refreshUI
{
	[super refreshUI];
	
	// Build Format
}

#pragma mark -

- (IBAction)setBuildFormat:(NSPopUpButton *)sender
{
	PKGProjectBuildFormat tBuildFormat=sender.selectedItem.tag;
	
	PKGDistributionProjectSettings * tDistributionProjectSettings=(PKGDistributionProjectSettings *)self.projectSettings;
	
	if (tDistributionProjectSettings.buildFormat!=tBuildFormat)
	{
		tDistributionProjectSettings.buildFormat=tBuildFormat;
		
		[self noteDocumentHasChanged];
	}
}

@end
