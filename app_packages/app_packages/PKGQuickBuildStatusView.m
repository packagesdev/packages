/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGQuickBuildStatusView.h"

#define STATUS_FRAME_PER_SEC	3.0

@interface PKGQuickBuildStatusView ()
{
	CGFloat _angle;
	
	NSImage * _image;
	
	NSTimer * _timer;
}

+ (NSImage *)sharedSuccessImage;
+ (NSImage *)sharedFailureImage;

@end

@implementation PKGQuickBuildStatusView

+ (NSImage *)sharedSuccessImage
{
	static NSImage * sSuccessImage=nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sSuccessImage=[NSImage imageNamed:@"QuickBuildSuccess"];
	});
	
	return sSuccessImage;
}

+ (NSImage *)sharedFailureImage
{
	static NSImage * sFailureImage=nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sFailureImage=[NSImage imageNamed:@"QuickBuildFailure"];
	});
	
	return sFailureImage;
}

- (instancetype)initWithFrame:(NSRect) inFrame
{
	self=[super initWithFrame:inFrame];
	
	if (self!=nil)
	{
		_status=PKGQuickBuildStateBuilding;
		
		_timer=[NSTimer scheduledTimerWithTimeInterval:1.0/STATUS_FRAME_PER_SEC
												target:self
											  selector:@selector(updateAnimation:)
											  userInfo:nil
											   repeats:YES];
		
		[[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSModalPanelRunLoopMode];
		[[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSEventTrackingRunLoopMode];
	}
	
	return self;
}

#pragma mark -

- (BOOL)isOpaque
{
	return NO;
}

- (void)setStatus:(PKGQuickBuildStatus)inStatus
{
	if (_status==inStatus)
		return;
	
	_image=nil;
	
	if (_status==PKGQuickBuildStateBuilding)
	{
		[_timer invalidate];
		_timer=nil;
	}
	
	_status=inStatus;
	
	switch (_status)
	{
		case PKGQuickBuildStateBuilding:
			
			_timer=[NSTimer scheduledTimerWithTimeInterval:1.0/STATUS_FRAME_PER_SEC
													target:self
												  selector:@selector(updateAnimation:)
												  userInfo:nil
												   repeats:YES];
			
			//[[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSEventTrackingRunLoopMode];
			
			break;
			
		case PKGQuickBuildStateSuccessful:
			
			_image=[PKGQuickBuildStatusView sharedSuccessImage];
			
			break;
			
		case PKGQuickBuildStateFailed:
			
			_image=[PKGQuickBuildStatusView sharedFailureImage];
			
			break;
	}
	
	[self setNeedsDisplay:YES];
}

#pragma mark -

- (void)updateAnimation:(NSTimer *)inAnimation
{
	_angle-=14.0;
	
	if (_angle<-360.0)
		_angle+=360.0;
	
	[self setNeedsDisplay:YES];
}

#define DEG_TO_RAD (2.0*M_PI/360.0)

#define TEETH_COUNT		8

#define TEETH_ARC_LENGTH	35.0

#define CICLE_RADIUS_PERC	(28.0/100.0)

#define TEETH_HEIGHT_PERC	(25.0/100.0)

- (void)drawRect:(NSRect)inRect
{
	NSRect tBounds=self.bounds;
	
	switch(self.status)
	{
		case PKGQuickBuildStateBuilding:
		{
			NSPoint tCenter={
				.x=NSMidX(tBounds),
				.y=NSMidY(tBounds)
			};
			
			
			CGFloat tRadius=NSWidth(tBounds)*0.5;
			CGFloat tHoleLength=(360.0/TEETH_COUNT)-TEETH_ARC_LENGTH;
			CGFloat tAngle=_angle;
			NSPoint tPoint=NSMakePoint(tCenter.x+(1.0-TEETH_HEIGHT_PERC)*tRadius*cosf(tAngle*DEG_TO_RAD),tCenter.y+(1.0-TEETH_HEIGHT_PERC)*tRadius*sinf(tAngle*DEG_TO_RAD));
			
			NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
			
			[tBezierPath moveToPoint:tPoint];
			
			for(NSUInteger i=0;i<TEETH_COUNT;i++)
			{
				tPoint=NSMakePoint(tCenter.x+tRadius*cosf((tAngle+5.0)*DEG_TO_RAD),tCenter.y+tRadius*sinf((tAngle+5.0)*DEG_TO_RAD));
				
				[tBezierPath lineToPoint:tPoint];
				
				[tBezierPath appendBezierPathWithArcWithCenter:tCenter
														radius:tRadius
													startAngle:(tAngle+5.0)
													  endAngle:tAngle+TEETH_ARC_LENGTH-5.0
													 clockwise:NO];
				
				tAngle+=TEETH_ARC_LENGTH;
				
				tPoint=NSMakePoint(tCenter.x+(1.0-TEETH_HEIGHT_PERC)*tRadius*cosf(tAngle*DEG_TO_RAD),tCenter.y+(1.0-TEETH_HEIGHT_PERC)*tRadius*sinf(tAngle*DEG_TO_RAD));
				
				[tBezierPath lineToPoint:tPoint];
				
				[tBezierPath appendBezierPathWithArcWithCenter:tCenter
														radius:(1.0-TEETH_HEIGHT_PERC)*tRadius
													startAngle:tAngle
													  endAngle:tAngle+tHoleLength
													 clockwise:NO];
				
				tAngle+=tHoleLength;
				
			}
			
			[tBezierPath closePath];
			
			[[NSColor colorWithDeviceWhite:0.15 alpha:1.0] set];
			
			[tBezierPath fill];
			
			tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(tCenter.x-CICLE_RADIUS_PERC*tRadius,tCenter.y-CICLE_RADIUS_PERC*tRadius,2*CICLE_RADIUS_PERC*tRadius,2*CICLE_RADIUS_PERC*tRadius) ];
			
			[[NSColor colorWithDeviceWhite:0.45 alpha:1.0] set];
			
			[tBezierPath fill];
			
			break;
		}
			
		case PKGQuickBuildStateSuccessful:
		case PKGQuickBuildStateFailed:
			
			if (_image!=nil)
				[_image drawInRect:tBounds fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
			
			break;
	}
}

@end
