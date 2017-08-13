/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPresentationPaneTitleView.h"

@interface PKGPresentationPaneTitleView ()
{
	NSRect _boundingRect;
	
	CGFloat _offset;
}

- (void)delayedScroll:(id)sender;

@end

@implementation PKGPresentationPaneTitleView

- (void)viewWillMoveToWindow:(NSWindow *)inWindow
{
	if (inWindow==nil)
	{
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedScroll:) object:nil];
	}
}

- (void)setStringValue:(NSString *)inStringValue
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedScroll:) object:nil];
	
	[super setStringValue:inStringValue];
	
	NSRect tBounds=self.bounds;
	
	NSAttributedString * tAttributedString=self.attributedStringValue;
	
	_boundingRect=[tAttributedString boundingRectWithSize:tBounds.size options:NSStringDrawingUsesLineFragmentOrigin];
	
	_boundingRect.size.width+=5.0;
	
	_offset=0.0;
	
	if (NSWidth(_boundingRect)>NSWidth(tBounds))
		[self performSelector:@selector(delayedScroll:) withObject:nil afterDelay:2.5];
}

- (void)setAttributedStringValue:(NSAttributedString *)inAttributedStringValue
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedScroll:) object:nil];
	
	super.attributedStringValue=inAttributedStringValue;
	
	NSRect tBounds=self.bounds;
	
	_boundingRect=[inAttributedStringValue boundingRectWithSize:tBounds.size options:NSStringDrawingUsesLineFragmentOrigin];
	
	_boundingRect.size.width+=5.0;
	
	_offset=0.0;
	
	if (NSWidth(_boundingRect)>NSWidth(tBounds))
		[self performSelector:@selector(delayedScroll:) withObject:nil afterDelay:2.5];
}

- (void)setFont:(NSFont *)inFont
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedScroll:) object:nil];
	
	super.font=inFont;
	
	NSRect tBounds=self.bounds;
	
	NSAttributedString * tAttributedString=self.attributedStringValue;
	
	_boundingRect=[tAttributedString boundingRectWithSize:tBounds.size options:NSStringDrawingUsesLineFragmentOrigin];
	
	_boundingRect.size.width+=5.0;
	
	_offset=0.0;
	
	if (NSWidth(_boundingRect)>NSWidth(tBounds))
		[self performSelector:@selector(delayedScroll:) withObject:nil afterDelay:2.5];
}

- (void)setFrame:(NSRect)inFrame
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedScroll:) object:nil];
	
	[super setFrame:inFrame];
	
	NSRect tBounds=self.bounds;
	
	NSAttributedString * tAttributedString=self.attributedStringValue;
	
	_boundingRect=[tAttributedString boundingRectWithSize:tBounds.size options:NSStringDrawingUsesLineFragmentOrigin];
	
	_boundingRect.size.width+=5.0;
	
	_offset=0.0;
	
	if (NSWidth(_boundingRect)>NSWidth(tBounds))
	{
		[self performSelector:@selector(delayedScroll:) withObject:nil afterDelay:2.5];
	}
}

#pragma mark -

- (void)delayedScroll:(id)sender
{
	if ((NSMaxX(_boundingRect)-_offset)<=NSWidth(self.bounds))
	{
		_offset=0.0;
		
		[self performSelector:@selector(delayedScroll:) withObject:nil afterDelay:3.0];
	}
	else
	{
		_offset+=1.0;
		
		[self setNeedsDisplay:YES];
		
		[self performSelector:@selector(delayedScroll:) withObject:nil afterDelay:0.05];
	}
}

- (void)drawRect:(NSRect)inRect
{
	NSRect tRect=NSOffsetRect(_boundingRect,-_offset,0.0);

	[[self cell] drawWithFrame:tRect inView:self];
}

@end
