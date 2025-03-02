/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPresentationListView.h"

#import "PKGInstallerApp.h"

#import "PKGPresentationTheme.h"

#import "PKGDocument.h"

#define PKGPresentationListViewMoreRowHeight	20.0

#define PKGPresentationListViewDefaultRowHeight	24.0

#define ICPRESENTATIONLISTVIEW_ROW_X_OFFSET	5.0


#define PKGPresentationListViewTopButtonIndex		-2
#define PKGPresentationListViewBottomButtonIndex	-1

#define PKGPresentationListViewBulletRadius	4.0

typedef NS_ENUM(NSUInteger, PKGPresentationListViewMouseMode)
{
	PKGPresentationListViewMouseModeClickNone,
	PKGPresentationListViewMouseModeClickTop,
	PKGPresentationListViewMouseModeClickBottom,
	PKGPresentationListViewMouseModeClick,
	PKGPresentationListViewMouseModeDrag
};

NSString * PKGPresentationListViewSelectionDidChangeNotification=@"PKGPresentationListViewSelectionDidChangeNotification";

//#define LIST_DEBUG_VIEW 1

@interface PKGPresentationListView () <NSDraggingSource>
{
	// Theme
	
	PKGPresentationThemeVersion _themeVersion;
	
	BOOL _supportThemeYosemite;
	
	NSInteger _firstVisibleStep;
	
	NSInteger _lastVisibleStep;
	
	BOOL _shouldSeeSelectedStep;
	
	// Tracking
	
	BOOL _mouseTrackInside;
	
	NSTrackingRectTag _trackingTag;
	NSRect _trackingRect;
	
	// Mouse Down
	
	BOOL _topPushed;
	BOOL _bottomPushed;
	BOOL _mouseSelectedStepPushed;
	
	NSInteger _mouseSelectedStep;
	
	NSPoint _originalMouseDownPointLocation;
	
	// Mouse Mode
	
	PKGPresentationListViewMouseMode _mouseMode;
	
	NSImage * _unselectedPaneImage;
    NSImage * _unProcessedPaneImage;
    NSImage * _selectedPaneImage;
	
	
	
	// Drag & Drop
	
	BOOL _dragInProgress;
	
	NSInteger _currentDropStep;
	
	NSInteger _oldDropStep;
	
	NSRect _oldDroppingRect;
	
	NSDragOperation _currentDragOperation;
}

	@property (readwrite) NSInteger selectedStep;

+ (NSCursor *)sharedUnselectableCursor;

+ (CGFloat)labelFrameOriginX;

- (CGFloat)heightOfString:(NSString *)inString forFont:(NSFont *)inFont andMaxWidth:(CGFloat)inMaxWidth;

- (NSRect)frameForStep:(NSInteger)inStep;

- (NSInteger)indexOfStepAtPoint:(NSPoint)inPoint;

- (NSImage *)imageOfStep:(NSInteger)inStep;

// Notifications

- (void)presentationThemeDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationListView

+ (NSCursor *)sharedUnselectableCursor
{
	static NSCursor * sUnselectableCursor=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sUnselectableCursor=[[NSCursor alloc] initWithImage:[NSImage imageNamed:@"unselectableCursor"] hotSpot:NSMakePoint(5.0,5.0)]; 
	});
	
	return sUnselectableCursor;
}

+ (CGFloat)labelFrameOriginX
{
    static CGFloat sLabelOriginX=0.0;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
        sLabelOriginX=ICPRESENTATIONLISTVIEW_ROW_X_OFFSET;
		
		PKGInstallerApp * tInstallerApp=[PKGInstallerApp installerApp];
		
        if ([tInstallerApp isVersion6_1OrLater]==NO)
        {
            NSSize tBulletSize=tInstallerApp.currentStepDot.size;
         
            sLabelOriginX+=tBulletSize.width+4.0;
        }
        else
        {
            sLabelOriginX+=2.0*PKGPresentationListViewBulletRadius+8.0;
        }
        
	});
	
	return sLabelOriginX;
}

#pragma mark -

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
	
    if (self!=nil)
	{
		_trackingRect=NSZeroRect;
	
		if (NSAppKitVersionNumber>=NSAppKitVersionNumber10_14)
		{
			_supportThemeYosemite=NO;
			
			NSNumber * tNumber=((PKGDocument *)((NSWindowController *)self.window.windowController).document).registry[PKGPresentationTheme];
			
			if (tNumber==nil)
			{
				_themeVersion=PKGPresentationThemeMojaveDynamic;
			}
			else
			{
				_themeVersion=[tNumber unsignedIntegerValue];
			}
		}
		else
		{
			_themeVersion=[((PKGDocument *)((NSWindowController *)self.window.windowController).document).registry[PKGPresentationTheme] unsignedIntegerValue];
			
			PKGInstallerApp * tInstallerApp=[PKGInstallerApp installerApp];
		
			if ([tInstallerApp isVersion6_1OrLater]==NO)
			{
				_supportThemeYosemite=YES;
				
				_unselectedPaneImage=tInstallerApp.anteriorStepDot;
				
				_selectedPaneImage=tInstallerApp.currentStepDot;
			
				_unProcessedPaneImage=tInstallerApp.posteriorStepDot;
			}
			else
			{
				_supportThemeYosemite=NO;
				
				if (_themeVersion==PKGPresentationThemeMountainLion)
					_themeVersion=PKGPresentationThemeMojaveDynamic;
			}
		}
		
		_currentDropStep=-1;
		
		_oldDropStep = -1;

		_oldDroppingRect = NSZeroRect;

		_currentDragOperation = NSDragOperationEvery;
    }
	
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)viewWillMoveToWindow:(NSWindow *) inWindow
{
	if (inWindow==nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		
		if (_trackingTag!=0)
		{
			[self removeTrackingRect:_trackingTag];
		
			_trackingRect=NSZeroRect;
		}
		
		return;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentationThemeDidChange:) name:PKGPresentationThemeDidChangeNotification object:inWindow];

}

- (CGFloat)heightOfStep:(NSInteger)inStep
{
    if (inStep==PKGPresentationListViewTopButtonIndex ||
        inStep==PKGPresentationListViewBottomButtonIndex)
        
        return PKGPresentationListViewMoreRowHeight;
    
    if (self.dataSource==nil)
        return PKGPresentationListViewDefaultRowHeight+1.0;
    
    NSFont * tFont;
    
    if ((inStep<self.selectedStep && _themeVersion==PKGPresentationThemeMountainLion) ||
        inStep==self.selectedStep)
        tFont=[NSFont boldSystemFontOfSize:13.0];
    else
        tFont=[NSFont systemFontOfSize:13.0];
    
    NSString * tStepTitle=[self.dataSource presentationListView:self objectForStep:inStep];
	
    CGFloat tStepHeight=[self heightOfString:tStepTitle forFont:tFont andMaxWidth:NSMaxX(self.bounds)-[PKGPresentationListView labelFrameOriginX]];
    
    return (tStepHeight==PKGPresentationListViewDefaultRowHeight) ? PKGPresentationListViewDefaultRowHeight+1.0 : tStepHeight+11.0;
}

