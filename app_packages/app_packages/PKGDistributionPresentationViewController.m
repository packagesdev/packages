/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionPresentationViewController.h"

#import "PKGDistributionMainControlledView.h"

#import "PKGInstallationSurgeryWindow.h"

#import <HumanInterface/HumanInterface.h>

#import "PKGPresentationListView.h"

#import "PKGPresentationImageView.h"

#import "PKGPresentationPaneTitleView.h"

#import "PKGRightInspectorView.h"

#import "PKGPresentationBox.h"
#import "PKGPresentationPluginButton.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGPresentationTitleSettings.h"

#import "PKGChoiceItemOptionsDependencies+UI.h"
#import "PKGPresentationBackgroundSettings+UI.h"
#import "PKGPresentationLocalizableStepSettings+UI.h"
#import "PKGPresentationSection+UI.h"

#import "PKGPresentationTheme.h"
#import "PKGPresentationBackgroundSettings+Theme.h"

#import "PKGInstallerApp.h"

#import "PKGPresentationInspectorItem.h"

#import "PKGLocalizationUtilities.h"

#import "PKGLanguageConverter.h"

#import "NSIndexSet+Analysis.h"

#import "NSFileManager+FileTypes.h"

#import "PKGApplicationPreferences.h"

#import "PKGOwnershipAndReferenceStyleViewController.h"
#import "PKGOwnershipAndReferenceStylePanel.h"



#import "PKGPresentationSectionViewController.h"
#import "PKGPresentationInspectorViewController.h"

#import "PKGDistributionPresentationInstallerPluginOpenPanelDelegate.h"

#import "PKGPresentationSectionInstallationTypeViewController.h"
#import "PKGPresentationSectionInstallerPluginViewController.h"

#import "PKGPresentationInstallationTypeChoiceDependenciesViewController.h"

#ifndef NSAppKitVersionNumber10_13
#define NSAppKitVersionNumber10_13 1504
#endif

NSString * const PKGDistributionPresentationSelectedStep=@"ui.project.presentation.step.selected";

NSString * const PKGDistributionPresentationInspectedItem=@"ui.project.presentation.item.inspected";

NSString * const PKGDistributionPresentationSectionsInternalPboardType=@"fr.whitebox.packages.internal.distribution.presentation.sections";

NSString * const PKGDistributionPresentationShowAppearanceSwitchKey=@"ui.project.presentation.appearance-switch.show";

#define PKGDistributionPresentationInspectorEnlargementWidth 170.0

@interface PKGDistributionPresentationViewController () <PKGPresentationImageViewDelegate,PKGPresentationListViewDataSource,PKGPresentationListViewDelegate>
{
	IBOutlet NSView * _leftView;
	
	IBOutlet HIWWindowView * _windowView;
	
	IBOutlet PKGPresentationImageView * _backgroundView;
	
	IBOutlet PKGPresentationListView * _listView;
	
	IBOutlet PKGPresentationPaneTitleView * _pageTitleView;
	
	IBOutlet NSView * _sectionContentsView;
	
	IBOutlet NSButton * _printButton;
	
	IBOutlet NSButton * _saveButton;
	
	IBOutlet NSButton * _goBackButton;
	
	IBOutlet NSButton * _continueButton;
	
	
	IBOutlet PKGPresentationPluginButton * _pluginAddButton;
	IBOutlet PKGPresentationPluginButton * _pluginRemoveButton;
	
	IBOutlet PKGPresentationBox * _appearancePreviewBox;
	
	IBOutlet NSButton * _appearanceLightRadioButton;
	IBOutlet NSButton * _appearanceDarkRadioButton;
	
	IBOutlet NSView * _accessoryPlaceHolderView;
	
	IBOutlet NSPopUpButton * _languagePreviewPopUpButton;
	
	
	IBOutlet PKGRightInspectorView * _rightView;
	
	IBOutlet NSPopUpButton * _inspectorPopUpButton;
	
	IBOutlet NSView * _inspectorContentsView;
	
	PKGPresentationSectionViewController * _currentSectionViewController;
	
	
	PKGPresentationInspectorItemTag _currentInspectorItemTag;
	PKGPresentationInspectorViewController * _currentInspectorViewController;
	
	PKGDistributionPresentationInstallerPluginOpenPanelDelegate * _openPanelDelegate;
	
	NSArray * _supportedLocalizations;
	
	BOOL _supportThemeYosemite;
	
	PKGPresentationThemeVersion _currentTheme;
	
	NSString * _currentPreviewLanguage;
	
	NSIndexSet * _internalDragData;
	
	NSArray * _navigationButtons;
	
	
	PKGPresentationInstallationTypeChoiceDependenciesViewController * _dependenciesViewController;
	
	PKGInstallationSurgeryWindow * _surgeryWindow;
	
	CGFloat _savedRightViewWidth;
}

- (void)updateBackgroundView;
- (void)updateTitleViews;

- (IBAction)switchPresentationTheme:(id)sender;

- (IBAction)addPlugin:(id)sender;
- (IBAction)removePlugin:(id)sender;

- (IBAction)switchPreviewAppearance:(id)sender;

- (IBAction)switchPreviewLanguage:(NSPopUpButton *)sender;

- (IBAction)switchInspectedView:(id)sender;

- (void)showViewForSection:(PKGPresentationSection *)inPresentationSection;
- (void)showViewForInspectorItem:(PKGPresentationInspectorItem *)inInspectorItem;

// Notifications

- (void)distributionViewEffectiveAppearanceDidChange:(NSNotification *)inNotification;

- (void)selectionSectionLanguageDidChange:(NSNotification *)inNotification;

- (void)windowStateDidChange:(NSNotification *)inNotification;

- (void)windowViewEffectiveAppearanceDidChange:(NSNotification *)inNotification;

- (void)titleSettingsDidChange:(NSNotificationCenter *)inNotification;

- (void)backgroundImageSettingsDidChange:(NSNotification *)inNotification;

- (void)choiceDependenciesEditionWillBegin:(NSNotification *)inNotification;
- (void)choiceDependenciesEditionDidEnd:(NSNotification *)inNotification;

- (void)leftViewDidResize:(NSNotification *)inNotification;

- (void)pluginPathDidChange:(NSNotification *)inNotification;

@end

@implementation PKGDistributionPresentationViewController

+ (void)initialize
{
	NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
	
	[tUserDefaults registerDefaults:@{PKGDistributionPresentationShowAppearanceSwitchKey:@(NO)}];
}

