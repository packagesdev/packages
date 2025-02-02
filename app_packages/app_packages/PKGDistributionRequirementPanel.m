/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionRequirementPanel.h"

#import "PKGRequirementWindowController.h"

#import "PKGRequirementBehaviorViewController.h"
#import "PKGDistributionInstallationRequirementBehaviorViewController.h"
#import "PKGDistributionVolumeRequirementBehaviorViewController.h"

#import "PKGRequirementMessagesDataSource.h"

@interface PKGDistributionRequirementWindowController : PKGRequirementWindowController
{
	IBOutlet NSView * _checkTypeView;

	IBOutlet NSButton * _requirementTypeCheckBox;

	IBOutlet NSView * _behaviorPlaceHolderView;
	
	PKGRequirementBehaviorViewController * _currentBehaviorController;
	
	PKGRequirementType _cachedRequirementCheckType;
}

- (IBAction)switchRequirementCheckType:(id)sender;

- (void)showBehaviorViewForCheckType:(PKGRequirementType)inRequirementCheckType;

// Notifications

- (void)requirementCheckTypeDidChange:(NSNotification *)inNotification;

@end

@implementation PKGDistributionRequirementWindowController

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_cachedRequirementCheckType=PKGRequirementTypeUndefined;
	}
	
	return self;
}

- (NSString *)windowNibName
{
	return @"PKGDistributionRequirementPanel";
}

#pragma mark -

#pragma mark -

- (void)showRequirementViewControllerWithIdentifier:(NSString *)inIdentifier
{
	if (self.currentRequirementViewController!=nil)
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:PKGRequirementTypeDidChangeNotification
													  object:self.currentRequirementViewController];
	
	[super showRequirementViewControllerWithIdentifier:inIdentifier];
	
	if (self.currentRequirementViewController!=nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(requirementCheckTypeDidChange:)
													 name:PKGRequirementTypeDidChangeNotification
												   object:self.currentRequirementViewController];
		
		[self requirementCheckTypeDidChange:nil];
	}
	
	NSView * tPreviousKeyView=[self.currentRequirementViewController previousKeyView];
	
	if (tPreviousKeyView!=nil)
	{
		[_currentBehaviorController.tableView setNextKeyView:tPreviousKeyView];
		
		[self.currentRequirementViewController setNextKeyView:_currentBehaviorController.tableView];
		
		[self.window makeFirstResponder:tPreviousKeyView];
	}
	else
	{
		[self.window makeFirstResponder:_currentBehaviorController.tableView];
	}
}

- (IBAction)switchRequirementCheckType:(id)sender
{
	PKGRequirementType tRequirementCheckType=([sender state]==WBControlStateValueOn) ? PKGRequirementTypeTarget : PKGRequirementTypeInstallation;
	
	if (_cachedRequirementCheckType!=tRequirementCheckType)
	{
		self.requirement.type=tRequirementCheckType;
		
		_cachedRequirementCheckType=tRequirementCheckType;
		
		// Update Behavior View
		
		[self showBehaviorViewForCheckType:_cachedRequirementCheckType];
	}
}

