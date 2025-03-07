/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageProjectMainViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGPackageProjectSettingsViewController.h"
#import "PKGPackageSettingsViewController.h"
#import "PKGPackagePayloadViewController.h"
#import "PKGPackageScriptsAndResourcesViewController.h"
#import "PKGPackageCommentsViewController.h"

#import "PKGPackageProject.h"

#import "PKGProject+Safe.h"
#import "PKGPackageProject+Safe.h"

#import "PKGDistributionProject+Edition.h"

@interface PKGPackageProjectMainViewController ()
{
	IBOutlet NSSegmentedControl * _segmentedControl;
	
	IBOutlet NSView * _contentsView;
	
	PKGSegmentViewController * _currentContentsViewController;
	
	PKGPackageProjectSettingsViewController * _projectSettingsController;
	PKGPackageSettingsViewController *_settingsController;
	PKGPackagePayloadViewController *_payloadController;
	PKGPackageScriptsAndResourcesViewController *_scriptsAndResourcesViewController;
	PKGCommentsViewController * _commentsController;
}

- (void)showTabViewWithTag:(PKGPreferencesGeneralPackageProjectPaneTag) inTag;

- (IBAction)showTabView:(id)sender;

// Notifications

- (void)viewDidResize:(NSNotification *)inNotification;

@end

@implementation PKGPackageProjectMainViewController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	[_segmentedControl setLabel:NSLocalizedString(@"Project_tab",@"") forSegment:PKGPreferencesGeneralPackageProjectPaneProject];
	[_segmentedControl setLabel:NSLocalizedString(@"Settings_tab",@"") forSegment:PKGPreferencesGeneralPackageProjectPaneSettings];
	[_segmentedControl setLabel:NSLocalizedString(@"Payload_tab",@"") forSegment:PKGPreferencesGeneralPackageProjectPanePayload];
	[_segmentedControl setLabel:NSLocalizedString(@"Scripts_tab",@"") forSegment:PKGPreferencesGeneralPackageProjectPaneScriptsAndResources];
	[_segmentedControl setLabel:NSLocalizedString(@"Comments_tab",@"") forSegment:PKGPreferencesGeneralPackageProjectPaneComments];
	
	// Register for Notification
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidResize:) name:NSViewFrameDidChangeNotification object:self.view];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	if (_segmentedControl.selectedSegment==-1)
    {
        // Show the default tab as defined in the preferences
        
        PKGApplicationPreferences * tApplicationPreferences=[PKGApplicationPreferences sharedPreferences];
        
        PKGPreferencesGeneralPackageProjectPaneTag tTag=tApplicationPreferences.defaultVisiblePackageProjectPane;
        
        [_segmentedControl selectSegmentWithTag:tTag];
        [self showTabViewWithTag:tTag];
    }
    else
    {
        [_currentContentsViewController WB_viewWillAppear];
    }
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[_currentContentsViewController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_currentContentsViewController WB_viewWillDisappear];
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

- (void)showTabViewWithTag:(PKGPreferencesGeneralPackageProjectPaneTag) inTag
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
		case PKGPreferencesGeneralPackageProjectPaneProject:
			
			if (_projectSettingsController==nil)
			{
				_projectSettingsController=[[PKGPackageProjectSettingsViewController alloc] initWithDocument:self.document];
				_projectSettingsController.projectSettings=(PKGPackageProjectSettings *)self.project.settings;
			}
			
			tNewSegmentViewController=_projectSettingsController;
			
			break;
			
		case PKGPreferencesGeneralPackageProjectPaneSettings:
			
			if (_settingsController==nil)
			{
				_settingsController=[[PKGPackageSettingsViewController alloc] initWithDocument:self.document];
				_settingsController.packageSettings=((id<PKGPackageObjectProtocol>) self.project).packageSettings;
			}
			
			tNewSegmentViewController=_settingsController;
			
			break;
			
		case PKGPreferencesGeneralPackageProjectPanePayload:
			
			if (_payloadController==nil)
			{
				_payloadController=[[PKGPackagePayloadViewController alloc] initWithDocument:self.document];
				_payloadController.payload=((PKGPackageProject *) self.project).payload_safe;
				
				if (_payloadController.payload==nil)
				{
					NSAlert * tAlert=[[NSAlert alloc] init];
					
					tAlert.messageText=@"Description forthcoming";		// A COMPLETER
					tAlert.informativeText=@"Description forthcoming";	// A COMPLETER
					
					[tAlert beginSheetModalForWindow:self.view.window completionHandler:nil];
					
					return;
				}
			}
			
			tNewSegmentViewController=_payloadController;
			
			break;
			
		case PKGPreferencesGeneralPackageProjectPaneScriptsAndResources:
			
			if (_scriptsAndResourcesViewController==nil)
			{
				_scriptsAndResourcesViewController=[[PKGPackageScriptsAndResourcesViewController alloc] initWithDocument:self.document];
				_scriptsAndResourcesViewController.scriptsAndResources=((PKGPackageProject *) self.project).scriptsAndResources_safe;
			}
			
			tNewSegmentViewController=_scriptsAndResourcesViewController;
			
			break;
			
		case PKGPreferencesGeneralPackageProjectPaneComments:
			
			if (_commentsController==nil)
			{
				_commentsController=[[PKGPackageCommentsViewController alloc] initWithDocument:self.document];
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
	
	[_currentContentsViewController WB_viewWillDisappear];
	[tNewSegmentViewController WB_viewWillAppear];
	
	[tOldView removeFromSuperview];
	[_contentsView addSubview:tNewView];
	
	[tNewSegmentViewController WB_viewDidAppear];
	[_currentContentsViewController WB_viewDidDisappear];
	
	_currentContentsViewController=tNewSegmentViewController;
	
	[self.view.window makeFirstResponder:_currentContentsViewController];
}

