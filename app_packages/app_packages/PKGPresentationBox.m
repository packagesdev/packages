/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPresentationBox.h"

#define PKGPresentationBoxCornerRadius	10.0

#define PKGPresentationBoxLineWidth		2.0

#define PKGPresentationBoxTextPadding	6.0

#define PKGPresentationBoxTextHeight		16.0

@implementation PKGPresentationBox

- (void)drawRect:(NSRect)inFrame
{
	NSRect tBounds=[self bounds];
	CGFloat tWidth=NSWidth(tBounds);
	CGFloat tHeight=NSHeight(tBounds);
	
	NSRect tTitleRect=[self titleRect];
	
	tTitleRect.origin.x=round((tWidth-NSWidth(tTitleRect))*0.5)+2.0;
	tTitleRect.origin.y=round(tHeight-PKGPresentationBoxTextHeight);
	
	CGFloat tSideWidth=round((tWidth-NSWidth(tTitleRect))*0.5-PKGPresentationBoxCornerRadius-PKGPresentationBoxTextPadding);
	
	// Draw Frame
	
	NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
	tBezierPath.lineWidth=PKGPresentationBoxLineWidth;
	
	if (tSideWidth>0)
	{
		[tBezierPath moveToPoint:NSMakePoint(PKGPresentationBoxCornerRadius+tSideWidth,round(tHeight-PKGPresentationBoxTextHeight*0.5-1.0)-0.5)];
		
		[tBezierPath lineToPoint:NSMakePoint(round(PKGPresentationBoxCornerRadius+PKGPresentationBoxLineWidth*0.5)+0.5,round(tHeight-PKGPresentationBoxTextHeight*0.5-1.0))];
	}
	else
	{
		[tBezierPath moveToPoint:NSMakePoint(round(PKGPresentationBoxCornerRadius+PKGPresentationBoxLineWidth*0.5),round(tHeight-PKGPresentationBoxTextHeight*0.5-1.0))];
	}
	
	[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(round(PKGPresentationBoxCornerRadius+PKGPresentationBoxLineWidth*0.5)+0.5,round(tHeight-PKGPresentationBoxTextHeight*0.5-1.0)-PKGPresentationBoxCornerRadius)
											radius:PKGPresentationBoxCornerRadius
										startAngle:90.0
										  endAngle:180.0];
	
	[tBezierPath lineToPoint:NSMakePoint(round(PKGPresentationBoxLineWidth*0.5)+0.5,round(PKGPresentationBoxLineWidth*0.5+PKGPresentationBoxCornerRadius)+0.5)];
	
	[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(round(PKGPresentationBoxLineWidth*0.5+PKGPresentationBoxCornerRadius)+0.5,round(PKGPresentationBoxLineWidth*0.5+PKGPresentationBoxCornerRadius)+0.5)
											radius:PKGPresentationBoxCornerRadius
										startAngle:180.0
										  endAngle:270.0];
	
	[tBezierPath lineToPoint:NSMakePoint(tWidth-round(PKGPresentationBoxLineWidth*0.5+PKGPresentationBoxCornerRadius)-0.5f,round(PKGPresentationBoxLineWidth*0.5)+0.5)];
	
	[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(tWidth-round(PKGPresentationBoxLineWidth*0.5f+PKGPresentationBoxCornerRadius)-0.5,round(PKGPresentationBoxLineWidth*0.5+PKGPresentationBoxCornerRadius)+0.5)
											radius:PKGPresentationBoxCornerRadius
										startAngle:270.0
										  endAngle:360.0];
	
	[tBezierPath lineToPoint:NSMakePoint(round(tWidth-PKGPresentationBoxLineWidth*0.5f)-0.5f,round(tHeight-PKGPresentationBoxTextHeight*0.5-1.0)-PKGPresentationBoxCornerRadius-0.5)];
	
	[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(round(tWidth-PKGPresentationBoxLineWidth*0.5)-PKGPresentationBoxCornerRadius-0.5,round(tHeight-PKGPresentationBoxTextHeight*0.5-1.0)-PKGPresentationBoxCornerRadius-0.5)
											radius:PKGPresentationBoxCornerRadius
										startAngle:0.0
										  endAngle:90.0];

	if (tSideWidth>0)
		[tBezierPath lineToPoint:NSMakePoint(tWidth-PKGPresentationBoxCornerRadius-tSideWidth,round(tHeight-PKGPresentationBoxTextHeight*0.5-1.0)-0.5)];
	
	[[NSColor colorWithDeviceWhite:0.25 alpha:1.0] set];
	
	[tBezierPath stroke];
		
	// Draw Text
										
	[[self title] drawInRect:tTitleRect 
			  withAttributes:@{NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:0.25 alpha:1.0],
							   NSFontAttributeName:[self titleFont]}];
}

@end
