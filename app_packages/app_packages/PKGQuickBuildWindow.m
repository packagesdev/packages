/*
 Copyright (c) 2008-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGQuickBuildWindow.h"



@interface PKGQuickBuildMainView : NSView

@end

@implementation PKGQuickBuildMainView

- (void)drawRect:(NSRect)inRect
{
	NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:10.0 yRadius:10.0];
	
	[[NSColor colorWithDeviceWhite:0.0 alpha:0.55] setFill];
	
	[tBezierPath fill];
	
	[[NSColor colorWithDeviceWhite:0.0 alpha:0.1] setStroke];
	
	[tBezierPath stroke];
}

@end

@implementation PKGQuickBuildWindow

- (instancetype)init
{
	NSScreen * tMainScreen=[NSScreen mainScreen];
	NSRect tVisibleFrame=[tMainScreen visibleFrame];
	
	NSRect tWindowFrame=NSMakeRect(floor(NSMidX(tVisibleFrame)-PKGQuickBuildWindowDefaultWidth*0.5),
								   floor(NSMidY(tVisibleFrame)-PKGQuickBuildWindowDefaultWidth*0.5),
								   PKGQuickBuildWindowDefaultWidth,
								   PKGQuickBuildWindowDefaultWidth);
	
	self=[super initWithContentRect:tWindowFrame styleMask:WBWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
	
	if (self!=nil)
	{
		[self setIgnoresMouseEvents:YES];
		[self setHasShadow:NO];
		[self setOpaque:NO];
		
		[self setBackgroundColor:[NSColor clearColor]];
		
		[self setLevel:NSScreenSaverWindowLevel];
		
		PKGQuickBuildMainView * tContentView=[[PKGQuickBuildMainView alloc] initWithFrame:NSMakeRect(0,0,PKGQuickBuildWindowDefaultWidth,PKGQuickBuildWindowDefaultWidth)];
		
		if (tContentView!=nil)
			[self setContentView:tContentView];
	}
	
	return self;
}

@end
