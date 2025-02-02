/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadTreeNodeImageView.h"

@interface PKGPayloadTreeNodeImageView ()

+ (NSImage *)aliasBadgeImage;

@end

@implementation PKGPayloadTreeNodeImageView

+ (NSImage *)aliasBadgeImage
{
	static dispatch_once_t onceToken;
	static NSImage * sAliasBadgeImage=nil;
	
	dispatch_once(&onceToken, ^{
		
		NSBundle * tCoreTypesBundle=[NSBundle bundleWithPath:@"/System/Library/CoreServices/CoreTypes.bundle"];
		
		if (tCoreTypesBundle!=nil)
			sAliasBadgeImage=[tCoreTypesBundle imageForResource:@"AliasBadgeIcon"];
	});
	
	return sAliasBadgeImage;
}

- (void)setAttributedImage:(PKGPayloadTreeNodeAttributedImage *)inAttributedImage
{
	if (inAttributedImage!=_attributedImage)
	{
		_attributedImage=[inAttributedImage copy];
		
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -

- (NSView *)hitTest:(NSPoint)inPoint
{
	// To avoid the control+click event being intercepted.
	
	return nil;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect:(NSRect)inRect
{
	if (_attributedImage==nil)
		return;
	
	NSRect tBounds=self.bounds;
	
	if (_attributedImage.isElasticFolder==YES)
    {
        NSImage * tFolderIcon=_attributedImage.image;
        
        CGFloat tSideLength=round(NSWidth(inRect)*0.75);
        NSRect tRect;
            
        tRect.size=NSMakeSize(tSideLength,tSideLength);
        tRect.origin.x=0;
        tRect.origin.y=NSMaxY(inRect)-tSideLength;
            
        [tFolderIcon drawInRect:tRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
            
        tRect.origin.x=tSideLength*0.25;
        tRect.origin.y=NSMinY(inRect);
            
        [tFolderIcon drawInRect:tRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
        
        return;
    }
    
    if (_attributedImage.image!=nil)
		[_attributedImage.image drawInRect:tBounds fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:_attributedImage.alpha];
	
	// Draw the Symbolic link arrow
	
	if (_attributedImage.drawsSymbolicLinkArrow==YES)
		[[PKGPayloadTreeNodeImageView aliasBadgeImage] drawInRect:tBounds fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:_attributedImage.alpha];
	
	// Draw the target cross
	
    if (_attributedImage.drawsTargetCross==YES)
	{
		NSSize tSize=tBounds.size;
		
		[[NSColor redColor] set];
		
		NSRect tRect=NSMakeRect(0.0,0.0,tSize.width,tSize.height);
		
		NSRect tInsetRect=NSInsetRect(tRect,floor(tSize.width/4.0),floor(tSize.height/4.0));
		
		tInsetRect.size.width-=1.0;
		
		tInsetRect.origin.y+=1.0;
		
		tInsetRect.size.height-=1.0;
		
		NSFrameRect(tInsetRect);
		
		NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
		
		if (tBezierPath==nil)
			return;
		
		CGFloat tLineDashPattern[2]={3.0,3.0};
			
		[tBezierPath setLineDash:tLineDashPattern count:2 phase:0.0];
		
		[tBezierPath moveToPoint:NSMakePoint(NSMinX(tRect),floor(NSMidY(tRect))+0.5)];
		
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tRect),floor(NSMidY(tRect))+0.5)];
		
		[tBezierPath stroke];
		
		[tBezierPath removeAllPoints];
		
		[tBezierPath moveToPoint:NSMakePoint(floor(NSMidX(tRect))-0.5,NSMinY(tRect)+1.0)];
		
		[tBezierPath lineToPoint:NSMakePoint(floor(NSMidX(tRect))-0.5,NSMaxY(tRect))];
		
		[tBezierPath stroke];
	}
}

@end
