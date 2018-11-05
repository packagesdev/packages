/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGConclusionTableRowView.h"

NSString * const PKGConclusionTableRowViewIdentifier=@"PKGConclusionTableRowViewIdentifier";

@implementation PKGConclusionTableRowView

- (void)setState:(PKGBuildEventItemState)inState
{
	if (_state==inState)
		return;
	
	_state=inState;
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)inRect
{
	if (self.isSelected==YES)
	{
		[super drawRect:inRect];
		return;
	}
	
	NSRect tBounds=self.bounds;
	
	BOOL tIsDark=[self WB_isEffectiveAppearanceDarkAqua];
	
	if (tIsDark==NO)
	{
		if (self.state==PKGBuildEventItemStateSuccess)
			[[NSColor colorWithCalibratedRed:0.8471f green:0.9647f blue:0.8510f alpha:1.0] set];
		else
			[[NSColor colorWithCalibratedRed:0.9647f green:0.8471f blue:0.8510f alpha:1.0] set];
	}
	else
	{
		if (self.state==PKGBuildEventItemStateSuccess)
			[[NSColor colorWithCalibratedRed:0.1647f green:0.7882f blue:0.0902f alpha:1.0] set];
		else
			[[NSColor colorWithCalibratedRed:0.7882f green:0.1647f blue:0.0902f alpha:1.0] set];
	}
	
	NSRectFill(tBounds);
	
	if (tIsDark==NO)
	{
		if (self.state==PKGBuildEventItemStateSuccess)
			[[NSColor colorWithCalibratedRed:0.1647f green:0.7882f blue:0.0902f alpha:1.0] set];
		else
			[[NSColor colorWithCalibratedRed:0.7882f green:0.1647f blue:0.0902f alpha:1.0] set];
	}
	else
	{
		if (self.state==PKGBuildEventItemStateSuccess)
			[[NSColor colorWithCalibratedRed:0.8471f green:0.9647f blue:0.8510f alpha:1.0] set];
		else
			[[NSColor colorWithCalibratedRed:0.9647f green:0.8471f blue:0.8510f alpha:1.0] set];
	}
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tBounds),NSMinY(tBounds)+0.5) toPoint:NSMakePoint(NSMaxX(tBounds),NSMinY(tBounds)+0.5)];
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tBounds),NSMaxY(tBounds)-0.5) toPoint:NSMakePoint(NSMaxX(tBounds),NSMaxY(tBounds)-0.5)];

}

@end
