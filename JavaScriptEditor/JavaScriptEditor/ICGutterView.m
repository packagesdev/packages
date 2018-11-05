/*
Copyright (c) 2009, Todd Ditchendorf
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the Todd Ditchendorf nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*

Moving Todd source code back to Obj-C 1.0
Fixing some bugs

Copyright (c) 2009-2018, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ICGutterView.h"

#import "NSResponder+Appearance.h"

@implementation ICGutterView

- (BOOL)isOpaque
{
	return YES;
}

- (BOOL)isFlipped
{
	return YES;
}

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10)
- (NSAutoresizingMaskOptions)autoresizingMask
#else
- (NSUInteger)autoresizingMask
#endif
{
	return NSViewHeightSizable;
}

- (void)drawRect:(NSRect)inRect
{
	NSRect tBounds=self.bounds;
	
	// Draw Background
	
	BOOL tIsDarkMode=[self WB_isEffectiveAppearanceDarkAqua];
	
	if (tIsDarkMode==NO)
		[[NSColor colorWithCalibratedWhite:0.933 alpha:1.0] set];
	else
		[[NSColor textBackgroundColor] set];
	
	NSRectFill(inRect);
	
	// Draw right and bottom frame
	
	if (NSMaxX(inRect)==NSMaxX(tBounds))
	{
		if (tIsDarkMode==NO)
			[[NSColor colorWithCalibratedWhite:0.5765 alpha:1.0] set];
		else
			[[NSColor textBackgroundColor] set];
		
		[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(tBounds)-0.5,NSMinY(inRect)) toPoint:NSMakePoint(NSMaxX(tBounds)-0.5,NSMaxY(inRect))];
	}
	
	if (NSMinY(inRect)==NSMinY(tBounds))
	{
		if (tIsDarkMode==NO)
			[[NSColor colorWithCalibratedWhite:0.5765 alpha:1.0] set];
		else
			[[NSColor colorWithDeviceWhite:0.1 alpha:1.0] set];
		
		[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tBounds),NSMaxY(inRect)-0.5) toPoint:NSMakePoint(NSMaxX(tBounds),NSMaxY(inRect)-0.5)];
	}
	
	// Draw line numbers
	
	CGFloat tWidth = NSWidth(tBounds);
	
	if ([_lineNumberRects count]>0)
	{
		NSSize tMaxSize=NSMakeSize(800,400);
		
		NSUInteger tCount = _startLineNumber + [_lineNumberRects count];
		
		for (NSUInteger tIndex=_startLineNumber ; tIndex < tCount; tIndex++)
		{
			NSRect tRect = [[_lineNumberRects objectAtIndex:(tIndex - _startLineNumber)] rectValue];
			
			// set the x origin of the number according to the number of digits it contains
			
			// center the number vertically for tall lines
			
			tRect.origin.y += NSHeight(tRect)*0.5 - 6.;
			
			NSString * tString = [NSString stringWithFormat:@"%lu",(unsigned long)tIndex+1];
			
			NSDictionary * tAttributes;
			
			if (tIsDarkMode==NO)
				tAttributes=@{NSFontAttributeName:[NSFont systemFontOfSize:9.0],
							  NSForegroundColorAttributeName:[NSColor darkGrayColor]};
			else
				tAttributes=@{NSFontAttributeName:[NSFont systemFontOfSize:9.0],
							  NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.38 alpha:1.0]};
			
			
			tRect.origin.x=tWidth-NSWidth([tString boundingRectWithSize:tMaxSize options:0 attributes:tAttributes])-2.0;
			
			[tString drawAtPoint:tRect.origin withAttributes:tAttributes];
		}
	}
}

@end
