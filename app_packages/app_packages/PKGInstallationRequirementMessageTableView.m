/*
 Copyright (c) 2008-2010, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGInstallationRequirementMessageTableView.h"

@implementation PKGInstallationRequirementMessageTableView

- (void) drawGridInClipRect:(NSRect)clipRect
{
	[super drawGridInClipRect:clipRect];
	
	CGFloat rowHeight = [self rowHeight] + self.intercellSpacing.height;
    NSRect tBounds=self.bounds;
    NSRect highlightRect;
	NSBezierPath * tBezierPath;
	const CGFloat tPattern[2]={1.0,1.0};
	
	highlightRect.origin = NSMakePoint(NSMinX(tBounds), round(NSMinY(tBounds)/rowHeight)*rowHeight);
    highlightRect.size = NSMakeSize(NSWidth(tBounds), rowHeight + [self intercellSpacing].height);
    
	CGFloat tColumWidth=[[self tableColumnWithIdentifier:@"message.language"] width] + [self intercellSpacing].width;
	
	[self.gridColor setStroke];
	
	tBezierPath=[NSBezierPath bezierPath];
	
    while (NSMinY(highlightRect) < NSMaxY(tBounds))
    {
        NSRect clippedHighlightRect = NSIntersectionRect(highlightRect, tBounds);
		
		NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
		
		[tBezierPath setLineDash:tPattern count:2 phase:0];
		
		[tBezierPath moveToPoint:NSMakePoint(NSMinX(clippedHighlightRect)+tColumWidth,round(NSMidY(clippedHighlightRect))-0.5)];
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(clippedHighlightRect),round(NSMidY(clippedHighlightRect))-0.5)];
		
		[tBezierPath stroke];
		
        highlightRect.origin.y += rowHeight;
    }
	
	[tBezierPath setLineDash:tPattern count:0 phase:0];
			
	[tBezierPath moveToPoint:NSMakePoint(NSMinX(tBounds)+tColumWidth-0.5,NSMinY(tBounds))];
	
	[tBezierPath lineToPoint:NSMakePoint(NSMinX(tBounds)+tColumWidth-0.5,NSMaxY(tBounds))];
	
	[tBezierPath stroke];
}

@end
