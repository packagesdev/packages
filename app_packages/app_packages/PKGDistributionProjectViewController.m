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
#import "PKGDistributionPresentationViewController.h"
#import "PKGDistributionRequirementsAndResourcesViewController.h"
#import "PKGDistributionCommentsViewController.h"

#import "PKGProject+Safe.h"
#import "PKGDistributionProject+Safe.h"

#import "PKGChoiceItemOptionsDependencies+UI.h"


@interface PKGDistributionProjectViewController ()
{
	IBOutlet NSSegmentedControl * _segmentedControl;
	
	IBOutlet NSView * _contentsView;
	
	PKGSegmentViewController * _currentContentsViewController;
	
	PKGDistributionProjectSettingsViewController * _projectSettingsController;
	PKGDistributionPresentationViewController * _presentationController;
	PKGDistributionRequirementsAndResourcesViewController * _requirementsAndResourcesController;
	PKGDistributionCommentsViewController * _commentsController;
	
	BOOL _editingInstallationTypeChoice;
}

- (void)showTabViewWithTag:(PKGPreferencesGeneralDistributionProjectPaneTag) inTag;

- (IBAction)showTabView:(id)sender;

- (IBAction)showProjectSettingsTab:(id)sender;
- (IBAction)showDistributionPresentationTab:(id)sender;
- (IBAction)showDistributionRequirementsAndResourcesTab:(id)sender;
- (IBAction)showProjectCommentsTab:(id)sender;

// Presentation Menu

- (IBAction)switchShowRawNames:(id)sender;

// Notifications

- (void)viewDidResize:(NSNotification *)inNotification;

- (void)choiceDependenciesEditionWillBegin:(NSNotification *)inNotification;
- (void)choiceDependenciesEditionDidEnd:(NSNotification *)inNotification;

@end

@implementation PKGDistributionProjectViewController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	[_segmentedControl setLabel:NSLocalizedString(@"Settings_tab",@"") forSegment:PKGPreferencesGeneralDistributionProjectPaneSettings];
	[_segmentedControl setLabel:NSLocalizedString(@"Presentation_tab",@"") forSegment:PKGPreferencesGeneralDistributionProjectPanePresentation];
	[_segmentedControl setLabel:NSLocalizedString(@"Requirements & Resources_tab",@"") forSegment:PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources];
	[_segmentedControl setLabel:NSLocalizedString(@"Comments_tab",@"") forSegment:PKGPreferencesGeneralDistributionProjectPaneComments];
	
	// Register for Notification
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidResize:) name:NSViewFrameDidChangeNotification object:self.view];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	PKGPreferencesGeneralDistributionProjectPaneTag tTag;
	
	// Show the tab that was saved
	
	NSString * tRegistryKey=@"ui.project.selected.segment";
	
	if ([self.documentRegistry objectForKey:tRegistryKey]==nil)
	{
		// Use the default tab
		
		PKGApplicationPreferences * tApplicationPreferences=[PKGApplicationPreferences sharedPreferences];
		
		tTag=tApplicationPreferences.defaultVisibleDistributionProjectPane;
	}
	else
	{
		tTag=[self.documentRegistry integerForKey:tRegistryKey];
	}
	
	[_segmentedControl selectSegmentWithTag:tTag];
	[self showTabViewWithTag:tTag];
	
	[_currentContentsViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[_currentContentsViewController WB_viewDidAppear];
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(choiceDependenciesEditionWillBegin:) name:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:self.document];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(choiceDependenciesEditionDidEnd:) name:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:self.document];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_currentContentsViewController WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:self.document];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:self.document];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_currentContentsViewController WB_viewDidDisappear];
}

- (BOOL)PKG_viewCanBeRemoved
{
	if (_currentContentsViewController!=nil)
		return [_currentContentsViewController PKG_viewCanBeRemoved];
	
	return YES;
}

#pragma mark -

