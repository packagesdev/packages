/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGDistributionProjectSettingsViewController.h"
#import "PKGDistributionRequirementsAndResourcesViewController.h"
#import "PKGDistributionCommentsViewController.h"

#import "PKGProject+Safe.h"
#import "PKGDistributionProject+Safe.h"

#import "NSAlert+Block.h"

@interface PKGDistributionProjectViewController ()
{
	IBOutlet NSSegmentedControl * _segmentedControl;
	
	IBOutlet NSView * _contentView;
	
	PKGSegmentViewController * _currentContentController;
	
	PKGDistributionProjectSettingsViewController * _projectSettingsController;
	PKGDistributionRequirementsAndResourcesViewController * _requirementsAndResourcesController;
	PKGDistributionCommentsViewController * _commentsController;
}

- (void)showTabViewWithTag:(PKGPreferencesGeneralDistributionProjectPaneTag) inTag;

- (IBAction)showTabView:(id)sender;

- (IBAction)showProjectSettingsTab:(id)sender;
- (IBAction)showRequirementsAndResourcesTab:(id)sender;
- (IBAction)showCommentsTab:(id)sender;

// Notifications

- (void)viewDidResize:(NSNotification *)inNotification;

@end

@implementation PKGDistributionProjectViewController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	PKGApplicationPreferences * tApplicationPreferences=[PKGApplicationPreferences sharedPreferences];
	
	PKGPreferencesGeneralPackageProjectPaneTag tTag=tApplicationPreferences.defaultVisibleDistributionProjectPane;
	
	[_segmentedControl selectSegmentWithTag:tTag];
	[self showTabViewWithTag:tTag];
	
	// Register for Notification
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidResize:) name:NSViewFrameDidChangeNotification object:self.view];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[_currentContentController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[_currentContentController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_currentContentController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_currentContentController WB_viewDidDisappear];
}

- (BOOL)PKG_viewCanBeRemoved
{
	if (_currentContentController!=nil)
		return [_currentContentController PKG_viewCanBeRemoved];
	
	return YES;
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	// A COMPLETER
	
	return YES;
}

#pragma mark -

- (void)showTabViewWithTag:(PKGPreferencesGeneralDistributionProjectPaneTag) inTag
{
	if (_currentContentController!=nil)
	{
		if ([_currentContentController PKG_viewCanBeRemoved]==NO)
		{
			[_segmentedControl selectSegmentWithTag:_currentContentController.tag];
			
			return;
		}
	}
	
	PKGSegmentViewController * tNewSegmentViewController=nil;
	
	switch(inTag)
	{
		case PKGPreferencesGeneralDistributionProjectPaneSettings:
			
			if (_projectSettingsController==nil)
			{
				_projectSettingsController=[PKGDistributionProjectSettingsViewController new];
				_projectSettingsController.projectSettings=(PKGDistributionProjectSettings *)self.project.settings;
			}
			
			tNewSegmentViewController=_projectSettingsController;
			
			break;
			
		case PKGPreferencesGeneralDistributionProjectPanePresentation:
			
			/*if (_settingsController==nil)
			{
				_settingsController=[PKGPackageSettingsViewController new];
				_settingsController.packageSettings=((id<PKGPackageObjectProtocol>) self.project).packageSettings;
			}
			
			tNewSegmentViewController=_settingsController;*/
			
			break;
			
		case PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources:
			
			if (_requirementsAndResourcesController==nil)
			{
				_requirementsAndResourcesController=[PKGDistributionRequirementsAndResourcesViewController new];
				_requirementsAndResourcesController.requirementsAndResources=((PKGDistributionProject *) self.project).requirementsAndResources_safe;
			}
			
			tNewSegmentViewController=_requirementsAndResourcesController;
			
			break;
			
		case PKGPreferencesGeneralDistributionProjectPaneComments:
			
			if (_commentsController==nil)
			{
				_commentsController=[PKGDistributionCommentsViewController new];
				_commentsController.comments=self.project.comments_safe;
			}
			
			tNewSegmentViewController=_commentsController;
			
			break;
	}
	
	if (_currentContentController==tNewSegmentViewController)
		return;
	
	NSView * tOldView=_currentContentController.view;
	NSView * tNewView=tNewSegmentViewController.view;
	
	tNewView.frame=_contentView.bounds;
	
	if (self.view.window!=nil)
	{
		[_currentContentController WB_viewWillDisappear];
		[tNewSegmentViewController WB_viewWillAppear];
	}
	
	[tOldView removeFromSuperview];
	[_contentView addSubview:tNewView];
	
	if (self.view.window!=nil)
	{
		[tNewSegmentViewController WB_viewDidAppear];
		[_currentContentController WB_viewDidDisappear];
	}
	
	_currentContentController=tNewSegmentViewController;
}

- (IBAction)showTabView:(id)sender
{
	[self showTabViewWithTag:[sender selectedSegment]];
}

#pragma mark -

- (IBAction)showProjectSettingsTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionProjectPaneSettings];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionProjectPaneSettings];
}

- (IBAction)showRequirementsAndResourcesTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources];
}

- (IBAction)showCommentsTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionProjectPaneComments];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionProjectPaneComments];
}

#pragma mark - Notifications

- (void)viewDidResize:(NSNotification *)inNotification
{
	NSInteger tSegmentCount=_segmentedControl.segmentCount;
	
	NSRect tFrame=_segmentedControl.frame;
	
	tFrame.origin.x=-7.0;
	tFrame.size.width=NSWidth(self.view.frame)+7.0;
	
	CGFloat tSegmentWidth=tFrame.size.width/tSegmentCount;
	
	for(NSUInteger tIndex=0;tIndex<(tSegmentCount-1);tIndex++)
		[_segmentedControl setWidth:tSegmentWidth forSegment:tIndex];
	
	[_segmentedControl setWidth:tFrame.size.width-(tSegmentCount-1)*tSegmentWidth forSegment:(tSegmentCount-1)];
	
	_segmentedControl.frame=tFrame;
}

@end
