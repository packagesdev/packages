/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationSectionIntroductionViewController.h"

#import "PKGPresentationWelcomeStepSettings.h"

#import "PKGPresentationLocalizableStepSettings+UI.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGInstallerApp.h"


@interface PKGPresentationSectionIntroductionViewController ()
{
	PKGPresentationWelcomeStepSettings * _settings;
	
	PKGPresentationTitleSettings * _titleSettings;
}

@end

@implementation PKGPresentationSectionIntroductionViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	if (self!=nil)
	{
		_settings=[inPresentationSettings welcomeSettings_safe];
		
		_titleSettings=[inPresentationSettings titleSettings_safe];
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
}

#pragma mark -

- (PKGPresentationStepSettings *)settings
{
	return _settings;
}

- (NSString *)sectionPaneTitle
{
	NSString * tStringFormat=[[[PKGInstallerApp installerApp] pluginWithSectionName:PKGPresentationSectionIntroductionName] pageTitleForLocalization:self.localization];
	
	if (tStringFormat==nil)
		return nil;
	
	NSString * tTitle=[_titleSettings valueForLocalization:self.localization exactMatch:NO];
	
	if (tTitle==nil)
		tTitle=self.document.project.settings.name.stringByDeletingPathExtension;
	
	if (tTitle==nil)
		return nil;
	
    NSString * tFinalTitle=[self stringByReplacingKeysInString:tTitle];
    
	return [NSString stringWithFormat:tStringFormat,tFinalTitle];
}

#pragma mark -

- (void)refreshUIForLocalization:(NSString *)inLocalization
{
	if (self.textView==nil)
		return;
	
	if (inLocalization==nil || _settings==nil)
		return;
	
	NSMutableDictionary * tAvailableLocalizations=[_settings.localizations WB_filteredDictionaryUsingBlock:^BOOL(NSString * bLanguage, id bValue) {
		
		return [_settings isValueSet:bValue];
	}];
	
	if (tAvailableLocalizations.count>0)
	{
		self.textView.textContainerInset=NSMakeSize(7.0,7.0);
		
		[super refreshUIForLocalization:inLocalization];
		
		return;
	}
	
	// Show Default Welcome Message
	
	NSString * tString=[[[PKGInstallerApp installerApp] pluginWithSectionName:PKGPresentationSectionIntroductionName] stringForKey:@"PageText" localization:self.localization];
	
    if (tString==nil)   // Worse case scenario, we could not extract the localized string from Installer.app
        tString=@"You will be guided through the steps necessary to install this software.";
    
	self.textView.font=[NSFont systemFontOfSize:[NSFont systemFontSize]];
	
	self.textView.string=tString;
	
	NSTextStorage * tTextStorage=self.textView.textStorage;
	
	[tTextStorage beginEditing];
	
	[tTextStorage setAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:[NSFont systemFontSize]],
								  NSForegroundColorAttributeName:[NSColor controlTextColor]}
						  range:NSMakeRange(0,tString.length)];
	
	[tTextStorage endEditing];
	
	
	self.textView.textContainerInset=NSMakeSize(7.0,7.0);
}

@end
