/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGStackView.h"

@interface PKGStackView ()
{
	NSMutableArray * _mutableViews;
}

- (void)_updatelayout;

@end

@implementation PKGStackView

- (instancetype)initWithFrame:(NSRect)inRect
{
	self=[super initWithFrame:inRect];
	
	if (self!=nil)
	{
		_orientation=PKGUserInterfaceLayoutOrientationVertical;
		
		_mutableViews=[NSMutableArray array];
		
		_hasEqualSize=YES;
		
		_spacing=0.0;
	}
	
	return self;
}

#pragma mark -

- (void)setHasEqualSize:(BOOL)inHasEqualSize
{
	if (_hasEqualSize!=inHasEqualSize)
	{
		_hasEqualSize=inHasEqualSize;
		
		[self _updatelayout];
	}
}

- (void)setOrientation:(PKGUserInterfaceLayoutOrientation)inOrientation
{
	if (_orientation!=inOrientation)
	{
		_orientation=inOrientation;
		
		[self _updatelayout];
	}
}

- (void)setSpacing:(CGFloat)inSpacing
{
	inSpacing=round(inSpacing);
	
	if (inSpacing<0.0)
		inSpacing=0.0;
	
	if (_spacing!=inSpacing)
	{
		_spacing=inSpacing;
		
		[self _updatelayout];
	}
}

- (NSArray *)views
{
	return [_mutableViews copy];
}

- (void)setFrame:(NSRect)inFrame
{
	[super setFrame:inFrame];
	
	[self _updatelayout];
}

#pragma mark -

- (void)_updatelayout
{
	NSSet * tSubviewsSet=[NSSet setWithArray:[self subviews]];
	NSMutableSet * tRemovedSet=[tSubviewsSet mutableCopy];
	
	NSMutableSet * tFutureSet=[NSMutableSet setWithArray:_mutableViews];
	[tRemovedSet minusSet:tFutureSet];
	
	[tFutureSet minusSet:tSubviewsSet];
	
	// Notify View controllers
	
	[tRemovedSet enumerateObjectsUsingBlock:^(NSView *bView,BOOL *bOutStop){
	
		NSViewController * tViewController=nil;
		NSResponder * tNextResponder=bView.nextResponder;
		
		if ([tNextResponder isKindOfClass:[NSViewController class]]==YES)
		{
			tViewController=(NSViewController *)tNextResponder;
		
			if (tViewController.view!=bView)
				tViewController=nil;
		}
		
		[tViewController WB_viewWillRemove];
		
		[bView removeFromSuperview];
		
		[tViewController WB_viewDidRemove];
	}];
	
	// Layout
	
	NSRect tBounds=self.bounds;
	CGFloat tStackedViewWidth=NSWidth(tBounds);
	CGFloat tStackedViewHeight=NSHeight(tBounds);
	NSUInteger tViewsCount=_mutableViews.count;
	
	if (self.hasEqualSize==YES && tViewsCount>1)
	{
		switch(self.orientation)
		{
			case PKGUserInterfaceLayoutOrientationHorizontal:
				
				tStackedViewWidth=round((NSWidth(tBounds)-(tViewsCount-1)*self.spacing)/tViewsCount);
				
				break;
				
			case PKGUserInterfaceLayoutOrientationVertical:
				
				tStackedViewHeight=round((NSHeight(tBounds)-(tViewsCount-1)*self.spacing)/tViewsCount);
				
				break;
				
			default:
				
				NSLog(@"Unknown orientation");
				return;
		}
	}
	
	__block NSPoint tOrigin=NSMakePoint(NSMinX(tBounds),NSMaxY(tBounds));
	
	[_mutableViews enumerateObjectsUsingBlock:^(NSView *bView,NSUInteger bIndex,BOOL *bOutStop){
	
		CGFloat tWidth=tStackedViewWidth;
		CGFloat tHeight=tStackedViewHeight;

		switch(self.orientation)
		{
			case PKGUserInterfaceLayoutOrientationHorizontal:
				
				tOrigin.y=NSMinY(tBounds);
				
				if (self.hasEqualSize==NO)
					tWidth=NSWidth(bView.frame);
				
				if (bIndex!=(tViewsCount-1))
				{
					bView.frame=NSMakeRect(tOrigin.x, tOrigin.y, tWidth, tStackedViewHeight);
				
					tOrigin.x+=(tWidth+self.spacing);
				}
				else
				{
					tWidth=NSWidth(tBounds)-tOrigin.x;
					
					bView.frame=NSMakeRect(tOrigin.x, tOrigin.y,tWidth, tStackedViewHeight);
				}
				
				break;
				
			case PKGUserInterfaceLayoutOrientationVertical:
				
				if (self.hasEqualSize==NO)
					tHeight=NSHeight(bView.frame);
				
				if (bIndex!=(tViewsCount-1))
				{
					bView.frame=NSMakeRect(tOrigin.x, tOrigin.y-tHeight, tStackedViewWidth, tHeight);
					
					tOrigin.y-=(tHeight+self.spacing);
				}
				else
				{
					tHeight=tOrigin.y-NSMinY(tBounds);
					
					bView.frame=NSMakeRect(tOrigin.x, tOrigin.y-tHeight, tStackedViewWidth, tHeight);
				}
				
				break;
		}
	}];
	
	// Notify View controllers
	
	[tFutureSet enumerateObjectsUsingBlock:^(NSView *bView,BOOL *bOutStop){
	
		NSViewController * tViewController=nil;
		NSResponder * tNextResponder=bView.nextResponder;
		
		if ([tNextResponder isKindOfClass:[NSViewController class]]==YES)
		{
			tViewController=(NSViewController *)tNextResponder;
			
			if (tViewController.view!=bView)
				tViewController=nil;
		}
		
		[tViewController WB_viewWillAdd];
		
		[self addSubview:bView];
		
		[tViewController WB_viewDidAdd];
	}];
}

- (void)addView:(NSView *)inView
{
	if (inView==nil)
		return;
	
	[_mutableViews addObject:inView];
	
	[self _updatelayout];
}

- (void)insertView:(NSView *)inView atIndex:(NSUInteger)inIndex
{
	if (inView==nil)
		return;
	
	[_mutableViews insertObject:inView atIndex:inIndex];
	
	[self _updatelayout];
}

- (void)removeView:(NSView *)inView
{
	if (inView==nil)
		return;
	
	[_mutableViews removeObject:inView];
	
	[self _updatelayout];
}

@end
