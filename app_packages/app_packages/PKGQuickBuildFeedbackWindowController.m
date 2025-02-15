/*
 Copyright (c) 2008-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGQuickBuildFeedbackWindowController.h"

#import "PKGQuickBuildTextField.h"
#import "PKGQuickBuildWindow.h"

NSString * const PKGQuickBuildBuildViewKey=@"BuildView";
NSString * const PKGQuickBuildStatusViewKey=@"StatusView";

@interface PKGQuickBuildFeedbackWindowController ()
{
	NSView * _mainView;
	
	PKGQuickBuildTextField * _buildingLabelView;
	
	NSMutableArray * _viewsArray;
	
	NSMutableDictionary * _viewsDictionary;
}

// Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation PKGQuickBuildFeedbackWindowController

+ (PKGQuickBuildFeedbackWindowController *)sharedController
{
	static PKGQuickBuildFeedbackWindowController * sQuickBuildFeedbackController=nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		
		PKGQuickBuildWindow * tWindow=[PKGQuickBuildWindow new];
		
		sQuickBuildFeedbackController=[[PKGQuickBuildFeedbackWindowController alloc] initWithWindow:tWindow];
		
		[sQuickBuildFeedbackController windowDidLoad];
	});
	
	return sQuickBuildFeedbackController;
}

- (id)initWithWindow:(NSWindow *)inWindow
{
	self=[super initWithWindow:inWindow];
	
	if (self!=nil)
	{
		_viewsArray=[NSMutableArray new];
		
		_viewsDictionary=[NSMutableDictionary new];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	_mainView=self.window.contentView;
	
	NSRect tBounds=_mainView.bounds;
	
	_buildingLabelView=[[PKGQuickBuildTextField alloc] initWithFrame:NSMakeRect(10.0,NSMaxY(tBounds)-44.0,PKGQuickBuildWindowDefaultWidth-20.0,31.0)];
	
	_buildingLabelView.drawsBackground=NO;
	_buildingLabelView.bezeled=NO;
	_buildingLabelView.bordered=NO;
	_buildingLabelView.editable=NO;
	_buildingLabelView.selectable=NO;
	_buildingLabelView.alignment=WBTextAlignmentCenter;
	_buildingLabelView.font=[NSFont systemFontOfSize:20.0];
	
	_buildingLabelView.stringValue=NSLocalizedString(@"Building",@"");
	
	[_mainView addSubview:_buildingLabelView];
	
	// Register for notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:_mainView];
}

#pragma mark -

- (void)addViewForUUID:(NSUUID *)inUUID fileName:(NSString *)inFileName
{
	NSRect tBounds;
	NSUInteger i;
	
	NSUInteger tCount=_viewsArray.count;
	
	NSRect tBuildViewFrame=NSMakeRect(tCount*PKGQuickBuildWindowDefaultWidth,0.0,PKGQuickBuildWindowDefaultWidth,PKGQuickBuildWindowDefaultWidth);
	
	NSView * tBuildView=[[NSView alloc] initWithFrame:tBuildViewFrame];
	
	if (tBuildView!=nil) 
	{
		tBounds=tBuildView.bounds;
		
		// Background Image
		
		NSImageView * tImageView=[[NSImageView alloc] initWithFrame:NSMakeRect(NSMidX(tBounds)-64.0,NSMidY(tBounds)-64.0,128.0,128.0)];
		
		tImageView.image=[NSImage imageNamed:@"buildPackage"];
	
		[tBuildView addSubview:tImageView];
		
		
		PKGQuickBuildStatusView * tStatusView=[[PKGQuickBuildStatusView alloc] initWithFrame:NSMakeRect(35.5,35.5,57.0,57.0)];
		
		[tImageView addSubview:tStatusView];
		
		// Text labels
		
		PKGQuickBuildTextField * tTextField=[[PKGQuickBuildTextField alloc] initWithFrame:NSMakeRect(10.0,NSMinY(tBounds)+10.0,PKGQuickBuildWindowDefaultWidth-20.0,25.0)];
		
		[[tTextField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
		
		tTextField.drawsBackground=NO;
		tTextField.bezeled=NO;
		tTextField.bordered=NO;
		tTextField.editable=NO;
		tTextField.selectable=NO;
		tTextField.alignment=WBTextAlignmentCenter;
		tTextField.font=[NSFont systemFontOfSize:14.0];
		tTextField.stringValue=inFileName;
	
		[tBuildView addSubview:tTextField];
		
		NSDictionary * tViewDictionary=@{PKGQuickBuildBuildViewKey:tBuildView,
										 PKGQuickBuildStatusViewKey:tStatusView};
		
		[_viewsArray addObject:tViewDictionary];
		
		_viewsDictionary[inUUID]=tViewDictionary;
		
		[_mainView addSubview:tBuildView];
		
		
		tCount=_viewsArray.count;
		
		for(i=0;i<tCount;i++)
		{
			NSDictionary * tDictionary=_viewsArray[i];
			
			NSView * tView=tDictionary[PKGQuickBuildBuildViewKey];
			
			if (tView!=nil)
				tView.autoresizingMask=NSViewMaxXMargin;
		}
		
		if (tCount==1)
		{
			[self.window makeKeyAndOrderFront:self];
			return;
		}
		
		NSRect tContentViewFrame=[[self.window contentView] frame];
		
		tContentViewFrame.size.width=tCount*PKGQuickBuildWindowDefaultWidth;
	
		NSRect tNewWindowBounds=[self.window frameRectForContentRect:tContentViewFrame];
		NSRect tOldWindowFrame=[self.window frame];
		
		NSRect tNewWindowFrame=NSMakeRect(floor(NSMidX(tOldWindowFrame)-NSWidth(tNewWindowBounds)*0.5),tOldWindowFrame.origin.y,NSWidth(tNewWindowBounds),NSHeight(tOldWindowFrame));
		
		// Animation
		
		[self.window setFrame:tNewWindowFrame display:YES animate:YES];
	}
}

- (void)removeViewForUUID:(NSUUID *)inUUID
{
	NSUInteger tCount=_viewsArray.count;
	
	NSDictionary * tDictionary=_viewsDictionary[inUUID];
	
	if (tDictionary!=nil)
	{
		NSView * tView=tDictionary[PKGQuickBuildBuildViewKey];
		
		NSUInteger tIndex=[_viewsArray indexOfObject:tDictionary];
		
		if (tIndex!=NSNotFound)
		{
			for(NSUInteger i=0;i<tIndex;i++)
			{
				NSDictionary * tOtherDictionary=_viewsArray[i];
			
				NSView * tOtherView=tOtherDictionary[PKGQuickBuildBuildViewKey];
				
				if (tOtherView!=nil)
					tOtherView.autoresizingMask=NSViewMaxXMargin;
			}
			
			for(NSUInteger i=tIndex;i<tCount;i++)
			{
				NSDictionary * tOtherDictionary=_viewsArray[i];
			
				NSView * tOtherView=tOtherDictionary[PKGQuickBuildBuildViewKey];
				
				if (tOtherView!=nil)
				tOtherView.autoresizingMask=NSViewMaxXMargin;
			}
			
			[_viewsArray removeObjectAtIndex:tIndex];
		}
		
		[_viewsDictionary removeObjectForKey:inUUID];
		
		[tView removeFromSuperview];
		
		if (tCount==1)
		{
			[self.window orderOut:self];
		}
		else
		{
			NSRect tContentViewFrame=[[self.window contentView] frame];
			
			tCount=_viewsArray.count;
			
			tContentViewFrame.size.width=tCount*PKGQuickBuildWindowDefaultWidth;
			
			NSRect tNewWindowBounds=[self.window frameRectForContentRect:tContentViewFrame];
			
			NSRect tOldWindowFrame=[self.window frame];
			
			NSRect tNewWindowFrame=NSMakeRect(floor(NSMidX(tOldWindowFrame)-NSWidth(tNewWindowBounds)*0.5),tOldWindowFrame.origin.y,NSWidth(tNewWindowBounds),NSHeight(tOldWindowFrame));
			
			// Animation
			
			[self.window setFrame:tNewWindowFrame display:YES animate:YES];
		}
	}
	
	if (_viewsArray.count==0)
		[self.window orderOut:self];
}

- (void)setStatus:(PKGQuickBuildStatus)inStatus forUUID:(NSUUID *)inUUID
{
	PKGQuickBuildStatusView * tStatusView=_viewsDictionary[inUUID][PKGQuickBuildStatusViewKey];
	
	if (tStatusView!=nil)
			tStatusView.status=inStatus;
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	// We want to make sure the no display text label is centered
	
	NSRect tViewFrame=_mainView.frame;
	NSRect tLabelFrame=_buildingLabelView.frame;
	
	tLabelFrame.origin.x=round(NSMidX(tViewFrame)-NSWidth(tLabelFrame)*0.5f);
	
	_buildingLabelView.frame=tLabelFrame;
}

@end
