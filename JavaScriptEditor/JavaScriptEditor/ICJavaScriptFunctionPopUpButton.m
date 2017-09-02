/*
Copyright (c) 2009-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ICJavaScriptFunctionPopUpButton.h"

@implementation ICJavaScriptFunctionPopUpButton

- (void) sizeToFit
{
	if ([self indexOfSelectedItem]==-1)
	{
		[self addItemWithTitle:NSLocalizedString(@"<No selected function>",@"")];
		
		[self selectItemAtIndex:self.numberOfItems-1];
		
		[super sizeToFit];
		
		[self removeItemAtIndex:(self.numberOfItems-1)];
		
		[self selectItemAtIndex:-1];
	}
	else
	{
		[super sizeToFit];
	}
}

- (void) drawRect:(NSRect)inRect
{
	NSRect tBounds=self.bounds;
	
	[[NSColor colorWithCalibratedWhite:0.6157 alpha:1.0] set];
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0.5,0.0) toPoint:NSMakePoint(0.5,NSMaxY(tBounds)-1.0)];

	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(tBounds)-0.5,0.0) toPoint:NSMakePoint(NSMaxX(tBounds)-0.5,NSMaxY(tBounds)-1.0)];

	tBounds.size.width-=5.0;
	
	if ([self indexOfSelectedItem]==-1)
	{
		[self addItemWithTitle:NSLocalizedString(@"<No selected function>",@"")];
		
		[self selectItemAtIndex:self.numberOfItems-1];
		
		[[self cell] drawWithFrame:tBounds inView:self];
		
		[self removeItemAtIndex:(self.numberOfItems-1)];
		
		[self selectItemAtIndex:-1];
	}
	else
	{
		[[self cell] drawWithFrame:tBounds inView:self];
	}
}

@end
