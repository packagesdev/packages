/*
 Copyright (c) 2008-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPreferencePaneAdvancedViewController.h"

#import "PKGApplicationPreferences.h"

#import "WBRemoteVersionChecker.h"

@interface PKGPreferencePaneAdvancedViewController ()
{
	IBOutlet NSButton * _advancedModeCheckbox;
	
	IBOutlet NSButton * _appleModeCheckbox;
	
	IBOutlet NSButton * _remoteVersionCheckerCheckbox;
}

- (IBAction)switchAdvancedMode:(id) sender;

- (IBAction)switchAppleMode:(id) sender;

- (IBAction)switchRemoteVersionCheck:(id) sender;

@end

@implementation PKGPreferencePaneAdvancedViewController

- (void)WB_viewWillAppear
{
	// Advanced Mode
	
	_advancedModeCheckbox.state=([PKGApplicationPreferences sharedPreferences].advancedMode==YES) ? WBControlStateValueOn: WBControlStateValueOff;
	
	// Apple Mode
	
	_appleModeCheckbox.state=([PKGApplicationPreferences sharedPreferences].appleMode==YES) ? WBControlStateValueOn: WBControlStateValueOff;
	
	// Remote Version Check
	
	_remoteVersionCheckerCheckbox.state=([[WBRemoteVersionChecker sharedChecker] isCheckEnabled]==YES) ? WBControlStateValueOn: WBControlStateValueOff;
}

- (IBAction)switchAdvancedMode:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].advancedMode=(_advancedModeCheckbox.state==WBControlStateValueOn);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification
														object:nil];
}

- (IBAction)switchAppleMode:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].appleMode=(_appleModeCheckbox.state==WBControlStateValueOn);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPreferencesAdvancedAppleModeStateDidChangeNotification
														object:nil];
}

- (IBAction)switchRemoteVersionCheck:(id) sender
{
	[[WBRemoteVersionChecker sharedChecker] setCheckEnabled:(_remoteVersionCheckerCheckbox.state==WBControlStateValueOn)];
}

@end
