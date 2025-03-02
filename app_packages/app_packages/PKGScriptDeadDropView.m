/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGScriptDeadDropView.h"

@interface PKGScriptDeadDropView ()
{
	NSImage * _cachedFileIcon;
}

@end

@implementation PKGScriptDeadDropView

- (void)reloadData
{
	_cachedFileIcon=nil;
	
	if (self.dataSource!=nil)
	{
		NSString * tAbsolutePath=[self.dataSource pathForScriptDeadDropView:self];
		
		if (tAbsolutePath!=nil)
			_cachedFileIcon=[[NSWorkspace sharedWorkspace] iconForFile:tAbsolutePath];
	}
	
	[self setNeedsDisplay:YES];
}

- (void)viewDidMoveToWindow
{
	// Refreshing the icon because that's when the filePathConvert becomes "accessible" to the views.
	
	[self reloadData];
}

#pragma mark -

- (void)drawRect:(NSRect)inRect
{
	NSRect tBounds=[self bounds];
	
	void (^drawBackground)(void) = ^void(void){
		
		NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(tBounds,2.0,2.0) xRadius:5.0 yRadius:5.0];
		
		BOOL tIsDark=[self WB_isEffectiveAppearanceDarkAqua];
		
		if (tIsDark==NO)
			[[NSColor colorWithDeviceWhite:0.85 alpha:0.5] setFill];
		else
			[[NSColor colorWithDeviceWhite:0.20 alpha:0.5] setFill];
		
		[tBezierPath fill];
		
		if (tIsDark==NO)
			[[NSColor colorWithDeviceWhite:0.7 alpha:0.5] setStroke];
		else
			[[NSColor colorWithDeviceWhite:0.7 alpha:0.5] setStroke];
		
		CGFloat tArray[2]={5.0,2.0};
		[tBezierPath setLineDash:tArray count:2 phase:0.5];
		
		[tBezierPath setLineWidth:2.0];
		
		[tBezierPath stroke];
	};
	
	// Icon
	
	NSString * tAbsolutePath=nil;
	
	if (self.dataSource!=nil)
		tAbsolutePath=[self.dataSource pathForScriptDeadDropView:self];
	
	if (tAbsolutePath!=nil)
	{
		CGFloat tMarginProportion=0.0;
		NSImage * tImage=_cachedFileIcon;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:tAbsolutePath]==NO)
		{
			drawBackground();
			
			tMarginProportion=0.2;
			tImage=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kQuestionMarkIcon)];
		}
		
		CGFloat tSmallerDimension=NSWidth(tBounds);
		
		if (tSmallerDimension>NSHeight(tBounds))
			tSmallerDimension=NSHeight(tBounds);
		
		CGFloat tImageDimension=round(tSmallerDimension*(1.0-2.0*tMarginProportion));
		
		NSRect tDestinationRect={
			.origin={round((NSWidth(tBounds)-tImageDimension)*0.5),round((NSHeight(tBounds)-tImageDimension)*0.5)},
			.size={tImageDimension,tImageDimension}
		};
		
		[tImage drawInRect:tDestinationRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
	}
	else
	{
		drawBackground();
	}
	
	// Highlight
	
	if (self.isHighlighted==YES)
	{
		NSBezierPath * tPath=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(tBounds,2.0,2.0) xRadius:8.0 yRadius:8.0];
		
		[NSColor.selectedContentBackgroundColor setStroke];
			
		[tPath setLineWidth:2.0];
			
		[tPath stroke];
	}
}

@end