- (instancetype)initWithNibName:(NSString *)inNibName bundle:(NSBundle *)inBundle
{
	self=[super initWithNibName:inNibName bundle:inBundle];
	
	if (self!=nil)
	{
		_supportedLocalizations=[[PKGInstallerApp installerApp] supportedLocalizations];
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// Window
	
	_windowView.drawsShadow=YES;
	
	// Background
	
	_backgroundView.presentationDelegate=self;
	
	[_backgroundView registerForDraggedTypes:@[NSFilenamesPboardType]];
	
	_listView.dataSource=self;
	_listView.delegate=self;
	
	[_listView registerForDraggedTypes:@[PKGDistributionPresentationSectionsInternalPboardType,NSFilenamesPboardType]];
	
	_navigationButtons=@[_printButton,_saveButton,_goBackButton,_continueButton];
	
	// Plugin Buttons
	
	_pluginAddButton.pluginButtonType=PKGPlusButton;
	_pluginRemoveButton.pluginButtonType=PKGMinusButton;
	
	// Mode
	
	if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14 || [[NSUserDefaults standardUserDefaults] boolForKey:PKGDistributionPresentationShowAppearanceSwitchKey]==NO)
	{
		_appearancePreviewBox.hidden=YES;
	}
	
	// Build the Preview In Menu
	
	NSMenu * tLanguagesMenu=_languagePreviewPopUpButton.menu;
	
	[tLanguagesMenu removeAllItems];
	
	[_supportedLocalizations enumerateObjectsUsingBlock:^(PKGInstallerAppLocalization * bLocalization, NSUInteger bIndex, BOOL *bOutStop) {
		
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:bLocalization.localizedName action:nil keyEquivalent:@""];
		tMenuItem.image=bLocalization.flagIcon;
		tMenuItem.tag=bIndex;
		
		[tLanguagesMenu addItem:tMenuItem];
	}];
	
	_languagePreviewPopUpButton.menu=tLanguagesMenu;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowViewEffectiveAppearanceDidChange:) name:HIWWindowViewEffectiveAppearanceDidChangeNotification object:_windowView];
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
		if (_presentationSettings!=nil)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPresentationStepSettingsDidChangeNotification object:[_presentationSettings titleSettings_safe]];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPresentationStepSettingsDidChangeNotification object:[_presentationSettings backgroundSettings_safe]];
		}
		
		_presentationSettings=inPresentationSettings;
		
		[self.presentationSettings sections_safe];	// Useful to make sure there is a list of steps;
	
		[self refreshUI];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(titleSettingsDidChange:) name:PKGPresentationStepSettingsDidChangeNotification object:[_presentationSettings titleSettings_safe]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundImageSettingsDidChange:) name:PKGPresentationStepSettingsDidChangeNotification object:[_presentationSettings backgroundSettings_safe]];
	}
}

#pragma mark -

