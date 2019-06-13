/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationSectionLicenseViewController.h"

#import "PKGPresentationLicenseStepSettings.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGInstallerApp.h"

#import "PKGLicenseProvider+UI.h"

#import "PKGLanguageConverter.h"

#import "PKGInstallerSimulatorBundle.h"

#import "PKGPresentationLicenseStepSettings+UI.h"

@interface PKGPresentationSectionLicenseViewController () <NSTextViewDelegate>
{
	IBOutlet PKGPresentationSectionTextDocumentViewDropView * _defaultContentsView;
	
	IBOutlet NSTextField  * _stepNotDisplayedLabel;
	
	IBOutlet NSView * _licenseView;
	
	IBOutlet NSPopUpButton * _languagePopupButton;
	
	PKGPresentationLicenseStepSettings * _settings;
	
	NSString * _cachedLicenseLocalization;
}

- (void)refreshLicenseUIForNativeLocalization:(NSString *)inNativeLocalization;

- (IBAction)switchLicenseLocalization:(id)sender;

// Notifications

- (void)viewFrameDidChange:(NSNotification *) inNotification;

@end

@implementation PKGPresentationSectionLicenseViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	if (self!=nil)
	{
		_settings=[inPresentationSettings licenseSettings_safe];
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	self.textView.delegate=self;
	
	_defaultContentsView.delegate=self;
}

#pragma mark -

- (PKGPresentationStepSettings *)settings
{
	return _settings;
}