- (NSRect)frameForStep:(NSInteger) inStep
{
	if (inStep<_firstVisibleStep || inStep>_lastVisibleStep)
		return NSZeroRect;
	
	if (self.dataSource==nil)
		return NSZeroRect;
	
	NSInteger tNumberOfSteps=[self.dataSource numberOfStepsInPresentationListView:self];
	
	if (tNumberOfSteps==0)
		return NSZeroRect;

	// Compute the number of steps that can be displayed
	
	NSRect tBounds=self.bounds;
	
	NSRect tFrame=tBounds;
	
	tFrame.origin.y=NSMaxY(tBounds)-PKGPresentationListViewMoreRowHeight;
	
	for(NSInteger tIndex=_firstVisibleStep;tIndex<=_lastVisibleStep;tIndex++)
	{
		CGFloat tHeight=[self heightOfStep:tIndex];
        
		tFrame.origin.y-=tHeight;
        tFrame.size.height=tHeight;
		
		NSRect tClickableFrame=tFrame;
		
		tClickableFrame.origin.y+=2.0;
		
		if (tIndex==inStep)
			return tClickableFrame;
	}
	
	return NSZeroRect;
}

- (NSInteger)indexOfStepAtPoint:(NSPoint)inPoint
{
	if (self.dataSource==nil)
		return NSNotFound;
	
	NSInteger tNumberOfSteps=[self.dataSource numberOfStepsInPresentationListView:self];
	
	if (tNumberOfSteps==0)
		return NSNotFound;
	
	NSInteger tStepIndex=NSNotFound;
	
	NSRect tBounds=self.bounds;
	NSRect tFrame=tBounds;
	
    // Top Button ?
    
	tFrame.origin.y=NSMaxY(tBounds)-PKGPresentationListViewMoreRowHeight;
    tFrame.size.height=PKGPresentationListViewMoreRowHeight;
	
	if (_firstVisibleStep>0)
	{
		if (NSMouseInRect(inPoint,tFrame,YES)==YES)
			return PKGPresentationListViewTopButtonIndex;
	}
	
	for(NSInteger tIndex=_firstVisibleStep;tIndex<=_lastVisibleStep;tIndex++)
	{
		CGFloat tHeight=[self heightOfStep:tIndex];
		
		tFrame.origin.y-=tHeight;
        tFrame.size.height=tHeight;
		
		NSRect tClickableFrame=tFrame;
		
		tClickableFrame.origin.y+=2.0;
		
		if (NSMouseInRect(inPoint,tClickableFrame,YES)==YES)
			return tIndex;
	}
	
    // Bottom Button ?
    
	if (_lastVisibleStep<(tNumberOfSteps-1))
	{
		tFrame.origin.y=0;
        tFrame.size.height=PKGPresentationListViewMoreRowHeight;
	
		if (NSMouseInRect(inPoint,tFrame,YES)==YES)
			return PKGPresentationListViewBottomButtonIndex;
	}
	
	return tStepIndex;
}

#pragma mark -

- (void)selectStep:(NSInteger)inStep
{
	if (self.selectedStep!=inStep)
	{
		self.selectedStep=inStep;
		
		_shouldSeeSelectedStep=YES;
		
		[self setNeedsDisplay:YES];
	}
}

- (void)reloadData
{
	[self.window invalidateCursorRectsForView:self];
	
	[self _refreshVisibleSteps];
	
	[self setNeedsDisplay:YES];
}

#pragma mark -

- (NSImage *)imageOfStep:(NSInteger)inStep
{
	if (self.dataSource==nil)
		return nil;

	CGFloat tHeight=[self heightOfStep:inStep];
    
	NSRect tBounds=self.bounds;
    
	NSImage * tImage=[NSImage imageWithSize:NSMakeSize(NSWidth(tBounds)-ICPRESENTATIONLISTVIEW_ROW_X_OFFSET,tHeight)
									flipped:NO
							 drawingHandler:^BOOL(NSRect bRect){
								 
                                 CGFloat tTextOriginX=[PKGPresentationListView labelFrameOriginX];
                                 CGFloat tTextMaxWidth=NSWidth(tBounds)-tTextOriginX;
                                 
								 PKGPresentationThemeVersion tPresentationTheme=_themeVersion;
								 
								 if (tPresentationTheme==PKGPresentationThemeMojaveDynamic)
								 {
									 if ([self WB_isEffectiveAppearanceDarkAqua]==NO)
										 tPresentationTheme=PKGPresentationThemeMojaveLight;
									 else
										 tPresentationTheme=PKGPresentationThemeMojaveDark;
								 }
								 
								 // Draw the bullet
                                 
                                 if (_themeVersion==PKGPresentationThemeMountainLion)
								 {
                                    NSImage * tBulletImage=((inStep==self.selectedStep) ? _selectedPaneImage : ((inStep < self.selectedStep) ? _unselectedPaneImage : _unProcessedPaneImage));
								  
                                    NSSize tBulletSize=[tBulletImage size];
								  
                                    [tBulletImage drawAtPoint:NSMakePoint(ICPRESENTATIONLISTVIEW_ROW_X_OFFSET,tHeight-(PKGPresentationListViewDefaultRowHeight+tBulletSize.height)*0.5) fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
								 }
								 else
								 {
									 NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(ICPRESENTATIONLISTVIEW_ROW_X_OFFSET,tHeight-(PKGPresentationListViewDefaultRowHeight+2.0*PKGPresentationListViewBulletRadius)*0.5,2.0*PKGPresentationListViewBulletRadius,2.0*PKGPresentationListViewBulletRadius)];
									 
									 if (inStep==self.selectedStep)
									 {
										 [[NSColor systemBlueColor] setFill];
									 }
									 else
									 {
										 if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
										 {
											 if (inStep < self.selectedStep)
												 [[NSColor colorWithDeviceWhite:0.65 alpha:1.0] setFill];
											 else
												 [[NSColor colorWithDeviceWhite:0.85 alpha:1.0] setFill];

										 }
										 else
										 {
											 if (inStep < self.selectedStep)
												 [[NSColor quaternaryLabelColor] setFill];
											 else
												[[NSColor tertiaryLabelColor] setFill];
										 }
									 }
									 
									 [tBezierPath fill];
								 }
								 
								 // Draw the text
								 
                                 NSString * tStepTitle=[self.dataSource presentationListView:self objectForStep:inStep];
                                 
								 if (tStepTitle.length>0)
								 {
									 NSFont * tFont;
                                     
                                     if ((inStep<self.selectedStep && _themeVersion==PKGPresentationThemeMountainLion) ||
                                         inStep==self.selectedStep)
                                         tFont=[NSFont boldSystemFontOfSize:13.0];
                                     else
                                         tFont=[NSFont systemFontOfSize:13.0];
                                     
									 NSColor * tColor=nil;
									 
									 if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
									 {
										 tColor= (inStep >self.selectedStep) ? [NSColor grayColor] : [NSColor blackColor];
									 }
									 else
									 {
										 tColor= (inStep >self.selectedStep) ? [NSColor tertiaryLabelColor] : [NSColor labelColor];
									 }
									 
									 
									 
									 NSDictionary * tFontAttributes=@{NSFontAttributeName:tFont,
																	  NSForegroundColorAttributeName:tColor};
									 
									 CGFloat tTextVerticallOffset=(_themeVersion==PKGPresentationThemeMountainLion) ? 1.0 : 2.0;
									 
									 NSRect tTextFrame=NSMakeRect(tTextOriginX,-tTextVerticallOffset,tTextMaxWidth,tHeight);
									 
									 [tStepTitle drawInRect:tTextFrame withAttributes:tFontAttributes];
								 }
								 
								 return YES;
							 }];
	
	return tImage;
}

