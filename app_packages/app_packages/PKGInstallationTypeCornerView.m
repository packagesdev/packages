/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGInstallationTypeCornerView.h"

@interface PKGInstallationTypeCornerView ()
{
	NSCell *_drawCell;
}

@end

@implementation PKGInstallationTypeCornerView

- (instancetype)initWithFrame:(NSRect)inFrame
{
	self=[super initWithFrame:inFrame];
	
	if (self!=nil)
	{
		_drawCell=[[NSTableHeaderCell alloc] initImageCell:nil];
	}
	
	return self;
}

#pragma mark -

- (void)setDashedBorder:(BOOL)inDashedBorder
{
	if (_dashedBorder!=inDashedBorder)
	{
		_dashedBorder=inDashedBorder;
		
		[self setNeedsDisplay:YES];
	}
}

- (void)setMixedState:(BOOL)inMixedState
{
	if (_mixedState!=inMixedState)
	{
		_mixedState=inMixedState;
		
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -

- (void)drawRect:(NSRect)inRect
{
	NSRect tBounds=self.bounds;
	
	NSRect tClipRect=tBounds;
	
	tClipRect.size.width-=1.0;
	
	if (self.dashedBorder==YES)
	{
		NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
		
		[tBezierPath moveToPoint:NSMakePoint(0.0,NSMaxY(tBounds)-1.0)];
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBounds),NSMaxY(tBounds)-1.0)];
		
		[[NSColor whiteColor] setStroke];
		[tBezierPath stroke];
		
		const CGFloat tDash[2]={2.0,2.0};
		[tBezierPath setLineDash:tDash count:2 phase:0.0];
		
		[[NSColor colorWithDeviceWhite:0.530 alpha:1.0] setStroke];
		
		[tBezierPath stroke];
		
		tClipRect.size.height-=1;
	}
	
	[NSBezierPath clipRect:tClipRect];
	
	[_drawCell drawWithFrame:tBounds inView:self];
	
	if (self.mixedState==YES)
	{
		NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
	
		[tBezierPath moveToPoint:NSMakePoint(NSMinX(tBounds),NSMinY(tBounds))];
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBounds),NSMinY(tBounds))];
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBounds),NSMaxY(tBounds))];
		[tBezierPath closePath];
		
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.5] setFill];
		
		[tBezierPath fill];
	}
}

@end
