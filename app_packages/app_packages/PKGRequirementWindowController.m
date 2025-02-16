/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementWindowController.h"

#import "PKGPluginsManager+AppKit.h"



#import "PKGRequirementPluginsManager.h"

#import "PKGEvent.h"

@interface PKGRequirementWindowController ()
{
	IBOutlet NSImageView * _requirementTypeIcon;
	
	IBOutlet NSPopUpButton * _requirementTypePopUpButton;
	
	IBOutlet NSButton * _okButton;
	
	IBOutlet NSButton * _cancelButton;
	
	
	CGFloat _defaultContentWidth;
	
	NSMutableDictionary * _cachedSettingsRepresentations;
}

	@property (readwrite) IBOutlet NSView * requirementPlaceHolderView;

	@property (readwrite) PKGRequirementViewController * currentRequirementViewController;

- (void)showRequirementViewControllerWithIdentifier:(NSString *)inIdentifier;

- (IBAction)switchRequirementType:(id)sender;

// Notifications

- (void)optionKeyDidChange:(NSNotification *)inNotification;

@end

@implementation PKGRequirementWindowController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"";
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	_defaultContentWidth=NSWidth(((NSView *)self.window.contentView).frame);
	
	// Popup Button
	
	[_requirementTypePopUpButton removeAllItems];
	
	
	NSArray * tPluginsNames=[[PKGRequirementPluginsManager defaultManager] allPluginsNameSorted];
	
	if (tPluginsNames==nil)
	{
		NSLog(@"Unable to retrieve the list of plugins names");
	}
	else
	{
		[_requirementTypePopUpButton addItemsWithTitles:tPluginsNames];
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

- (void)setRequirement:(PKGRequirement *)inRequirement
{
	if (_requirement!=inRequirement)
	{
		_requirement=inRequirement;
		
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

#pragma mark -

- (void)refreshUI
{
	if (_requirementTypePopUpButton==nil)
		return;
	
	NSString * tRequirementIdentifier=self.requirement.identifier;
	
	// Set the Requirement
	
	if (tRequirementIdentifier==nil)
	{
		NSLog(@"[PKGRequirementWindowController refreshUI]: Missing requirement identifier value");
		
		return;
	}
	
	NSString * tLocalizedName=[[PKGRequirementPluginsManager defaultManager] localizedPluginNameForIdentifier:tRequirementIdentifier];
	
	[_requirementTypePopUpButton selectItemWithTitle:tLocalizedName];
	
	[self showRequirementViewControllerWithIdentifier:tRequirementIdentifier];
}

- (void)showRequirementViewControllerWithIdentifier:(NSString *)inIdentifier
{
	if (inIdentifier==nil)
		return;
	
	if (_currentRequirementViewController!=nil)
	{
		[self.window makeFirstResponder:nil];
		
		NSDictionary * tSettings=_currentRequirementViewController.settings;
		
		if (tSettings!=nil)
			_cachedSettingsRepresentations[self.requirement.identifier]=tSettings;
		
		if (_currentRequirementViewController.isResizableWindow==YES)
		{
			NSRect tBounds=_currentRequirementViewController.view.bounds;
			
			NSString * tKey=[NSString stringWithFormat:@"%@.size",self.requirement.identifier];
			
			[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(tBounds) forKey:tKey];
			
			_currentRequirementViewController.view.autoresizingMask=0;
		}
		
		[_currentRequirementViewController WB_viewWillDisappear];
		
		[_currentRequirementViewController.view removeFromSuperview];
		
		[_currentRequirementViewController WB_viewDidDisappear];
		
		_currentRequirementViewController=nil;
	}
	
	self.requirement.identifier=inIdentifier;
	
	_requirementTypeIcon.image=[[PKGRequirementPluginsManager defaultManager] iconForIdentifier:inIdentifier];
	
	_currentRequirementViewController=[[PKGRequirementPluginsManager defaultManager] createPluginUIControllerForIdentifier:inIdentifier];
	
	if (_currentRequirementViewController==nil)
	{
		NSAlert * tAlert=[NSAlert new];
		tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"The UI plugin for the requirement type (%@) could not be found", @""),inIdentifier];
		
		[tAlert runModal];
		
		return;
	}
	
	if (_cachedSettingsRepresentations[inIdentifier]!=nil)
	{
		self.requirement.settingsRepresentation=_cachedSettingsRepresentations[inIdentifier];
	}
	else
	{
		if (self.requirement.settingsRepresentation==nil)
			self.requirement.settingsRepresentation=[_currentRequirementViewController defaultSettings];
	}
	
	_currentRequirementViewController.settings=self.requirement.settingsRepresentation;
	
	
	NSRect tBounds=_requirementPlaceHolderView.bounds;
	
	NSRect tCurrentViewBounds=_currentRequirementViewController.view.bounds;
	
	if (_currentRequirementViewController.isResizableWindow==YES)
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
	
	// Avoid having the sheet OK, Cancel or bottom be out of screen whatever the position of the window is.
	
	NSScreen * tScreen=self.window.screen;
	
	if (tNewWindowFrame.origin.y<NSMinY(tScreen.visibleFrame))
	{
		
#define PKGAppKitWindowSheetTopOffset		22.0
		
		CGFloat tDelta=NSHeight(tScreen.visibleFrame)-NSHeight(tNewWindowFrame)-PKGAppKitWindowSheetTopOffset;
		
		if (tDelta<0 && _currentRequirementViewController.isResizableWindow==YES)
		{
			tNewWindowFrame.size.height=NSHeight(tScreen.visibleFrame)-PKGAppKitWindowSheetTopOffset;
			tNewWindowFrame.origin.y=NSMaxY(tOldWindowFrame)-NSHeight(tNewWindowFrame);
		}
	}
	
	[self.window setFrame:tNewWindowFrame display:YES animate:NO];
	
	
	[_currentRequirementViewController WB_viewWillAppear];
	
	if (_currentRequirementViewController.isResizableWindow==YES)
		_currentRequirementViewController.view.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
	
	_currentRequirementViewController.view.frame=_requirementPlaceHolderView.bounds;
	
	[_requirementPlaceHolderView addSubview:_currentRequirementViewController.view];
	
	[_currentRequirementViewController WB_viewDidAppear];
	
	NSView * tPreviousKeyView=[_currentRequirementViewController previousKeyView];
	
	if (tPreviousKeyView!=nil)
	{
		[_currentRequirementViewController setNextKeyView:tPreviousKeyView];
		
		[self.window makeFirstResponder:tPreviousKeyView];
	}
	else
	{
		[self.window makeFirstResponder:nil];
	}
	
	// Set Min and Max window size
	
	[self updateMinMaxWindowSize];
}

- (void)updateMinMaxWindowSize
{
	NSSize tSize=((NSView *)self.window.contentView).frame.size;
	
	if (_currentRequirementViewController.isResizableWindow==YES)
	{
		NSRect tContentFrame=((NSView *)self.window.contentView).frame;
		
		NSRect tRequirementFrame=_currentRequirementViewController.view.frame;
		
		tContentFrame.size.height=NSHeight(tContentFrame)-NSHeight(tRequirementFrame)+[_currentRequirementViewController minHeight];
		
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

- (IBAction)switchRequirementType:(NSPopUpButton *)sender
{
	NSString * tRequirementIdentifier=[[PKGRequirementPluginsManager defaultManager] identifierForLocalizedPluginName:sender.titleOfSelectedItem];
	
	if ([tRequirementIdentifier isEqualToString:self.requirement.identifier]==NO)
	{
		self.requirement.settingsRepresentation=nil;
		
		[self showRequirementViewControllerWithIdentifier:tRequirementIdentifier];
	}
}

- (IBAction)endDialog:(NSButton *)sender
{
	[self.window makeFirstResponder:nil];
	
	if (_currentRequirementViewController.isResizableWindow==YES)
	{
		NSRect tBounds=_currentRequirementViewController.view.bounds;
		
		NSString * tKey=[NSString stringWithFormat:@"%@.size",self.requirement.identifier];
		
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(tBounds) forKey:tKey];
		
		_currentRequirementViewController.view.autoresizingMask=0;
	}
	
	self.requirement.settingsRepresentation=[_currentRequirementViewController settings];
	
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
	
	[_currentRequirementViewController optionKeyStateDidChange:[tNumber boolValue]];
}

@end