- (CGFloat)heightOfString:(NSString *)inString forFont:(NSFont *)inFont andMaxWidth:(CGFloat)inMaxWidth
{
	if (inString==nil)
		return PKGPresentationListViewDefaultRowHeight;

	NSTextContainer * tTextContainer= [[NSTextContainer alloc] initWithContainerSize: NSMakeSize(inMaxWidth, FLT_MAX)];
	
	tTextContainer.lineFragmentPadding=0.0;
	
	NSLayoutManager * tLayoutManager = [NSLayoutManager new];
		
	tLayoutManager.typesetterBehavior=NSTypesetterBehavior_10_2_WithCompatibility;
	
	[tLayoutManager addTextContainer:tTextContainer];
	
	NSTextStorage * tTextStorage=[[NSTextStorage alloc] initWithString:inString];
	
	[tTextStorage addLayoutManager:tLayoutManager];

	[tTextStorage addAttribute:NSFontAttributeName value:inFont range:NSMakeRange(0, tTextStorage.length)];

	[tLayoutManager glyphRangeForTextContainer:tTextContainer];
	
	CGFloat tHeight=NSHeight([tLayoutManager usedRectForTextContainer:tTextContainer]);

	if (tHeight<PKGPresentationListViewDefaultRowHeight)
	{
		// Min Value
	
		return PKGPresentationListViewDefaultRowHeight;
	}
	
	return tHeight;
}

- (void)_refreshVisibleSteps
{
	NSRect tBounds=self.bounds;
	
	if (self.dataSource==nil)
		return;
	
	NSInteger tNumberOfSteps=[self.dataSource numberOfStepsInPresentationListView:self];
	
	if (tNumberOfSteps==0)
		return;
	
	// Compute the number of steps that can be displayed
	
	NSInteger tMinStepIndex;
	NSInteger tMaxStepIndex;
	CGFloat tHeight;
	NSString * tStepTitle;
	NSInteger tIndex;
#ifdef LIST_DEBUG_VIEW
	NSRect tSavedFrame;
#endif
	
	CGFloat tTextOriginX=[PKGPresentationListView labelFrameOriginX];
	
	CGFloat tTextMaxWidth=NSMaxX(tBounds)-tTextOriginX;
	
	CGFloat tMaxHeight=NSHeight(tBounds)-2*PKGPresentationListViewMoreRowHeight;
	
	if (self.selectedStep<0 || self.selectedStep>=tNumberOfSteps)
		self.selectedStep=0;
	
	if (_shouldSeeSelectedStep==YES)
	{
		NSFont * tFont=[NSFont boldSystemFontOfSize:13.0];
		
		tMinStepIndex=tMaxStepIndex=self.selectedStep;
		
		tStepTitle=[self.dataSource presentationListView:self objectForStep:self.selectedStep];
		
		tHeight=[self heightOfString:tStepTitle forFont:tFont andMaxWidth:tTextMaxWidth];
		
		if (tHeight==PKGPresentationListViewDefaultRowHeight)
			tHeight++;
		else
			tHeight+=11.0;
		
		_shouldSeeSelectedStep=NO;
		
		if (_firstVisibleStep>self.selectedStep)
		{
			tFont=[NSFont systemFontOfSize:13.0];
			
			tIndex=self.selectedStep+1;
			
			while (tIndex<tNumberOfSteps && tHeight<tMaxHeight)
			{
				tStepTitle=[self.dataSource presentationListView:self objectForStep:tIndex];
				
				CGFloat tStepHeight=[self heightOfString:tStepTitle forFont:tFont andMaxWidth:tTextMaxWidth];
				
				if (tStepHeight==PKGPresentationListViewDefaultRowHeight)
					tStepHeight++;
				else
					tStepHeight+=11.0;
				
				if ((tStepHeight+tHeight)>tMaxHeight)
					break;
				
				tHeight+=tStepHeight;
				
				tMaxStepIndex=tIndex;
				
				tIndex++;
			}
		}
		else
		{
			tIndex=self.selectedStep-1;
			
			while (tIndex>=_firstVisibleStep && tHeight<tMaxHeight)
			{
				tStepTitle=[self.dataSource presentationListView:self objectForStep:tIndex];
				
				CGFloat tStepHeight=[self heightOfString:tStepTitle forFont:tFont andMaxWidth:tTextMaxWidth];
				
				if (tStepHeight==PKGPresentationListViewDefaultRowHeight)
					tStepHeight++;
				else
					tStepHeight+=11.0;
				
				if ((tStepHeight+tHeight)>tMaxHeight)
					break;
				
				tHeight+=tStepHeight;
				
				tMinStepIndex=tIndex;
				
				tIndex--;
			}
			
			if (tHeight<tMaxHeight)
			{
				tFont=[NSFont systemFontOfSize:13.0];
				
				tIndex=self.selectedStep+1;
				
				while (tIndex<tNumberOfSteps && tHeight<tMaxHeight)
				{
					tStepTitle=[self.dataSource presentationListView:self objectForStep:tIndex];
					
					CGFloat tStepHeight=[self heightOfString:tStepTitle forFont:tFont andMaxWidth:tTextMaxWidth];
					
					if (tStepHeight==PKGPresentationListViewDefaultRowHeight)
						tStepHeight++;
					else
						tStepHeight+=11.0;
					
					if ((tStepHeight+tHeight)>tMaxHeight)
						break;
					
					tHeight+=tStepHeight;
					
					tMaxStepIndex=tIndex;
					
					tIndex++;
				}
			}
			
		}
		
		_firstVisibleStep=tMinStepIndex;
		
		_lastVisibleStep=tMaxStepIndex;
	}
	else
	{
		NSFont * tFont=nil;
		
		tIndex=_firstVisibleStep;
		
		tMinStepIndex=tMaxStepIndex=_firstVisibleStep;
		
		tHeight=0;
		
		while (tIndex<tNumberOfSteps && tHeight<tMaxHeight)
		{
			tStepTitle=[self.dataSource presentationListView:self objectForStep:tIndex];
			
			if ((tIndex<self.selectedStep && _themeVersion==PKGPresentationThemeMountainLion) ||
				tIndex==self.selectedStep)
				tFont=[NSFont boldSystemFontOfSize:13.0];
			else
				tFont=[NSFont systemFontOfSize:13.0];
			
			CGFloat tStepHeight=[self heightOfString:tStepTitle forFont:tFont andMaxWidth:tTextMaxWidth];
			
			if (tStepHeight==PKGPresentationListViewDefaultRowHeight)
				tStepHeight++;
			else
				tStepHeight+=11.0;
			
			if ((tStepHeight+tHeight)>tMaxHeight)
				break;
			
			tHeight+=tStepHeight;
			
			tMaxStepIndex=tIndex;
			
			tIndex++;
		}
		
		if (tIndex==tNumberOfSteps && tHeight<tMaxHeight)
		{
			tIndex=_firstVisibleStep-1;
			
			while (tIndex>=0 && tHeight<tMaxHeight)
			{
				tStepTitle=[self.dataSource presentationListView:self objectForStep:tIndex];
				
				CGFloat tStepHeight=[self heightOfString:tStepTitle forFont:tFont andMaxWidth:tTextMaxWidth];
				
				if (tStepHeight==PKGPresentationListViewDefaultRowHeight)
					tStepHeight++;
				else
					tStepHeight+=11.0;
				
				if ((tStepHeight+tHeight)>tMaxHeight)
					break;
				
				tHeight+=tStepHeight;
				
				tMinStepIndex=tIndex;
				
				tIndex--;
			}
		}
		
		_firstVisibleStep=tMinStepIndex;
		
		_lastVisibleStep=tMaxStepIndex;
	}
}

