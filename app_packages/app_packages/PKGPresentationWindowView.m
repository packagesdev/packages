/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of Stephane Sudre nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPresentationWindowView.h"
#include <Carbon/Carbon.h>

#define PKGPresentationWindowViewShadowOffset	10.0
#define PKGPresentationWindowViewTitleBarHeight	24.0

@interface PKGPresentationWindowView ()
{
	IBOutlet NSWindow * _helperWindow;	/* An optional outlet to a real window to get its background color */
}

@end

@implementation PKGPresentationWindowView

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawRect:(NSRect)inFrame
{
	NSRect tBounds=self.bounds;
	
	// Draw Shadow
	
	NSRect tShadowFrame={
		{.x=PKGPresentationWindowViewShadowOffset,.y=PKGPresentationWindowViewShadowOffset},
		{.width=NSWidth(tBounds)-2.0*PKGPresentationWindowViewShadowOffset,.height=NSHeight(tBounds)-2.0*PKGPresentationWindowViewShadowOffset}};
	
	[NSGraphicsContext saveGraphicsState];
	
	NSShadow * tShadow=[[NSShadow alloc] init];
	
	tShadow.shadowOffset=NSMakeSize(0.0,-3.0);
	tShadow.shadowBlurRadius=12.0;
	tShadow.shadowColor=[([[self window] isMainWindow]==YES) ? [NSColor blackColor] : [NSColor lightGrayColor] colorWithAlphaComponent:0.5];
	
	[tShadow set];
	
	[[NSColor blackColor] set];
	
	NSRectFillUsingOperation(tShadowFrame,NSCompositeSourceOver);
	
	[NSGraphicsContext restoreGraphicsState];
	
	// Draw Bezel
	
	HIRect tContentRect={
		{.x=PKGPresentationWindowViewShadowOffset,.y=PKGPresentationWindowViewShadowOffset},
		{.width=NSWidth(tBounds)-2.0*PKGPresentationWindowViewShadowOffset,.height=NSHeight(tBounds)-PKGPresentationWindowViewTitleBarHeight-PKGPresentationWindowViewShadowOffset}};
		
	CGContextRef tContextRef=(CGContextRef) [[self.window graphicsContext] graphicsPort];
	
	HIThemeWindowDrawInfo tWindowDrawInfo={
		.version=0,
		.state=([self.window isMainWindow]==YES) ? kThemeStateActive : kThemeStateInactive,
		.windowType=kThemeDocumentWindow,
		.attributes=kThemeWindowHasTitleText,
		.titleHeight=10.0,
		.titleWidth=100.0};
	
	HIRect tTitleRect;
	HIThemeDrawWindowFrame(&tContentRect,&tWindowDrawInfo,tContextRef,kHIThemeOrientationInverted,&tTitleRect);
	
	// Draw Frame
	
	tBounds=NSMakeRect(tContentRect.origin.x,tContentRect.origin.y,tContentRect.size.width,tContentRect.size.height);
	
	[[NSColor colorWithDeviceWhite:0.7373 alpha:0.5] set];
		
	NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
	
	[tBezierPath moveToPoint:NSMakePoint(NSMinX(tBounds)-0.5,NSMinY(tBounds)-0.5)];
	[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBounds)+0.5,NSMinY(tBounds)-0.5)];
	[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBounds)+0.5,NSMaxY(tBounds)+16.5)];
	[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(tBounds)+0.5-5.0,NSMaxY(tBounds)+16.5)
											radius:5.0
										startAngle:0.0
										  endAngle:90.0];
	[tBezierPath lineToPoint:NSMakePoint(NSMinX(tBounds)+5.0,NSMaxY(tBounds)+21.5)];
	[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(tBounds)-0.5+5.0,NSMaxY(tBounds)+16.5)
											radius:5.0
										startAngle:90.0
										  endAngle:180.0];
	[tBezierPath closePath];
	
	[tBezierPath stroke];
	
	// Draw Background

	tBounds=NSMakeRect(tContentRect.origin.x,tContentRect.origin.y,tContentRect.size.width,tContentRect.size.height);
	
	if (_helperWindow!=nil)
		[_helperWindow.backgroundColor set];
	else
		[self.window.backgroundColor set];
	
	NSRectFillUsingOperation(tBounds,NSCompositeSourceOver);
}

#pragma mark -

- (void) viewWillMoveToWindow:(NSWindow *) inWindow
{
	if (inWindow!=nil)
	{
		// Register for Notifications
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:inWindow];
												   
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:inWindow];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.window];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.window];
	}
}

#pragma mark - Notifications

- (void)windowDidBecomeMain:(NSNotification *) inNotification
{
	[self setNeedsDisplay:YES];
}

- (void)windowDidResignMain:(NSNotification *) inNotification
{
	[self setNeedsDisplay:YES];
}

@end
