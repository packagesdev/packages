/*
 Copyright (c) 2017-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGOwnershipAndReferenceStylePanel.h"

#import "PKGOwnershipAndReferenceStyleViewController.h"

@interface PKGOwnershipAndReferenceStyleWindowController : NSWindowController
{
	IBOutlet NSView * _placeHolderView;
	
	IBOutlet NSButton * _defaultButton;
	
	PKGOwnershipAndReferenceStyleViewController * _ownershipAndReferenceStyleController;
}

	@property (nonatomic) BOOL canChooseOwnerAndGroupOptions;

	@property (nonatomic) BOOL keepOwnerAndGroup;

	@property (nonatomic) PKGFilePathType referenceStyle;

	@property (nonatomic,copy) NSString * prompt;

- (void)_updateLayout;

- (IBAction)endDialog:(id)sender;

@end


@implementation PKGOwnershipAndReferenceStyleWindowController

@synthesize keepOwnerAndGroup=_keepOwnerAndGroup;
@synthesize referenceStyle=_referenceStyle;

- (NSString *)windowNibName
{
	return @"PKGOwnershipAndReferenceStylePanel";
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	_ownershipAndReferenceStyleController=[PKGOwnershipAndReferenceStyleViewController new];
	
	_ownershipAndReferenceStyleController.canChooseOwnerAndGroupOptions=self.canChooseOwnerAndGroupOptions;
	_ownershipAndReferenceStyleController.keepOwnerAndGroup=self.keepOwnerAndGroup;
	_ownershipAndReferenceStyleController.referenceStyle=self.referenceStyle;
	
	NSView * tView=_ownershipAndReferenceStyleController.view;	// To be sure it's loaded before the willAdd
	
	[_placeHolderView addSubview:tView];
	
	
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
	
	[self _updateLayout];
}

#pragma mark -

- (void)setCanChooseOwnerAndGroupOptions:(BOOL)inBool
{
	if (_canChooseOwnerAndGroupOptions!=inBool)
	{
		_canChooseOwnerAndGroupOptions=inBool;
		
		if (_ownershipAndReferenceStyleController!=nil)
		{
			_ownershipAndReferenceStyleController.canChooseOwnerAndGroupOptions=inBool;
			
			[self _updateLayout];
		}
	}
}

- (BOOL)keepOwnerAndGroup
{
	if (_ownershipAndReferenceStyleController!=nil)
		_keepOwnerAndGroup=_ownershipAndReferenceStyleController.keepOwnerAndGroup;
	
	return _keepOwnerAndGroup;
}

- (void)setKeepOwnerAndGroup:(BOOL)inBool
{
	if (_keepOwnerAndGroup!=inBool)
	{
		_keepOwnerAndGroup=inBool;
		
		if (_ownershipAndReferenceStyleController!=nil)
			_ownershipAndReferenceStyleController.keepOwnerAndGroup=inBool;
	}
}

- (PKGFilePathType)referenceStyle
{
	if (_ownershipAndReferenceStyleController!=nil)
		_referenceStyle=_ownershipAndReferenceStyleController.referenceStyle;
	
	return _referenceStyle;
}

- (void)setReferenceStyle:(PKGFilePathType)inReferenceStyle
{
	if (_referenceStyle!=inReferenceStyle)
	{
		_referenceStyle=inReferenceStyle;
		
		if (_ownershipAndReferenceStyleController!=nil)
			_ownershipAndReferenceStyleController.referenceStyle=inReferenceStyle;
	}
}

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

#pragma mark -

- (void)_updateLayout
{
	NSView * tView=[_placeHolderView subviews][0];
	
	NSRect tRect=tView.bounds;
	NSRect tPlaceHolderBounds=_placeHolderView.bounds;
	
	CGFloat tDelta=NSHeight(tPlaceHolderBounds)-NSHeight(tRect);
	
	NSRect tWindowFrame=[self.window frame];
	tWindowFrame.size.height-=tDelta;
	tWindowFrame.origin.y+=tDelta;
	
	[self.window setFrame:tWindowFrame display:YES animate:YES];
}

#pragma mark -

- (IBAction)endDialog:(NSButton *)sender
{
	[NSApp endSheet:self.window returnCode:sender.tag];
}

@end

@interface PKGOwnershipAndReferenceStylePanel ()
{
	PKGOwnershipAndReferenceStyleWindowController * retainedWindowController;
}

- (void)_sheetDidEndSelector:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;

@end

@implementation PKGOwnershipAndReferenceStylePanel

+ (PKGOwnershipAndReferenceStylePanel *) ownershipAndReferenceStylePanel
{
	PKGOwnershipAndReferenceStyleWindowController * tWindowController=[PKGOwnershipAndReferenceStyleWindowController new];
	
	PKGOwnershipAndReferenceStylePanel * tPanel=(PKGOwnershipAndReferenceStylePanel *)tWindowController.window;
	tPanel->retainedWindowController=tWindowController;
	
	return tPanel;
}

#pragma mark -

- (void)setCanChooseOwnerAndGroupOptions:(BOOL)inBool
{
	retainedWindowController.canChooseOwnerAndGroupOptions=inBool;
}

- (BOOL)canChooseOwnerAndGroupOptions
{
	return retainedWindowController.canChooseOwnerAndGroupOptions;
}

- (BOOL)keepOwnerAndGroup
{
	return retainedWindowController.keepOwnerAndGroup;
}

- (void)setKeepOwnerAndGroup:(BOOL)inBool
{
	retainedWindowController.keepOwnerAndGroup=inBool;
}

- (PKGFilePathType)referenceStyle
{
	return retainedWindowController.referenceStyle;
}

- (void)setReferenceStyle:(PKGFilePathType)inReferenceStyle
{
	retainedWindowController.referenceStyle=inReferenceStyle;
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

- (void)_sheetDidEndSelector:(PKGOwnershipAndReferenceStylePanel *)inPanel returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
	
	if (handler!=nil)
		handler(inReturnCode);
	
	inPanel->retainedWindowController=nil;
	
	[inPanel orderOut:self];
}

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSModalResponse bResponse))handler
{
	[inWindow beginSheet:self completionHandler:^(NSModalResponse bResponse) {

		if (handler!=nil)
			handler(bResponse);

		self->retainedWindowController=nil;
	}];
}

@end
