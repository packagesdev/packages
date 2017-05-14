/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationSectionViewController.h"

#import "PKGInstallerApp.h"

#import "PKGInstallerSimulatorBundle.h"

@interface PKGPresentationSectionViewController ()

	@property (readwrite) IBOutlet NSView * accessoryView;

@end

@implementation PKGPresentationSectionViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSection:(PKGPresentationSection *)inPresentationSection
{
	return nil;
}

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	return [super initWithDocument:inDocument];
}

#pragma mark -

- (void)setLocalization:(NSString *)inLocalization
{
	if (inLocalization!=_localization)
	{
		_localization=[inLocalization copy];
		
		[self refreshUIForLocalization:_localization];
	}
}

- (PKGPresentationStepSettings *)settings
{
	return nil;
}

- (NSString *)sectionPaneTitle
{
	NSLog(@"Should be implemented in subclass of PKGPresentationSectionViewController");
	
	return nil;
}

#pragma mark -

- (void)refreshUIForLocalization:(NSString *)inLocalization
{
	NSLog(@"Should be implemented in subclass of PKGPresentationSectionViewController");
}

- (void)updateButtons:(NSArray *)inButtonsArray
{
	if (_localization==nil || inButtonsArray.count!=4)
		return;
	
	// Print / Customize
	
	NSButton * tButton=inButtonsArray[PKGPresentationSectionButtonPrint];
	
	tButton.hidden=YES;
	
	// Save
	
	tButton=inButtonsArray[PKGPresentationSectionButtonSave];
	
	tButton.hidden=YES;
	
	// Continue
	
	tButton=inButtonsArray[PKGPresentationSectionButtonContinue];
	
	tButton.hidden=NO;
	tButton.title=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Continue" localization:self.localization];
	
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

@end
