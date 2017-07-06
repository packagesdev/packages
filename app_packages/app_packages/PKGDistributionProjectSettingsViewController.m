
#import "PKGDistributionProjectSettingsViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGDistributionProject.h"
#import "PKGDistributionProjectSettings.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsViewController.h"

#import "PKGDistributionProjectSettingsAdvancedOptionsDataSource.h"

@interface PKGDistributionProjectSettingsViewController ()
{
	IBOutlet NSView * _buildSectionView;
	
	IBOutlet NSPopUpButton * _buildFormatPopUpButton;
	
	IBOutlet NSTextField * _buildFormatWarningLabel;
	
	IBOutlet NSView * _advancedOptionsPlaceHolderView;
	
	PKGDistributionProjectSettingsAdvancedOptionsViewController * _advancedOptionsViewController;
	
	PKGDistributionProjectSettingsAdvancedOptionsDataSource * _dataSource;
	
	CGFloat _cachedBuildSectionViewInitialHeight;
}

- (IBAction)setBuildFormat:(id)sender;

- (void)showBuildFormatWarningLabel:(BOOL)inShow;

// Notifications

- (void)advancedModeStateDidChange:(NSNotification *)inNotification;

@end

@implementation PKGDistributionProjectSettingsViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		_dataSource=[PKGDistributionProjectSettingsAdvancedOptionsDataSource new];
	}
	
	return self;
}

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

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_cachedBuildSectionViewInitialHeight=NSHeight(_buildSectionView.frame);
}

#pragma mark -

- (void)refreshUI
{
	[super refreshUI];
	
	PKGDistributionProjectSettings * tDistributionProjectSettings=(PKGDistributionProjectSettings *)self.projectSettings;
	
	// Build Format
	
	[_buildFormatPopUpButton selectItemWithTag:tDistributionProjectSettings.buildFormat];
	
	[self showBuildFormatWarningLabel:(tDistributionProjectSettings.buildFormat==PKGProjectBuildFormatFlat)];
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_advancedOptionsPlaceHolderView.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self updateLayout];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(advancedModeStateDidChange:) name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	_advancedOptionsPlaceHolderView.autoresizingMask=NSViewWidthSizable|NSViewMinYMargin;	// Hack to avoid some resizing issues when the window is resized and the controller view is not visible.
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
}

#pragma mark -

- (void)updateLayout
{
	[super updateLayout];
	
	BOOL tAdvancedModeEnabled=[PKGApplicationPreferences sharedPreferences].advancedMode;
	
	if (tAdvancedModeEnabled==NO)
	{
		if (_advancedOptionsViewController!=nil)
		{
			[_advancedOptionsViewController WB_viewWillDisappear];
			
			[_advancedOptionsViewController.view removeFromSuperview];
			
			[_advancedOptionsViewController WB_viewDidDisappear];
			
			_advancedOptionsViewController=nil;
		}
		
		_advancedOptionsPlaceHolderView.hidden=YES;
		
		NSRect tViewBounds=self.view.bounds;
		
		NSRect tSectionFrame=_buildSectionView.frame;
		
		tSectionFrame.origin.y=0.0;
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
		
		if (_advancedOptionsViewController==nil)
		{
			PKGDistributionProjectSettings * tDistributionProjectSettings=(PKGDistributionProjectSettings *)self.projectSettings;
			
			_advancedOptionsViewController=[[PKGDistributionProjectSettingsAdvancedOptionsViewController alloc] initWithDocument:self.document];
			_advancedOptionsViewController.advancedOptionsDataSource=_dataSource;
			_advancedOptionsViewController.advancedOptionsSettings=tDistributionProjectSettings.advancedOptions;
			_dataSource.delegate=_advancedOptionsViewController;
			
			NSRect tBounds=_advancedOptionsPlaceHolderView.bounds;
			
			_advancedOptionsViewController.view.frame=tBounds;
			
			[_advancedOptionsViewController WB_viewWillAppear];
			
			[_advancedOptionsPlaceHolderView addSubview:_advancedOptionsViewController.view];
			
			[_advancedOptionsViewController WB_viewDidAppear];
		}
		
		_advancedOptionsPlaceHolderView.hidden=NO;
		
		CGFloat tMaximumAdvancedOptionsHeight=_advancedOptionsViewController.maximumViewHeight;
		
		NSRect tBounds=self.view.bounds;
		
		NSRect tBuildFrame=_buildSectionView.frame;
		
		CGFloat tAvailableHeight=NSHeight(tBounds)-_cachedBuildSectionViewInitialHeight;
		
		NSRect tAdvancedOptionsFrame=_advancedOptionsPlaceHolderView.frame;
		tAdvancedOptionsFrame.origin.y=0.0;
		
		if (tMaximumAdvancedOptionsHeight<tAvailableHeight)
		{
			tAdvancedOptionsFrame.size.height=tMaximumAdvancedOptionsHeight;
			
			_advancedOptionsPlaceHolderView.frame=tAdvancedOptionsFrame;
			
			
			tBuildFrame.size.height=NSHeight(tBounds)-tAdvancedOptionsFrame.size.height;
		}
		else
		{
			tAdvancedOptionsFrame.size.height=tAvailableHeight;
			
			_advancedOptionsPlaceHolderView.frame=tAdvancedOptionsFrame;
			
			tBuildFrame.size.height=_cachedBuildSectionViewInitialHeight;
		}
		
		tBuildFrame.origin.y=NSMaxY(tAdvancedOptionsFrame);
		
		_buildSectionView.frame=tBuildFrame;
		

		
		[self.view setNeedsDisplay:YES];
	}
}

#pragma mark -

- (BOOL)isSignable
{
	PKGDistributionProjectSettings * tDistributionProjectSettings=(PKGDistributionProjectSettings *)self.projectSettings;
	
	return (tDistributionProjectSettings.buildFormat==PKGProjectBuildFormatFlat);
}

- (void)showBuildFormatWarningLabel:(BOOL)inShow
{
	if (inShow==YES)
	{
		PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)self.documentProject;
		
		if ([tDistributionProject.presentationSettings containsInstallerPluginSection]==YES)
		{
			_buildFormatWarningLabel.hidden=NO;
				
			return;
		}
	}
	
	_buildFormatWarningLabel.hidden=YES;
}

- (IBAction)setBuildFormat:(NSPopUpButton *)sender
{
	PKGProjectBuildFormat tBuildFormat=sender.selectedItem.tag;
	
	PKGDistributionProjectSettings * tDistributionProjectSettings=(PKGDistributionProjectSettings *)self.projectSettings;
	
	if (tDistributionProjectSettings.buildFormat!=tBuildFormat)
	{
		tDistributionProjectSettings.buildFormat=tBuildFormat;
		
		[self showBuildFormatWarningLabel:(tBuildFormat==PKGProjectBuildFormatFlat)];
		
		[self noteDocumentHasChanged];
	}
}

#pragma mark - Notifications

- (void)advancedModeStateDidChange:(NSNotification *)inNotification
{
	[self updateLayout];
}

@end
