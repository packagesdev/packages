
#import "PKGDistributionPresentationViewController.h"

#import "PKGPresentationListView.h"

#import "PKGPresentationImageView.h"

#import "PKGRightInspectorView.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGInstallerApp.h"

#import "PKGInstallerPlugin.h"

#import "PKGLocalizationUtilities.h"

NSString * const PKGDistributionPresentationCurrentPreviewLanguage=@"ui.project.presentation.preview.language";

@interface PKGDistributionPresentationViewController () <PKGPresentationImageViewDelegate,PKGPresentationListViewDataSource,PKGPresentationListViewDelegate>
{
	IBOutlet NSImageView * _proxyIconView;
	
	IBOutlet NSTextField * _windowTitleLabel;
	
	IBOutlet PKGPresentationImageView * _backgroundView;
	
	IBOutlet PKGPresentationListView * _listView;
	
	
	IBOutlet NSButton * _printButton;
	
	IBOutlet NSButton * _saveButton;
	
	IBOutlet NSButton * _goBackButton;
	
	IBOutlet NSButton * _continueButton;
	
	IBOutlet PKGRightInspectorView * _rightView;
	
	
	IBOutlet NSButton * _pluginAddButton;
	IBOutlet NSButton * _pluginRemoveButton;
	
	
	
	NSString * _currentPreviewLanguage;
}

- (void)updateBackgroundView;

- (IBAction)addPlugin:(id)sender;
- (IBAction)removePlugin:(id)sender;

@end

@implementation PKGDistributionPresentationViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_backgroundView.presentationDelegate=self;
	
	_listView.dataSource=self;
	_listView.delegate=self;
	
	// A COMPLETER
}

#pragma mark -

- (void)setDistributionProject:(PKGDistributionProject *)inDistributionProject
{
	if (_distributionProject!=inDistributionProject)
	{
		_distributionProject=inDistributionProject;
		
		[self refreshUI];
	}
}

- (void)setPresentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	if (_presentationSettings!=inPresentationSettings)
	{
		_presentationSettings=inPresentationSettings;
		
		[self.presentationSettings sections_safe];	// Useful to make sure there is a list of steps;
	
		[self refreshUI];
	}
}

#pragma mark -

- (void)updateBackgroundView
{
	void (^displayDefaultImage)() = ^{
		
		// A COMPLETER (check if image is shown on 10.8 or later)
		
		_backgroundView.image=nil;
	};
	
	void (^displayImageNotFound)() = ^{
		
		// A COMPLETER (find the ? image)
		
		_backgroundView.image=nil;
	};
	
	PKGPresentationBackgroundSettings * tBackgroundSettings=[_presentationSettings backgroundSettings_safe];
	
	if (tBackgroundSettings.showCustomImage==NO)
	{
		displayDefaultImage();
		
		return;
	}
	
	_backgroundView.imageAlignment=tBackgroundSettings.imageAlignment;
	_backgroundView.imageScaling=tBackgroundSettings.imageScaling;
	
	PKGFilePath * tFilePath=tBackgroundSettings.imagePath;
	
	if (tFilePath==nil)
	{
		displayDefaultImage();
		
		return;
	}
	
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tFilePath];
	
	if (tAbsolutePath==nil)
	{
		displayImageNotFound();
		
		return;
	}
	
	NSImage * tImage=[[NSImage alloc] initWithContentsOfFile:tAbsolutePath];
	
	if (tImage==nil)
	{
		displayImageNotFound();
		
		return;
	}
	
	_backgroundView.image=tImage;
}

- (void)refreshUI
{
	if (_proxyIconView==nil)
		return;
	
	
	
	if (self.distributionProject!=nil)
	{
		// Proxy Icon
		
		//[[NSWorkspace sharedWorkspace] iconForFileType:@".pkg"]
		
		NSImage * tImage=[[PKGInstallerApp installerApp] iconForPackageType:(self.distributionProject.isFlat==YES) ? PKGInstallerAppDistrbutionFlat : PKGInstallerAppDistributionBundle];
		
		_proxyIconView.image=tImage;
	}
	
	if (_presentationSettings!=nil)
	{
		// Background View
		
		[self updateBackgroundView];
		
		// A COMPLETER
		
		// List View
		
		[_listView reloadData];
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_currentPreviewLanguage=self.documentRegistry[PKGDistributionPresentationCurrentPreviewLanguage];
	
	if (_currentPreviewLanguage==nil)
	{
		NSMutableArray * tEnglishLanguageNames=[PKGLocalizationUtilities englishLanguages];
		
		if (tEnglishLanguageNames!=nil)
		{
			NSArray * tPreferedLocalizations=(__bridge_transfer NSArray *) CFBundleCopyPreferredLocalizationsFromArray((__bridge CFArrayRef) tEnglishLanguageNames);
			
			if (tPreferedLocalizations.count>0)
				_currentPreviewLanguage=[tPreferedLocalizations.firstObject copy];
		}
		
		if (_currentPreviewLanguage==nil)
			_currentPreviewLanguage=@"English";
		
		if (_currentPreviewLanguage!=nil)
			self.documentRegistry[PKGDistributionPresentationCurrentPreviewLanguage]=[_currentPreviewLanguage copy];
	}
	
	[self refreshUI];
	
	// A COMPLETER
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// A COMPLETER
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidResignMainNotification object:self.view.window];
	
	
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.view.window];
	
	// A COMPLETER
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	// A COMPLETER
}