- (void)updateBackgroundView
{
	void (^displayDefaultImage)() = ^{
		
		PKGPresentationThemeVersion tThemeVersion=_currentTheme;
		
		switch (tThemeVersion)
		{
			case PKGPresentationThemeMountainLion:
				
				if (_supportThemeYosemite==NO)
					tThemeVersion=PKGPresentationThemeYosemite;
				
				break;
				
			default:
				
				break;
		}
		
		switch (tThemeVersion)
		{
			case PKGPresentationThemeMountainLion:
			{
				PKGInstallerApp * tInstallerApp=[PKGInstallerApp installerApp];
				
				self->_backgroundView.image=tInstallerApp.defaultBackground;
				
				self->_backgroundView.imageAlignment=NSImageAlignLeft;
				self->_backgroundView.imageScaling=NSImageScaleProportionallyDown;
				
				break;
			}
			default:
				
				self->_backgroundView.image=nil;
				
				return;
		}
	};
	
	void (^displayImageNotFound)() = ^{
		
		self->_backgroundView.image=[NSImage imageNamed:@"MissingFile"];
		
		self->_backgroundView.imageAlignment=NSImageAlignBottomLeft;
		self->_backgroundView.imageScaling=NSImageScaleNone;
	};
	
	PKGPresentationBackgroundSettings * tBackgroundSettings=[_presentationSettings backgroundSettings_safe];
	
	PKGPresentationBackgroundAppearanceSettings * tBackgroundAppearanceSettings=nil;
	
	if (tBackgroundSettings.sharedSettingsForAllAppearances==YES)
	{
		tBackgroundAppearanceSettings=[tBackgroundSettings appearanceSettingsForAppearanceMode:PKGPresentationAppearanceModeShared];
	}
	else
	{
		PKGPresentationThemeVersion tTheme=_currentTheme;
		
		if (tTheme==PKGPresentationThemeMojaveDynamic)
		{
			if ([_windowView WB_isEffectiveAppearanceDarkAqua]==NO)
				tTheme=PKGPresentationThemeMojaveLight;
			else
				tTheme=PKGPresentationThemeMojaveDark;
		}
		
		tBackgroundAppearanceSettings=[tBackgroundSettings appearanceSettingsForTheme:tTheme];
	}
	
	if (tBackgroundAppearanceSettings.showCustomImage==NO)
	{
		displayDefaultImage();
		
		return;
	}
	
	if (tBackgroundAppearanceSettings.imageLayoutDirection==PKGImageLayoutDirectionNatural)
	{
		// A COMPLETER (Alignment should match script)
		
		_backgroundView.imageAlignment=tBackgroundAppearanceSettings.imageAlignment;
	}
	else
	{
		_backgroundView.imageAlignment=tBackgroundAppearanceSettings.imageAlignment;
	}
	
	_backgroundView.imageScaling=tBackgroundAppearanceSettings.imageScaling;
	
	PKGFilePath * tFilePath=tBackgroundAppearanceSettings.imagePath;
	
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

- (void)updateWindowView
{
	HIWOperatingSystemVersion tSystemVersion;
	HIWAppearance tAppearance=HIWAppearanceEffective;
	
	switch(_currentTheme)
	{
		case PKGPresentationThemeMountainLion:
			
			tSystemVersion.majorVersion=10;
			tSystemVersion.minorVersion=8;
			tSystemVersion.patchVersion=0;
			
			tAppearance=HIWAppearanceAqua;
			
			break;
			
		case PKGPresentationThemeMojaveDynamic:
			
			tSystemVersion=HIWOperatingSystemVersionCurrent;
			
			tAppearance=HIWAppearanceEffective;
			
			break;
			
		case PKGPresentationThemeMojaveLight:
			
			tSystemVersion=HIWOperatingSystemVersionCurrent;
			
			tAppearance=HIWAppearanceAqua;
			
			break;
			
		case PKGPresentationThemeMojaveDark:
			
			tSystemVersion=HIWOperatingSystemVersionCurrent;
			
			tAppearance=HIWAppearanceDarkAqua;
			
			break;
	}
	
	_windowView.operatingSystemVersion=tSystemVersion;
	_windowView.displayedAppearance=tAppearance;
}

- (void)updateTitleViewFont
{
	PKGPresentationThemeVersion tTheme=_currentTheme;
	
	if (tTheme==PKGPresentationThemeMojaveDynamic)
	{
		NSWindowController * tWindowController=((PKGDocument *)self.document).windowControllers.firstObject;	// A VOIR
		
		if ([tWindowController.window WB_isEffectiveAppearanceDarkAqua]==NO)
			tTheme=PKGPresentationThemeMojaveLight;
		else
			tTheme=PKGPresentationThemeMojaveDark;
	}
	
	switch(tTheme)
	{
		case PKGPresentationThemeMountainLion:
			
			_pageTitleView.font=[NSFont boldSystemFontOfSize:14.0];
			
			break;
			
			//case PKGPresentationThemeYosemite:
		case PKGPresentationThemeMojaveLight:
			
			_pageTitleView.font=[NSFont labelFontOfSize:[NSFont systemFontSize]];
			
			break;
			
		case PKGPresentationThemeMojaveDark:
			
			_pageTitleView.font=[NSFont labelFontOfSize:[NSFont systemFontSize]];
			
			break;
			
		default:
			
			NSLog(@"Unsupported theme");
			break;
	}
}

- (void)updateTitleViews
{
	// Refresh Chapter Title View
	
	if (_currentSectionViewController!=nil)
	{
		NSString * tPaneTitle=[_currentSectionViewController sectionPaneTitle];
	
		_pageTitleView.stringValue=(tPaneTitle!=nil) ? tPaneTitle : @"";
	}
	
	// Refresh Fake Window Title
	
	PKGPresentationTitleSettings * tTitleSettings=[self.presentationSettings titleSettings_safe];
	
	NSString * tMostAppropriateLocalizedTitle=[tTitleSettings valueForLocalization:_currentPreviewLanguage exactMatch:NO];
	
	if (tMostAppropriateLocalizedTitle==nil)
    {
        tMostAppropriateLocalizedTitle=self.distributionProject.settings.name.stringByDeletingPathExtension;
    }
    
	if (tMostAppropriateLocalizedTitle!=nil)
	{
		NSString * tFinalTitle=[self stringByReplacingKeysInString:tMostAppropriateLocalizedTitle];
        
        NSString * tTitleFormat=[[PKGInstallerApp installerApp] localizedStringForKey:@"WindowTitle" localization:_currentPreviewLanguage];
		
		_windowView.title=(tTitleFormat!=nil) ? [NSString stringWithFormat:tTitleFormat,tFinalTitle] : tFinalTitle;
	}
	else
	{
		_windowView.title=@"-";
	}
}

- (void)refreshUI
{
	if (_backgroundView==nil)
		return;
	
	if (self.distributionProject!=nil)
	{
		// Proxy Icon
		
		NSImage * tImage=[[PKGInstallerApp installerApp] iconForPackageType:(self.distributionProject.isFlat==YES) ? PKGInstallerAppDistributionFlat : PKGInstallerAppDistributionBundle];
		
		_windowView.proxyIcon=tImage;
		
		// LocksButton
		
		_windowView.showsLockButton=(self.distributionProject.settings.certificateName!=nil);
	}
	
	if (_presentationSettings!=nil)
	{
		// Background View
		
		[self updateBackgroundView];
		
		// Title Views
		
		[self updateTitleViews];
		
		// List View
		
		NSNumber * tNumber=self.documentRegistry[PKGDistributionPresentationSelectedStep];
		
		[_listView reloadData];
		
		[_listView selectStep:(tNumber!=nil) ? [tNumber integerValue] : 0];
		
		// Inspector
		
		tNumber=self.documentRegistry[PKGDistributionPresentationInspectedItem];
		
		if (tNumber!=nil)
		{
			PKGPresentationInspectorItemTag * tItemTag=[tNumber integerValue];
		
			[_inspectorPopUpButton selectItemWithTag:tItemTag];
		
			// Show Inspected View
		
			[self showViewForInspectorItem:[PKGPresentationInspectorItem inspectorItemForTag:tItemTag]];
		}
		
		// Show the Section view
		
		[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:_listView userInfo:(tNumber==nil) ? nil : @{}]];
		
		// Language PopUpButton
		
		NSUInteger tLocalizationIndex=[_supportedLocalizations indexOfObjectPassingTest:^BOOL(PKGInstallerAppLocalization * bLocalization, NSUInteger bIndex, BOOL *bOutStop) {
		
			return [self->_currentPreviewLanguage isEqualToString:bLocalization.englishName];
			
		}];
		
		[_languagePreviewPopUpButton selectItemWithTag:(tLocalizationIndex!=NSNotFound) ? tLocalizationIndex : 0];
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	
	PKGInstallerApp * tInstallerApp=[PKGInstallerApp installerApp];
	
	_supportThemeYosemite=([tInstallerApp isVersion6_1OrLater]==NO);
	
	
	NSNumber * tNumber=self.documentRegistry[PKGPresentationTheme];
	
	if (tNumber!=nil)
	{
		_currentTheme=[tNumber unsignedIntegerValue];
	}
	else
	{
		/*if (NSAppKitVersionNumber>=NSAppKitVersionNumber10_13)*/
		{
			_currentTheme=PKGPresentationThemeMojaveDynamic;
		}
		/*else
		{
			if ([tInstallerApp isVersion6_1OrLater]==YES)
				_currentTheme=PKGPresentationThemeYosemite;
			else
				_currentTheme=PKGPresentationThemeMountainLion;
		}*/
		
		self.documentRegistry[PKGPresentationTheme]=@(_currentTheme);
	}
	
	[self updateWindowView];
	
	[self updateTitleViewFont];
	
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
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	if (NSAppKitVersionNumber>=NSAppKitVersionNumber10_14)
	{
		NSString * tSelectedAppearance=self.documentRegistry[PKGDistributionPresentationSelectedAppearance];
		NSString * tCurrentAppearance=[_leftView WB_effectiveAppearanceName];
		
		// Update the left view appearance if needed
		
		if (tSelectedAppearance==nil)
		{
			if (tCurrentAppearance!=nil)
				[_leftView setAppearance:nil];
		}
		else
		{
			if (tCurrentAppearance==nil || [tCurrentAppearance isEqualToString:tSelectedAppearance]==NO)
				[_leftView setAppearance:[NSAppearance appearanceNamed:tSelectedAppearance]];
		}
		
		WB_AppearanceMode tAppearanceMode=[NSResponder WB_appearanceModeForAppearanceName:[_leftView WB_effectiveAppearanceName]];
		
		switch (tAppearanceMode)
		{
			case WB_AppearanceAqua:
				
				_appearanceLightRadioButton.state=WBControlStateValueOn;
				
				break;
				
			case WB_AppearanceDarkAqua:
				
				_appearanceDarkRadioButton.state=WBControlStateValueOn;
				
				break;
				
		}
	}
	
	[_currentSectionViewController WB_viewDidAppear];
	[_currentInspectorViewController WB_viewDidAppear];
	
	// Register for notifications
	
	NSNotificationCenter * tDefaultCenter=[NSNotificationCenter defaultCenter];
	NSWindow * tWindow=self.view.window;
	
	[tDefaultCenter addObserver:self selector:@selector(selectionSectionLanguageDidChange:) name:PKGPresentationSectionSelectedSectionLanguageDidChangeNotification object:tWindow];
	
	[tDefaultCenter addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidBecomeMainNotification object:tWindow];
	[tDefaultCenter addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidResignMainNotification object:tWindow];
	
	[tDefaultCenter addObserver:self selector:@selector(choiceDependenciesEditionWillBegin:) name:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:self.document];
	[tDefaultCenter addObserver:self selector:@selector(choiceDependenciesEditionDidEnd:) name:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:self.document];
	
	[tDefaultCenter addObserver:self selector:@selector(presentationThemeDidChange:) name:PKGPresentationThemeDidChangeNotification object:tWindow];
	
	[tDefaultCenter addObserver:self selector:@selector(distributionViewEffectiveAppearanceDidChange:) name:PKGDistributionViewEffectiveAppearanceDidChangeNotification object:tWindow];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_currentSectionViewController WB_viewWillDisappear];
	[_currentInspectorViewController WB_viewWillDisappear];
	
	NSNotificationCenter * tDefaultCenter=[NSNotificationCenter defaultCenter];
	
	[tDefaultCenter removeObserver:self name:PKGPresentationSectionSelectedSectionLanguageDidChangeNotification object:nil];

	[tDefaultCenter removeObserver:self name:NSWindowDidBecomeMainNotification object:nil];
	[tDefaultCenter removeObserver:self name:NSWindowDidResignMainNotification object:nil];
	
	[tDefaultCenter removeObserver:self name:PKGPresentationThemeDidChangeNotification object:nil];
	
	[tDefaultCenter removeObserver:self name:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:nil];
	[tDefaultCenter removeObserver:self name:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:nil];
	
	[tDefaultCenter removeObserver:self name:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:nil];
	
	[tDefaultCenter removeObserver:self name:PKGPresentationSectionPluginPathDidChangeNotification object:nil];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];

	[_currentSectionViewController WB_viewDidDisappear];
	[_currentInspectorViewController WB_viewDidDisappear];
}

