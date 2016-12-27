/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WBSlideShowView.h"

NSString * const WBSlideShowViewVisibleSlideDidChange=@"WBSlideShowViewVisibleSlideDidChange";

@interface WBSlideShowView ()
{
	NSView * _visibleView;
}

@end

@implementation WBSlideShowView

- (instancetype)initWithFrame:(NSRect)inFrame
{
	self=[super initWithFrame:inFrame];
	
	if (self!=nil)
	{
		_visibleSlide=-1;
		
		_drawsBackground=NO;
		_backgroundColor=[NSColor whiteColor];
		_slideShowFrameStyle=WBSlideShowFrameNone;
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)inCoder
{
	self=[super initWithCoder:inCoder];
	
	if (self!=nil)
	{
		_visibleSlide=-1;
		
		_drawsBackground=NO;
		_backgroundColor=[NSColor whiteColor];
		_slideShowFrameStyle=WBSlideShowFrameNone;
	}
	
	return self;
}

#pragma mark -

- (void)setDataSource:(id<WBSlideShowViewDataSource>)inDataSource
{
	if (inDataSource!=_dataSource)
	{
		_dataSource=inDataSource;
		
		if (_dataSource!=nil)
			self.visibleSlide=0;
	}
}

- (void)setVisibleSlide:(NSInteger)inVisibleSlide
{
	if (self.dataSource==nil)
		return;
	
	if (inVisibleSlide<0 || inVisibleSlide>=[self.dataSource numberOfSlidesInSlideShowView:self])
		return;
	
	if (inVisibleSlide!=_visibleSlide)
	{
		_visibleSlide=inVisibleSlide;
		
		[_visibleView removeFromSuperview];
		
		_visibleView=[self.dataSource slideShowView:self viewForSlide:_visibleSlide];
		
		if (_visibleView==nil)
		{
			// A COMPLETER
			
			return;
		}
		
		_visibleView.frame=self.bounds;
		
		[self addSubview:_visibleView];
	}
}

- (void)setDrawsBackground:(BOOL)inBool
{
	_drawsBackground=inBool;
	[self setNeedsDisplay:YES];
}

- (void)setBackgroundColor:(NSColor *)inColor
{
	if (inColor==nil)
		return;
	
	_backgroundColor=[inColor copy];
	[self setNeedsDisplay:YES];
}

- (void)setSlideShowFrameStyle:(WBSlideShowFrameStyle)inStyle
{
	_slideShowFrameStyle=inStyle;
	[self setNeedsDisplay:YES];
}

#pragma mark -

- (void)viewWillMoveToWindow:(NSWindow *)inWindow
{
	[super viewWillMoveToWindow:inWindow];
	
	if (inWindow!=nil && self.visibleSlide==-1 && self.dataSource!=nil)
		self.visibleSlide=0;
}

#pragma mark -

- (BOOL)isLastSlide
{
	if (self.dataSource==nil)
		return YES;
	
	return (self.visibleSlide==([self.dataSource numberOfSlidesInSlideShowView:self]-1));
}

- (void)showPreviousSlide
{
	if (self.dataSource==nil)
		return;
	
	NSInteger tVisibleSlide=self.visibleSlide;
	
	if (tVisibleSlide>0)
	{
		tVisibleSlide--;
		
		self.visibleSlide=tVisibleSlide;
		
		// Notify delegate and post notification
		
		NSNotification * tNotification=[NSNotification notificationWithName:WBSlideShowViewVisibleSlideDidChange
																	 object:self
																   userInfo:@{}];
		
		if ([self.delegate respondsToSelector:@selector(slideShowViewVisibleSlideDidChange:)]==YES)
			[self.delegate slideShowViewVisibleSlideDidChange:tNotification];
		
		[[NSNotificationCenter defaultCenter] postNotification:tNotification];
	}
}

- (void)showNextSlide
{
	if (self.dataSource==nil)
		return;
	
	NSInteger tVisibleSlide=self.visibleSlide;
	NSInteger tLastVisibleSlide=[self.dataSource numberOfSlidesInSlideShowView:self]-1;
	
	if (tVisibleSlide<tLastVisibleSlide)
	{
		tVisibleSlide++;
		
		if ([self.delegate respondsToSelector:@selector(slideShowView:shouldShowNextSlide:)]==YES &&
			[self.delegate slideShowView:self shouldShowNextSlide:tVisibleSlide]==NO)
				return;
		
		self.visibleSlide=tVisibleSlide;
		
		// Notify delegate and post notification
		
		NSNotification * tNotification=[NSNotification notificationWithName:WBSlideShowViewVisibleSlideDidChange
																	 object:self
																   userInfo:@{}];
		
		if ([self.delegate respondsToSelector:@selector(slideShowViewVisibleSlideDidChange:)]==YES)
			[self.delegate slideShowViewVisibleSlideDidChange:tNotification];
		
		[[NSNotificationCenter defaultCenter] postNotification:tNotification];
	}
}

- (void)drawRect:(NSRect)inRect
{
	// Background
	
	if (self.drawsBackground==YES)
	{
		[self.backgroundColor setFill];
		NSRectFill(inRect);
	}
	
	// Frame
	
	if (self.slideShowFrameStyle==WBSlideShowFrameGrayBezel)
	{
		[[NSColor lightGrayColor] setFill];
		NSFrameRect(self.bounds);
	}
}

@end
