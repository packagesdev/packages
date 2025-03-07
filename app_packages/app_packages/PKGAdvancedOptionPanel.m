/*
 Copyright (c) 2017-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGAdvancedOptionPanel.h"

#import "PKGAdvancedOptionEditorViewController.h"

#import "PKGAdvancedOptionListEditorViewController.h"

@interface PKGAdvancedOptionWindowController : NSWindowController
{
	IBOutlet NSView * _optionPlaceHolderView;
	
	IBOutlet NSButton * _okButton;
	
	IBOutlet NSButton * _cancelButton;
	
	PKGAdvancedOptionEditorViewController * _editorViewController;
}

	@property (nonatomic,copy) NSString * prompt;

	@property (nonatomic) id optionValue;
	@property (nonatomic) PKGDistributionProjectSettingsAdvancedOptionObject * advancedOptionObject;

- (void)refreshUI;

- (IBAction)endDialog:(id)sender;

// Notifications

- (void)editorViewSizeShallChange:(NSNotification *)inNotification;

@end



@implementation PKGAdvancedOptionWindowController

@synthesize optionValue=_optionValue;

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"PKGAdvancedOptionPanel";
}

#pragma mark -

- (void)setPrompt:(NSString *)inPrompt
{
	_prompt=[inPrompt copy];
	
	if (_okButton!=nil && _prompt!=nil)
	{
		NSRect tButtonFrame=_okButton.frame;
		
		_okButton.title=_prompt;
		
		[_okButton sizeToFit];
		
		CGFloat tWidth=NSWidth(_okButton.frame);
		
		if (tWidth<PKGAppkitMinimumPushButtonWidth)
			tWidth=PKGAppkitMinimumPushButtonWidth;
		
		CGFloat tDeltaWidth=tWidth-NSWidth(tButtonFrame);
		
		tButtonFrame.origin.x-=tDeltaWidth;
		tButtonFrame.size.width=tWidth;
		
		_okButton.frame=tButtonFrame;
		
		tButtonFrame=_cancelButton.frame;
		tButtonFrame.origin.x-=tDeltaWidth;
		
		_cancelButton.frame=tButtonFrame;
	}
}

- (id)optionValue
{
	if (_editorViewController==nil)
		return nil;
	
	return _editorViewController.optionValue;
}

- (void)setOptionValue:(id)inOptionValue
{
	_optionValue=inOptionValue;
	
	if (_editorViewController==nil)
		return;
	
	_editorViewController.optionValue=_optionValue;
}

- (void)setAdvancedOptionObject:(PKGDistributionProjectSettingsAdvancedOptionObject *)inAdvancedOptionObject
{
	if (inAdvancedOptionObject==nil)
		return;
	
	if (_editorViewController!=nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGAdvancedOptionEditorViewSizeShallChangeNotification object:_editorViewController.view];
		
		[_editorViewController WB_viewWillDisappear];
		
		[_editorViewController.view removeFromSuperview];
		
		[_editorViewController WB_viewDidDisappear];
	}
	
	PKGAdvancedOptionEditorViewController * nEditorViewController=[PKGAdvancedOptionListEditorViewController new];
	
	nEditorViewController.editorRepresentation=inAdvancedOptionObject.advancedEditorRepresentation;
	nEditorViewController.optionValue=_optionValue;
	
	nEditorViewController.view.frame=_optionPlaceHolderView.bounds;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editorViewSizeShallChange:) name:PKGAdvancedOptionEditorViewSizeShallChangeNotification object:nEditorViewController.view];
	
	[nEditorViewController WB_viewWillAppear];
	
	[_optionPlaceHolderView addSubview:nEditorViewController.view];
	
	[nEditorViewController WB_viewDidAppear];
	
	_editorViewController=nEditorViewController;
}

#pragma mark -

- (void)refreshUI
{
	// A COMPLETER
}

#pragma mark -

- (IBAction)endDialog:(NSButton *)sender
{
	[self.window makeFirstResponder:nil];
	
	//self.locator.settingsRepresentation=[_currentLocatorViewController settings];
	
	[NSApp endSheet:self.window returnCode:sender.tag];
}

#pragma mark - Notifications

- (void)editorViewSizeShallChange:(NSNotification *)inNotification
{
	NSDictionary * tUserInfo=inNotification.userInfo;
	NSString * tSizeString=tUserInfo[@"Size"];
	
	NSSize tSize=NSSizeFromString(tSizeString);
	
	NSRect tPlaceHolderFrame=_optionPlaceHolderView.frame;
	
	CGFloat tDeltaX=tSize.width-NSWidth(tPlaceHolderFrame);
	CGFloat tDeltaY=tSize.height-NSHeight(tPlaceHolderFrame);
	
	NSRect tWindowFrame=self.window.frame;
	
	tWindowFrame.size.width+=tDeltaX;
	tWindowFrame.size.height+=tDeltaY;
	tWindowFrame.origin.y-=tDeltaY;
	
	[self.window setFrame:tWindowFrame display:YES];
}

@end

@interface PKGAdvancedOptionPanel ()
{
	PKGAdvancedOptionWindowController * _retainedWindowController;
}

@end

@implementation PKGAdvancedOptionPanel

+ (id)advancedOptionPanel
{
	PKGAdvancedOptionWindowController * tWindowController=[PKGAdvancedOptionWindowController new];
	
	PKGAdvancedOptionPanel * tPanel=(PKGAdvancedOptionPanel *)tWindowController.window;
	tPanel->_retainedWindowController=tWindowController;
	
	return tPanel;
}

#pragma mark -

- (NSString *)prompt
{
	return _retainedWindowController.prompt;
}

- (void)setPrompt:(NSString *)inPrompt
{
	_retainedWindowController.prompt=inPrompt;
}


- (id)optionValue
{
	return _retainedWindowController.optionValue;
}

- (void)setOptionValue:(id)inOptionValue
{
	_retainedWindowController.optionValue=inOptionValue;
}

- (void)setAdvancedOptionObject:(PKGDistributionProjectSettingsAdvancedOptionObject *)inAdvancedOptionObject
{
	_retainedWindowController.advancedOptionObject=inAdvancedOptionObject;
}

#pragma mark -

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSModalResponse))handler
{
	[inWindow beginSheet:self completionHandler:^(NSModalResponse bResponse) {
		
		if (handler!=nil)
			handler(bResponse);
		
		self->_retainedWindowController=nil;
	}];
}

@end
