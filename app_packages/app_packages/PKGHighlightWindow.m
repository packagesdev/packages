/*
Copyright (c) 2008-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGHighlightWindow.h"

#define PKGHighlightViewRoundedRectRadius 8.0

@interface PKGHighlightView : NSView

@end

@implementation PKGHighlightView

- (void) drawRect:(NSRect)inRect
{
	NSBezierPath * tPath=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds,2.0,2.0) xRadius:PKGHighlightViewRoundedRectRadius yRadius:PKGHighlightViewRoundedRectRadius];
	
	tPath.lineWidth=3.0;
		
	[NSColor.selectedContentBackgroundColor setStroke];
		
	[tPath stroke];
}

@end

@interface PKGHighlightWindow ()

- (instancetype)initForView:(NSView *)inView withFrame:(NSRect)inFrame;

@end

@implementation PKGHighlightWindow

- (instancetype)initForView:(NSView *)inView
{
	return [self initForView:inView withFrame:inView.frame];
}

- (instancetype)initForView:(NSView *) inView withFrame:(NSRect) inFrame
{
	if (inView==nil)
		return nil;
	
	inFrame=[inView convertRect:inFrame toView:nil];
	inFrame=[inView.window convertRectToScreen:inFrame];
	
	self=[super initWithContentRect:inFrame styleMask:WBWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
	
	if (self!=nil)
	{
		self.ignoresMouseEvents=YES;
		self.backgroundColor=[NSColor clearColor];
		self.opaque=NO;
		
		NSView * tContentView=[self contentView];
		
		PKGHighlightView * tView=[[PKGHighlightView alloc] initWithFrame:tContentView.bounds];
		
		if (tView==nil)
			return nil;

		[tContentView addSubview:tView];
	}
	
	return self;
}

@end