- (void)drawRect:(NSRect)inRect
{
	NSRect tBounds=self.bounds;
	
	if (_dragInProgress==NO)
	{
		if (NSEqualRects(tBounds,_trackingRect)==NO)
		{
			if (_trackingTag!=0)
				[self removeTrackingRect:_trackingTag];
			
			_trackingRect=tBounds;
			
			_trackingTag=[self addTrackingRect:tBounds owner:self userData:NULL assumeInside:NO];
		}
	}
	
	if (self.dataSource==nil)
		return;

	NSInteger tNumberOfSteps=[self.dataSource numberOfStepsInPresentationListView:self];
	
	if (tNumberOfSteps==0)
		return;
	
    BOOL tIsDarkMode=[self WB_isEffectiveAppearanceDarkAqua];
	
    /*PKGPresentationThemeVersion tPresentationTheme=_themeVersion;
	
	if (tPresentationTheme==PKGPresentationThemeMojaveDynamic)
	{
		if ([self WB_isEffectiveAppearanceDarkAqua]==NO)
			tPresentationTheme=PKGPresentationThemeMojaveLight;
		else
			tPresentationTheme=PKGPresentationThemeMojaveDark;
	}*/
	
	// Compute the number of steps that can be displayed
	
	
#ifdef LIST_DEBUG_VIEW
	NSRect tSavedFrame;
#endif
	
	
	NSSize tBulletSize;
	NSImage * tBulletImage;
	
	CGFloat tTextOriginX=[PKGPresentationListView labelFrameOriginX];
	
	NSGraphicsContext * tGraphicContext = [NSGraphicsContext currentContext];
	
	[NSGraphicsContext saveGraphicsState];
	
	if (_themeVersion==PKGPresentationThemeMountainLion)
	{
		tBulletImage=_selectedPaneImage;
		
		tBulletSize=tBulletImage.size;
	}
	else
	{
		tBulletImage=nil;
		tBulletSize=NSMakeSize(2.0*PKGPresentationListViewBulletRadius,2.0*PKGPresentationListViewBulletRadius);
	}
	
	[tGraphicContext setPatternPhase:NSMakePoint(0.0,NSMaxY(self.frame))];
	
	
	
	CGFloat tTextMaxWidth=NSMaxX(tBounds)-tTextOriginX;
	
	[self _refreshVisibleSteps];

#define PKGPresentationListViewEllipsisDotDiameter	4.0
#define PKGPresentationListViewEllipsisDotOffset	10.0
    
	void (^drawEllipsisInRect)(NSRect)=^(NSRect bRect)
    {
        CGFloat tX=round(NSMidX(bRect)-PKGPresentationListViewEllipsisDotDiameter*0.5);
        
        CGFloat tY=round(NSMidY(bRect)-PKGPresentationListViewEllipsisDotDiameter*0.5);
        
        if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
			[[NSColor grayColor] setFill];
        else
			[[NSColor tertiaryLabelColor] setFill];
		
        NSRect tEllipsisFrame=NSMakeRect(tX,tY,PKGPresentationListViewEllipsisDotDiameter,PKGPresentationListViewEllipsisDotDiameter);
        
        [[NSBezierPath bezierPathWithOvalInRect:tEllipsisFrame] fill];
        
        tEllipsisFrame.origin.x=tX-PKGPresentationListViewEllipsisDotOffset;
        
        [[NSBezierPath bezierPathWithOvalInRect:tEllipsisFrame] fill];
        
        tEllipsisFrame.origin.x=tX+PKGPresentationListViewEllipsisDotOffset;
        
        [[NSBezierPath bezierPathWithOvalInRect:tEllipsisFrame] fill];
    };
    
#define PKGPresentationListViewDropLineCircleRadius		3.0
#define PKGPresentationListViewDropLinePaddingX	2.0
    
    void (^drawDropLine)(NSRect) = ^(NSRect bRect)
    {
        [NSColor.selectedContentBackgroundColor set];
        
        NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(PKGPresentationListViewDropLinePaddingX,NSMinY(bRect)-1.0,PKGPresentationListViewDropLineCircleRadius*2.0,PKGPresentationListViewDropLineCircleRadius*2.0)];
        
        tBezierPath.lineWidth=1.5;
		
        
        [tBezierPath stroke];
        
        tBezierPath=[NSBezierPath bezierPath];
        
        tBezierPath.lineWidth=2.0;
        
        [tBezierPath moveToPoint:NSMakePoint(PKGPresentationListViewDropLineCircleRadius*2.0+PKGPresentationListViewDropLinePaddingX,NSMinY(bRect)+PKGPresentationListViewDropLineCircleRadius-1.0)];
        [tBezierPath lineToPoint:NSMakePoint(NSWidth(tBounds),NSMinY(bRect)+PKGPresentationListViewDropLineCircleRadius-1.0)];
        
        [tBezierPath stroke];
    };
    
	
	
	NSRect tFrame=tBounds;
	
	tFrame.origin.x+=ICPRESENTATIONLISTVIEW_ROW_X_OFFSET;
	tFrame.origin.y=NSMaxY(tBounds)-PKGPresentationListViewMoreRowHeight;
	tFrame.size.height=PKGPresentationListViewMoreRowHeight;
	
	NSBezierPath * tBezierPath;
	
	// Draw the top more (Debug)
    
	if (_firstVisibleStep>0)
	{
		if (_mouseTrackInside==NO && _topPushed==NO)
		{
			drawEllipsisInRect(tFrame);
		}
		else
		{
			CGFloat tMiddleX=round(NSMidX(tFrame));
            CGFloat tMiddleY=round(NSMidY(tFrame));
            
			if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
			{
				if (_topPushed==YES)
					[[NSColor darkGrayColor] setFill];
				else
					[[NSColor grayColor] setFill];
			}
			else
			{
				if (_topPushed==YES)
					[[NSColor labelColor] setFill];
				else
					[[NSColor tertiaryLabelColor] setFill];
			}
			
			tBezierPath=[NSBezierPath bezierPath];
			
			[tBezierPath moveToPoint:NSMakePoint(tMiddleX-6.0,tMiddleY-2.0)];
			[tBezierPath lineToPoint:NSMakePoint(tMiddleX,tMiddleY+3.0)];
			[tBezierPath lineToPoint:NSMakePoint(tMiddleX+6.0,tMiddleY-2.0)];
			[tBezierPath closePath];
			
			[tBezierPath fill];
		}
	}
	
#ifdef LIST_DEBUG_VIEW
	tSavedFrame=tFrame;