#pragma mark -

- (IBAction)switchPresentationTheme:(NSMenuItem *)sender
{
	if (sender.tag==_currentTheme)
		return;

	_currentTheme=sender.tag;
	
	[self updateWindowView];
	
	[self updateTitleViewFont];
	
	self.documentRegistry[PKGPresentationTheme]=@(_currentTheme);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationThemeDidChangeNotification object:self.view.window];
}

- (IBAction)addPlugin:(id)sender
{
	NSMutableArray * tSections=self.presentationSettings.sections;
	
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.canChooseFiles=YES;
	tOpenPanel.canChooseDirectories=NO;
	tOpenPanel.allowsMultipleSelection=YES;
	
	_openPanelDelegate=[PKGDistributionPresentationInstallerPluginOpenPanelDelegate new];
	
	_openPanelDelegate.plugInsPaths=[tSections WB_arrayByMappingObjectsLenientlyUsingBlock:^NSString *(PKGPresentationSection * bPresentationSection, NSUInteger bIndex) {
		
		PKGFilePath * tFilePath=bPresentationSection.pluginPath;
		
		if (tFilePath==nil)
			return nil;
		
		return [self.filePathConverter absolutePathForFilePath:tFilePath];
	}];
	
	tOpenPanel.delegate=_openPanelDelegate;
	
	tOpenPanel.prompt=NSLocalizedString(@"Add",@"No comment");
	
	__block PKGFilePathType tReferenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	PKGOwnershipAndReferenceStyleViewController * tOwnershipAndReferenceStyleViewController=nil;
	
	if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
	{
		tOwnershipAndReferenceStyleViewController=[PKGOwnershipAndReferenceStyleViewController new];
		
		tOwnershipAndReferenceStyleViewController.canChooseOwnerAndGroupOptions=NO;
		tOwnershipAndReferenceStyleViewController.referenceStyle=tReferenceStyle;
		
		NSView * tAccessoryView=tOwnershipAndReferenceStyleViewController.view;
		
		tOpenPanel.accessoryView=tAccessoryView;
	}
	
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult!=WBFileHandlingPanelOKButton)
			return;
		
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
			tReferenceStyle=tOwnershipAndReferenceStyleViewController.referenceStyle;
		
		NSArray * tPaths=[tOpenPanel.URLs WB_arrayByMappingObjectsUsingBlock:^(NSURL * bURL,NSUInteger bIndex){
			
			return bURL.path;
		}];
		
		__block BOOL tModified=NO;
		__block NSInteger tInsertionIndex=self->_listView.selectedStep+1;
		
		[tPaths enumerateObjectsUsingBlock:^(NSString * bPath, NSUInteger bIndex, BOOL *bOutStop) {
			
			NSBundle * tBundle=[NSBundle bundleWithPath:bPath];
			
			if (tBundle==nil)
			{
				// A COMPLETER
				
				return;
			}
			
			PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:bPath type:tReferenceStyle];
			
			if (tFilePath==nil)
			{
				// A COMPLETER
				
				return;
			}
			
			PKGPresentationSection * tPresentationSection=[[PKGPresentationSection alloc] initWithPluginPath:tFilePath];
			
			[tSections insertObject:tPresentationSection atIndex:tInsertionIndex];
			
			tInsertionIndex++;
			
			tModified=YES;
		}];
		
		if (tModified==YES)
		{
			[self->_listView reloadData];
			
			[self noteDocumentHasChanged];
		}
	}];
}

- (IBAction)removePlugin:(id)sender
{
	NSAlert * tAlert=[NSAlert new];
	tAlert.messageText=NSLocalizedStringFromTable(@"Do you really want to remove this Installer plugin?", @"Presentation",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		NSInteger tSelectedStep=self->_listView.selectedStep;
		
		if (tSelectedStep<0 || tSelectedStep>=self.presentationSettings.sections.count)
			return;
		
		[self.presentationSettings.sections removeObjectAtIndex:tSelectedStep];
		
		[self->_listView reloadData];
		
		// Find the first selectable Step
		
		NSInteger tIndex=tSelectedStep;
		
		if (tIndex==0)
		{
			[self->_listView selectStep:0];
		}
		else
		{
			tIndex=tSelectedStep-1;
			
			for (;tIndex>=0;tIndex--)
			{
				if ([self presentationListView:self->_listView shouldSelectStep:tIndex]==YES)
				{
					[self->_listView selectStep:tIndex];
					
					break;
				}
			}
		}
		
		// Refresh the list view
		
		[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:self->_listView]];
		
		[self noteDocumentHasChanged];
	}];
}

- (IBAction)switchPreviewAppearance:(NSButton *)sender
{
    NSString * tAppearanceName=[NSResponder WB_appearanceNameForAppearanceMode:sender.tag];
	
    sender.state=WBControlStateValueOn;
    
    self.documentRegistry[PKGDistributionPresentationSelectedAppearance]=tAppearanceName;
	
    if (NSAppKitVersionNumber>NSAppKitVersionNumber10_14)
        [_leftView setAppearance:[NSAppearance appearanceNamed:tAppearanceName]];
}

- (IBAction)switchPreviewLanguage:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	NSString * tNewLanguage=((PKGInstallerAppLocalization *)_supportedLocalizations[tTag]).englishName;
	
	if ([tNewLanguage isEqualToString:_currentPreviewLanguage]==NO)
	{
		_currentPreviewLanguage=[tNewLanguage copy];
		
		self.documentRegistry[PKGDistributionPresentationCurrentPreviewLanguage]=[_currentPreviewLanguage copy];
		
		// Refresh Section View
		
		if (_currentSectionViewController!=nil)
		{
			_currentSectionViewController.localization=_currentPreviewLanguage;
			
			// Refresh Buttons
			
			[_currentSectionViewController updateButtons:_navigationButtons];
		}
		
		// Refresh Window title and Pane title
		
		[self updateTitleViews];
		
		// Refresh List View
		
		[_listView reloadData];
	}
}

