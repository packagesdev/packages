/*
 Copyright (c) 2007-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGInstallationSurgeryWindow.h"

@interface PKGSurgeryView : NSView
{
	NSPoint _fieldOrigin;
	CGFloat _fieldRightMargin;
	CGFloat _fieldTopMargin;
}

- (void)setSurgeryFieldFrame:(NSRect)inFrame;

@end

@implementation PKGSurgeryView

- (void)setSurgeryFieldFrame:(NSRect)inFrame
{
	_fieldOrigin=inFrame.origin;
	
	_fieldRightMargin=NSWidth(self.bounds)-NSMaxX(inFrame);
	_fieldTopMargin=NSHeight(self.bounds)-NSMaxY(inFrame);
}

- (void)drawRect:(NSRect)inRect
{
	[[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
	
	NSRectFillUsingOperation(inRect,WBCompositingOperationSourceOver);
	
	[[NSColor clearColor] set];
	
	NSRect tBounds=self.bounds;
	
	CGFloat tWidth=NSWidth(tBounds)-_fieldOrigin.x-_fieldRightMargin;
	CGFloat tHeight=NSHeight(tBounds)-_fieldOrigin.y-_fieldTopMargin;
	
	NSRect tRect={
		.origin=_fieldOrigin,
		.size=NSMakeSize(tWidth, tHeight)
	};
	
	NSRectFillUsingOperation(tRect,WBCompositingOperationSourceOver);
}

@end

@interface PKGInstallationSurgeryWindow ()
{
	PKGSurgeryView * _surgeryView;
}

@end

@implementation PKGInstallationSurgeryWindow

+ (NSRect)windowFrameForView:(NSView *)inView
{
	NSRect tFrame=inView.frame;
	NSRect tWindowFrame=[inView convertRect:tFrame toView:inView.window.contentView];
	
	tFrame=[inView convertRect:tFrame toView:nil];
	
	tWindowFrame.origin=[inView.window convertRectToScreen:tFrame].origin;
	
	return tWindowFrame;
}

- (id)initForView:(NSView *) inView
{
	if (inView==nil)
		return nil;

	NSRect tWindowFrame=[PKGInstallationSurgeryWindow windowFrameForView:inView];
		
	self=[super initWithContentRect:tWindowFrame styleMask:WBWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
	
	if (self!=nil)
	{
		[super setBackgroundColor:[NSColor clearColor]];
		
		[super setOpaque:NO];
		
		_surgeryView=[[PKGSurgeryView alloc] initWithFrame:NSZeroRect];
		
		if (_surgeryView==nil)
			return nil;

		_surgeryView.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
		
		NSView * tContentView=[super contentView];
		
		_surgeryView.frame=tContentView.bounds;
		
		[tContentView addSubview:_surgeryView];
	}
	
	return self;
}

#pragma mark -

- (void)setSurgeryViewFrame:(NSRect)inFrame
{
	_surgeryView.surgeryFieldFrame=inFrame;
	
	[_surgeryView setNeedsDisplay:YES];
}

@end