#endif

	NSInteger tIndex;
	
	for(tIndex=_firstVisibleStep;tIndex<=_lastVisibleStep;tIndex++)
	{
		if (_currentDropStep!=-1 && _currentDropStep==tIndex)
            drawDropLine(tFrame);
		
		NSFont * tFont;
		
		if ((tIndex<self.selectedStep && _themeVersion==PKGPresentationThemeMountainLion) ||
			tIndex==self.selectedStep)
			tFont=[NSFont boldSystemFontOfSize:13.0];
		else
			tFont=[NSFont systemFontOfSize:13.0];
		
		NSString * tStepTitle=[self.dataSource presentationListView:self objectForStep:tIndex];
	
		CGFloat tStepHeight=[self heightOfString:tStepTitle forFont:tFont andMaxWidth:tTextMaxWidth];
			
		if (tIndex==_mouseSelectedStep && _mouseSelectedStepPushed==YES)
		{
			CGFloat tBakckgroundHeight=(tStepHeight==PKGPresentationListViewDefaultRowHeight) ? PKGPresentationListViewDefaultRowHeight+1.0 : tStepHeight+11.0;
			
			NSRect tBackgroundFrame=NSMakeRect(1.0,NSMinY(tFrame)-tBakckgroundHeight+1.0,NSWidth(tBounds)-2.0,tBakckgroundHeight);
			
			tBezierPath=[NSBezierPath bezierPathWithRoundedRect:tBackgroundFrame xRadius:5.0 yRadius:5.0];
			
			if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
				[[NSColor colorWithDeviceWhite:0.0 alpha:0.75] setFill];
			else
				[[NSColor labelColor] setFill];
			
			[tBezierPath fill];

			if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
				[[NSColor colorWithDeviceWhite:0.0 alpha:0.85] set];
			else
				[[NSColor colorWithDeviceWhite:1.0 alpha:0.9] set];		// A VOIR
			
			tBezierPath.lineWidth=2.0;
			
			[tBezierPath stroke];
		}
		else if (tIndex==self.selectedStep && _mouseSelectedStepPushed==NO)
		{
			CGFloat tBakckgroundHeight=(tStepHeight==PKGPresentationListViewDefaultRowHeight) ? PKGPresentationListViewDefaultRowHeight+1.0 : tStepHeight+11.0;
			
			NSRect tBackgroundFrame=NSMakeRect(1.0,NSMinY(tFrame)-tBakckgroundHeight+1.0,NSWidth(tBounds)-2.0,tBakckgroundHeight);
			
			tBezierPath=[NSBezierPath bezierPathWithRoundedRect:tBackgroundFrame xRadius:5.0 yRadius:5.0];

			if (tIsDarkMode==NO)
            {
				[[NSColor colorWithDeviceWhite:0.0 alpha:0.025] setFill];
                [[NSColor colorWithDeviceWhite:0.0 alpha:0.05] setStroke];
            }
            else
            {
                [[NSColor colorWithDeviceWhite:1.0 alpha:0.035] setFill];
                [[NSColor colorWithDeviceWhite:1.0 alpha:0.045] setStroke];
            }
            
			[tBezierPath fill];
			[tBezierPath stroke];
		}
		
		BOOL tWillBeVisible=YES;
		
		if ([self.delegate respondsToSelector:@selector(presentationListView:stepWillBeVisible:)]==YES)
			tWillBeVisible=[self.delegate presentationListView:self stepWillBeVisible:tIndex];
		
		// Draw the bullet
		
		if (tIndex!=_mouseSelectedStep || _mouseSelectedStepPushed==NO)
		{
			if (NSAppKitVersionNumber<NSAppKitVersionNumber10_10)
			{
				NSImage * tBulletProcessedImage=((tIndex==self.selectedStep) ? _selectedPaneImage : ((tIndex < self.selectedStep) ? _unselectedPaneImage : _unProcessedPaneImage));
			
				if (tWillBeVisible==NO)
				{
					tBulletProcessedImage=[NSImage imageWithSize:tBulletProcessedImage.size flipped:NO drawingHandler:^BOOL(NSRect bRect){
                    
                        NSRect tCircleRect=NSInsetRect(bRect,1,1);
                        tCircleRect.origin.y+=0.5;
                        
                        NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:tCircleRect];
                        
                        [[NSGraphicsContext currentContext] saveGraphicsState];
                        
                        [tBezierPath addClip];
                        
                        NSImage * tImage=[NSImage imageNamed:@"Strip32Composite"];
                        [tImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
             
                        [[NSGraphicsContext currentContext] restoreGraphicsState];
                        
                        [tBulletProcessedImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:WBCompositingOperationSourceIn fraction:1.0];
						
						return YES;
                    }];
				}
				
				[tBulletProcessedImage drawAtPoint:NSMakePoint(ICPRESENTATIONLISTVIEW_ROW_X_OFFSET,NSMinY(tFrame)-(PKGPresentationListViewDefaultRowHeight+tBulletSize.height)*0.5) fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
			}
			else
			{
				NSBezierPath * tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(ICPRESENTATIONLISTVIEW_ROW_X_OFFSET,NSMinY(tFrame)-(PKGPresentationListViewDefaultRowHeight+2.0*PKGPresentationListViewBulletRadius)*0.5,2.0*PKGPresentationListViewBulletRadius,2.0*PKGPresentationListViewBulletRadius)];
				
				if (tIndex==self.selectedStep)
				{
					[[NSColor systemBlueColor] setFill];
				}
				else
				{
					if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
					{
						if (tIndex < self.selectedStep)
							[[NSColor colorWithDeviceWhite:0.65 alpha:1.0] setFill];
						else
							[[NSColor colorWithDeviceWhite:0.85 alpha:1.0] setFill];
					}
					else
					{
						if (tIndex < self.selectedStep)
							[[NSColor quaternaryLabelColor] setFill];
						else
							[[NSColor tertiaryLabelColor] setFill];
					}
				}
				
				[tBezierPath fill];
				
				if (tWillBeVisible==NO)
				{
					NSImage * tImage;
					
					if (tIsDarkMode==NO)
						tImage=[NSImage imageNamed:@"Strip32Composite"];
					else
						tImage=[NSImage imageNamed:@"Strip32CompositeDark"];
					
					[[NSColor colorWithPatternImage:tImage] setFill];
					
					[tBezierPath fill];
				}
			}
		}
		else
		{
			tBezierPath=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(1+ICPRESENTATIONLISTVIEW_ROW_X_OFFSET,NSMinY(tFrame)-(PKGPresentationListViewDefaultRowHeight+tBulletSize.height)*0.5+2.0,tBulletSize.width-2.0,tBulletSize.width-2.0)];
				
			if (tWillBeVisible==NO)
			{
				NSImage * tImage;
				
				if (tIsDarkMode==NO)
					tImage=[NSImage imageNamed:@"Strip32"];
				else
					tImage=[NSImage imageNamed:@"Strip32Dark"];
				
				NSColor * tColor=nil;
				
				if (tImage!=nil)
					tColor=[[NSColor colorWithPatternImage:tImage] colorWithAlphaComponent:0.75];
				
				if (tColor==nil)
					tColor=[NSColor colorWithDeviceWhite:1.0 alpha:0.75];
				
				[tColor set];
			}
			else
			{
				[[NSColor textBackgroundColor] setFill];
			}
			
			[tBezierPath fill];
		}
		
		
		// Draw the text
		
		if (tStepTitle.length>0)
		{
			NSColor * tColor;
			
            if (tIndex==_mouseSelectedStep && _mouseSelectedStepPushed==YES)
            {
                tColor=[NSColor textBackgroundColor];
            }
            else
            {
                if (tIndex >self.selectedStep)
                {
                    if (tWillBeVisible==YES)
                    {
                        if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
                        {
                            tColor=[NSColor grayColor];
                        }
                        else
                        {
                            tColor=[NSColor tertiaryLabelColor];
                        }
                    }
                    else
                    {
                        if (tIsDarkMode==NO)
                            tColor=[NSColor colorWithPatternImage:[NSImage imageNamed:@"Strip32Disabled"]];
                        else
                            tColor=[NSColor colorWithPatternImage:[NSImage imageNamed:@"Strip32DisabledDark"]];
                    }
                }
                else
                {
                    if (tWillBeVisible==YES)
                    {
                        if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
                            tColor=[NSColor blackColor];
                        else
                            tColor=[NSColor labelColor];
                    }
                    else
                    {
                        if (tIsDarkMode==NO)
                            tColor=[NSColor colorWithPatternImage:[NSImage imageNamed:@"Strip32"]];
                        else
                            tColor=[NSColor colorWithPatternImage:[NSImage imageNamed:@"Strip32Dark"]];
                    }
                }
            }
            
			NSDictionary * tFontAttributes=@{NSFontAttributeName:tFont,
											 NSForegroundColorAttributeName:tColor};
			
			CGFloat tTextVerticallOffset=(_themeVersion==PKGPresentationThemeMountainLion) ? 1.0 : 2.0;
			
			NSRect tTextFrame=NSMakeRect(tTextOriginX,NSMinY(tFrame)-tStepHeight-tTextVerticallOffset,tTextMaxWidth,tStepHeight);
			
			[tStepTitle drawInRect:tTextFrame withAttributes:tFontAttributes];
		}
		
		if (tStepHeight==PKGPresentationListViewDefaultRowHeight)
			tFrame.size.height=PKGPresentationListViewDefaultRowHeight+1.0;
		else
			tFrame.size.height=tStepHeight+11.0;
		
		tFrame.origin.y-=NSHeight(tFrame);
		
