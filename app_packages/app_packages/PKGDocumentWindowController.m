/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDocumentWindowController.h"

#import "PKGDocument.h"

#import "PKGProject+Update.h"

#import "PKGDistributionProject+Edition.h"

#import "PKGPackageProjectMainViewController.h"
#import "PKGDistributionProjectMainViewController.h"

#import "PKGDocumentWindowStatusViewController.h"

#import "PKGApplicationPreferences.h"

#import "NSAlert+block.h"

#define PKGDocumentWindowPackageProjectMinWidth				1026.0
#define PKGDocumentWindowDistributionProjectMinWidth		1200.0
#define PKGDocumentWindowMinHeight							613.0

@interface PKGDocumentWindowController ()
{
	PKGProjectMainViewController * _projectMainViewController;
}

	@property (readwrite) PKGProject * project;

	@property (readwrite) PKGDocumentWindowStatusViewController * statusViewController;

- (IBAction)upgradeToDistribution:(id)sender;

- (void)layoutAccessoryViews;

@end

@implementation PKGDocumentWindowController

- (instancetype)initWithProject:(PKGProject *)inProject
{
	self=[super init];
	
	if (self!=nil)
	{
		_project=inProject;
		
		self.shouldCloseDocument=YES;
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)windowNibName
{
	return @"PKGDocumentWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self.window setContentBorderThickness:33.0 forEdge:NSMinYEdge];
	
	NSView * tContentView=self.window.contentView;
	
	NSRect tMiddleFrame=self.middleAccessoryView.frame;
	NSRect tRightFrame=self.rightAccessoryView.frame;
	
	tMiddleFrame.size.width=NSMaxX(tContentView.frame)-NSMinX(tMiddleFrame);
	
	tRightFrame.origin.x=NSMaxX(tContentView.frame);
	
	self.middleAccessoryView.frame=tMiddleFrame;
	self.rightAccessoryView.frame=tRightFrame;
	
	[self setMainViewController];
	
	[self layoutAccessoryViews];
	
	// Check whether we need to update the default payload hierarchies with fixed/updated permissions and items
	
	[self.project updateProjectAttributes:PKGProjectAttributeDefaultPayloadHierarchy completionHandler:^(PKGProjectAttribute bUpdatedAttributes) {
		
		if (bUpdatedAttributes!=PKGProjectAttributeNone)
			[self.document updateChangeCount:NSChangeDone];
		
		if ((bUpdatedAttributes & PKGProjectAttributeDefaultPayloadHierarchy)==PKGProjectAttributeDefaultPayloadHierarchy)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				NSAlert * tAlert=[NSAlert new];
				
				tAlert.messageText=NSLocalizedString(@"The standard folders have been updated.",@"No Comments");
				
				NSString * tInformativeText;
				
				if (self.project.type==PKGProjectTypePackage)
					tInformativeText=NSLocalizedString(@"The standard folders in the payload of this project have been updated to match the ones defined by this version of Packages. No existing items were removed.",@"No Comments");
				else
					tInformativeText=NSLocalizedString(@"The standard folders in the payload(s) of this project have been updated to match the ones defined by this version of Packages. No existing items were removed.",@"No Comments");
				
				tAlert.informativeText=tInformativeText;
				
				[tAlert beginSheetModalForWindow:self.window completionHandler:nil];
			});
		}
	}];
}

#pragma mark -

- (void)setContentsOfRightAccessoryView:(NSView *)inView
{
	NSArray * tSubViews=self.rightAccessoryView.subviews;
	
	if (tSubViews.count==0 && inView==nil)
		return;
	
	for(NSView * tSubView in tSubViews)
		[tSubView removeFromSuperview];
	
	NSView * tContentView=self.window.contentView;
	
	NSRect tMiddleFrame=self.middleAccessoryView.frame;
	NSRect tRightFrame=self.rightAccessoryView.frame;
	
	if (inView==nil)
	{
		// Hide Right Accessory View
		
		tMiddleFrame.size.width=NSMaxX(tContentView.frame)-NSMinX(tMiddleFrame);
		
		tRightFrame.origin.x=NSMaxX(tContentView.frame);
		
		self.middleAccessoryView.frame=tMiddleFrame;
		self.rightAccessoryView.frame=tRightFrame;
	}
	else
	{
		// Show/Resize Accessory View
		
		tRightFrame.size=inView.frame.size;
		
		[self.rightAccessoryView addSubview:inView];
		
		tRightFrame.origin.x=NSMaxX(tContentView.frame)-NSWidth(tRightFrame);
		
		tMiddleFrame.size.width=NSMaxX(tContentView.frame)-NSMinX(tMiddleFrame)-NSWidth(tRightFrame);
		
		self.middleAccessoryView.frame=tMiddleFrame;
		self.rightAccessoryView.frame=tRightFrame;
	}
}

