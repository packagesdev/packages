/*
 Copyright (c) 2017-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLocatorPanel.h"

#import "PKGPluginsManager+AppKit.h"

#import "PKGLocatorPluginsManager.h"

#import "PKGPayloadTreeNode+UI.h"
#import "PKGPayloadTreeNode+Bundle.h"

#import "PKGLocatorViewController.h"

#import "PKGEvent.h"

@interface PKGLocatorWindowController : NSWindowController
{
	IBOutlet NSImageView * _locatorTypeIcon;
	
	IBOutlet NSPopUpButton * _locatorTypePopUpButton;
	
	IBOutlet NSView * _locatorPlaceHolderView;
	
	IBOutlet NSButton * _okButton;
	
	IBOutlet NSButton * _cancelButton;
	
	
	
	CGFloat _defaultContentWidth;
	
	PKGLocatorViewController * _currentLocatorViewController;
	
	NSMutableDictionary * _cachedSettingsRepresentations;
	
	NSMutableDictionary * _cachedCommonValues;
}

	@property (nonatomic) PKGLocator * locator;

	@property (nonatomic,copy) NSString * prompt;

	@property (nonatomic) PKGPayloadTreeNode * payloadTreeNode;

    @property (nonatomic,weak) id<PKGFilePathConverter> filePathConverter;

- (void)refreshUI;

- (void)showLocatorViewControllerWithIdentifier:(NSString *)inIdentifier;

- (IBAction)switchLocatorType:(id)sender;

- (IBAction)endDialog:(id)sender;

@end

@implementation PKGLocatorWindowController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"PKGLocatorPanel";
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	_defaultContentWidth=NSWidth(((NSView *)self.window.contentView).frame);
	
	// Popup Button
	
	[_locatorTypePopUpButton removeAllItems];
	
	
	NSArray * tPluginsNames=[[PKGLocatorPluginsManager defaultManager] allPluginsNameSorted];
	
	if (tPluginsNames==nil)
	{
		NSLog(@"Unable to retrieve the list of plugins names");
	}
	else
	{
		[_locatorTypePopUpButton addItemsWithTitles:tPluginsNames];
	}
	
	// OK button
	
	if (self.prompt!=nil)
	{
		NSRect tButtonFrame=_okButton.frame;
		
		_okButton.title=self.prompt;
		
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
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(optionKeyDidChange:)
												 name:PKGOptionKeyDidChangeStateNotification
											   object:self.window];
}

#pragma mark -

- (void)setLocator:(PKGLocator *)inLocator
{
	if (_locator!=inLocator)
	{
		_locator=inLocator;
		
		_cachedSettingsRepresentations=[NSMutableDictionary dictionary];
	}
}

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

- (void)setPayloadTreeNode:(PKGPayloadTreeNode *)inPayloadTreeNode
{
	if (_payloadTreeNode!=inPayloadTreeNode)
	{
		_payloadTreeNode=inPayloadTreeNode;
		
		_cachedCommonValues=[NSMutableDictionary dictionary];
		
		_cachedCommonValues[PKGLocatorCommonValuePathKey]=[_payloadTreeNode filePathWithSeparator:@"/"];
		
		NSString * tBundleIdentifier;
		
		if (self.filePathConverter!=nil && [_payloadTreeNode isBundleWithFilePathConverter:self.filePathConverter bundleIdentifier:&tBundleIdentifier]==YES_value)
			_cachedCommonValues[PKGLocatorCommonValueBundleIdentifierKey]=tBundleIdentifier;
	}
}

- (void)setFilePathConverter:(id<PKGFilePathConverter>)inFilePathConverter
{
	if (_filePathConverter!=inFilePathConverter)
	{
		_filePathConverter=inFilePathConverter;
		
		NSString * tBundleIdentifier;
		
		if (self.payloadTreeNode!=nil && [self.payloadTreeNode isBundleWithFilePathConverter:self.filePathConverter bundleIdentifier:&tBundleIdentifier]==YES_value)
			_cachedCommonValues[PKGLocatorCommonValueBundleIdentifierKey]=tBundleIdentifier;	// Should work even if _cachedCommonValues is nil
	}
}

#pragma mark -

- (void)refreshUI
{
	if (_locatorTypePopUpButton==nil)
		return;
	
	NSString * tLocatorIdentifier=self.locator.identifier;
	
	// Set the Locator
	
	if (tLocatorIdentifier==nil)
	{
		NSLog(@"[PKGLocatorWindowController refreshUI]: Missing locator identifier value");
		
		return;
	}

	NSString * tLocalizedName=[[PKGLocatorPluginsManager defaultManager] localizedPluginNameForIdentifier:tLocatorIdentifier];
		
	[_locatorTypePopUpButton selectItemWithTitle:tLocalizedName];
		
	[self showLocatorViewControllerWithIdentifier:tLocatorIdentifier];
}

- (void)showLocatorViewControllerWithIdentifier:(NSString *)inIdentifier
{
	if (inIdentifier==nil)
		return;
	
	if (_currentLocatorViewController!=nil)
	{
		[self.window makeFirstResponder:nil];
		
		NSDictionary * tSettings=_currentLocatorViewController.settings;
		
		if (tSettings!=nil)
			_cachedSettingsRepresentations[self.locator.identifier]=tSettings;
		
		if (_currentLocatorViewController.isResizableWindow==YES)
		{
			NSRect tBounds=_currentLocatorViewController.view.bounds;
			
			NSString * tKey=[NSString stringWithFormat:@"%@.size",self.locator.identifier];
			
			[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(tBounds) forKey:tKey];
			
			_currentLocatorViewController.view.autoresizingMask=0;
		}
		
		[_currentLocatorViewController WB_viewWillDisappear];
		
		[_currentLocatorViewController.view removeFromSuperview];
		
		[_currentLocatorViewController WB_viewDidDisappear];
		
		_currentLocatorViewController=nil;
	}
	
	self.locator.identifier=inIdentifier;
	
	_locatorTypeIcon.image=[[PKGLocatorPluginsManager defaultManager] iconForIdentifier:inIdentifier];
	
	_currentLocatorViewController=[[PKGLocatorPluginsManager defaultManager] createPluginUIControllerForIdentifier:inIdentifier];
	
	if (_currentLocatorViewController==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	if (_cachedSettingsRepresentations[inIdentifier]!=nil)
	{
		self.locator.settingsRepresentation=_cachedSettingsRepresentations[inIdentifier];
	}
	else
	{
		if (self.locator.settingsRepresentation==nil)
			self.locator.settingsRepresentation=[_currentLocatorViewController defaultSettingsWithCommonValues:_cachedCommonValues];
	}
	
	_currentLocatorViewController.settings=self.locator.settingsRepresentation;
	
	NSRect tBounds=_locatorPlaceHolderView.bounds;
	
	NSRect tCurrentViewBounds=_currentLocatorViewController.view.bounds;
	
	if (_currentLocatorViewController.isResizableWindow==YES)
	{
		NSString * tKey=[NSString stringWithFormat:@"%@.size",inIdentifier];
		
		NSString * tSizeString=[[NSUserDefaults standardUserDefaults] objectForKey:tKey];
		
		if (tSizeString!=nil)
			tCurrentViewBounds=NSRectFromString(tSizeString);
		
		self.window.showsResizeIndicator=YES;
	}
	else
	{
		self.window.showsResizeIndicator=NO;
	}
	
	// Resize window
	
	NSRect tOldWindowFrame=self.window.frame;
	
	NSRect tComputeRect=NSMakeRect(0,0,NSWidth(tCurrentViewBounds)-NSWidth(tBounds),NSHeight(tCurrentViewBounds)-NSHeight(tBounds));
	
	tComputeRect=[NSWindow frameRectForContentRect:tComputeRect styleMask:WBWindowStyleMaskBorderless];
	
	NSRect tNewWindowFrame;
	
	tNewWindowFrame.size=NSMakeSize(NSWidth(tOldWindowFrame)+NSWidth(tComputeRect),NSHeight(tOldWindowFrame)+NSHeight(tComputeRect));
	
	tNewWindowFrame.origin.x=floor(NSMidX(tOldWindowFrame)-NSWidth(tNewWindowFrame)*0.5);
	tNewWindowFrame.origin.y=NSMaxY(tOldWindowFrame)-NSHeight(tNewWindowFrame);
	
	[self.window setFrame:tNewWindowFrame display:YES animate:NO];
	
	
	[_currentLocatorViewController WB_viewWillAppear];
	
	if (_currentLocatorViewController.isResizableWindow==YES)
		_currentLocatorViewController.view.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
	
	_currentLocatorViewController.view.frame=_locatorPlaceHolderView.bounds;
	
	[_locatorPlaceHolderView addSubview:_currentLocatorViewController.view];
	
	[_currentLocatorViewController WB_viewDidAppear];
	
	NSView * tPreviousKeyView=[_currentLocatorViewController previousKeyView];
	
	if (tPreviousKeyView!=nil)
	{
		[_currentLocatorViewController setNextKeyView:tPreviousKeyView];
		
		[self.window makeFirstResponder:tPreviousKeyView];
	}
	else
	{
		[self.window makeFirstResponder:nil];
	}
	
	// Set Min and Max window size
	
	NSSize tSize=((NSView *)self.window.contentView).frame.size;
	
	if (_currentLocatorViewController.isResizableWindow==YES)
	{
		NSRect tContentFrame=((NSView *)self.window.contentView).frame;
		
		NSRect tLocatortFrame=_currentLocatorViewController.view.frame;
		
		tContentFrame.size.height=NSHeight(tContentFrame)-NSHeight(tLocatortFrame)+[_currentLocatorViewController minHeight];
		
		self.window.contentMinSize=NSMakeSize(_defaultContentWidth, NSHeight(tContentFrame));
		self.window.contentMaxSize=NSMakeSize(2000.0,2000.0);
	}
	else
	{
		tSize.width=_defaultContentWidth;
		
		self.window.contentMinSize=tSize;
		self.window.contentMaxSize=tSize;
	}
}

#pragma mark -

- (IBAction)switchLocatorType:(NSPopUpButton *)sender
{
	NSString * tLocatorIdentifier=[[PKGLocatorPluginsManager defaultManager] identifierForLocalizedPluginName:sender.titleOfSelectedItem];
	
	if ([tLocatorIdentifier isEqualToString:self.locator.identifier]==NO)
	{
		self.locator.settingsRepresentation=nil;
		
		[self showLocatorViewControllerWithIdentifier:tLocatorIdentifier];
	}
}

- (IBAction)endDialog:(NSButton *)sender
{
	[self.window makeFirstResponder:nil];
	
	if (_currentLocatorViewController.isResizableWindow==YES)
	{
		NSRect tBounds=_currentLocatorViewController.view.bounds;
			
		NSString * tKey=[NSString stringWithFormat:@"%@.size",self.locator.identifier];
			
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(tBounds) forKey:tKey];
			
		_currentLocatorViewController.view.autoresizingMask=0;
	}
	
	self.locator.settingsRepresentation=[_currentLocatorViewController settings];
	
	[NSApp endSheet:self.window returnCode:sender.tag];
}

#pragma mark - Notifications

- (void)optionKeyDidChange:(NSNotification *)inNotification
{
	if (inNotification==nil)
		return;
	
	NSNumber * tNumber=inNotification.userInfo[PKGOptionKeyState];
	
	if (tNumber==nil)
		return;
	
	[_currentLocatorViewController optionKeyStateDidChange:[tNumber boolValue]];
}

@end

@interface PKGLocatorPanel ()
{
	PKGLocatorWindowController * retainedWindowController;
}

	@property (nonatomic,readwrite) id<PKGFilePathConverter> filePathConverter;

- (void)_sheetDidEndSelector:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;

@end

@implementation PKGLocatorPanel

+ (PKGLocatorPanel *)locatorPanel
{
	PKGLocatorWindowController * tWindowController=[PKGLocatorWindowController new];
	
	PKGLocatorPanel * tPanel=(PKGLocatorPanel *)tWindowController.window;
	tPanel->retainedWindowController=tWindowController;
	
	return tPanel;
}

#pragma mark -

- (PKGLocator *)locator
{
	return retainedWindowController.locator;
}

- (void)setLocator:(PKGLocator *)inLocator
{
	retainedWindowController.locator=inLocator;
}

- (NSString *)prompt
{
	return retainedWindowController.prompt;
}

- (void)setPrompt:(NSString *)inPrompt
{
	retainedWindowController.prompt=inPrompt;
}

- (PKGPayloadTreeNode *)payloadTreeNode
{
	return retainedWindowController.payloadTreeNode;
}

- (void)setPayloadTreeNode:(PKGPayloadTreeNode *)inPayloadTreeNode
{
	retainedWindowController.payloadTreeNode=inPayloadTreeNode;
}

#pragma mark -

- (void)_sheetDidEndSelector:(PKGLocatorPanel *)inPanel returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
	
	if (handler!=nil)
		handler(inReturnCode);
	
	inPanel->retainedWindowController=nil;
	
	[inPanel orderOut:self];
}

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSModalResponse))handler
{
    self.document=((NSWindowController *) inWindow.windowController).document;
    
    retainedWindowController.filePathConverter=self.document;
	
	[retainedWindowController refreshUI];
	
	[inWindow beginSheet:self completionHandler:^(NSModalResponse bResponse) {

		if (handler!=nil)
			handler(bResponse);

		self->retainedWindowController=nil;
	}];
}

@end
