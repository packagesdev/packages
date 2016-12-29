/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadTreeNodeImageView.h"

@implementation PKGPayloadTreeNodeImageView

- (void)setAttributedImage:(PKGPayloadTreeNodeAttributedImage *)inAttributedImage
{
	if (inAttributedImage!=_attributedImage)
	{
		_attributedImage=[inAttributedImage copy];
		
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -

- (BOOL)isOpaque
{
	return NO;
}

- (void)setDrawsTarget:(BOOL)inDrawsTarget
{
	if (_drawsTarget!=inDrawsTarget)
	{
		_drawsTarget=inDrawsTarget;
		
		[self setNeedsDisplay:YES];
	}
}

- (void)drawRect:(NSRect)inRect
{
	if (_attributedImage==nil)
		return;
	
	NSRect tBounds=self.bounds;
	
	if (_attributedImage.image!=nil)
		[_attributedImage.image drawInRect:tBounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:_attributedImage.alpha];
	
	// Draw the target cross
	
    if (self.drawsTarget==YES)
	{
		NSSize tSize=tBounds.size;
		
		[[NSColor redColor] set];
		
		NSRect tRect=NSMakeRect(0.0f,0.0f,tSize.width,tSize.height);
		
		NSRect tInsetRect=NSInsetRect(tRect,floor(tSize.width/4.0f),floor(tSize.height/4.0f));
		
		tInsetRect.size.width-=1.0f;
		
		tInsetRect.origin.y+=1.0f;
		
		tInsetRect.size.height-=1.0f;
		
		NSFrameRect(tInsetRect);
		
		NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
		
		if (tBezierPath==nil)
			return;
		
		CGFloat tLineDashPattern[2]={3.0f,3.0f};
			
		[tBezierPath setLineDash:tLineDashPattern count:2 phase:0.0f];
		
		[tBezierPath moveToPoint:NSMakePoint(NSMinX(tRect),floor(NSMidY(tRect))+0.5f)];
		
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tRect),floor(NSMidY(tRect))+0.5f)];
		
		[tBezierPath stroke];
		
		[tBezierPath removeAllPoints];
		
		[tBezierPath moveToPoint:NSMakePoint(floor(NSMidX(tRect))-0.5f,NSMinY(tRect)+1.0f)];
		
		[tBezierPath lineToPoint:NSMakePoint(floor(NSMidX(tRect))-0.5f,NSMaxY(tRect))];
		
		[tBezierPath stroke];
	}
}

@end
