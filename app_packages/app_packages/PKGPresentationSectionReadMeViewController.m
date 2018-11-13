/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationSectionReadMeViewController.h"

#import "PKGPresentationReadMeStepSettings.h"

#import "PKGPresentationLocalizableStepSettings+UI.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGInstallerApp.h"

#import "PKGInstallerSimulatorBundle.h"

@interface PKGPresentationSectionReadMeViewController ()
{
	IBOutlet PKGPresentationSectionTextDocumentViewDropView * _defaultContentsView;
	
	IBOutlet NSTextField  * _stepNotDisplayedLabel;
	
	PKGPresentationReadMeStepSettings * _settings;
}

// Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationSectionReadMeViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	if (self!=nil)
	{
		_settings=[inPresentationSettings readMeSettings_safe];
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_defaultContentsView.delegate=self;
	
    _stepNotDisplayedLabel.textColor=[NSColor secondaryLabelColor];
	_stepNotDisplayedLabel.stringValue=NSLocalizedStringFromTable(@"This step will not be displayed.", @"Presentation",@"");
}

#pragma mark -

- (PKGPresentationStepSettings *)settings
{
	return _settings;
}

- (NSString *)sectionPaneTitle
{
	return [[[PKGInstallerApp installerApp] pluginWithSectionName:PKGPresentationSectionReadMeName] pageTitleForLocalization:self.localization];
}

#pragma mark -

- (void)updateButtons:(NSArray *)inButtonsArray
{
	if (self.localization==nil || inButtonsArray.count!=4)
		return;
	
	// Print / Customize
	
	NSButton * tButton=inButtonsArray[PKGPresentationSectionButtonPrint];
	
	tButton.hidden=NO;
	
	tButton.title=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Print..." localization:self.localization];
	
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
	
	tButton.title=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Save..." localization:self.localization];
	
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
	tButton.title=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Continue" localization:self.localization];
	
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
	tButton.title=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Go Back" localization:self.localization];
	
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
		_defaultContentsView.hidden=YES;
		self.textView.enclosingScrollView.hidden=NO;
		
		[super refreshUIForLocalization:inLocalization];
		
		return;
	}
	
	// Show Default ReadMe Message
	
	_defaultContentsView.hidden=NO;
	self.textView.enclosingScrollView.hidden=YES;
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	[super viewFrameDidChange:inNotification];
	
	NSRect tBounds=_defaultContentsView.bounds;
	
	NSRect tFrame=_stepNotDisplayedLabel.frame;
	
	tFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tFrame)*0.5);
	
	_stepNotDisplayedLabel.frame=tFrame;
}

@end
