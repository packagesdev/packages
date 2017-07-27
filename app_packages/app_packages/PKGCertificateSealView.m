/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* Contains code from Apple Sample Code */

#import "PKGCertificateSealView.h"

#define PKGCertificateStampDefaultOuterRadius	36.0

#define PKGCertificateStampDefaultToothHeight	3.5

#define PKGCertificateStampDefaultTeethCount	40

#define DEG_TO_RAD		(3.141592654/180.0)

@interface PKGCertificateSealView ()
{
	BOOL _pushed;
	
	CGFloat _outerRadius;
	
	CGFloat _toothHeight;
	
	NSUInteger _teethCount;
	
	
	NSTextStorage * _textStorage;
	
    NSLayoutManager * _layoutManager;
	
    NSTextContainer * _textContainer;
}

#ifdef DEBUG

- (IBAction)takeOuterRadiusFrom:(id)sender;

- (IBAction)takeToothHeightFrom:(id)sender;

- (IBAction)takeTeethCountFrom:(id)sender;

#endif


@end

@implementation PKGCertificateSealView

- (instancetype)initWithFrame:(NSRect)inRect
{
    self = [super initWithFrame:inRect];
	
    if (self!=nil)
	{
		_outerRadius=PKGCertificateStampDefaultOuterRadius;
		_toothHeight=PKGCertificateStampDefaultToothHeight;
		_teethCount=PKGCertificateStampDefaultTeethCount;
		
		_textContainer = [[NSTextContainer alloc] init];
		
		_layoutManager = [[NSLayoutManager alloc] init];
		//_layoutManager.usesScreenFonts=NO;
		
		[_layoutManager addTextContainer:_textContainer];
		
		_textStorage = [[NSTextStorage alloc] initWithString:@""];
		
		[_textStorage addLayoutManager:_layoutManager];

		self.stringValue=@"CERTIFICATE OF AUTHENTICITY";
    }
	
    return self;
}

#pragma mark -

- (BOOL)isFlipped
{
	return NO;
}

- (BOOL)isOpaque
{
	return NO;
}

#if DEBUG

- (IBAction)takeOuterRadiusFrom:(id)sender
{
	_outerRadius=[sender floatValue];
	
	[self setNeedsDisplay:YES];
}

- (IBAction)takeToothHeightFrom:(id)sender
{
	_toothHeight=[sender floatValue];
	
	[self setNeedsDisplay:YES];
}

- (IBAction)takeTeethCountFrom:(id)sender
{
	_teethCount=[sender intValue];
	
	[self setNeedsDisplay:YES];
}

#endif

#pragma mark -

- (void)setMissing:(BOOL)inMissing
{
	if (_missing!=inMissing)
	{
		_missing=inMissing;
		
		[self setNeedsDisplay:YES];
	}
}

- (void)setStringValue:(NSString *)inString
{
	[_textStorage replaceCharactersInRange:NSMakeRange(0, _textStorage.length) withString:inString];
	
	[_textStorage addAttributes:@{NSFontAttributeName:[NSFont boldSystemFontOfSize:7.0],
								  NSForegroundColorAttributeName:[NSColor whiteColor]} range:NSMakeRange(0, _textStorage.length)];
	
    [self setNeedsDisplay:YES];
}

#pragma mark -

