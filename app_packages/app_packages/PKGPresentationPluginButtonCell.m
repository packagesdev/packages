/*
Copyright (c) 2007-2010, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPresentationPluginButtonCell.h"

#define PKGPresentationPluginButtonCellLineWidth		2.5f

#define PKGPresentationPluginButtonCellIconLineWidth	2.5f

#define PKGPresentationPluginButtonCellIconWidth		5.0f

@implementation PKGPresentationPluginButtonCell

- (void)drawWithFrame:(NSRect)inFrame inView:(NSView *)inControlView
{
	NSRect tRect=NSInsetRect(inFrame,PKGPresentationPluginButtonCellLineWidth,PKGPresentationPluginButtonCellLineWidth);
	
	[[NSColor colorWithDeviceWhite:0.25 alpha:([self isEnabled]==YES) ? 1.0 : 0.5] set];
	
	// Draw the circle
	
	NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:tRect];
	
	tBezierPath.lineWidth=PKGPresentationPluginButtonCellLineWidth;
	
	if ([self isHighlighted]==YES)
		[tBezierPath fill];

	[tBezierPath stroke];
	
	// Draw the Plus or Minus
	
	tBezierPath=[NSBezierPath bezierPath];
	
	if ([self isHighlighted]==YES)
		[[NSColor whiteColor] setStroke];
	
	tBezierPath.lineWidth=PKGPresentationPluginButtonCellIconLineWidth;
	
	switch(self.pluginButtonType)
	{
		case PKGPlusButton:
			
			[tBezierPath moveToPoint:NSMakePoint(round(NSMidX(tRect)),round(NSMidY(tRect)-PKGPresentationPluginButtonCellIconWidth))];
			[tBezierPath lineToPoint:NSMakePoint(round(NSMidX(tRect)),round(NSMidY(tRect)+PKGPresentationPluginButtonCellIconWidth))];
			
			/*
			[tBezierPath moveToPoint:NSMakePoint(round(NSMidX(tRect)-PKGPresentationPluginButtonCellIconWidth),round(NSMidY(tRect)))];
			[tBezierPath lineToPoint:NSMakePoint(round(NSMidX(tRect)+PKGPresentationPluginButtonCellIconWidth),round(NSMidY(tRect)))];
			
			break;*/	// Decomment if there are more types in the future
			
		case PKGMinusButton:
			
			[tBezierPath moveToPoint:NSMakePoint(round(NSMidX(tRect)-PKGPresentationPluginButtonCellIconWidth),round(NSMidY(tRect)))];
			[tBezierPath lineToPoint:NSMakePoint(round(NSMidX(tRect)+PKGPresentationPluginButtonCellIconWidth),round(NSMidY(tRect)))];
			
			break;
	}
	
	[tBezierPath stroke];
}

@end
