/*
Copyright (c) 2008-2024, Stéphane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGAboutBoxWindowController.h"

@interface PKGAboutBoxWindowController ()
{
	IBOutlet NSTextField * _versionLabel;
}

- (IBAction)showLicenseAgreement:(id)sender;

- (IBAction)showAcknowledgments:(id)sender;

@end

@implementation PKGAboutBoxWindowController

+ (void)showAbouxBox
{
	static dispatch_once_t onceToken;
	static PKGAboutBoxWindowController * sAbouxBoxWindowController=nil;
	
	dispatch_once(&onceToken, ^{
	
		sAbouxBoxWindowController=[PKGAboutBoxWindowController new];
	});
				  
	[sAbouxBoxWindowController showWindow:nil];
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"PKGAboutBoxWindowController";
}

#pragma mark -

- (void)windowDidLoad
{
    NSDictionary * tDictionary=[NSBundle mainBundle].infoDictionary;
        
	_versionLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"version %@ (%@)",@""),tDictionary[@"CFBundleShortVersionString"],tDictionary[@"CFBundleVersion"]];
	 
	[self.window center];
}

#pragma mark -

- (IBAction)showLicenseAgreement:(id) sender
{
	NSString * tPath=[[NSBundle mainBundle] pathForResource:@"Packages_License" ofType:@"pdf"];
	
	if (tPath==nil)
	{
		NSLog(@"[PKGAboutBoxWindowController showLicenseAgreement:] Missing License file");
		return;
	}
	
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:tPath]];
}

- (IBAction)showAcknowledgments:(id) sender
{
	NSString * tPath=[[NSBundle mainBundle] pathForResource:@"Packages_Acknowledgments" ofType:@"pdf"];
	
	if (tPath==nil)
	{
		NSLog(@"[PKGAboutBoxWindowController showLicenseAgreement:] Missing License file");
		return;
	}
	
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:tPath]];
}

@end
