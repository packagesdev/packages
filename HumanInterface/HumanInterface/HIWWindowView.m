/*
 Copyright (c) 2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "HIWWindowView.h"

#ifndef MAC_OS_X_VERSION_10_10
#define MAC_OS_X_VERSION_10_10      101000
#endif

#ifndef NSFoundationVersionNumber10_10
#define NSFoundationVersionNumber10_10 1151.16
#endif

#ifndef NSAppKitVersionNumber10_14
#define NSAppKitVersionNumber10_14 1641
#endif

#define HIWWindowViewShadowOffset	10.0

#define HIWWindowViewTitleBarHeight	20.0

#define HIWWindowViewProxyIconWidth	16.0
#define HIWWindowViewProxyIconHeight 16.0

#define HIWWindowViewProxyIconInterspace 4.0

#define HIWWindowViewRightIconWidth	16.0
#define HIWWindowViewRightIconHeight 16.0

#define HIWWindowViewTitleBarMarginLeft	69.0

#define HIWWindowViewTitleBarMarginRightNoIcon 8.0
#define HIWWindowViewTitleBarMarginRight 35.0

NSString * const HIWWindowViewEffectiveAppearanceDidChangeNotification=@"HIWWindowViewEffectiveAppearanceDidChangeNotification";

HIWOperatingSystemVersion HIWOperatingSystemVersionCurrent=
{
	.majorVersion=-1,
	.minorVersion=-1,
	.patchVersion=-1
};

typedef NS_ENUM(NSUInteger, HIWPartID)
{
	HIWPartBottomLeftCorner=0,
	HIWPartBottomEdge=1,
	HIWPartBottomRight=2,
	HIWPartLeftEdge=3,
	HIWPartCenter=4,
	HIWPartRightEdge=5,
	HIWPartTopLeftCorner=6,
	HIWPartTopEdge=7,
	HIWPartTopRightCorner=8,
};

@interface NSImage (Private)

- (void)_drawMappingAlignmentRectToRect:(NSRect)arg1 withState:(NSUInteger)inState backgroundStyle:(NSBackgroundStyle)inBackgroundStyle operation:(NSCompositingOperation)arg4 fraction:(CGFloat)inFraction flip:(BOOL)inFlipped hints:(NSDictionary *)inHints;

@end

@interface HIWWindowView ()
{
	NSDictionary * _cachedAttributes;
	
	NSImage * _cachedParts[9];
	
	NSImage * _cachedLockButtonIcon;
}

- (void)refreshCache;

@end

@implementation HIWWindowView

- (instancetype)initWithFrame:(NSRect)inFrame
{
	self=[super initWithFrame:inFrame];
	
	if (self!=nil)
	{
		_state=HIWThemeStateEffective;
		_operatingSystemVersion=HIWOperatingSystemVersionCurrent;
		_displayedAppearance=HIWAppearanceEffective;
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)inDecoder
{
	self=[super initWithCoder:inDecoder];
	
	if (self!=nil)
	{
		_state=HIWThemeStateEffective;
		_operatingSystemVersion=HIWOperatingSystemVersionCurrent;
		_displayedAppearance=HIWAppearanceEffective;
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma	mark -

- (void)setTitle:(NSString *)inTitle
{
	if (_title!=inTitle)
	{
		_title=[inTitle copy];
		
		[self setNeedsDisplay:YES];
	}
}

- (void)setProxyIcon:(NSImage *)inProxyIcon
{
	if (_proxyIcon==inProxyIcon)
		return;

	_proxyIcon=inProxyIcon;

	[self setNeedsDisplay:YES];
}

- (void)setDrawsShadow:(BOOL)inDrawsShadow
{
	if (_drawsShadow==inDrawsShadow)
		return;
	
	_drawsShadow=inDrawsShadow;
	
	[self setNeedsDisplay:YES];
}

- (void)setDrawsResizingIndicator:(BOOL)inDrawsResizingIndicator
{
	if (_drawsResizingIndicator==inDrawsResizingIndicator)
		return;
	
	_drawsResizingIndicator=inDrawsResizingIndicator;
	
	[self setNeedsDisplay:YES];
}

- (void)setShowsLockButton:(BOOL)inShowsLockButton
{
	if (_showsLockButton==inShowsLockButton)
		return;
	
	_showsLockButton=inShowsLockButton;
	
	[self setNeedsDisplay:YES];
}

- (void)setState:(HIWThemeDrawState)inState
{
	if (_state==inState)
		return;
	
	_state=inState;
	
	[self refreshCache];
	
	[self setNeedsDisplay:YES];
}

- (void)setOperatingSystemVersion:(HIWOperatingSystemVersion)inOperatingSystemVersion
{
	if (_operatingSystemVersion.majorVersion==inOperatingSystemVersion.majorVersion &&
		_operatingSystemVersion.minorVersion==inOperatingSystemVersion.minorVersion &&
		_operatingSystemVersion.patchVersion==inOperatingSystemVersion.patchVersion)
		return;
	
	_operatingSystemVersion=inOperatingSystemVersion;
	
	[self refreshCache];
	
	[self setNeedsDisplay:YES];
}

- (HIWOperatingSystemVersion)_resolvedOperatingSystemVersion
{
	HIWOperatingSystemVersion tResolvedOperatingSystemVersion=_operatingSystemVersion;
	
	if (tResolvedOperatingSystemVersion.majorVersion==HIWOperatingSystemVersionCurrent.majorVersion &&
		tResolvedOperatingSystemVersion.minorVersion==HIWOperatingSystemVersionCurrent.minorVersion &&
		tResolvedOperatingSystemVersion.patchVersion==HIWOperatingSystemVersionCurrent.patchVersion)
	{
		static dispatch_once_t onceToken;
		static HIWOperatingSystemVersion sSystemVersion;
		dispatch_once(&onceToken, ^{
			
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_10)
			NSOperatingSystemVersion tOperatingSystemVersion=[NSProcessInfo processInfo].operatingSystemVersion;
			
			sSystemVersion.majorVersion=tOperatingSystemVersion.majorVersion;
			sSystemVersion.minorVersion=tOperatingSystemVersion.minorVersion;
			sSystemVersion.patchVersion=tOperatingSystemVersion.patchVersion;
			
#else

#if __MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10
	
			if (NSFoundationVersionNumber>=NSFoundationVersionNumber10_10)
			{
				NSOperatingSystemVersion tOperatingSystemVersion=[NSProcessInfo processInfo].operatingSystemVersion;
				
				sSystemVersion.majorVersion=tOperatingSystemVersion.majorVersion;
				sSystemVersion.minorVersion=tOperatingSystemVersion.minorVersion;
				sSystemVersion.patchVersion=tOperatingSystemVersion.patchVersion;
			}
			else
			{
#endif

				SInt32 tMajorVersion,tMinorVersion,tBugFixVersion;
				
				Gestalt(gestaltSystemVersionMajor,&tMajorVersion);
				Gestalt(gestaltSystemVersionMinor,&tMinorVersion);
				Gestalt(gestaltSystemVersionBugFix,&tBugFixVersion);
				
				sSystemVersion.majorVersion=tMajorVersion;
				sSystemVersion.minorVersion=tMinorVersion;
				sSystemVersion.patchVersion=tBugFixVersion;

#if __MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10
			}
#endif
#endif
		});
		
		tResolvedOperatingSystemVersion=sSystemVersion;
	}
	
	return tResolvedOperatingSystemVersion;
}

- (void)setDisplayedAppearance:(HIWAppearance)inAppearance
{
	if (_displayedAppearance==inAppearance)
		return;
	
	_displayedAppearance=inAppearance;
	
	[self refreshCache];
	
	[self setNeedsDisplay:YES];
}

- (HIWAppearance)_resolvedDisplayedAppearance
{
	HIWAppearance tResolvedDisplayedAppearance=self.displayedAppearance;
	
	if (tResolvedDisplayedAppearance==HIWAppearanceEffective)
	{
        HIWOperatingSystemVersion tOSVersion=[self _resolvedOperatingSystemVersion];
		NSInteger tMinorVersion=tOSVersion.minorVersion;
        
        if (tOSVersion.majorVersion>=11)
            tMinorVersion=16;
		
		if (tMinorVersion<14 || NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
		{
			tResolvedDisplayedAppearance=HIWAppearanceAqua;
		}
		else
		{
			NSString * const HIW_NSAppearanceNameAqua=@"NSAppearanceNameAqua";
			
			NSString * const HIW_NSAppearanceNameDarkAqua=@"NSAppearanceNameDarkAqua";
			
			id tAppearance=self.effectiveAppearance;
			
			NSString * tBestMatch=(NSString *)[tAppearance performSelector:@selector(bestMatchFromAppearancesWithNames:) withObject:@[HIW_NSAppearanceNameAqua,HIW_NSAppearanceNameDarkAqua]];
			
			tResolvedDisplayedAppearance=([tBestMatch isEqualToString:HIW_NSAppearanceNameDarkAqua]==YES) ? HIWAppearanceDarkAqua : HIWAppearanceAqua;
		}
	}
	
	return tResolvedDisplayedAppearance;
}

#pragma mark -

- (void)refreshCache
{
    HIWOperatingSystemVersion tOSVersion=[self _resolvedOperatingSystemVersion];
    NSInteger tMinorVersion=tOSVersion.minorVersion;
    
    if (tOSVersion.majorVersion>=11)
        tMinorVersion=16;
	
	NSString * tOSName=nil;
	
	switch(tMinorVersion)
	{
		case 7:
		case 8:
		case 9:
			
			tOSName=@"Lion";

			break;
		
		case 10:
		case 11:
		case 12:
		case 13:
		case 14:
		default:
			tOSName=@"Mojave";
			
			break;
	}
	
	NSURL * tOSBundleURL=[[NSBundle bundleForClass:[self class]].resourceURL URLByAppendingPathComponent:[tOSName stringByAppendingPathExtension:@"bundle"]];
	
	NSBundle * tOSBundle=[NSBundle bundleWithURL:tOSBundleURL];
	
	HIWAppearance tDisplayedAppearance=[self _resolvedDisplayedAppearance];
	
	NSString * tDisplayedAppearanceName=@"Aqua";
	
	switch (tDisplayedAppearance)
	{
		case HIWAppearanceAqua:
			
			tDisplayedAppearanceName=@"Aqua";
			
			break;
		
		case HIWAppearanceDarkAqua:
			
			tDisplayedAppearanceName=@"DarkAqua";
			
			break;
			
		default:
			
			NSLog(@"Appearance not supported");
			
			break;
	}
	
	HIWThemeDrawState tState=self.state;
	
	if (tState==HIWThemeStateEffective)
		tState=(self.window.isMainWindow==YES) ? HIWThemeStateActive : HIWThemeStateInactive;
	
	for(NSUInteger tIndex=0;tIndex<9;tIndex++)
	{
		_cachedParts[tIndex]=[tOSBundle imageForResource:[NSString stringWithFormat:@"%@.%@.%02d",tDisplayedAppearanceName,(tState==HIWThemeStateActive) ? @"Active":@"Inactive",(int)tIndex]];
	}
	
	// Title Attributes
	
	// Draw Title and Proxy Icon
	
	NSMutableParagraphStyle * tParagraphStyle=[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	
	tParagraphStyle.lineBreakMode=NSLineBreakByTruncatingTail;
	tParagraphStyle.alignment=WBTextAlignmentNatural;
	
	NSFont * tFont=nil;
	
	switch(tMinorVersion)
	{
		case 7:
		case 8:
		case 9:
			
			tFont=[NSFont fontWithName:@"Lucida Grande" size:13.0];
			
			break;
			
		case 10:
			
			tFont=[NSFont fontWithName:@"Helvetica Neue" size:13.0];
			
			break;
			
		case 11:
		case 12:
		case 13:
		case 14:
		default:
			
			tFont=[NSFont fontWithName:@"San Francisco" size:13.0];
			
			break;
	}
	
	if (tFont==nil)
	{
		if ([[NSFont class] respondsToSelector:@selector(titleBarFontOfSize:)]==YES)
			tFont=[NSFont titleBarFontOfSize:13.0];
		
		if (tFont==nil)
			tFont=[NSFont systemFontOfSize:13.0];
	}
	
	NSColor * tTitleColor=nil;
	
	switch(tMinorVersion)
	{
		case 7:
		case 8:
		case 9:
			
			tTitleColor=(tState==HIWThemeStateActive) ? [NSColor colorWithDeviceWhite:0.0 alpha:1.0] : [NSColor colorWithDeviceWhite:0.0 alpha:0.50];
			
			break;
			
		case 10:
		case 11:
		case 12:
		case 13:
		case 14:
		default:
			
			switch(tDisplayedAppearance)
			{
				case HIWAppearanceAqua:
					
					tTitleColor=(tState==HIWThemeStateActive) ? [NSColor colorWithDeviceWhite:0.0 alpha:0.85] : [NSColor colorWithDeviceWhite:0.0 alpha:0.50];
					
					break;
					
				case HIWAppearanceDarkAqua:
					
					tTitleColor=(tState==HIWThemeStateActive) ? [NSColor colorWithDeviceWhite:1.0 alpha:0.85] : [NSColor colorWithDeviceWhite:1.0 alpha:0.50];
					
					break;
					
				default:
					break;
			}
			
			break;
	}
	
	_cachedAttributes=@{NSFontAttributeName:tFont,
						NSParagraphStyleAttributeName:tParagraphStyle,
						NSForegroundColorAttributeName:tTitleColor};
	
	// Lock Button
	
	_cachedLockButtonIcon=[tOSBundle imageForResource:[NSString stringWithFormat:@"%@.LockButton",@"Aqua"]];
}

#pragma mark -

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (newWindow==nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.window];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.window];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidBecomeMainNotification object:newWindow];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidResignMainNotification object:newWindow];
	}
}

- (void)viewDidMoveToWindow
{
	[self refreshCache];
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect tWindowFrame=[self bounds];
	
	HIWAppearance tDisplayedAppearance=[self _resolvedDisplayedAppearance];
	
	// Draw Shadow
	
	if (self.drawsShadow==YES)
	{
		tWindowFrame=NSInsetRect(tWindowFrame, HIWWindowViewShadowOffset, HIWWindowViewShadowOffset);
	
		tWindowFrame.size.height+=8.0;
		
		[NSGraphicsContext saveGraphicsState];
		
		NSShadow * tShadow=[[NSShadow alloc] init];
		
		tShadow.shadowOffset=NSMakeSize(0.0,-3.0);
		tShadow.shadowBlurRadius=12.0;
		
		HIWThemeDrawState tState=self.state;
		
		if (tState==HIWThemeStateEffective)
			tState=(self.window.isMainWindow==YES) ? HIWThemeStateActive : HIWThemeStateInactive;
		
		tShadow.shadowColor=[[NSColor blackColor] colorWithAlphaComponent:(tState==HIWThemeStateActive) ? 0.5 : 0.20];
		
		[tShadow set];
		
		NSRect tBezelFrame=NSInsetRect(tWindowFrame, -1.0, -1.0);
		
		// Title Bar frame
		
		switch(tDisplayedAppearance)
		{
			case HIWAppearanceDarkAqua:
				
				[[NSColor colorWithDeviceWhite:1.0 alpha:(tState==HIWThemeStateActive) ? 0.25 : 0.15] set];
				
				break;
				
			case HIWAppearanceAqua:
			default:
				
				[[NSColor colorWithDeviceWhite:0.0 alpha:0.25] set];
				
				break;
		}
		
		NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
		
		CGFloat tCornerRadius=5.0;
		
		[tBezierPath moveToPoint:NSMakePoint(NSMinX(tBezelFrame)+0.5,NSMaxY(tBezelFrame)-HIWWindowViewTitleBarHeight-2.5)];
		[tBezierPath lineToPoint:NSMakePoint(NSMinX(tBezelFrame)+0.5,NSMaxY(tBezelFrame)-0.5-tCornerRadius)];
		[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(tBezelFrame)+0.5+tCornerRadius,NSMaxY(tBezelFrame)-0.5-tCornerRadius)
												radius:tCornerRadius
											startAngle:180.0
											  endAngle:90.0
											 clockwise:YES];
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBezelFrame)-0.5-tCornerRadius,NSMaxY(tBezelFrame)-0.5)];
		[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(tBezelFrame)-0.5-tCornerRadius,NSMaxY(tBezelFrame)-0.5-tCornerRadius)
												radius:tCornerRadius
											startAngle:90.0
											  endAngle:0.0
											 clockwise:YES];
		
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBezelFrame)-0.5,NSMaxY(tBezelFrame)-HIWWindowViewTitleBarHeight-2.5)];
		[tBezierPath closePath];
		
		[tBezierPath fill];
		
		// Contents frame
		
		switch(tDisplayedAppearance)
		{
			case HIWAppearanceDarkAqua:
				
				[[NSColor colorWithDeviceWhite:0.0 alpha:(tState==HIWThemeStateActive) ? 1.0 : 0.8] set];
				
				break;
				
			case HIWAppearanceAqua:
			default:
				
				[[NSColor windowFrameColor] set];
				
				break;
		}
		
		tBezierPath=[NSBezierPath bezierPath];
		
		[tBezierPath moveToPoint:NSMakePoint(NSMinX(tBezelFrame)+0.5,NSMaxY(tBezelFrame)-HIWWindowViewTitleBarHeight-2.5)];
		[tBezierPath lineToPoint:NSMakePoint(NSMinX(tBezelFrame)+0.5,NSMinY(tBezelFrame)+0.5+tCornerRadius)];
		[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(tBezelFrame)+0.5+tCornerRadius,NSMinY(tBezelFrame)+0.5+tCornerRadius)
												radius:tCornerRadius
											startAngle:180
											  endAngle:270.0];
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBezelFrame)-0.5-tCornerRadius,NSMinY(tBezelFrame)+0.5)];
		[tBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(tBezelFrame)-0.5-tCornerRadius,NSMinY(tBezelFrame)+0.5+tCornerRadius)
												radius:tCornerRadius
											startAngle:270.0
											  endAngle:360.0];
		
		[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBezelFrame)-0.5,NSMaxY(tBezelFrame)-HIWWindowViewTitleBarHeight-2.5)];
		[tBezierPath closePath];
		
		[tBezierPath fill];
		
		if (tDisplayedAppearance==HIWAppearanceDarkAqua)
		{
			[[NSColor colorWithDeviceWhite:1.0 alpha:(tState==HIWThemeStateActive) ? 0.35 : 0.25] set];
			
			[tBezierPath fill];
		}
		
		[NSGraphicsContext restoreGraphicsState];
	}
	
	if (self.operatingSystemVersion.minorVersion==-2)
	{
		NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(tWindowFrame,2.0,2.0) xRadius:5.0 yRadius:5.0];
		
		[[NSColor colorWithDeviceWhite:0.20 alpha:0.5] setFill];
		
		//[tBezierPath fill];
		
		[[NSColor colorWithDeviceWhite:0.4 alpha:0.5] setStroke];
		
		CGFloat tArray[2]={5.0,4.0};
		[tBezierPath setLineDash:tArray count:2 phase:0.5];
		
		[tBezierPath setLineWidth:3.0];
		
		[tBezierPath stroke];
	}
	else
	{
		// Draw Window Frame
	
		NSDrawNinePartImage(tWindowFrame,
							_cachedParts[HIWPartTopLeftCorner],_cachedParts[HIWPartTopEdge], _cachedParts[HIWPartTopRightCorner],
							_cachedParts[HIWPartLeftEdge], _cachedParts[HIWPartCenter], _cachedParts[HIWPartRightEdge],
							_cachedParts[HIWPartBottomLeftCorner], _cachedParts[HIWPartBottomEdge], _cachedParts[HIWPartBottomRight],
                            WBCompositingOperationSourceOver,
							1.0,
							NO);
	}
	
	NSString * tTitle=self.title;
	
	if (tTitle==nil)
		tTitle=@"Window";
	
	NSImage * tIcon=self.proxyIcon;
	//NSImage * tRightIcon=self.rightIcon;
	
	/*NSRect tDebugFrame=NSMakeRect(NSMinX(tBounds)+HIWWindowViewTitleBarMarginLeft, NSMaxY(tBounds)-HIWWindowViewTitleBarHeight, NSWidth(tBounds)-HIWWindowViewTitleBarMarginLeft-PKGPresentationWindowTitleBarMarginRight, HIWWindowViewTitleBarHeight);
	 
	 [[NSColor redColor] set];
	 
	 NSFrameRect(tDebugFrame);*/
	
	/*NSRect tDebugFrame=NSMakeRect(NSMinX(tWindowFrame), NSMaxY(tWindowFrame)-HIWWindowViewTitleBarHeight, HIWWindowViewTitleBarMarginLeft, HIWWindowViewTitleBarHeight);
	
	[[NSColor redColor] set];
	
	NSFrameRect(tDebugFrame);*/
	
	CGFloat tRightMargin=(self.showsLockButton==NO) ? HIWWindowViewTitleBarMarginRightNoIcon : HIWWindowViewTitleBarMarginRight;
	
	CGFloat tAvailableWidth=NSWidth(tWindowFrame)-HIWWindowViewTitleBarMarginLeft-tRightMargin;
	
	NSSize tIdealSize=[tTitle sizeWithAttributes:_cachedAttributes];
	
	if (tIcon!=nil)
		tIdealSize.width+=HIWWindowViewProxyIconInterspace+HIWWindowViewProxyIconWidth;
	
	NSRect tTitleFrame;
	BOOL tTooBig=NO;
	
	//[[NSColor greenColor] set];
	
	tTitleFrame.origin.y=round(NSMaxY(tWindowFrame)-(HIWWindowViewTitleBarHeight+tIdealSize.height)*0.5)-1.0;
	tTitleFrame.size.height=tIdealSize.height;
	
	
	if (tIdealSize.width>tAvailableWidth)
	{
		tTooBig=YES;
		tTitleFrame.size.width=tAvailableWidth;
	}
	else
	{
		tTitleFrame.size.width=tIdealSize.width;
	}
	
	CGFloat tMiddleTitleBar=round(NSMidX(tWindowFrame));
	
	if ((tMiddleTitleBar-tTitleFrame.size.width*0.5)<(NSMinX(tWindowFrame)+HIWWindowViewTitleBarMarginLeft))
	{
		//[[NSColor yellowColor] set];
		
		tMiddleTitleBar=round(NSMinX(tWindowFrame)+HIWWindowViewTitleBarMarginLeft+tTitleFrame.size.width*0.5);
	}
	
	if (tIcon!=nil)
	{
		if (tTooBig==YES)
			tTitleFrame.origin.x=NSMinX(tWindowFrame)+HIWWindowViewTitleBarMarginLeft+HIWWindowViewProxyIconInterspace+HIWWindowViewProxyIconWidth;
		else
			tTitleFrame.origin.x=round(tMiddleTitleBar-tTitleFrame.size.width*0.5)+HIWWindowViewProxyIconInterspace+HIWWindowViewProxyIconWidth;
		
		tTitleFrame.size.width-=HIWWindowViewProxyIconInterspace+HIWWindowViewProxyIconWidth;
	}
	else
	{
		if (tTooBig==YES)
			tTitleFrame.origin.x=NSMinX(tWindowFrame)+HIWWindowViewTitleBarMarginLeft;
		else
			tTitleFrame.origin.x=round(tMiddleTitleBar-tTitleFrame.size.width*0.5);
	}
	
	/*NSFrameRect(tTitleFrame);*/
	
	[tTitle drawInRect:tTitleFrame withAttributes:_cachedAttributes];
	
	if (tIcon!=nil)
	{
		NSRect tIconFrame;
		
		tIconFrame.origin.x=NSMinX(tTitleFrame)-(HIWWindowViewProxyIconInterspace+HIWWindowViewProxyIconWidth);
		tIconFrame.origin.y=round(NSMaxY(tWindowFrame)-(HIWWindowViewTitleBarHeight+HIWWindowViewProxyIconHeight)*0.5)-1.0;
		tIconFrame.size=NSMakeSize(HIWWindowViewProxyIconWidth, HIWWindowViewProxyIconHeight);
		
		[tIcon drawInRect:tIconFrame fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:(self.window.isMainWindow==YES) ? 1.0 : 0.5];
	}
	
	// Draw Locks Button
	
	if (self.showsLockButton==YES)
	{
		NSSize tSize=_cachedLockButtonIcon.size;
		NSRect tIconFrame;
		
		tIconFrame.origin.x=NSMaxX(tWindowFrame)-(HIWWindowViewTitleBarMarginRightNoIcon+tSize.width-1);
		tIconFrame.origin.y=round(NSMaxY(tWindowFrame)-(HIWWindowViewTitleBarHeight+tSize.height)*0.5);
		tIconFrame.size=tSize;
		
		if (tDisplayedAppearance==HIWAppearanceDarkAqua && [_cachedLockButtonIcon respondsToSelector:@selector(_drawMappingAlignmentRectToRect:withState:backgroundStyle:operation:fraction:flip:hints:)]==YES)
		{
			BOOL isTemplate=[_cachedLockButtonIcon isTemplate];
			
			[_cachedLockButtonIcon setTemplate:YES];
			
			[_cachedLockButtonIcon _drawMappingAlignmentRectToRect:tIconFrame
														 withState:1
												   backgroundStyle:7
														 operation:WBCompositingOperationSourceOver
														  fraction:(self.window.isMainWindow==YES) ? 0.5 : 0.3
															  flip:NO hints:nil];
			
			[_cachedLockButtonIcon setTemplate:isTemplate];
		}
		else
		{
			[_cachedLockButtonIcon drawInRect:tIconFrame fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:(self.window.isMainWindow==YES) ? 0.5 : 0.3];
		}
	}
}

#pragma mark -

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	[self refreshCache];
	
	[self setNeedsDisplay:YES];
}

- (void)viewDidChangeEffectiveAppearance
{
	[self refreshCache];
	
	// A COMPLETER
	
	[[NSNotificationCenter defaultCenter] postNotificationName:HIWWindowViewEffectiveAppearanceDidChangeNotification object:self];
}

@end
