/*
Copyright (c) 2007-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGVerticallyCenteredTextField.h"

@interface PKGVerticallyCenteredTextField ()
{
	NSRect _boundingRect;
}

- (void) updateBoundingRect;

@end

@implementation PKGVerticallyCenteredTextField

- (void)viewWillMoveToWindow:(NSWindow *) inWindow
{
	if (inWindow!=nil)
		[self updateBoundingRect];
}

- (void)setFrame:(NSRect) inFrame
{
	[super setFrame:inFrame];
	
	[self updateBoundingRect];
}

- (void)setStringValue:(NSString *) inString
{
	[super setStringValue:inString];
	
	[self updateBoundingRect];
}

- (void)updateBoundingRect
{
	NSRect tBounds=[self bounds];
	
	NSAttributedString * tAttributedString=[[self cell] attributedStringValue];
	
	NSMutableString * tMutableString=[[tAttributedString string] mutableCopy];
	
	NSRange tRange;
	NSDictionary * tAttributesDictionary=[tAttributedString attributesAtIndex:0 effectiveRange:&tRange];
	
	NSRect tRect=[tMutableString boundingRectWithSize:NSMakeSize(NSWidth(tBounds),1.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:tAttributesDictionary];
	
	NSUInteger tLength=tMutableString.length;
	
	NSUInteger tMiddle=tLength/2;
	
	BOOL tShortened=NO;
	while (NSHeight(tRect)>NSHeight(tBounds) && tLength>3)
	{
		[tMutableString deleteCharactersInRange:NSMakeRange(tMiddle-1,3)];
		
		[tMutableString insertString:NSLocalizedString(@"...",@"") atIndex:tMiddle-1];
		
		tLength-=2;
		
		tMiddle=tMiddle-1;
		
		tShortened=YES;
		
		tRect=[tMutableString boundingRectWithSize:NSMakeSize(NSWidth(tBounds),1.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:tAttributesDictionary];
	}
	
	_boundingRect.size=tRect.size;
	
	_boundingRect.origin.x=0;
	_boundingRect.origin.y=floor(NSMidY(tBounds)-NSHeight(_boundingRect)*0.5);
	
	if (tShortened==YES)
		self.toolTip=[self stringValue];
	else
		self.toolTip=@"";
	
	[super setStringValue:tMutableString];
}

#pragma mark -

- (void)drawRect:(NSRect) inRect
{
    [[[self cell] attributedStringValue] drawWithRect:_boundingRect options:NSStringDrawingUsesLineFragmentOrigin];
}

@end
