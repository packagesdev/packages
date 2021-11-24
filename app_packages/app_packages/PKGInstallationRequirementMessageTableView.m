/*
 Copyright (c) 2008-2021, Stephane Sudre
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
	
	CGFloat tRowHeight = self.rowHeight + self.intercellSpacing.height;
    NSRect tBounds=self.bounds;
    NSRect highlightRect;
	
	highlightRect.origin = NSMakePoint(NSMinX(tBounds), round(NSMinY(tBounds)/rowHeight)*tRowHeight);
    highlightRect.size = NSMakeSize(NSWidth(tBounds), tRowHeight + self.intercellSpacing.height);
    
    CGFloat tHalfHeight=round(NSHeight(highlightRect)*0.5);
    CGFloat tColumMaxX=NSMaxX([self rectOfColumn:0]);
	
	[self.gridColor setStroke];
    
    const CGFloat tPattern[2]={1.0,1.0};
    
    while (NSMinY(highlightRect) < NSMaxY(tBounds))
    {
        NSRect clippedHighlightRect = NSIntersectionRect(highlightRect, tBounds);
        
		NSBezierPath * tDashedBezierPath=[NSBezierPath bezierPath];
		
		[tDashedBezierPath setLineDash:tPattern count:2 phase:0];
		
		[tDashedBezierPath moveToPoint:NSMakePoint(tColumMaxX,round(NSMinY(clippedHighlightRect)+tHalfHeight)-0.5)];
		[tDashedBezierPath lineToPoint:NSMakePoint(NSMaxX(clippedHighlightRect),round(NSMinY(clippedHighlightRect)+tHalfHeight)-0.5)];
		
		[tDashedBezierPath stroke];
		
        highlightRect.origin.y += tRowHeight;
    }
}

@end
