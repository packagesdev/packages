/*
Copyright (c) 2007-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPreferencesWindowController.h"

#import "PKGPreferencePaneViewController.h"

#import "NSToolBar+Packages.h"



NSString * const PKGPreferencesWindowSelectedPaneIdentifierKey=@"preferences.ui.selected.identifier";

@interface PKGPreferencesWindowController () <NSToolbarDelegate>
{
	IBOutlet NSToolbar * _toolBar;
	
	NSMutableDictionary * _paneControllersDictionary;
	
	PKGPreferencePaneViewController * _currentViewController;
}

- (void)showPaneWithIdentifier:(NSString *)inIdentifier;

- (IBAction)showPane:(id)sender;

@end

@implementation PKGPreferencesWindowController

+ (void)showPreferences
{
	static dispatch_once_t onceToken;
	static PKGPreferencesWindowController * sPreferencesWindowController=nil;
	
	dispatch_once(&onceToken, ^{
		
		sPreferencesWindowController=[PKGPreferencesWindowController new];
	});
	
	[sPreferencesWindowController showWindow:nil];
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_paneControllersDictionary=[NSMutableDictionary dictionary];
	}
	
	return self;
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"PKGPreferencesWindowController";
}

- (void)windowDidLoad
{
	[self.window center];
	
	[self.window setShowsToolbarButton:NO];
	
	// Show the first pane
	
	NSString * tSelectedIdentifier=[[NSUserDefaults standardUserDefaults] objectForKey:PKGPreferencesWindowSelectedPaneIdentifierKey];
	
	if (tSelectedIdentifier==nil)
		tSelectedIdentifier=((NSToolbarItem *)[_toolBar items][0]).itemIdentifier;
	
	_toolBar.selectedItemIdentifier=tSelectedIdentifier;
		
	[self showPaneWithIdentifier:tSelectedIdentifier];
}

#pragma mark -

- (void)showPaneWithIdentifier:(NSString *) inIdentifier
{
	if (inIdentifier==nil)
		return;
	
	PKGPreferencePaneViewController * tViewController=_paneControllersDictionary[inIdentifier];
	
	if (tViewController==nil)
	{
		NSArray * tArray=[inIdentifier componentsSeparatedByString:@"."];
		
		if ([tArray count]!=2)
			return;
		
		Class tClass=NSClassFromString([NSString stringWithFormat:@"PKGPreferencePane%@ViewController",[tArray[1] capitalizedString]]);
		
		if (tClass==nil)
			return;
		
		tViewController=[tClass new];
		
		if (tViewController==nil)
			return;
		
		_paneControllersDictionary[inIdentifier]=tViewController;
	}
	
	[_currentViewController WB_viewWillDisappear];
	
	if (_currentViewController!=nil)
		[_currentViewController.view removeFromSuperview];
	
	[_currentViewController WB_viewDidDisappear];
	
	_currentViewController=tViewController;
	
	NSRect tOldWindowFrame=[self.window frame];
	
	NSRect tNewContentRect=[[self.window contentView] bounds];
	
	tNewContentRect.size=[_currentViewController.view frame].size;
	
	NSRect tWindowFrame=[self.window frameRectForContentRect:tNewContentRect];
	
	tWindowFrame.origin.x=NSMinX(tOldWindowFrame);
	
	tWindowFrame.origin.y=NSMaxY(tOldWindowFrame)-NSHeight(tWindowFrame);
	
	
	[self.window setTitle:[_toolBar PKG_toolBarItemWithIdentifier:inIdentifier].label];
	
	[self.window setFrame:tWindowFrame display:YES animate:YES];
	
	[_currentViewController WB_viewWillAppear];
	
	[[self.window contentView] addSubview:_currentViewController.view];
	
	[_currentViewController WB_viewDidAppear];
	
	[[NSUserDefaults standardUserDefaults] setObject:inIdentifier forKey:PKGPreferencesWindowSelectedPaneIdentifierKey];
}

- (IBAction)showPane:(id) sender
{
    [self showPaneWithIdentifier:[sender itemIdentifier]];
}

@end