- (NSString *)sectionPaneTitle
{
	NSString * tSelectedLanguage=[[PKGLanguageConverter sharedConverter] englishForNative:_cachedLicenseLocalization];
	
	NSString * tLocalizedTitle=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Software License Agreement" localization:tSelectedLanguage];
	
	return (tLocalizedTitle!=nil) ? tLocalizedTitle : [[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Software License Agreement" localization:self.localization];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];

	[self viewFrameDidChange:nil];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
}

#pragma mark -

- (void)updateButtons:(NSArray *)inButtonsArray
{
	if (self.localization==nil || inButtonsArray.count!=4)
		return;
	
	NSString * tSelectedLanguage=[[PKGLanguageConverter sharedConverter] englishForNative:_cachedLicenseLocalization];
	
	// Print / Customize
	
	NSButton * tButton=inButtonsArray[PKGPresentationSectionButtonPrint];
	
	tButton.hidden=NO;
	
	NSString * tLocalizedTitle=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Print..." localization:tSelectedLanguage];
	
	tButton.title=(tLocalizedTitle!=nil) ? tLocalizedTitle : [[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Print..." localization:self.localization];
	
	NSRect tFrame=tButton.frame;
	
	[tButton sizeToFit];
	
	tFrame.size.width=NSWidth(tButton.frame);
	
	if (tFrame.size.width<=PKGAppkitMinimumPushButtonWidth)
		tFrame.size.width=PKGAppkitMinimumPushButtonWidth;
	
	tFrame.size.width+=12.0;
	
	tButton.frame=tFrame;
	
	CGFloat tMinX=NSMaxX(tFrame)-4.0;
	
	// Save
	
	tButton=inButtonsArray[PKGPresentationSectionButtonSave];
	
	tButton.hidden=NO;
	
	tLocalizedTitle=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Save..." localization:tSelectedLanguage];
	
	tButton.title=(tLocalizedTitle!=nil) ? tLocalizedTitle : [[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Save..." localization:self.localization];
	
	tFrame=tButton.frame;
	
	[tButton sizeToFit];
	
	tFrame.origin.x=tMinX;
	
	tFrame.size.width=NSWidth(tButton.frame);
	
	if (tFrame.size.width<=PKGAppkitMinimumPushButtonWidth)
		tFrame.size.width=PKGAppkitMinimumPushButtonWidth;
	
	tFrame.size.width+=12.0;
	
	tButton.frame=tFrame;
	
	// Continue
	
	tButton=inButtonsArray[PKGPresentationSectionButtonContinue];
	
	tButton.hidden=NO;
	
	tLocalizedTitle=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Continue" localization:tSelectedLanguage];
	
	tButton.title=(tLocalizedTitle!=nil) ? tLocalizedTitle : [[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Continue" localization:self.localization];
	
	tFrame=tButton.frame;
	
	CGFloat tMaxX=NSMaxX(tFrame);
	
	[tButton sizeToFit];
	
	tFrame.size.width=NSWidth(tButton.frame);
	
	if (tFrame.size.width<=PKGAppkitMinimumPushButtonWidth)
		tFrame.size.width=PKGAppkitMinimumPushButtonWidth;
	
	tFrame.size.width+=12.0;
	
	tFrame.origin.x=tMaxX-NSWidth(tFrame);
	
	tButton.frame=tFrame;
	
	tMaxX=NSMinX(tFrame);
	
	// Go Back
	
	tButton=inButtonsArray[PKGPresentationSectionButtonGoBack];
	
	tButton.hidden=NO;
	
	tLocalizedTitle=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Go Back" localization:tSelectedLanguage];
	
	tButton.title=(tLocalizedTitle!=nil) ? tLocalizedTitle : [[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Go Back" localization:self.localization];
	
	tFrame=[tButton frame];
	
	[tButton sizeToFit];
	
	tFrame.size.width=NSWidth(tButton.frame);
	
	if (tFrame.size.width<=PKGAppkitMinimumPushButtonWidth)
		tFrame.size.width=PKGAppkitMinimumPushButtonWidth;
	
	tFrame.size.width+=12.0;
	
	tFrame.origin.x=tMaxX-NSWidth(tFrame)+4.0;
	
	tButton.frame=tFrame;
	
	[tButton.superview setNeedsDisplay:YES];
}

- (void)refreshLicenseUIForNativeLocalization:(NSString *)inNativeLocalization
{
	NSDictionary * tLocalizations=nil;
	
	switch (_settings.licenseType)
	{
		case PKGLicenseTypeCustom:
			
			{
				tLocalizations=[_settings.localizations WB_filteredDictionaryUsingBlock:^BOOL(NSString * bLanguage, id bValue) {
				
					return [_settings isValueSet:bValue];
				}];
			}
			
			break;
			
		case PKGLicenseTypeTemplate:
			
			tLocalizations=[[PKGLicenseProvider defaultProvider] licenseTemplateNamed:_settings.templateName].localizations;
			
			break;
	}
	
	if (tLocalizations.count==0)
		return;
	
	PKGFilePath * tFilePath=tLocalizations[[[PKGLanguageConverter sharedConverter] englishForNative:inNativeLocalization]];
	
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tFilePath];
	
	if (tAbsolutePath==nil)
	{
		NSLog(@"Unable to determine absolute path for file path (%@)",tFilePath);
		
		return;
	}
	
	self.textView.string=@"";
	
	NSTextStorage * tTextStorage=self.textView.textStorage;
	[tTextStorage beginEditing];
	
	NSURL * tFileURL=[NSURL fileURLWithPath:tAbsolutePath];
	NSError * tError=nil;
	
	BOOL tSuccess=[tTextStorage readFromURL:tFileURL
									options:@{NSBaseURLDocumentOption:tFileURL,
											  NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:12.0]}
						 documentAttributes:NULL
									  error:&tError];
	
	if (tSuccess==YES)
	{
		if (NSAppKitVersionNumber>=NSAppKitVersionNumber10_14)
			[self.textView setTextColor:[NSColor textColor]];
		
		if (_settings.licenseType==PKGLicenseTypeTemplate)
			[PKGLicenseProvider UI_replaceKeywords:_settings.templateValues inAttributedString:tTextStorage];

		[tTextStorage endEditing];
	
		[self.textView scrollRangeToVisible:NSMakeRange(0,0)];
	}
	else
	{
		// A COMPLETER
		
		//_stepNotDisplayedLabel.stringValue=NSLocalizedStringFromTable(@"This step will not be displayed.", @"Presentation",@"");
		
		[tTextStorage endEditing];
	}
}

- (void)refreshUIForLocalization:(NSString *)inLocalization
{
	if (self.textView==nil)
		return;
	
	if (_settings==nil || inLocalization==nil)
		return;
	
	NSDictionary * tLocalizations=nil;
	
	switch (_settings.licenseType)
	{
		case PKGLicenseTypeCustom:
			{
				tLocalizations=[_settings.localizations WB_filteredDictionaryUsingBlock:^BOOL(NSString * bLanguage, id bValue) {
					
					return [_settings isValueSet:bValue];
				}];
			}
			
			break;
			
		case PKGLicenseTypeTemplate:
			
			tLocalizations=[[PKGLicenseProvider defaultProvider] licenseTemplateNamed:_settings.templateName].localizations;
			
			break;
	}
	
	if (tLocalizations.count==0)
	{
		_cachedLicenseLocalization=nil;
		
		_defaultContentsView.hidden=NO;
		_licenseView.hidden=YES;
		
        _stepNotDisplayedLabel.textColor=[NSColor secondaryLabelColor];
		_stepNotDisplayedLabel.stringValue=NSLocalizedStringFromTable(@"This step will not be displayed.", @"Presentation",@"");
		
		return;
	}
	
	_defaultContentsView.hidden=YES;
	_licenseView.hidden=NO;
	
	// Update the Language PopUp Button
	
	[_languagePopupButton removeAllItems];
	
	PKGLanguageConverter * tLanguageConverter=[PKGLanguageConverter sharedConverter];
	
	NSArray * tSortedNativeLanguages=nil;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"FixAppleBugs"]==NO)
	{
		// The resulting sorted array of native language names does not make any sense. (rdar://45713825)
		
		NSArray * tISOLanguages=[tLocalizations.allKeys WB_arrayByMappingObjectsUsingBlock:^id(NSString * bEnglishLanguageName, NSUInteger bIndex) {
			
			return [tLanguageConverter ISOFromEnglish:bEnglishLanguageName];
		}];
		
		NSArray * tSortedISOLanguages=[tISOLanguages sortedArrayUsingSelector:@selector(compare:)];
		
		tSortedNativeLanguages=[tSortedISOLanguages WB_arrayByMappingObjectsUsingBlock:^NSString *(NSString * bISOLanguageCode, NSUInteger bIndex) {
			
			NSString * tNativeLanguageName=[tLanguageConverter nativeForEnglish:[tLanguageConverter englishFromISO:bISOLanguageCode]];
			
			return tNativeLanguageName;
			
		}];
		
		// There's a list that defines the preferred order for the first languages. It's located in the Info.plist fule of the private Install.framework.
		
		static NSArray * sPreferredOrderArray=nil;
		static dispatch_once_t onceToken;
		
		dispatch_once(&onceToken, ^{
			
			NSBundle * tInstallFrameworkBundle=[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Install.framework"];
			
			sPreferredOrderArray = [[tInstallFrameworkBundle objectForInfoDictionaryKey:@"IFLanguageNamesOrder"] WB_arrayByMappingObjectsUsingBlock:^id(NSString * bLanguageCode, NSUInteger bIndex) {
				
				NSString * tEnglishName=[tLanguageConverter englishFromISO:bLanguageCode];
				
				return [tLanguageConverter nativeForEnglish:tEnglishName];
			}];
		});
		
		NSMutableArray * tMutableSortedArray=[tSortedNativeLanguages mutableCopy];
		
		[sPreferredOrderArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * bNativeLanguage, NSUInteger bIndex, BOOL * bOutStop) {
			
			NSUInteger tIndex=[tMutableSortedArray indexOfObject:bNativeLanguage];
			
			if (tIndex!=NSNotFound)
			{
				[tMutableSortedArray removeObjectAtIndex:tIndex];
				[tMutableSortedArray insertObject:bNativeLanguage atIndex:0];
			}
			
		}];
		
		tSortedNativeLanguages=[tMutableSortedArray copy];
	}
	else
	{
		NSArray * tNativesLanguages=[tLocalizations.allKeys WB_arrayByMappingObjectsUsingBlock:^id(NSString * bEnglishLanguageName, NSUInteger bIndex) {
			
			return [tLanguageConverter nativeForEnglish:bEnglishLanguageName];
		}];
		
		tSortedNativeLanguages=[tNativesLanguages sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	}
	
	[_languagePopupButton addItemsWithTitles:tSortedNativeLanguages];
	
	NSString * tEnglishLanguageName=inLocalization;
	
	if (_cachedLicenseLocalization!=nil)
	{
		id tObject=nil;
		
		tEnglishLanguageName=[tLanguageConverter englishForNative:_cachedLicenseLocalization];
		
		if (tEnglishLanguageName!=nil)
			tObject=tLocalizations[tEnglishLanguageName];
		
		if (tObject==nil)
		{
			tEnglishLanguageName=inLocalization;
			_cachedLicenseLocalization=nil;
		}
	}
	
	id tObject=tLocalizations[tEnglishLanguageName];
	
	if (tObject!=nil)
	{
		_cachedLicenseLocalization=[tLanguageConverter nativeForEnglish:tEnglishLanguageName];
		
		[_languagePopupButton selectItemWithTitle:_cachedLicenseLocalization];
		
		[self refreshLicenseUIForNativeLocalization:_cachedLicenseLocalization];
		
		return;
	}
	
	NSArray * tAvailableLocalizations=(__bridge_transfer NSArray *)CFBundleCopyPreferredLocalizationsFromArray((__bridge CFArrayRef) tLocalizations.allKeys);
	
	_cachedLicenseLocalization=[tLanguageConverter nativeForEnglish:tAvailableLocalizations.firstObject];
	
	[_languagePopupButton selectItemWithTitle:_cachedLicenseLocalization];
	
	[self refreshLicenseUIForNativeLocalization:_cachedLicenseLocalization];
}

#pragma mark -

- (IBAction)switchLicenseLocalization:(NSPopUpButton *)sender
{
	NSString * tSelectedLocalization=[sender titleOfSelectedItem];
	
	if ([_cachedLicenseLocalization isEqualToString:tSelectedLocalization]==YES)
		return;
	
	_cachedLicenseLocalization=tSelectedLocalization;
	
	[self refreshLicenseUIForNativeLocalization:_cachedLicenseLocalization];
	
	// 45684749 radar to take into account
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationSectionSelectedSectionLanguageDidChangeNotification object:self.view.window];
}

#pragma mark - NSTextViewDelegate

- (void)textView:(NSTextView *)inTextView doubleClickedOnCell:(id <NSTextAttachmentCell>)inCell inRect:(NSRect)inCellFrame atIndex:(NSUInteger)inIndex
{
	PKGTokenTextAttachmentCell * tTokenTextAttachmentCell=(PKGTokenTextAttachmentCell *)inCell;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationLicenseStepSettingsDidDoubleClickTokenNotification object:_settings userInfo:@{PKGLicenseTemplateTokenName:tTokenTextAttachmentCell.tokenLabel.string}];
}

#pragma mark - PKGPresentationTextViewDelegate

- (BOOL)presentationTextView:(PKGPresentationTextView *)inPresentationTextView acceptDrop:(id <NSDraggingInfo>)info
{
	PKGLicenseType tSavedLicenseType=_settings.licenseType;
	
	_settings.licenseType=PKGLicenseTypeCustom;
	
	BOOL tResult=[super presentationTextView:inPresentationTextView acceptDrop:info];
	
	if (tResult==NO)
		_settings.licenseType=tSavedLicenseType;
	
	return tResult;
}

#pragma mark - PKGFileDeadDropViewDelegate

- (BOOL)fileDeadDropView:(PKGPresentationSectionTextDocumentViewDropView *)inView acceptDropFiles:(NSArray *)inFilenames
{
	PKGLicenseType tSavedLicenseType=_settings.licenseType;
	
	_settings.licenseType=PKGLicenseTypeCustom;
	
	BOOL tResult=[super fileDeadDropView:inView acceptDropFiles:inFilenames];
	
	if (tResult==NO)
		_settings.licenseType=tSavedLicenseType;
	
	return tResult;
}

#pragma mark -

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	NSRect tBounds=_defaultContentsView.bounds;
	
	NSRect tFrame=_stepNotDisplayedLabel.frame;
	
	tFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tFrame)*0.5);
	
	_stepNotDisplayedLabel.frame=tFrame;
	
	// License View
	
	tBounds=_licenseView.bounds;
	
	tFrame=_languagePopupButton.frame;
	
	tFrame.origin.x=round(NSMidX(tBounds)-NSWidth(tFrame)*0.5);
	
	_languagePopupButton.frame=tFrame;
}

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	[self refreshLicenseUIForNativeLocalization:_cachedLicenseLocalization];
}

- (void)settingsDidChange:(NSNotification *)inNotification
{
	[self refreshUIForLocalization:self.localization];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationSectionSelectedSectionLanguageDidChangeNotification object:self.view.window];
}

@end