- (IBAction)switchInspectedView:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	if (tTag!=_currentInspectorItemTag)
	{
		PKGPresentationInspectorItemTag tSectionTag=tTag;
		
		if (tSectionTag==PKGPresentationInspectorItemTitle ||
			tSectionTag==PKGPresentationInspectorItemBackground)
			tSectionTag=PKGPresentationInspectorItemIntroduction;
		
		NSUInteger tIndex=[self.presentationSettings.sections indexOfObjectPassingTest:^BOOL(PKGPresentationSection * bPresentationSection, NSUInteger bIndex, BOOL *bOutStop) {
			
			return (bPresentationSection.inspectorItemTag==tSectionTag);
			
		}];
						   
		if (tIndex==NSNotFound)
		{
			// A COMPLETER
			
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			// Show the Inspector View
			
			[self showViewForInspectorItem:[PKGPresentationInspectorItem inspectorItemForTag:tTag]];
			
			self.documentRegistry[PKGDistributionPresentationInspectedItem]=@(tTag);
			
			// Show the View
			
			if (self->_listView.selectedStep!=tIndex)
			{
				[self->_listView selectStep:tIndex];
			
				[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:self->_listView userInfo:@{}]];
			}
		});
	}
}

- (IBAction)switchShowRawNames:(id)sender
{
	[_currentSectionViewController performSelector:@selector(switchShowRawNames:) withObject:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchPresentationTheme:))
	{
		inMenuItem.state=(inMenuItem.tag==_currentTheme) ? WBControlStateValueOn : WBControlStateValueOff;
		
		return YES;
	}
	
	if (tAction==@selector(switchInspectedView:))
		return (inMenuItem.tag!=PKGPresentationInspectorItemPlugIn);
	
	if (tAction==@selector(switchShowRawNames:))
	{
		if ([_currentSectionViewController isKindOfClass:PKGPresentationSectionInstallationTypeViewController.class]==NO)
			return NO;
		
		return [_currentSectionViewController validateMenuItem:inMenuItem];
	}
	
	return YES;
}

#pragma mark -

- (void)showViewForSection:(PKGPresentationSection *)inPresentationSection
{
	Class tNewClass=[inPresentationSection viewControllerClass];
	
	if (_currentSectionViewController!=nil)
	{
		if ([_currentSectionViewController class]==tNewClass && [tNewClass isKindOfClass:PKGPresentationSectionInstallerPluginViewController.class]==NO)
		{
			// A COMPLETER
		
			return;
		}
		
		[_currentSectionViewController WB_viewWillDisappear];
		
		[_accessoryPlaceHolderView setSubviews:@[]];
		
		[_currentSectionViewController.view removeFromSuperview];
		
		[_currentSectionViewController WB_viewDidDisappear];
	}
	
	PKGPresentationSectionViewController * tNewSectionViewController=nil;
	
	// Unregister for notification
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPresentationSectionPluginPathDidChangeNotification object:nil];
	
	if (inPresentationSection.pluginPath==nil)
	{
		tNewSectionViewController=[[tNewClass alloc] initWithDocument:self.document presentationSettings:self.presentationSettings];
	}
	else
	{
		tNewSectionViewController=[[tNewClass alloc] initWithDocument:self.document presentationSection:inPresentationSection];
	
		// Register for notifications
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginPathDidChange:) name:PKGPresentationSectionPluginPathDidChangeNotification object:inPresentationSection];
	}
	
	if (tNewSectionViewController==nil)
	{
		// A COMPLETER
	}
	
	// Set the appropriate localization
	
	tNewSectionViewController.localization=_currentPreviewLanguage;
	
	
	tNewSectionViewController.view.frame=_sectionContentsView.bounds;
	
	[tNewSectionViewController WB_viewWillAppear];
	
	[_sectionContentsView addSubview:tNewSectionViewController.view];
	
	// Title view
	
	NSString * tPaneTitle=[tNewSectionViewController sectionPaneTitle];
	
	_pageTitleView.stringValue=(tPaneTitle!=nil) ? tPaneTitle : @"";
	
	// Buttons
	
	[tNewSectionViewController updateButtons:_navigationButtons];
	
	// Accessory view
	
	if (tNewSectionViewController.accessoryView!=nil)
	{
		NSRect tBounds=_accessoryPlaceHolderView.bounds;
		
		tNewSectionViewController.accessoryView.frame=tBounds;
		
		[_accessoryPlaceHolderView addSubview:tNewSectionViewController.accessoryView];
	}
	
	[tNewSectionViewController WB_viewDidAppear];
	
	_currentSectionViewController=tNewSectionViewController;
}

- (void)showViewForInspectorItem:(PKGPresentationInspectorItem *)inInspectorItem
{
	if (inInspectorItem==nil)
		return;
	
	Class tNewClass=inInspectorItem.inspectorViewControllerClass;
	
	if (tNewClass==nil)
		return;
	
	BOOL tIsInstallerPluginInspectorViewController=[NSStringFromClass(tNewClass) isEqualToString:@"PKGPresentationInstallerPluginInspectorViewController"];
	
	if (_currentInspectorViewController!=nil)
	{
		if ([_currentInspectorViewController class]==tNewClass && tIsInstallerPluginInspectorViewController==NO)
		{
			// A COMPLETER
			
			return;
		}
		
		[_currentInspectorViewController WB_viewWillDisappear];
		
		[_currentInspectorViewController.view removeFromSuperview];
		
		[_currentInspectorViewController WB_viewDidDisappear];
	}
	
	PKGPresentationInspectorViewController * tNewInspectorViewController=nil;
	
	if (tIsInstallerPluginInspectorViewController==NO)
		tNewInspectorViewController=[[tNewClass alloc] initWithDocument:self.document presentationSettings:self.presentationSettings];
	else
		tNewInspectorViewController=[[tNewClass alloc] initWithDocument:self.document presentationSection:self.presentationSettings.sections[_listView.selectedStep]];
	
	if (tNewInspectorViewController==nil)
	{
		// A COMPLETER
	}
	
	tNewInspectorViewController.view.frame=_inspectorContentsView.bounds;
	
	[tNewInspectorViewController WB_viewWillAppear];
	
	[_inspectorContentsView addSubview:tNewInspectorViewController.view];
	
	[tNewInspectorViewController WB_viewDidAppear];
	
	_currentInspectorViewController=tNewInspectorViewController;
	
	_currentInspectorItemTag=inInspectorItem.tag;
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
			NSLog(@"Unable to determine absolute path for file path (%@)",tAbsolutePath);
			
			return nil;
		}
		
		PKGInstallerPlugin * tInstallerPlugin=[[PKGInstallerPlugin alloc] initWithBundleAtPath:tAbsolutePath];
		
		if (tInstallerPlugin==nil)
			return NSLocalizedStringFromTable(@"Not Found", @"Presentation",@"");
		
		NSString * tSectionTitle=[tInstallerPlugin sectionTitleForLocalization:_currentPreviewLanguage];
		
		return (tSectionTitle!=nil) ? tSectionTitle : NSLocalizedStringFromTable(@"Not Found", @"Presentation",@"");
	}
	else
	{
		return [[[PKGInstallerApp installerApp] pluginWithSectionName:tPresentationSection.name] sectionTitleForLocalization:_currentPreviewLanguage];
	}
	
	return nil;
}