#pragma mark -

- (IBAction)addPlugin:(id)sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.canChooseFiles=YES;
	tOpenPanel.allowsMultipleSelection=YES;
	//tOpenPanel.delegate=self;
	
	tOpenPanel.prompt=NSLocalizedString(@"Add",@"No comment");
	
	// A COMPLETER
}

- (IBAction)removePlugin:(id)sender
{
	// A COMPLETER
}

#pragma mark - PKGPresentationListViewDataSource

- (NSInteger)numberOfStepsInPresentationListView:(PKGPresentationListView *)inPresentationListView
{
	if (inPresentationListView!=_listView)
		return 0;
	
	return self.presentationSettings.sections.count;
}

- (id)presentationListView:(PKGPresentationListView *)inPresentationListView objectForStep:(NSInteger)inStep
{
	if (inPresentationListView!=_listView)
		return nil;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	if (tPresentationSection.pluginPath!=nil)
	{
		// It's a plugin step
		
		NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tPresentationSection.pluginPath];
		
		if (tAbsolutePath==nil)
		{
			// A COMPLETER
			
			return nil;
		}
		
		PKGInstallerPlugin * tInstallerPlugin=[[PKGInstallerPlugin alloc] initWithBundleAtPath:tAbsolutePath];
		
		if (tInstallerPlugin==nil)
		{
			return NSLocalizedStringFromTable(@"Not Found",@"Presentation",@"");
		}
		
		NSString * tSectionTitle=[tInstallerPlugin sectionTitleForLanguage:_currentPreviewLanguage];
		
		return (tSectionTitle!=nil) ? tSectionTitle : NSLocalizedStringFromTable(@"Not Found",@"Presentation",@"");
	}
	else
	{
		return [[[PKGInstallerApp installerApp] pluginWithSectionName:tPresentationSection.installerPluginName] sectionTitleForLanguage:_currentPreviewLanguage];
	}
	
	return nil;
}

#pragma mark - PKGPresentationListViewDelegate

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView shouldSelectStep:(NSInteger)inStep
{
	if (inPresentationListView!=_listView)
		return YES;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	return  ([tPresentationSection.name isEqualToString:PKGPresentationSectionTargetName]==NO &&
			 [tPresentationSection.name isEqualToString:PKGPresentationSectionInstallName]==NO);
}

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView stepWillBeVisible:(NSInteger)inStep
{
	if (inPresentationListView!=_listView)
		return YES;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	if (tPresentationSection.pluginPath!=nil)
		return YES;
	
	if ([tPresentationSection.name isEqualToString:PKGPresentationSectionReadMeName]==YES)
	{
		return [self.presentationSettings readMeSettings_safe].isCustomized;
	}
	
	if ([tPresentationSection.name isEqualToString:PKGPresentationSectionLicenseName]==YES)
	{
		return [self.presentationSettings licenseSettings_safe].isCustomized;
	}
	
	return YES;
}

#pragma mark - PKGPresentationImageViewDelegate

- (void)presentationImageView:(PKGPresentationImageView *)inImageView imagePathDidChange:(NSString *)inPath
{
	// A COMPLETER
}

#pragma mark - Notifications

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	/*if ([[currentViewController_ className] isEqualToString:@"ICPresentationViewInstallerPluginController"]==YES)
	{
		NSString * tPaneTitle;
		
		// Refresh Chapter Title View
		
		tPaneTitle=[currentViewController_ paneTitleForLanguage:currentPreviewLanguage_];
		
		if (tPaneTitle!=nil)
		{
			[IBchapterTitleView_ setStringValue:tPaneTitle];
		}
		else
		{
			[IBchapterTitleView_ setStringValue:@""];
		}
	}*/
	
	// Refresh Background
	
	[self updateBackgroundView];
}

- (void)presentationListViewSelectionDidChange:(NSNotification *)inNotification
{
	// A COMPLETER
}

@end