- (void)drawRect:(NSRect)inRect
{
	NSRect tBounds=[self bounds];
	
	CGFloat tMidX=NSMidX(tBounds);
	CGFloat tMidY=NSMidY(tBounds);
	
	CGFloat tInnerRadius=_outerRadius-_toothHeight;
	
	CGFloat tAngle=0.0;
	
	// Draw the edge
	
	CGFloat tDeltaAngle=360.0/_teethCount;
	
	CGFloat tSemiDeltaAngle=tDeltaAngle*0.5;
	
	NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
	
	[tBezierPath moveToPoint:NSMakePoint(tMidX+tInnerRadius*cosf(tAngle*DEG_TO_RAD),tMidY+tInnerRadius*sinf(tAngle*DEG_TO_RAD))];
	
	for(NSUInteger i=0;i<_teethCount;i++)
	{
		[tBezierPath lineToPoint:NSMakePoint(tMidX+_outerRadius*cosf((tAngle+tSemiDeltaAngle)*DEG_TO_RAD),tMidY+_outerRadius*sinf((tAngle+tSemiDeltaAngle)*DEG_TO_RAD))];
		
		tAngle+=tDeltaAngle;
		
		[tBezierPath lineToPoint:NSMakePoint(tMidX+tInnerRadius*cosf(tAngle*DEG_TO_RAD),tMidY+tInnerRadius*sinf(tAngle*DEG_TO_RAD))];
	}
	
	[tBezierPath closePath];
	
	CGFloat tFactor=(_pushed==NO) ? 1.0 : 0.5;
	
	if (self.isMissing==NO)
		[[NSColor colorWithDeviceWhite:0.485*tFactor alpha:1.0] setFill];
	else
		[[NSColor colorWithDeviceRed:202.0/255.0 green:46.0/255.0 blue:50.0/255.0 alpha:1.0] setFill];
	
	[tBezierPath fill];
	
	if (self.isMissing==NO)
		[[NSColor colorWithDeviceWhite:0.325*tFactor alpha:1.0] setStroke];
	else
		[[NSColor colorWithDeviceRed:137.0/255.0 green:46.0/255.0 blue:50.0/255.0 alpha:1.0] setStroke];
	
	[tBezierPath stroke];
	
	CGFloat tCircleRadius=tInnerRadius*0.95;
	
	if (self.isMissing==NO)
	{
		tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(tMidX-tCircleRadius,tMidY-tCircleRadius,tCircleRadius*2.0,tCircleRadius*2.0)];
		
		NSGradient * tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.7*tFactor alpha:1.0] endingColor:[NSColor colorWithDeviceWhite:0.1*tFactor alpha:1.0]];
		
		[tGradient drawInBezierPath:tBezierPath angle:-90.0];
	}
	
	if (self.isMissing==NO)
		[[NSColor colorWithDeviceWhite:0.425*tFactor alpha:1.0] set];
	else
		[[NSColor colorWithDeviceRed:110.0/255.0 green:46.0/255.0 blue:50.0/255.0 alpha:1.0] set];
	
	tCircleRadius=tInnerRadius*0.89;
	
	tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(tMidX-tCircleRadius,tMidY-tCircleRadius,tCircleRadius*2.0,tCircleRadius*2.0)];
	tBezierPath.lineWidth=2.0;
		
	[tBezierPath stroke];
	
	// Draw the text (code from some Apple Sample code)
	
	CGFloat startingAngle=-M_PI_2;

	tCircleRadius=tInnerRadius*0.58;

    // Note that usedRectForTextContainer: does not force layout, so it must 
    // be called after glyphRangeForTextContainer:, which does force layout.
	
    NSRange tGlyphRange = [_layoutManager glyphRangeForTextContainer:_textContainer];
    NSRect usedRect = [_layoutManager usedRectForTextContainer:_textContainer];

    for (NSUInteger tGlyphIndex = tGlyphRange.location; tGlyphIndex < NSMaxRange(tGlyphRange); tGlyphIndex++)
	{
		NSRect lineFragmentRect = [_layoutManager lineFragmentRectForGlyphAtIndex:tGlyphIndex effectiveRange:NULL];
		NSPoint layoutLocation = [_layoutManager locationForGlyphAtIndex:tGlyphIndex];
        
        // Here layoutLocation is the location (in container coordinates) where the glyph was laid out. 
        layoutLocation.x += lineFragmentRect.origin.x;
        layoutLocation.y += lineFragmentRect.origin.y;

        // We then use the layoutLocation to calculate an appropriate position for the glyph 
        // around the circle (by angle and distance, or viewLocation in rectangular coordinates).
        CGFloat distance = tCircleRadius + usedRect.size.height - layoutLocation.y;
        CGFloat angle = startingAngle + layoutLocation.x / distance;

        NSPoint tViewLocation={
			.x=tMidX + distance * sin(angle),
			.y=tMidY + distance * cos(angle)
		};
        
        // We use a different affine transform for each glyph, to position and rotate it
        // based on its calculated position around the circle.  
        
		NSAffineTransform * tTransform = [NSAffineTransform transform];
		
		[tTransform translateXBy:tViewLocation.x yBy:tViewLocation.y];
        [tTransform rotateByRadians:-angle];

        // We save and restore the graphics state so that the transform applies only to this glyph.
        
		 NSGraphicsContext *tGraphicsContext = [NSGraphicsContext currentContext];
		
		[tGraphicsContext saveGraphicsState];
        [tTransform concat];
        // drawGlyphsForGlyphRange: draws the glyph at its laid-out location in container coordinates.
        // Since we are using the transform to place the glyph, we subtract the laid-out location here.
        [_layoutManager drawGlyphsForGlyphRange:NSMakeRange(tGlyphIndex, 1) atPoint:NSMakePoint(-layoutLocation.x, -layoutLocation.y)];
        [tGraphicsContext restoreGraphicsState];
    }
	
	if (self.isMissing==NO)
	{
		tCircleRadius=tInnerRadius*0.54;
	
		tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(tMidX-tCircleRadius,tMidY-tCircleRadius,tCircleRadius*2.0,tCircleRadius*2.0)];
	
		NSGradient * tGradient=[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.7*tFactor alpha:1.0] endingColor:[NSColor colorWithDeviceWhite:0.1*tFactor alpha:1.0]];
		[tGradient drawInBezierPath:tBezierPath angle:-90.0];
	}
}

- (void)mouseDown:(NSEvent *)inEvent
{
	if (self.isEnabled==NO)
		return;
	
	NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:self.bounds];
	
	if ([tBezierPath containsPoint:[self convertPoint:inEvent.locationInWindow fromView:nil]]==YES)
	{
		_pushed=YES;
			
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseDragged:(NSEvent *)inEvent
{
    if (self.isEnabled==NO)
		return;
	
	NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:self.bounds];
	
	if ([tBezierPath containsPoint:[self convertPoint:inEvent.locationInWindow fromView:nil]]==YES)
	{
		if (_pushed==NO)
		{
			_pushed=YES;
			
			[self setNeedsDisplay:YES];
		}
	}
	else
	{
		if (_pushed==YES)
		{
			_pushed=NO;
			
			[self setNeedsDisplay:YES];
		}
	}
}

- (void)mouseUp:(NSEvent *)inEvent
{
	if (self.isEnabled==NO)
		return;
	
	_pushed=NO;
	
	NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:self.bounds];
	
	if ([tBezierPath containsPoint:[self convertPoint:inEvent.locationInWindow fromView:nil]]==YES)
	{
		[self sendAction:self.action to:self.target];
		
		[self setNeedsDisplay:YES];
	}
}

@end
