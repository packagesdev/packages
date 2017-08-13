/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationInspectorViewController.h"


@implementation PKGPresentationInspectorViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSection:(PKGPresentationSection *)inPresentationSection
{
	return [super initWithDocument:inDocument];
}

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	return [super initWithDocument:inDocument];
}

#pragma mark -

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self refreshUI];
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidResignMainNotification object:self.view.window];

	if (self.settings!=nil)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsDidChange:) name:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPresentationStepSettingsDidChangeNotification object:nil];
}

#pragma mark - Notifications

- (void)settingsDidChange:(NSNotification *)inNotification
{
	// to be implemented by the subclasses
}

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	// to be implemented by the subclasses
}

@end
