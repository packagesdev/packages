/*
Copyright (c) 2007-2025, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGCertificatePanel.h"

#import <SecurityInterface/SFCertificateView.h>

#define PKGCertificateWindowDisclosedDefaultHeight	606.0

@interface PKGCertificateWindowController : NSWindowController
{
	IBOutlet SFCertificateView * _certificateView;
	
	IBOutlet NSButton * _defaultButton;
	
	BOOL _manuallyResized;
	
	CGFloat _defaultWindowHeight;
}

	@property (nonatomic) SecCertificateRef certificate;

	@property (nonatomic,copy) NSString * prompt;


- (IBAction)endDialog:(id)sender;

- (void)refreshUI;

// Notifications

- (void)certificateViewDisclosureStateDidChange:(NSNotification *)inNotification;

@end

@implementation PKGCertificateWindowController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"PKGCertificatePanel";
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	_defaultWindowHeight=self.window.frame.size.height;
	
	[_certificateView setDisplayTrust:NO];
	
	[_certificateView setEditableTrust:NO];
	
	[_certificateView setDisplayDetails:YES];
	
	// Default button
	
	if (self.prompt!=nil)
	{
		NSRect tButtonFrame=_defaultButton.frame;
		
		_defaultButton.title=self.prompt;
		
		[_defaultButton sizeToFit];
		
		CGFloat tWidth=NSWidth(_defaultButton.frame);
		
		if (tWidth<PKGAppkitMinimumPushButtonWidth)
			tWidth=PKGAppkitMinimumPushButtonWidth;
		
		tButtonFrame.origin.x=NSMaxX(tButtonFrame)-tWidth;
		tButtonFrame.size.width=tWidth;
		
		_defaultButton.frame=tButtonFrame;
	}
	
	[self refreshUI];
	
	// Register for notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(certificateViewDisclosureStateDidChange:) name:@"SFCertificateViewDisclosureStateDidChange" object:_certificateView];
}

#pragma mark -

- (void)setPrompt:(NSString *)inPrompt
{
	_prompt=[inPrompt copy];
	
	if (_defaultButton!=nil && _prompt!=nil)
	{
		NSRect tButtonFrame=_defaultButton.frame;
		
		_defaultButton.title=_prompt;
		
		[_defaultButton sizeToFit];
		
		CGFloat tWidth=NSWidth(_defaultButton.frame);
		
		if (tWidth<PKGAppkitMinimumPushButtonWidth)
			tWidth=PKGAppkitMinimumPushButtonWidth;
		
		tButtonFrame.origin.x=NSMaxX(tButtonFrame)-tWidth;
		tButtonFrame.size.width=tWidth;
		
		_defaultButton.frame=tButtonFrame;
	}
}

- (void)setCertificate:(SecCertificateRef)inCertificate
{
	if (_certificate!=inCertificate)
	{
		_certificate=inCertificate;
		
		[self refreshUI];
	}
}

#pragma mark -

- (void)refreshUI
{
	if (_certificateView==nil)
		return;
	
	[_certificateView setCertificate:_certificate];
}

#pragma mark -

- (IBAction)endDialog:(NSButton *)sender
{
	[NSApp endSheet:self.window returnCode:sender.tag];
}

#pragma mark - Notifications

- (void)certificateViewDisclosureStateDidChange:(NSNotification *)inNotification
{
	if (_manuallyResized==YES)
		return;
	
	NSRect tWindowFrame=self.window.frame;
	CGFloat tNewHeight=([_certificateView detailsDisclosed]==YES) ? PKGCertificateWindowDisclosedDefaultHeight : _defaultWindowHeight;
	
	tWindowFrame.origin.y+=(tNewHeight-tWindowFrame.size.height);
	tWindowFrame.size.height=tNewHeight;
	
	[self.window setFrame:tWindowFrame display:YES animate:YES];
}

- (NSSize)windowWillResize:(NSWindow *)inWindow toSize:(NSSize)inSize
{
	if (inWindow==self.window)
		_manuallyResized=YES;
	
	return inSize;
}

@end

@interface PKGCertificatePanel ()
{
	PKGCertificateWindowController * retainedWindowController;
}

@end

@implementation PKGCertificatePanel

+ (PKGCertificatePanel *) certificatePanel
{
	PKGCertificateWindowController * tWindowController=[PKGCertificateWindowController new];
	
	PKGCertificatePanel * tPanel=(PKGCertificatePanel *)tWindowController.window;
	tPanel->retainedWindowController=tWindowController;
	
	return tPanel;
}

#pragma mark -

- (SecCertificateRef)certificate
{
	return retainedWindowController.certificate;
}

- (void)setCertificate:(SecCertificateRef)inCertificate
{
	retainedWindowController.certificate=inCertificate;
}

- (NSString *)prompt
{
	return retainedWindowController.prompt;
}

- (void)setPrompt:(NSString *)inPrompt
{
	retainedWindowController.prompt=inPrompt;
}

#pragma mark -

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(void))handler
{
	[inWindow beginSheet:self completionHandler:^(NSModalResponse bResponse) {

		if (handler!=nil)
			handler();

		self->retainedWindowController=nil;
	}];
}

@end