- (void)presentationListView:(PKGPresentationListView *)inPresentationListView draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:(NSDragOperation)inOperation
{
	_internalDragData=nil;
}

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView writeStep:(NSInteger) inStep toPasteboard:(NSPasteboard*) inPasteboard
{
	if (_listView!=inPresentationListView)
		return NO;

	if (inStep<0 || inStep>=self.presentationSettings.sections.count)
		return NO;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	if (tPresentationSection.pluginPath==nil)
		return NO;
	
	_internalDragData=[NSIndexSet indexSetWithIndex:inStep];
	
	[inPasteboard declareTypes:@[PKGDistributionPresentationSectionsInternalPboardType] owner:self];
	
	[inPasteboard setData:[NSData data] forType:PKGDistributionPresentationSectionsInternalPboardType];
	
	return YES;
}

- (NSDragOperation)presentationListView:(PKGPresentationListView*)inPresentationListView validateDrop:(id <NSDraggingInfo>)info proposedStep:(NSInteger)inStep
{
	if (_listView!=inPresentationListView)
		return NSDragOperationNone;
	
	if (inStep<0 || inStep>=self.presentationSettings.sections.count)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[PKGDistributionPresentationSectionsInternalPboardType]]!=nil)
	{
		// We need to check it's an internal drag
		
		if (_listView==[info draggingSource])
		{
			// Check that the step is acceptable
			
			if ([_internalDragData WB_containsOnlyOneRange]==YES)
			{
				NSUInteger tFirstIndex=_internalDragData.firstIndex;
				NSUInteger tLastIndex=_internalDragData.lastIndex;
				
				if (inStep>=tFirstIndex && inStep<=(tLastIndex+1))
					return NSDragOperationNone;
			}
			else
			{
				if ([_internalDragData containsIndex:(inStep-1)]==YES)
					return NSDragOperationNone;
			}
			
			return NSDragOperationMove;
		}
		
		return NSDragOperationNone;
	}
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		// We need to check that the plugins are not already in the list
		
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tArray.count==0)
			return NSDragOperationNone;
		
		NSMutableArray * tExistingPlugins=[self.presentationSettings.sections WB_arrayByMappingObjectsLenientlyUsingBlock:^NSString *(PKGPresentationSection * bPresentationSection, NSUInteger bIndex) {
			
			PKGFilePath * tFilePath=bPresentationSection.pluginPath;
			
			if (tFilePath==nil)
				return nil;
			
			return [self.filePathConverter absolutePathForFilePath:tFilePath];
		}];
		
		NSFileManager * tFileManager=[NSFileManager defaultManager];
		
		for(NSString * tPath in tArray)
		{
			if ([tPath.pathExtension caseInsensitiveCompare:@"bundle"]!=NSOrderedSame)
				return NSDragOperationNone;
			
			if ([tExistingPlugins indexOfObjectPassingTest:^BOOL(NSString * bPlugInPath,NSUInteger bIndex,BOOL * bOutStop){
				
				return ([bPlugInPath caseInsensitiveCompare:tPath]==NSOrderedSame);
				
			}]!=NSNotFound)
				return NSDragOperationNone;
				
			BOOL isDirectory;
			
			[tFileManager fileExistsAtPath:tPath isDirectory:&isDirectory];
			
			if (isDirectory==NO)
				return NSDragOperationNone;
				
			NSBundle * tBundle=[NSBundle bundleWithPath:tPath];
			
			if ([[tBundle objectForInfoDictionaryKey:@"InstallerSectionTitle"] isKindOfClass:NSString.class]==NO)
				return NSDragOperationNone;
		}
		
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (BOOL)presentationListView:(PKGPresentationListView*)inPresentationListView acceptDrop:(id <NSDraggingInfo>)info step:(NSInteger)inStep
{
	if (_listView!=inPresentationListView)
		return NO;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
		
	if ([tPasteBoard availableTypeFromArray:@[PKGDistributionPresentationSectionsInternalPboardType]]!=nil)
	{
		// Switch Position of Installer Plugin
		
		NSArray * tSections=[self.presentationSettings.sections objectsAtIndexes:_internalDragData];
		
		[self.presentationSettings.sections removeObjectsAtIndexes:_internalDragData];
		
		NSUInteger tIndex=[_internalDragData firstIndex];
		
		while (tIndex!=NSNotFound)
		{
			if (tIndex<inStep)
				inStep--;
			
			tIndex=[_internalDragData indexGreaterThanIndex:tIndex];
		}
		
		NSIndexSet * tNewIndexSet=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inStep, _internalDragData.count)];
		
		[self.presentationSettings.sections insertObjects:tSections atIndexes:tNewIndexSet];
		
		// Refresh the list view
		
		[_listView reloadData];
		
		[_listView selectStep:inStep];
				
		[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:_listView]];
				
		[self noteDocumentHasChanged];
		
		return YES;
	}
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		// Add Installer Plugins
		
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		BOOL (^importPlugins)(PKGFilePathType) = ^BOOL(PKGFilePathType bPathType) {
		
			NSArray * tNewSections=[tArray WB_arrayByMappingObjectsUsingBlock:^id(NSString * bPath, NSUInteger bIndex) {
				
				PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:bPath type:bPathType];
				
				return [[PKGPresentationSection alloc] initWithPluginPath:tFilePath];
			}];
			
			if (tNewSections==nil)
				return NO;
			
			[self.presentationSettings.sections insertObjects:tNewSections atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inStep, tNewSections.count)]];
			
			// Refresh the list view
			
			[self->_listView reloadData];
			
			[self->_listView selectStep:inStep];
			
			[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:self->_listView]];
			
			[self noteDocumentHasChanged];
			
			/*if ([tArray count]==1)
			{
				[IBinstallationStepsView_ selectStepAtIndex:inStep];
				
				[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:_listView]];
			}
			else
			{
				[[IBinstallationStepsView_ window] invalidateCursorRectsForView:IBinstallationStepsView_];
				
				[IBinstallationStepsView_ setNeedsDisplay:YES];
			}*/
			
			return YES;
		};
		
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==NO)
			return importPlugins([PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle);
		
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		 
		tPanel.canChooseOwnerAndGroupOptions=NO;
		tPanel.keepOwnerAndGroup=NO;
		tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		 
		[tPanel beginSheetModalForWindow:_listView.window completionHandler:^(NSInteger bReturnCode){
			
			if (bReturnCode==PKGPanelCancelButton)
				return;
			
			importPlugins(tPanel.referenceStyle);
		}];
		
		return YES;		// It may at the end be not accepted by the completion handler from the sheet
	}
	
	return NO;
}

