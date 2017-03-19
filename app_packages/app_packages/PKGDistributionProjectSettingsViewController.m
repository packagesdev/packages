
#import "PKGDistributionProjectSettingsViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGDistributionProjectSettings.h"

@interface PKGDistributionProjectSettingsViewController ()
{
	IBOutlet NSView * _buildSectionView;
	
	IBOutlet NSPopUpButton * _buildFormatPopUpButton;
	
	IBOutlet NSView * _advancedOptionsPlaceHolderView;
}

- (void)_updateLayout;

- (IBAction)setBuildFormat:(id)sender;

// Notifications

- (void)advancedModeStateDidChange:(NSNotification *)inNotification;

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

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self _updateLayout];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(advancedModeStateDidChange:) name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];
}

#pragma mark -

- (void)_updateLayout
{
	BOOL tAdvancedModeEnabled=[PKGApplicationPreferences sharedPreferences].advancedMode;
	
	if (tAdvancedModeEnabled==NO)
	{
		// WB_viewWill...
		
		_advancedOptionsPlaceHolderView.hidden=YES;
		
		NSRect tViewBounds=self.view.bounds;
		
		NSRect tSectionFrame=_buildSectionView.frame;
		
		tSectionFrame.origin.y=0;
		tSectionFrame.size.height=NSHeight(tViewBounds);
		
		_buildSectionView.frame=tSectionFrame;
		
		//[IBexclusionArray_ setNextKeyView:self.buildPathTextField];
		
		_buildSectionView.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
		
		[self.view setNeedsDisplay:YES];
	}
	else
	{
		_buildSectionView.autoresizingMask=NSViewWidthSizable|NSViewMinYMargin;
		
		//[IBadvancedOptionsOutlineView_ setNextKeyView:self.buildPathTextField];
		
		// WB_viewWill...
		
		_advancedOptionsPlaceHolderView.hidden=NO;
		
		// A COMPLETER (resize)
		
		[self.view setNeedsDisplay:YES];
	}
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

#pragma mark - Notifications

- (void)advancedModeStateDidChange:(NSNotification *)inNotification
{
	[self _updateLayout];
}

@end