- (void)showTabViewWithTag:(PKGPreferencesGeneralDistributionProjectPaneTag)inTag
{
	if (_currentContentsViewController!=nil)
	{
		if ([_currentContentsViewController PKG_viewCanBeRemoved]==NO)
		{
			[_segmentedControl selectSegmentWithTag:_currentContentsViewController.tag];
			
			return;
		}
	}
	
	PKGSegmentViewController * tNewSegmentViewController=nil;
	
	switch(inTag)
	{
		case PKGPreferencesGeneralDistributionProjectPaneSettings:
			
			if (_projectSettingsController==nil)
			{
				_projectSettingsController=[[PKGDistributionProjectSettingsViewController alloc] initWithDocument:self.document];
				_projectSettingsController.projectSettings=(PKGDistributionProjectSettings *)self.project.settings;
			}
			
			tNewSegmentViewController=_projectSettingsController;
			
			break;
			
		case PKGPreferencesGeneralDistributionProjectPanePresentation:
			
			if (_presentationController==nil)
			{
				_presentationController=[[PKGDistributionPresentationViewController alloc] initWithDocument:self.document];
				_presentationController.distributionProject=self.project;
				_presentationController.presentationSettings=self.project.presentationSettings;
			}
			
			tNewSegmentViewController=_presentationController;
			
			break;
			
		case PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources:
			
			if (_requirementsAndResourcesController==nil)
			{
				_requirementsAndResourcesController=[[PKGDistributionRequirementsAndResourcesViewController alloc] initWithDocument:self.document];
				_requirementsAndResourcesController.requirementsAndResources=((PKGDistributionProject *) self.project).requirementsAndResources_safe;
			}
			
			tNewSegmentViewController=_requirementsAndResourcesController;
			
			break;
			
		case PKGPreferencesGeneralDistributionProjectPaneComments:
			
			if (_commentsController==nil)
			{
				_commentsController=[[PKGDistributionCommentsViewController alloc] initWithDocument:self.document];
				_commentsController.comments=self.project.comments_safe;
			}
			
			tNewSegmentViewController=_commentsController;
			
			break;
	}
	
	if (_currentContentsViewController==tNewSegmentViewController)
		return;
	
	NSView * tOldView=_currentContentsViewController.view;
	NSView * tNewView=tNewSegmentViewController.view;
	
	tNewView.frame=_contentsView.bounds;
	
	if (self.view.window!=nil)
	{
		[_currentContentsViewController WB_viewWillDisappear];
		[tNewSegmentViewController WB_viewWillAppear];
	}
	
	[tOldView removeFromSuperview];
	[_contentsView addSubview:tNewView];
	
	if (self.view.window!=nil)
	{
		[_currentContentsViewController WB_viewDidDisappear];
		[tNewSegmentViewController WB_viewDidAppear];
	}
	
	_currentContentsViewController=tNewSegmentViewController;
	
	[self.documentRegistry setInteger:inTag forKey:@"ui.project.selected.segment"];
	
	[self.view.window makeFirstResponder:_currentContentsViewController];
}

- (IBAction)showTabView:(NSSegmentedControl *)sender
{
	[self showTabViewWithTag:sender.selectedSegment];
}

#pragma mark - View Menu

- (IBAction)showProjectSettingsTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionProjectPaneSettings];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionProjectPaneSettings];
}

- (IBAction)showDistributionPresentationTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionProjectPanePresentation];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionProjectPanePresentation];
}

- (IBAction)showDistributionRequirementsAndResourcesTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources];
}

- (IBAction)showProjectCommentsTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionProjectPaneComments];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionProjectPaneComments];
}

#pragma mark - Presentation Menu

- (IBAction)switchShowRawNames:(id)sender
{
	[_presentationController switchShowRawNames:sender];
}

#pragma mark - Project Menu

- (IBAction)selectCertificate:(id)sender
{
	[_projectSettingsController selectCertificate:sender];
}

- (IBAction)removeCertificate:(id) sender
{
	[_projectSettingsController removeCertificate:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	if (_editingInstallationTypeChoice==YES)
		return NO;
	
	SEL tAction=[inMenuItem action];
	
	if (tAction==@selector(selectCertificate:) ||
		tAction==@selector(removeCertificate:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGDistributionProjectSettingsViewController.class]==NO)
			return NO;
		
		return [_currentContentsViewController validateMenuItem:inMenuItem];
	}
	
	if (tAction==@selector(switchShowRawNames:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGDistributionPresentationViewController.class]==NO)
			return NO;
		
		return [_currentContentsViewController validateMenuItem:inMenuItem];
	}
	
	return YES;
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

- (void)choiceDependenciesEditionWillBegin:(NSNotification *)inNotification
{
	_segmentedControl.enabled=NO;
	
	_editingInstallationTypeChoice=YES;
}

- (void)choiceDependenciesEditionDidEnd:(NSNotification *)inNotification
{
	_segmentedControl.enabled=YES;
	
	_editingInstallationTypeChoice=NO;
}

@end