#pragma mark - PKGPresentationListViewDelegate

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView shouldSelectStep:(NSInteger)inStep
{
	if (inPresentationListView!=_listView)
		return YES;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	return  ([tPresentationSection.name isEqualToString:PKGPresentationSectionDestinationSelectName]==NO &&
			 [tPresentationSection.name isEqualToString:PKGPresentationSectionInstallationName]==NO);
}

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView stepWillBeVisible:(NSInteger)inStep
{
	if (inPresentationListView!=_listView)
		return YES;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	if (tPresentationSection.pluginPath!=nil)
		return YES;
	
	if ([tPresentationSection.name isEqualToString:PKGPresentationSectionReadMeName]==YES)
		return [self.presentationSettings readMeSettings_safe].isCustomized;
	
	if ([tPresentationSection.name isEqualToString:PKGPresentationSectionLicenseName]==YES)
		return [self.presentationSettings licenseSettings_safe].isCustomized;
	
	return YES;
}

- (void)presentationListViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=_listView)
		return;
	
	NSInteger tSelectedStep=_listView.selectedStep;
	
	if (tSelectedStep<0 || tSelectedStep>=self.presentationSettings.sections.count)
		return;
	
	self.documentRegistry[PKGDistributionPresentationSelectedStep]=@(tSelectedStep);
	
	PKGPresentationSection * tSelectedPresentationSection=self.presentationSettings.sections[tSelectedStep];
	
	_pluginRemoveButton.enabled=(tSelectedPresentationSection.pluginPath!=nil);
	
	// Inspector
	
	if (inNotification.userInfo==nil)
	{
		PKGPresentationInspectorItemTag tTag=tSelectedPresentationSection.inspectorItemTag;
		
		if (((NSInteger)tTag)==-1)
		{
			// A COMPLETER
			
			NSLog(@"");
		}
		else
		{
			[_inspectorPopUpButton selectItemWithTag:tTag];
			
			if (tTag==PKGPresentationInspectorItemPlugIn)
				[_inspectorPopUpButton selectedItem].enabled=NO;
			
			// Show the Inspector View
			
			[self showViewForInspectorItem:[PKGPresentationInspectorItem inspectorItemForTag:tTag]];
			
			self.documentRegistry[PKGDistributionPresentationInspectedItem]=@(tTag);
		}
	}
	
	// Show the Section View
	
	[self showViewForSection:tSelectedPresentationSection];
}

#pragma mark - PKGPresentationImageViewDelegate

- (NSDragOperation)presentationImageView:(PKGPresentationImageView *)inImageView validateDrop:(id <NSDraggingInfo>)info
{
	if (inImageView!=_backgroundView)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard = [info draggingPasteboard];
	
	if ([[tPasteBoard types] containsObject:NSFilenamesPboardType]==NO)
		return NSDragOperationNone;
	
	NSDragOperation sourceDragMask= [info draggingSourceOperationMask];
	
	if ((sourceDragMask & NSDragOperationCopy)==0)
		return NSDragOperationNone;
	
	NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
	
	if (tFiles.count!=1)
		return NSDragOperationNone;
	
	NSString * tFilePath=tFiles.lastObject;
	
	BOOL tImageFormatSupported=[[NSFileManager defaultManager] WB_fileAtPath:tFilePath matchesTypes:[PKGPresentationBackgroundSettings backgroundImageTypes]];
	
	if (tImageFormatSupported==NO)
	{
		NSURL * tURL = [NSURL fileURLWithPath:tFilePath];
		
		CGImageSourceRef tSourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef) tURL, NULL);
		
		if (tSourceRef!=NULL)
		{
			NSString * tImageUTI=(__bridge NSString *) CGImageSourceGetType(tSourceRef);
			
			if (tImageUTI!=nil)
				tImageFormatSupported=[[PKGPresentationBackgroundSettings backgroundImageUTIs] containsObject:tImageUTI];
			
			// Release Memory
			
			CFRelease(tSourceRef);
		}
	}
	
	if (tImageFormatSupported==NO)
		return NSDragOperationNone;
	
	return NSDragOperationCopy;
}

- (BOOL)presentationImageView:(PKGPresentationImageView *)inImageView acceptDrop:(id <NSDraggingInfo>)info
{
	if (inImageView!=_backgroundView)
		return NO;
	
	NSPasteboard * tPasteBoard= [info draggingPasteboard];
	
	if ([[tPasteBoard types] containsObject:NSFilenamesPboardType]==NO)
		return NO;
	
	NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
	
	if (tFiles.count!=1)
		return NO;
	
	NSString * tPath=tFiles.lastObject;
	
	NSImage * tImage=[[NSImage alloc] initWithContentsOfFile:tPath];
	
	if (tImage==nil)
		return NO;
	
	PKGFilePath * tFilePath=nil;
	
	void (^finalizeSetBackgroundImagePath)(PKGFilePath *) = ^(PKGFilePath * bFilePath) {
		
		PKGPresentationBackgroundSettings * tBackgroundSettings=self.presentationSettings.backgroundSettings;
		
		if (tBackgroundSettings.sharedSettingsForAllAppearances==YES)
		{
			[tBackgroundSettings.appearancesSettings enumerateKeysAndObjectsUsingBlock:^(NSString * bAppearanceNameKey, PKGPresentationBackgroundAppearanceSettings * bAppearanceSettings, BOOL *bOutStop) {
				
				bAppearanceSettings.showCustomImage=YES;
				
				bAppearanceSettings.imagePath=[bFilePath copy];
			}];
		}
		else
		{
			PKGPresentationThemeVersion tTheme=_currentTheme;
			
			if (tTheme==PKGPresentationThemeMojaveDynamic)
			{
				if ([_windowView WB_isEffectiveAppearanceDarkAqua]==NO)
					tTheme=PKGPresentationThemeMojaveLight;
				else
					tTheme=PKGPresentationThemeMojaveDark;
			}
			
			PKGPresentationBackgroundAppearanceSettings * tAppearanceSettings=[tBackgroundSettings appearanceSettingsForTheme:tTheme];
			
			tAppearanceSettings.showCustomImage=YES;
			
			tAppearanceSettings.imagePath=[bFilePath copy];
		}
		
		self->_backgroundView.image=tImage;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.presentationSettings.backgroundSettings userInfo:@{}];
		
		[self noteDocumentHasChanged];
	};
	
	if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
	{
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		
		tPanel.canChooseOwnerAndGroupOptions=NO;
		tPanel.keepOwnerAndGroup=NO;
		tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		[tPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bReturnCode){
			
			if (bReturnCode==PKGPanelCancelButton)
				return;
			
			PKGFilePath * tNewFilePath=[self.filePathConverter filePathForAbsolutePath:tPath type:tPanel.referenceStyle];
			
			finalizeSetBackgroundImagePath(tNewFilePath);
		}];
		
		return YES;
	}
	
	tFilePath=[self.filePathConverter filePathForAbsolutePath:tPath type:[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle];
	
	finalizeSetBackgroundImagePath(tFilePath);
	
	return YES;
}

