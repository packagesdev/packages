/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGTellerView.h"

NSString * const PKGWindowDidBecomeMainNotification=@"PKGWindowDidBecomeMainNotification";
NSString * const PKGWindowDidResignMainNotification=@"PKGWindowDidResignMainNotification";

@interface PKGTellerView ()

- (void)windowDidBecomeMain:(NSNotification *)inNotification;
- (void)windowDidResignMain:(NSNotification *)inNotification;

@end

@implementation PKGTellerView

- (void)viewWillMoveToWindow:(NSWindow *) inWindow
{
	[super viewWillMoveToWindow:inWindow];
	
	if (inWindow==nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.window];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.window];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:inWindow];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:inWindow];
	}
}


#pragma mark -

- (void)windowDidBecomeMain:(NSNotification *)inNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGWindowDidBecomeMainNotification object:self userInfo:@{@"NSObject":inNotification.object}];
}

- (void)windowDidResignMain:(NSNotification *)inNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGWindowDidResignMainNotification object:self userInfo:@{@"NSObject":inNotification.object}];
}

@end
