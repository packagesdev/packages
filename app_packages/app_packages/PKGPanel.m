/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPanel.h"

#import "PKGEvent.h"

@interface PKGPanel ()
{
	BOOL _optionKeyDown;
}

@end

@implementation PKGPanel

- (void)becomeKeyWindow
{
	NSEvent * tEvent=[NSApp currentEvent];
	
	if (tEvent!=nil)
	{
		NSUInteger tModifierFlags=tEvent.modifierFlags;
		
		BOOL isDown=((tModifierFlags & WBEventModifierFlagOption) == WBEventModifierFlagOption);
		
		if (isDown!=_optionKeyDown)
		{
			_optionKeyDown=isDown;
			
			[[NSNotificationCenter defaultCenter] postNotificationName:PKGOptionKeyDidChangeStateNotification
																object:self
															  userInfo:@{PKGOptionKeyState:@(_optionKeyDown)}];
		}
	}
	
	[super becomeKeyWindow];
}

- (void)resignKeyWindow
{
	if (_optionKeyDown==YES)
	{
		_optionKeyDown=NO;
		
		// Post Notification
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGOptionKeyDidChangeStateNotification
															object:self
														  userInfo:@{PKGOptionKeyState:@(_optionKeyDown)}];
	}
	
	[super resignKeyWindow];
}

- (void)flagsChanged:(NSEvent *) inEvent
{
	if (inEvent==nil)
		return;

	NSUInteger tModifierFlags=inEvent.modifierFlags;
	
	BOOL isDown=((tModifierFlags & WBEventModifierFlagOption) == WBEventModifierFlagOption);
	
	if (isDown!=_optionKeyDown)
	{
		_optionKeyDown=isDown;
		
		// Post Notification
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGOptionKeyDidChangeStateNotification
															object:self
														  userInfo:@{PKGOptionKeyState:@(_optionKeyDown)}];
	}
}

@end