#pragma mark - Notifications

- (void)distributionViewEffectiveAppearanceDidChange:(NSNotification *)inNotification
{
	[_leftView setAppearance:nil];
	
	WB_AppearanceMode tAppearanceMode=[NSResponder WB_appearanceModeForAppearanceName:inNotification.userInfo[@"EffectiveAppearance"]];
	
	switch (tAppearanceMode)
	{
		case WB_AppearanceAqua:
			
			_appearanceLightRadioButton.state=WBControlStateValueOn;
			
			break;
			
		case WB_AppearanceDarkAqua:
			
			_appearanceDarkRadioButton.state=WBControlStateValueOn;
			
			break;
			
	}
}

- (void)selectionSectionLanguageDidChange:(NSNotification *)inNotification
{
	NSString * tPaneTitle=[_currentSectionViewController sectionPaneTitle];
	
	_pageTitleView.stringValue=(tPaneTitle!=nil) ? tPaneTitle : @"";
	
	// Refresh Buttons
	
	[_currentSectionViewController updateButtons:_navigationButtons];
}

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	if ([_currentSectionViewController isKindOfClass:PKGPresentationSectionInstallerPluginViewController.class]==YES)
	{
		// Refresh Chapter Title View
		
		NSString * tPaneTitle=[_currentSectionViewController sectionPaneTitle];
	 
		_pageTitleView.stringValue=(tPaneTitle!=nil) ? tPaneTitle : @"";
	}
	
	// Refresh Background
	
	[self updateBackgroundView];
	
	// Refresh List (in case a plugin file disappeared or reappeared)
	
	[_listView reloadData];
}

- (void)windowViewEffectiveAppearanceDidChange:(NSNotification *)inNotification
{
	[self updateBackgroundView];
}

- (void)titleSettingsDidChange:(NSNotificationCenter *)inNotification
{
	[self updateTitleViews];
}

- (void)backgroundImageSettingsDidChange:(NSNotification *)inNotification
{
	[self updateBackgroundView];
}

- (void)choiceDependenciesEditionWillBegin:(NSNotification *)inNotification
{
	// Hide contents of right view
	
	for(NSView * tSubView in _rightView.subviews)
		tSubView.hidden=YES;
	
	// Show Dependencies View Controller
	
	_dependenciesViewController=[[PKGPresentationInstallationTypeChoiceDependenciesViewController alloc] initWithDocument:self.document];
	
	_dependenciesViewController.choiceTreeNode=inNotification.userInfo[PKGChoiceDependencyTreeNodeKey];
	_dependenciesViewController.choicesForest=inNotification.userInfo[PKGChoiceDependencyForestKey];
	
	_dependenciesViewController.view.frame=_rightView.bounds;
	
	[_dependenciesViewController WB_viewWillAppear];
	
	[_rightView addSubview:_dependenciesViewController.view];
	
	[_dependenciesViewController WB_viewDidAppear];
	
	// Hide Source List
	
	// A COMPLETER
	
	// Resize left and right views
	
	NSRect tLeftViewFrame=_leftView.frame;
	NSRect tRightViewFrame=_rightView.frame;
	
	_savedRightViewWidth=NSWidth(tRightViewFrame);
	
	
	tLeftViewFrame.size.width-=PKGDistributionPresentationInspectorEnlargementWidth;
	
	_leftView.frame=tLeftViewFrame;
	
	tRightViewFrame.origin.x-=PKGDistributionPresentationInspectorEnlargementWidth;
	tRightViewFrame.size.width+=PKGDistributionPresentationInspectorEnlargementWidth;
	
	_rightView.frame=tRightViewFrame;
	
	[self.view setNeedsDisplay:YES];
	
	if ([_currentSectionViewController isKindOfClass:PKGPresentationSectionInstallationTypeViewController.class]==NO)
		return;
	
	PKGPresentationSectionInstallationTypeViewController * tViewController=(PKGPresentationSectionInstallationTypeViewController *)_currentSectionViewController;
	
	// Show the Surgery field
	
	_surgeryWindow=[[PKGInstallationSurgeryWindow alloc] initForView:_leftView];
	
	if (_surgeryWindow!=nil)
	{
		NSScrollView * tOutlineScrollView=tViewController.outlineView.enclosingScrollView;
		
		NSRect tFrame=[tOutlineScrollView frame];
		
		tFrame=[_leftView convertRect:tFrame fromView:tOutlineScrollView.superview];
		
		[self.view.window addChildWindow:_surgeryWindow ordered:NSWindowAbove];
		
		[_surgeryWindow setSurgeryViewFrame:tFrame];
		
		[_surgeryWindow orderFront:self];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(leftViewDidResize:) name:NSViewFrameDidChangeNotification object:_leftView];
	}
}

- (void)choiceDependenciesEditionDidEnd:(NSNotification *)inNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_leftView];
	
	// Remove the Surgery field
	
	if (_surgeryWindow!=nil)
	{
		[self.view.window removeChildWindow:_surgeryWindow];
		
		[_surgeryWindow orderOut:self];
		
		_surgeryWindow=nil;
	}
	
	// Resize Left and Right View
	
	NSRect tLeftViewFrame=_leftView.frame;
	NSRect tRightViewFrame=_rightView.frame;
	
	tLeftViewFrame.size.width+=PKGDistributionPresentationInspectorEnlargementWidth;
	
	_leftView.frame=tLeftViewFrame;
	
	tRightViewFrame.origin.x+=PKGDistributionPresentationInspectorEnlargementWidth;
	tRightViewFrame.size.width-=PKGDistributionPresentationInspectorEnlargementWidth;
	
	_rightView.frame=tRightViewFrame;
	
	// Hide Dependencies View Controller
	
	[_dependenciesViewController WB_viewWillDisappear];
	
	[_dependenciesViewController.view removeFromSuperview];
	
	[_dependenciesViewController WB_viewDidDisappear];
	
	_dependenciesViewController=nil;
	
	// Show contents of right view
	
	for(NSView * tSubView in _rightView.subviews)
		tSubView.hidden=NO;
	
	[self.view setNeedsDisplay:YES];
}

- (void)leftViewDidResize:(NSNotification *)inNotification
{
	if (_surgeryWindow==nil)
		return;
	
	NSRect tWindowFrame=[PKGInstallationSurgeryWindow windowFrameForView:_leftView];
	
	[_surgeryWindow setFrame:tWindowFrame display:YES];
}

- (void)presentationThemeDidChange:(NSNotification *)inNotification
{
	if (self.view.window==nil)
		return;
	
	[self updateBackgroundView];
}

- (void)pluginPathDidChange:(NSNotification *)inNotification
{
	// Refresh Chapter Title View
	
	NSString * tPaneTitle=[_currentSectionViewController sectionPaneTitle];
	
	_pageTitleView.stringValue=(tPaneTitle!=nil) ? tPaneTitle : @"";

	// Refresh List

	[_listView reloadData];
}

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
    
    [self updateTitleViews];
}

@end
