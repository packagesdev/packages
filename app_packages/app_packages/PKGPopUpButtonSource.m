/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPopUpButtonSource.h"

@interface PKGPopUpButtonSource ()
{
	NSTrackingRectTag _trackingTag;
	NSRect _trackingRect;
	
	BOOL _pushed;
    BOOL _hovered;
}

@end

@implementation PKGPopUpButtonSource

- (void)dealloc
{
	if (_trackingTag!=0)
		[self removeTrackingRect:_trackingTag];
}

#pragma mark -

- (void)setFrame:(NSRect)inFrame
{
	[super setFrame:inFrame];
	
	if (_trackingTag!=0)
		[self removeTrackingRect:_trackingTag];
	
	_trackingTag=[self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:NO];
}

#pragma mark -

- (void)mouseEntered:(NSEvent *)theEvent
{
    _hovered=YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    _hovered=NO;
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *) inEvent
{
    _pushed=YES;
    [super mouseDown:inEvent];
    _pushed=NO;
	
    [self setNeedsDisplay:YES];
}

#pragma mark -

- (void)viewWillMoveToWindow:(NSWindow *)inWindow
{
	if (inWindow==nil)
	{
		if (_trackingTag!=0)
			[self removeTrackingRect:_trackingTag];
			
		_trackingRect=NSZeroRect;
	}
	else
	{
		_trackingTag=[self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:NO];
	}
}

- (void)drawRect:(NSRect)rect
{
    NSRect tBounds=[self bounds];
    CGFloat tHalfHeight=NSHeight(tBounds)*0.5;
        
    if (_pushed==NO && _hovered==NO)
	{
		[self.title drawAtPoint:NSMakePoint(tHalfHeight*0.75,2.0) 
				 withAttributes:@{NSForegroundColorAttributeName:[NSColor blackColor],
			NSFontAttributeName:[self font]}];
		
		return;
	}
		
	NSBezierPath * tPath=[NSBezierPath bezierPath];
        
	[tPath moveToPoint:NSMakePoint(tHalfHeight*0.6875,tHalfHeight*0.125)];
	[tPath lineToPoint:NSMakePoint(NSMaxX(tBounds),tHalfHeight*0.125)];
	[tPath lineToPoint:NSMakePoint(NSMaxX(tBounds),NSMaxY(tBounds)-tHalfHeight*0.5)];
	[tPath lineToPoint:NSMakePoint(tHalfHeight*0.6875,NSMaxY(tBounds)-tHalfHeight*0.5)];
	
	[tPath appendBezierPathWithArcWithCenter:NSMakePoint(tHalfHeight*0.6875,tHalfHeight*0.6875+tHalfHeight*0.125) radius:tHalfHeight*0.6875 startAngle:90.0 endAngle:270.0];
    
    NSColor * tFillColor=[NSColor colorWithDeviceWhite:(_pushed==YES) ? 0.5 : 0.6941 alpha:1.0];
	[tFillColor setFill];
	[tPath fill];
        
	[self.title drawAtPoint:NSMakePoint(tHalfHeight*0.75,2.0) 
			 withAttributes:@{NSForegroundColorAttributeName:[NSColor whiteColor],
							  NSFontAttributeName:[self font]}];
}

@end