- (IBAction)showTabView:(NSSegmentedControl *)sender
{
	[self showTabViewWithTag:sender.selectedSegment];
}

#pragma mark - View Menu

- (IBAction)showProjectSettingsTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralPackageProjectPaneProject];
	[self showTabViewWithTag:PKGPreferencesGeneralPackageProjectPaneProject];
}

- (IBAction)showPackageSettingsTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralPackageProjectPaneSettings];
	[self showTabViewWithTag:PKGPreferencesGeneralPackageProjectPaneSettings];
}

- (IBAction)showPackagePayloadTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralPackageProjectPanePayload];
	[self showTabViewWithTag:PKGPreferencesGeneralPackageProjectPanePayload];
}

- (IBAction)showPackageScriptsAndResourcesTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralPackageProjectPaneScriptsAndResources];
	[self showTabViewWithTag:PKGPreferencesGeneralPackageProjectPaneScriptsAndResources];
}

- (IBAction)showProjectCommentsTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralPackageProjectPaneComments];
	[self showTabViewWithTag:PKGPreferencesGeneralPackageProjectPaneComments];
}

#pragma mark - Hierarchy Menu

- (IBAction)addFiles:(id)sender
{
	[_currentContentsViewController performSelector:@selector(addFiles:) withObject:sender];
}

- (IBAction)addNewFolder:(id)sender
{
	[_currentContentsViewController performSelector:@selector(addNewFolder:) withObject:sender];
}

- (IBAction)expandOneLevel:(id)sender
{
	[_currentContentsViewController performSelector:@selector(expandOneLevel:) withObject:sender];
}

- (IBAction)expand:(id)sender
{
	[_currentContentsViewController performSelector:@selector(expand:) withObject:sender];
}

- (IBAction)expandAll:(id)sender
{
	[_currentContentsViewController performSelector:@selector(expandAll:) withObject:sender];
}

- (IBAction)contract:(id)sender
{
	[_currentContentsViewController performSelector:@selector(contract:) withObject:sender];
}

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender
{
	[_currentContentsViewController performSelector:@selector(switchHiddenFolderTemplatesVisibility:) withObject:sender];
}

- (IBAction)setDefaultDestination:(id)sender
{
	[_currentContentsViewController performSelector:@selector(switchHiddenFolderTemplatesVisibility:) withObject:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=[inMenuItem action];
	
	// View Menu
	
	if (tAction==@selector(showDistributionPresentationTab:) ||
		tAction==@selector(showDistributionRequirementsAndResourcesTab:))
	{
		inMenuItem.hidden=YES;
		inMenuItem.keyEquivalentModifierMask=0;
		inMenuItem.keyEquivalent=@"";
		
		return NO;
	}
	
	if (tAction==@selector(showProjectSettingsTab:) ||
		tAction==@selector(showPackageSettingsTab:) ||
		tAction==@selector(showPackagePayloadTab:) ||
		tAction==@selector(showPackageScriptsAndResourcesTab:) ||
		tAction==@selector(showProjectCommentsTab:))
	{
		inMenuItem.keyEquivalentModifierMask=WBEventModifierFlagCommand;
		inMenuItem.hidden=NO;
	
		if (tAction==@selector(showProjectSettingsTab:))
		{
			inMenuItem.title=NSLocalizedString(@"Project",@"");
			inMenuItem.keyEquivalent=@"1";
		}
		else if (tAction==@selector(showPackageSettingsTab:))
		{
			inMenuItem.keyEquivalent=@"2";
		}
		else if (tAction==@selector(showPackagePayloadTab:))
		{
			inMenuItem.keyEquivalent=@"3";
		}
		else if (tAction==@selector(showPackageScriptsAndResourcesTab:))
		{
			inMenuItem.keyEquivalent=@"4";
		}
		else if (tAction==@selector(showProjectCommentsTab:))
		{
			inMenuItem.keyEquivalent=@"5";
		}
		
		return YES;
	}
	
	// Hierarchy Menu
	
	if (tAction==@selector(addFiles:) ||
		tAction==@selector(addNewFolder:) ||
		tAction==@selector(expandOneLevel:) ||
		tAction==@selector(expand:) ||
		tAction==@selector(expandAll:) ||
		tAction==@selector(contract:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGPackagePayloadViewController.class]==NO &&
			[_currentContentsViewController isKindOfClass:PKGPackageScriptsAndResourcesViewController.class]==NO)
			return NO;
		
		return [_currentContentsViewController validateMenuItem:inMenuItem];
	}
	
	if (tAction==@selector(switchHiddenFolderTemplatesVisibility:) ||
		tAction==@selector(setDefaultDestination:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGPackagePayloadViewController.class]==NO)
			return NO;
		
		return [_currentContentsViewController validateMenuItem:inMenuItem];
	}
	
	return YES;
}

#pragma mark - Notifications

- (void)viewDidResize:(NSNotification *)inNotification
{
	NSInteger tSegmentCount=[_segmentedControl segmentCount];
	
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