- (void)showBehaviorViewForCheckType:(PKGRequirementType)inRequirementCheckType
{
	if (_currentBehaviorController!=nil)
	{
		if ([_currentBehaviorController PKG_viewCanBeRemoved]==NO)
			return;
		
		[_currentBehaviorController WB_viewWillDisappear];
		
		[_currentBehaviorController.view removeFromSuperview];

		[_currentBehaviorController WB_viewDidDisappear];
		
		_currentBehaviorController=nil;
	}
	
	PKGRequirementMessagesDataSource * tDataSource=[PKGRequirementMessagesDataSource new];
	tDataSource.messages=self.requirement.messages;
	
    PKGRequirementPanel * tRequirementPanel=(PKGRequirementPanel *)self.window;
    
	if (inRequirementCheckType==PKGRequirementTypeTarget)
	{
		_currentBehaviorController=[[PKGDistributionVolumeRequirementBehaviorViewController alloc] initWithDocument:tRequirementPanel.document];
	}
	else if (inRequirementCheckType==PKGRequirementTypeInstallation)
	{
		_currentBehaviorController=[[PKGDistributionInstallationRequirementBehaviorViewController alloc] initWithDocument:tRequirementPanel.document];
	}
	else
	{
		// A COMPLETER
	}
	
	_currentBehaviorController.dataSource=tDataSource;
	
	if (_currentBehaviorController==nil)
	{
		NSLog(@"[PKGDistributionRequirementWindowController showBehaviorViewForCheckType:] Missing controller for Check Type: %ld",(long)inRequirementCheckType);
		
		return;
	}
	
	NSRect tNewWindowFrame;
	NSRect tComputeRect;
	
	NSView * tBehaviorView=_currentBehaviorController.view;
	
	NSRect tBounds=_behaviorPlaceHolderView.bounds;
	
	NSRect tCurrentViewBounds=tBehaviorView.bounds;
	
	tCurrentViewBounds.size.width=NSWidth(tBounds);
	
	[tBehaviorView setFrame:tCurrentViewBounds];
	
	NSRect tOldWindowFrame=self.window.frame;
	
	tComputeRect=NSMakeRect(0,0,0,NSHeight(tCurrentViewBounds)-NSHeight(tBounds));
	
	tComputeRect=[NSWindow frameRectForContentRect:tComputeRect styleMask:NSBorderlessWindowMask];
	
	tNewWindowFrame.size=NSMakeSize(tOldWindowFrame.size.width,NSHeight(tOldWindowFrame)+NSHeight(tComputeRect));
	
	tNewWindowFrame.origin.x=NSMinX(tOldWindowFrame);
	tNewWindowFrame.origin.y=NSMaxY(tOldWindowFrame)-NSHeight(tNewWindowFrame);
	
	// Initialize View widgets
	
	[_currentBehaviorController WB_viewWillAppear];
	
	[_behaviorPlaceHolderView addSubview:tBehaviorView];
	
	_currentBehaviorController.requirementBehavior=self.requirement.failureBehavior;
	
	[_currentBehaviorController WB_viewDidAppear];
	
	_behaviorPlaceHolderView.autoresizingMask=NSViewWidthSizable+NSViewHeightSizable;
	
	self.requirementPlaceHolderView.autoresizingMask=NSViewMinYMargin+NSViewWidthSizable;
	
	_checkTypeView.autoresizingMask=NSViewMinYMargin+NSViewWidthSizable;
	
	[self.window setFrame:tNewWindowFrame display:YES animate:NO];
	
	self.requirementPlaceHolderView.autoresizingMask=NSViewWidthSizable+NSViewHeightSizable;
	
	_checkTypeView.autoresizingMask=NSViewMaxYMargin+NSViewWidthSizable;
	
	_behaviorPlaceHolderView.autoresizingMask=NSViewMaxYMargin+NSViewWidthSizable;

	
	[self updateMinMaxWindowSize];
}

- (IBAction)endDialog:(NSButton *)sender
{
	self.requirement.failureBehavior=_currentBehaviorController.requirementBehavior;
	
	[super endDialog:sender];
}

#pragma mark - Notifications

- (void)requirementCheckTypeDidChange:(NSNotification *)inNotification
{
	PKGRequirementType tRequirementCheckType=self.currentRequirementViewController.requirementType;
	
	if (tRequirementCheckType==PKGRequirementTypeUndefined)
	{
		_requirementTypeCheckBox.enabled=YES;
		
		tRequirementCheckType=((self.requirement.type==PKGRequirementTypeUndefined) ? PKGRequirementTypeInstallation : self.requirement.type);
		
		_requirementTypeCheckBox.state=(tRequirementCheckType==PKGRequirementTypeTarget) ? WBControlStateValueOn : WBControlStateValueOff;
	}
	else
	{
		_requirementTypeCheckBox.enabled=NO;
		
		self.requirement.type=tRequirementCheckType;
		
		if (tRequirementCheckType==PKGRequirementTypeTarget)
		{
			_requirementTypeCheckBox.state=WBControlStateValueOn;
		}
		else if (tRequirementCheckType==PKGRequirementTypeInstallation)
		{
			_requirementTypeCheckBox.state=WBControlStateValueOff;
		}
		else
		{
			NSLog(@"[PKGDistributionRequirementWindowController requirementCheckTypeDidChange:] Unsupported Requirement Check Type");
		}
	}
	
	
	if (_cachedRequirementCheckType!=tRequirementCheckType)
	{
		_cachedRequirementCheckType=tRequirementCheckType;
		
		// Update Behavior View
		
		[self showBehaviorViewForCheckType:_cachedRequirementCheckType];
	}
	else
	{
		[self updateMinMaxWindowSize];
	}
}

@end

@interface PKGRequirementPanel ()

	@property PKGRequirementWindowController * retainedWindowController;

@end

@interface PKGDistributionRequirementPanel ()

@end

@implementation PKGDistributionRequirementPanel

+ (PKGDistributionRequirementPanel *)distributionRequirementPanel
{
	PKGDistributionRequirementWindowController * tWindowController=[PKGDistributionRequirementWindowController new];
	
	PKGDistributionRequirementPanel * tPanel=(PKGDistributionRequirementPanel *)tWindowController.window;
	tPanel.retainedWindowController=tWindowController;
	
	return tPanel;
}

@end
