/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationSectionSummaryViewController.h"

#import "PKGPresentationSummaryStepSettings.h"

#import "PKGPresentationLocalizableStepSettings+UI.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGInstallerApp.h"

#import "PKGInstallerSimulatorBundle.h"

#import "PKGPresentationSectionTextDocumentViewDropView.h"

@interface PKGPresentationSectionSummaryViewController ()
{
	IBOutlet PKGPresentationSectionTextDocumentViewDropView * _defaultContentsView;
	
	IBOutlet NSImageView * _successIconView;
	
	IBOutlet NSTextField * _messageLabel;
	
	IBOutlet NSTextField * _descriptionLabel;
	
	PKGPresentationSummaryStepSettings * _settings;
}

// Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationSectionSummaryViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	if (self!=nil)
	{
		_settings=[inPresentationSettings summarySettings_safe];
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_defaultContentsView.delegate=self;
	
	_successIconView.image=[NSImage imageWithSize:NSMakeSize(72.0,72.0) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		
		PKGInstallerPlugin * tPlugin=[[PKGInstallerApp installerApp] pluginWithSectionName:PKGPresentationSectionSummaryName];
	
		NSImage * tSourceImage=[tPlugin.bundle imageForResource:@"Success"];
		
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		
		[tSourceImage drawInRect:dstRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
		
		return YES;
		
	}];
}

#pragma mark -

- (PKGPresentationStepSettings *)settings
{
	return _settings;
}

- (NSString *)sectionPaneTitle
{
	return [[[PKGInstallerApp installerApp] pluginWithSectionName:PKGPresentationSectionSummaryName] stringForKey:@"InstallCompletedSuccessfullyTitle" localization:self.localization];
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
	
	// Print / Customize
	
	NSButton * tButton=inButtonsArray[PKGPresentationSectionButtonPrint];
	
	tButton.hidden=YES;
	
	// Save
	
	tButton=inButtonsArray[PKGPresentationSectionButtonSave];
	
	tButton.hidden=YES;
	
	// Continue
	
	tButton=inButtonsArray[PKGPresentationSectionButtonContinue];
	
	// A COMPLETER (Voir si on peut avoir une estimation pas trop mauvaise du comportement de la distribution)
	
	tButton.hidden=NO;
	tButton.title=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Close" localization:self.localization];
	
	NSRect tFrame=tButton.frame;
	
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
	
	// Show Default Summary Message
	
	_defaultContentsView.hidden=NO;
	self.textView.enclosingScrollView.hidden=YES;
	
	PKGInstallerPlugin * tPlugin=[[PKGInstallerApp installerApp] pluginWithSectionName:PKGPresentationSectionSummaryName];
	
	_messageLabel.stringValue=[tPlugin stringForKey:@"InstallSucceededTitle" localization:self.localization];
	
	_descriptionLabel.stringValue=[tPlugin stringForKey:@"InstallCompletedSuccessfullyDescription" localization:self.localization];
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	NSRect tBounds=_defaultContentsView.bounds;
	
	NSRect tFrame=_successIconView.frame;
	
	tFrame.origin.x=round(NSMidX(tBounds)-NSWidth(tFrame)*0.5);
	
	_successIconView.frame=tFrame;
}

@end