#ifdef LIST_DEBUG_VIEW
		tSavedFrame.size.height=PKGPresentationListViewDefaultRowHeight;
	
		tSavedFrame.origin.y-=PKGPresentationListViewDefaultRowHeight;
		
		[[NSColor blueColor] set];
		
		NSFrameRect(tFrame);
		
		[[NSColor redColor] set];
#endif
	}
	
    // Draw the drop line
    
	if (_currentDropStep!=-1 && _currentDropStep==tIndex)
        drawDropLine(tFrame);
	
	// Draw the bottom More
	
	tFrame.origin.y=0;
    tFrame.size.height=PKGPresentationListViewMoreRowHeight;
	
	if (_lastVisibleStep<(tNumberOfSteps-1))
	{
		if (_mouseTrackInside==NO && _bottomPushed==NO)
		{
			drawEllipsisInRect(tFrame);
		}
		else
		{
			CGFloat tMiddleX=round(NSMidX(tFrame));
            CGFloat tMiddleY=round(NSMidY(tFrame));
            
			if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
			{
				if (_topPushed==YES)
					[[NSColor darkGrayColor] setFill];
				else
					[[NSColor grayColor] setFill];
			}
			else
			{
				if (_topPushed==YES)
					[[NSColor labelColor] setFill];
				else
					[[NSColor tertiaryLabelColor] setFill];
			}
			
			tBezierPath=[NSBezierPath bezierPath];
			
			[tBezierPath moveToPoint:NSMakePoint(tMiddleX-6.0,tMiddleY+2.0)];
			[tBezierPath lineToPoint:NSMakePoint(tMiddleX,tMiddleY-3.0)];
			[tBezierPath lineToPoint:NSMakePoint(tMiddleX+6.0,tMiddleY+2.0)];
			[tBezierPath closePath];
			
			[tBezierPath fill];
		}
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark -

#define PKGPresentationListViewMFirstClickDelay     0.5
#define PKGPresentationListViewMSecondClickDelay    0.25

- (void)mouseUp:(NSEvent *) inEvent
{
	if (_mouseMode==PKGPresentationListViewMouseModeClickNone)
		return;
	
	NSPoint tMouseLoc=[self convertPoint:inEvent.locationInWindow fromView:nil];
	BOOL tRefreshNeeded=NO;
	
	switch(_mouseMode)
	{
		case PKGPresentationListViewMouseModeClickTop:
		
			if (_topPushed==YES)
			{
				_topPushed=NO;
			
				tRefreshNeeded=YES;
			
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				
				[self.window performSelector:@selector(invalidateCursorRectsForView:) withObject:self afterDelay:0.1];
			}
			
			break;
		
		case PKGPresentationListViewMouseModeClickBottom:
		
			if (_bottomPushed==YES)
			{
				_bottomPushed=NO;
			
				tRefreshNeeded=YES;
			
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				
				[self.window performSelector:@selector(invalidateCursorRectsForView:) withObject:self afterDelay:0.1];
			}
			
			break;
		
		case PKGPresentationListViewMouseModeClick:
			
			_mouseSelectedStepPushed=NO;
			
			if ([self indexOfStepAtPoint:tMouseLoc]==_mouseSelectedStep)
			{
				tRefreshNeeded=YES;
				
				if (_selectedStep!=_mouseSelectedStep)
				{
					// Select new step
				
					[self selectStep:_mouseSelectedStep];
					
					if ([self.delegate respondsToSelector:@selector(presentationListViewSelectionDidChange:)]==YES)
					{
						NSNotification * tNotification=[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:self];
						
						[self.delegate presentationListViewSelectionDidChange:tNotification];
						
						// A COMPLETER
					}
				}
				
				_mouseSelectedStep=NSNotFound;
			}
			
			break;
			
		default:
			break;
	}
	
	if (tRefreshNeeded==YES)
		[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)inEvent
{
	if (_mouseMode==PKGPresentationListViewMouseModeClickNone)
		return;
	
	NSPoint tMouseLoc=[self convertPoint:inEvent.locationInWindow fromView:nil];
	BOOL tRefreshNeeded=NO;

	NSInteger tStep=[self indexOfStepAtPoint:tMouseLoc];

	switch(_mouseMode)
	{
		case PKGPresentationListViewMouseModeClickTop:
		
			if (_topPushed==YES)
			{
				if (tStep!=PKGPresentationListViewTopButtonIndex)
				{
					_topPushed=NO;
					
					[NSObject cancelPreviousPerformRequestsWithTarget:self];
					
					tRefreshNeeded=YES;
				}
			}
			else
			{
				if (tStep==PKGPresentationListViewTopButtonIndex)
				{
					_topPushed=YES;
					
					tRefreshNeeded=YES;
					
					[self performSelector:@selector(delayedScrollTop:) withObject:self afterDelay:PKGPresentationListViewMFirstClickDelay];
				}
			}
			
			break;
		
		case PKGPresentationListViewMouseModeClickBottom:
		
			if (_bottomPushed==YES)
			{
				if (tStep!=PKGPresentationListViewBottomButtonIndex)
				{
					_bottomPushed=NO;
					
					[NSObject cancelPreviousPerformRequestsWithTarget:self];
					
					tRefreshNeeded=YES;
				}
			}
			else
			{
				if (tStep==PKGPresentationListViewBottomButtonIndex)
				{
					_bottomPushed=YES;
					
					tRefreshNeeded=YES;
					
					[self performSelector:@selector(delayedScrollBottom:) withObject:self afterDelay:PKGPresentationListViewMFirstClickDelay];
				}
			}
			
			break;
		
		case PKGPresentationListViewMouseModeClick:
			
			// We need to check that we are not far enough to start a drag
			
#define PKGPresentationListViewDragOffset	4.0

			if (fabs(_originalMouseDownPointLocation.x-tMouseLoc.x)>PKGPresentationListViewDragOffset || fabs(_originalMouseDownPointLocation.y-tMouseLoc.y)>PKGPresentationListViewDragOffset)
			{
				NSPasteboard * tPasteboard=[NSPasteboard pasteboardWithName:NSDragPboard];
				
				if (tPasteboard!=nil && [self.dataSource respondsToSelector:@selector(presentationListView:writeStep:toPasteboard:)]==YES)
				{
					if ([self.dataSource presentationListView:self writeStep:_mouseSelectedStep toPasteboard:tPasteboard]==YES)
					{
						_mouseMode=PKGPresentationListViewMouseModeDrag;
						_mouseSelectedStepPushed=NO;
						
						[self setNeedsDisplay:YES];
						
						// Move the pasteboard data to the pasteboard item
						
						NSPasteboardItem *tPasteboardItem = [NSPasteboardItem new];
						
						for(NSString * tType in tPasteboard.types)
						{
							id tObject=[tPasteboard dataForType:tType];
							if (tObject!=nil)
							{
								[tPasteboardItem setData:tObject forType:tType];
								continue;
							}
							
							tObject=[tPasteboard propertyListForType:tType];
							if (tObject!=nil)
							{
								[tPasteboardItem setPropertyList:tObject forType:tType];
								continue;
							}

							tObject=[tPasteboard stringForType:tType];
							if (tObject!=nil)
							{
								[tPasteboardItem setString:tObject forType:tType];
								continue;
							}
						}
						
						NSDraggingItem *tDraggingItem=[[NSDraggingItem alloc] initWithPasteboardWriter:tPasteboardItem];
						tDraggingItem.draggingFrame=[self frameForStep:_mouseSelectedStep];
						tDraggingItem.imageComponentsProvider=^{
							
							NSImage * tImage=[self imageOfStep:_mouseSelectedStep];
							NSSize tSize=tImage.size;
							
							NSDraggingImageComponent * tDraggingImageComponent=[NSDraggingImageComponent draggingImageComponentWithKey:NSDraggingImageComponentIconKey];
							tDraggingImageComponent.contents=tImage;
							tDraggingImageComponent.frame=NSMakeRect(0, 0, tSize.width, tSize.height);
							
							return @[tDraggingImageComponent];
						};
						
						NSDraggingSession * tDraggingSession=[self beginDraggingSessionWithItems:@[tDraggingItem] event:inEvent source:self];
						tDraggingSession.animatesToStartingPositionsOnCancelOrFail=YES;
						tDraggingSession.draggingFormation=NSDraggingFormationNone;
						
						return;
					}
				}
			}
			
			// Step is not draggable
				
			// We just need to check whether the click is in or not
			
			if (_mouseSelectedStepPushed==YES)
			{
				if (tStep!=_mouseSelectedStep)
				{
					_mouseSelectedStepPushed=NO;
					
					tRefreshNeeded=YES;
				}
			}
			else
			{
				if (tStep==_mouseSelectedStep)
				{
					_mouseSelectedStepPushed=YES;
					
					tRefreshNeeded=YES;
				}
			}
			
			break;
			
		default:
			break;
	}

	if (tRefreshNeeded==YES)
		[self setNeedsDisplay:YES];
}

- (void)delayedScrollTop:(id)sender
{
	_topPushed=NO;
	
	if (_firstVisibleStep>0)
	{
		_topPushed=YES;
		
		_firstVisibleStep--;
		
		[self setNeedsDisplay:YES];
		
		[self performSelector:@selector(delayedScrollTop:) withObject:self afterDelay:PKGPresentationListViewMSecondClickDelay];
	}
}

- (void)delayedScrollBottom:(id)sender
{
	_bottomPushed=NO;
	
	if (self.dataSource==nil)
		return;
	
	if (_lastVisibleStep<([self.dataSource numberOfStepsInPresentationListView:self]-1))
	{
		_bottomPushed=YES;
	
		_firstVisibleStep++;
		
		[self setNeedsDisplay:YES];
		
		[self performSelector:@selector(delayedScrollBottom:) withObject:self afterDelay:PKGPresentationListViewMSecondClickDelay];
	}
}

- (void)mouseDown:(NSEvent *)inEvent
{
	NSPoint tMouseLoc=[self convertPoint:inEvent.locationInWindow fromView:nil];
	NSInteger tStep=[self indexOfStepAtPoint:tMouseLoc];
	
	switch(tStep)
	{
		case PKGPresentationListViewTopButtonIndex:
			
			_topPushed=YES;
			
			_firstVisibleStep--;
				
			[self setNeedsDisplay:YES];
			
			_mouseMode=PKGPresentationListViewMouseModeClickTop;
			
			// Launch delayed Scroll
			
			[self performSelector:@selector(delayedScrollTop:) withObject:self afterDelay:PKGPresentationListViewMFirstClickDelay];
			
			break;
		
		case PKGPresentationListViewBottomButtonIndex:
		
			_bottomPushed=YES;
			
			_firstVisibleStep++;
				
			[self setNeedsDisplay:YES];
			
			_mouseMode=PKGPresentationListViewMouseModeClickBottom;
			
			// Launch delayed Scroll
			
			[self performSelector:@selector(delayedScrollBottom:) withObject:self afterDelay:PKGPresentationListViewMFirstClickDelay];
			
			break;
		
		case NSNotFound:
			
			_mouseMode=PKGPresentationListViewMouseModeClickNone;
			
			return;
	
		default:
			
			_mouseSelectedStep=tStep;
			
			_mouseMode=PKGPresentationListViewMouseModeClickNone;
			
			if ([self.delegate respondsToSelector:@selector(presentationListView:shouldSelectStep:)]==NO ||
				[self.delegate presentationListView:self shouldSelectStep:_mouseSelectedStep]==YES)
			{
				_originalMouseDownPointLocation=tMouseLoc;
				
				_mouseMode=PKGPresentationListViewMouseModeClick;
				
				_mouseSelectedStepPushed=YES;
				
				[self setNeedsDisplay:YES];
			}
		
			break;
	}
}

- (void)mouseEntered:(NSEvent *) inEvent
{
    if (_dragInProgress==NO)
	{
		_mouseTrackInside=YES;
    
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseExited:(NSEvent *) inEvent
{
	if (_dragInProgress==NO)
	{
		_mouseTrackInside=NO;

		[self setNeedsDisplay:YES];
	}
}

- (void)resetCursorRects
{
	if (self.dataSource==nil)
		return;
	
	NSInteger tNumberOfSteps=[self.dataSource numberOfStepsInPresentationListView:self];
	
	if (tNumberOfSteps==0)
		return;
	
	// Compute the number of steps that can be displayed
	
	NSRect tBounds=self.bounds;
	
	NSRect tFrame=tBounds;
	
	tFrame.origin.y=NSMaxY(tBounds)-PKGPresentationListViewMoreRowHeight;
	tFrame.size.height=PKGPresentationListViewMoreRowHeight;
    
	if (_firstVisibleStep>0)
	{
		//[self addCursorRect:tFrame cursor:[NSCursor arrowCursor]];
	}
	
	for(NSInteger tIndex=_firstVisibleStep;tIndex<=_lastVisibleStep;tIndex++)
	{
		CGFloat tHeight=[self heightOfStep:tIndex];
		
		tFrame.origin.y-=tHeight;
        tFrame.size.height=tHeight;
		
		NSRect tClickableFrame=tFrame;
		
		tClickableFrame.origin.y+=2.0;
		
		if ([self.delegate respondsToSelector:@selector(presentationListView:shouldSelectStep:)]==YES &&
			[self.delegate presentationListView:self shouldSelectStep:tIndex]==NO)
			[self addCursorRect:tFrame cursor:[PKGPresentationListView sharedUnselectableCursor]];
	}
	
	if (_lastVisibleStep<(tNumberOfSteps-1))
	{
		tFrame.origin.y=0;
        tFrame.size.height=PKGPresentationListViewMoreRowHeight;
	
		//[self addCursorRect:tFrame cursor:[NSCursor arrowCursor]];
	}
}

#pragma mark - NSDraggingSource

- (NSDragOperation)draggingSession:(NSDraggingSession *)inDraggingSession sourceOperationMaskForDraggingContext:(NSDraggingContext)inDraggingContext
{
	if (inDraggingContext==NSDraggingContextOutsideApplication)
		return NSDragOperationNone;
	
	return NSDragOperationMove;
}

/*- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint
{
	// Useless
}*/

- (void)draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:(NSDragOperation)inDragOperation
{
	if ([self.dataSource respondsToSelector:@selector(presentationListView:shouldSelectStep:)]==YES)
		[self.dataSource presentationListView:self draggingSession:inDraggingSession endedAtPoint:inScreenPoint operation:inDragOperation];
}

#pragma mark -

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL) flag
{
	return NSDragOperationEvery;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if (_trackingTag!=0)
		[self removeTrackingRect:_trackingTag];
	
	_dragInProgress=YES;
	
	_trackingRect=NSZeroRect;
	
	_currentDropStep = -1;

	_oldDropStep = -1;

	_oldDroppingRect = NSZeroRect;

	_currentDragOperation = NSDragOperationEvery;
	
	return _currentDragOperation;
}

- (BOOL)wantsPeriodicDraggingUpdates
{
	// To Scroll when it's still possible
	
	return YES;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSRect tFrame;
	BOOL tRefreshNeeded=NO;
	
	NSPoint tPoint=[self convertPoint:[sender draggingLocation] fromView:nil];
	
	NSInteger tStep=[self indexOfStepAtPoint:tPoint];
	
	NSInteger tOldCurrentDropStep=_currentDropStep;
	
	switch(tStep)
	{
		case PKGPresentationListViewTopButtonIndex:
			
			if (_firstVisibleStep>0)
			{
				_firstVisibleStep--;
				
				tRefreshNeeded=YES;
			}
			
			tStep=_firstVisibleStep;
			
			_currentDropStep=_firstVisibleStep;
			
			tFrame=[self frameForStep:tStep];
			
			break;
		
		case PKGPresentationListViewBottomButtonIndex:
		
			if (_lastVisibleStep<([self.dataSource numberOfStepsInPresentationListView:self]-1))
			{
				_firstVisibleStep++;
				
				tRefreshNeeded=YES;
			}
			
			tStep=_lastVisibleStep;
			
			_currentDropStep=_lastVisibleStep+1;
			
			tFrame=[self frameForStep:tStep];
			
			break;
			
		case NSNotFound:
			
			if (tPoint.y<NSMidY(self.bounds))
			{
				tStep=_lastVisibleStep;
				
				_currentDropStep=_lastVisibleStep+1;
			}
			else
			{
				tStep=_firstVisibleStep;
				
				_currentDropStep=_firstVisibleStep;
			}
			
			tFrame=[self frameForStep:tStep];
			
			break;
			
		default:
			
			tFrame=[self frameForStep:tStep];
			
			if (tPoint.y<NSMidY(tFrame))
				_currentDropStep=tStep+1;
			else
				_currentDropStep=tStep;
			
			break;
	}
	
	if (_oldDropStep!=_currentDropStep)
	{
		_oldDropStep=_currentDropStep;
		
		if ([self.dataSource respondsToSelector: @selector(presentationListView:validateDrop:proposedStep:)]==YES)
		{	
			_currentDragOperation=[self.dataSource presentationListView:self validateDrop:sender proposedStep:_currentDropStep];
		
			if (_currentDragOperation==NSDragOperationNone)
				_currentDropStep=-1;
			
			if (tRefreshNeeded==NO)
				[self setNeedsDisplayInRect:_oldDroppingRect];
			
			if (_currentDropStep==tStep)
			{
				// Above
				
				_oldDroppingRect=NSMakeRect(0,NSMaxY(tFrame)-5.0,NSWidth(self.bounds),10.0);
			}
			else
			{
				// Below
				
				_oldDroppingRect=NSMakeRect(0,NSMinY(tFrame)-5.0,NSWidth(self.bounds),10.0);
			}
			
			if (tRefreshNeeded==NO)
				[self displayRect:_oldDroppingRect];
		}
	}
	else
	{
		_currentDropStep=tOldCurrentDropStep;
	}
	
	if (tRefreshNeeded==YES)
		[self setNeedsDisplay:YES];
	
	return _currentDragOperation;
}

- (BOOL)performDragOperation: (id<NSDraggingInfo>)sender
{
	_mouseTrackInside=YES;

	if (_currentDropStep!=-1 && [self.dataSource respondsToSelector: @selector(presentationListView:acceptDrop:step:)]==YES)
    {
		BOOL tResult=[self.dataSource presentationListView:self acceptDrop:sender step:_currentDropStep];
    
		_currentDropStep=-1;
		
		return tResult;
	}
	
    return NO;
}

- (BOOL)prepareForDragOperation: (id<NSDraggingInfo>)sender
{
	[self setNeedsDisplayInRect:_oldDroppingRect];

	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	_dragInProgress=NO;
	
	_currentDropStep=-1;
	
	[self setNeedsDisplay:YES];
	
	/*if ([self.dataSource respondsToSelector: @selector(presentationListView:draggingSession:endedAtPoint:operation:)]==YES)
		[self.dataSource presentationListView:self draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:];*/
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	_dragInProgress=NO;
	
	_currentDropStep=-1;
	
	[self setNeedsDisplayInRect:_oldDroppingRect];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	_dragInProgress=NO;
	
	_currentDropStep=-1;
	
	[self setNeedsDisplayInRect:_oldDroppingRect];
}

#pragma mark - Notifications

- (void)presentationThemeDidChange:(NSNotification *)inNotification
{
	if (self.window==nil)
		return;
	
	if (_supportThemeYosemite==YES)
		_themeVersion=[((PKGDocument *)((NSWindowController *)self.window.windowController).document).registry[PKGPresentationTheme] unsignedIntegerValue];
	
	[self setNeedsDisplay:YES];
}

@end
