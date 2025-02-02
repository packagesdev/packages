/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPreferencesTabButton.h"

@interface PKGPreferencesTabButton ()
{
	BOOL _pushed;
}

@end

@implementation PKGPreferencesTabButton

- (void)mouseDown:(NSEvent *)inEvent
{
	_pushed=YES;
	
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)inEvent
{
	NSPoint tMouseLocation=[self convertPoint:[inEvent locationInWindow] fromView:nil];
	
	if (NSPointInRect(tMouseLocation, [self bounds])!=_pushed)
	{
		_pushed=!_pushed;
		
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(NSEvent *)inEvent
{
	if (_pushed==YES)
	{
		if ([self state]!=WBControlStateValueOn)
		{
			[self setState:WBControlStateValueOn];
			
			[self sendAction:[self action] to:[self target]];
		}
		
		_pushed=NO;
		
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -

- (void)drawRect:(NSRect)inRect
{
	NSMutableAttributedString * tAttributedString=[[self attributedTitle] mutableCopy];
	BOOL tIsDark=[self WB_isEffectiveAppearanceDarkAqua];
	NSColor * tColor;
	
	if (self.state==WBControlStateValueOn)
	{
		if (tIsDark==NO)
		{
			if (_pushed==YES)
				tColor=[NSColor blueColor];
			else
				tColor=[NSColor colorWithDeviceRed:25.0/255.0 green:116.0/255.0 blue:219.0/255.0 alpha:1.0];
		}
		else
		{
			if (_pushed==YES)
				tColor=[NSColor colorWithDeviceRed:83.0/255.0 green:165.0/255.0 blue:251.0/255.0 alpha:1.0];
			else
				tColor=[NSColor colorWithDeviceRed:83.0/255.0 green:165.0/255.0 blue:251.0/255.0 alpha:1.0];
		}
	}
	else
	{
		if (_pushed==YES)
		{
			tColor=(tIsDark==NO) ? [NSColor blackColor] : [NSColor whiteColor];
		}
		else
		{
			tColor=[NSColor labelColor];
		}
	}
	
	[tAttributedString addAttribute:NSForegroundColorAttributeName
							  value:tColor
							  range:NSMakeRange(0,[tAttributedString length])];
	
	[self setAttributedTitle:tAttributedString];
	
	[super drawRect:inRect];
}

@end