- (void)layoutAccessoryViews
{
	NSRect tLeftFrame=self.leftAccessoryView.frame;
	NSRect tMiddleFrame=self.middleAccessoryView.frame;
	NSRect tRightFrame=self.rightAccessoryView.frame;
	
	NSView * tContentView=self.window.contentView;
	NSRect tContentFrame=tContentView.frame;
	
	switch (_project.type)
	{
		case PKGProjectTypeDistribution:
			
			tLeftFrame.origin.x=NSMinX(tContentFrame);
			
			break;
		
		case PKGProjectTypePackage:
			
			tLeftFrame.origin.x=NSMinX(tContentFrame)-tLeftFrame.size.width;
			
			break;
	}
	
	tMiddleFrame.origin.x=NSMaxX(tLeftFrame);
	tMiddleFrame.size.width=NSMinX(tRightFrame)-NSMinX(tMiddleFrame);
	
	self.leftAccessoryView.frame=tLeftFrame;
	self.middleAccessoryView.frame=tMiddleFrame;
}

#pragma mark -

- (NSArray *)buildNotificationObservers
{
	if (self.statusViewController==nil)
	{
		PKGDocumentWindowStatusViewController * tStatusViewController=[PKGDocumentWindowStatusViewController new];
		
		if (tStatusViewController==nil)
			return @[];
		
		tStatusViewController.view.frame=self.middleAccessoryView.bounds;
			
		[tStatusViewController WB_viewWillAppear];
			
		[self.middleAccessoryView addSubview:tStatusViewController.view];
			
		[tStatusViewController WB_viewDidAppear];
		
		self.statusViewController=tStatusViewController;
	}
	
	return @[self.statusViewController];
}

#pragma mark -

- (void)setMainViewController
{
	if (_projectMainViewController!=nil)
	{
		[_projectMainViewController WB_viewWillDisappear];
		
		[_projectMainViewController.view removeFromSuperview];
		
		[_projectMainViewController WB_viewDidDisappear];
	}
	
	switch(self.project.type)
	{
		case PKGProjectTypeDistribution:
			
			_projectMainViewController=[[PKGDistributionProjectMainViewController alloc] initWithDocument:self.document];
			
			self.window.minSize=NSMakeSize(PKGDocumentWindowDistributionProjectMinWidth, PKGDocumentWindowMinHeight);
			
			NSRect tWindowFrame=self.window.frame;
			
			if (NSWidth(tWindowFrame)<PKGDocumentWindowDistributionProjectMinWidth)
			{
				tWindowFrame.size.width=PKGDocumentWindowDistributionProjectMinWidth;
				
				[self.window setFrame:tWindowFrame display:YES];
			}
			
			break;
			
		case PKGProjectTypePackage:
			
			_projectMainViewController=[[PKGPackageProjectMainViewController alloc] initWithDocument:self.document];
			
			self.window.minSize=NSMakeSize(PKGDocumentWindowPackageProjectMinWidth, PKGDocumentWindowMinHeight);
			
			break;
	}
	
	_projectMainViewController.project=self.project;
	
	NSView * tContentView=self.window.contentView;
	
	NSView * tMainView=_projectMainViewController.view;
	
	tMainView.frame=tContentView.bounds;
	
	[_projectMainViewController WB_viewWillAppear];
	
	[tContentView addSubview:tMainView];
	
	[_projectMainViewController WB_viewDidAppear];
}

#pragma mark - Project Menu

- (IBAction)upgradeToDistribution:(id)sender
{
	PKGDistributionProject * tDistributionProject=[[PKGDistributionProject alloc] initWithPackageProject:(PKGPackageProject *)self.project];
	
	if (tDistributionProject==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	// Reset the Status view controller
	
	if (self.statusViewController!=nil)
	{
		[self.statusViewController WB_viewWillDisappear];
		
		[self.statusViewController.view removeFromSuperview];
		
		[self.statusViewController WB_viewDidDisappear];
		
		self.statusViewController=nil;
	}
	
	self.project=tDistributionProject;
	
	[self setMainViewController];
	
	[self layoutAccessoryViews];
	
	[self.document updateChangeCount:NSChangeDone];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;

	if (tAction==@selector(upgradeToDistribution:))
		return [self.project isKindOfClass:PKGPackageProject.class];
	
	return YES;
}

#pragma mark -

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[_projectMainViewController updateViewMenu];
}

@end
