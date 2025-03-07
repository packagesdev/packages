
#import "PKGDistributionPackageComponentViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGPackageComponentSettingsViewController.h"
#import "PKGPackageComponentPayloadViewController.h"
#import "PKGPackageComponentScriptsAndResourcesViewController.h"

#import "PKGPackageComponent+Safe.h"

#import "PKGPackageComponent+UI.h"

@interface PKGDistributionPackageComponentViewController ()
{
	IBOutlet NSSegmentedControl * _segmentedControl;
	
	IBOutlet NSView * _contentsView;
	
	PKGSegmentViewController * _currentContentsViewController;
	
	PKGPackageComponentSettingsViewController * _settingsController;
	PKGPackageComponentPayloadViewController *_payloadController;
	PKGPackageComponentScriptsAndResourcesViewController *_scriptsAndResourcesViewController;
}

- (void)showTabViewWithTag:(PKGPreferencesGeneralDistributionPackageComponentPaneTag) inTag;

- (IBAction)showTabView:(id)sender;

// View Menu

- (IBAction)showProjectSettingsTab:(id)sender;
- (IBAction)showDistributionPresentationTab:(id)sender;
- (IBAction)showDistributionRequirementsAndResourcesTab:(id)sender;

- (IBAction)showPackageSettingsTab:(id)sender;
- (IBAction)showPackagePayloadTab:(id)sender;
- (IBAction)showPackageScriptsAndResourcesTab:(id)sender;

// Hierarchy Menu

- (IBAction)addFiles:(id)sender;
- (IBAction)addNewFolder:(id)sender;
- (IBAction)expandOneLevel:(id)sender;
- (IBAction)expand:(id)sender;
- (IBAction)expandAll:(id)sender;
- (IBAction)contract:(id)sender;

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender;

- (IBAction)setDefaultDestination:(id)sender;

// Notifications

- (void)viewDidResize:(NSNotification *)inNotification;

@end

@implementation PKGDistributionPackageComponentViewController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	[_segmentedControl setLabel:NSLocalizedString(@"Settings_tab",@"") forSegment:PKGPreferencesGeneralDistributionPackageComponentPaneSettings];
	[_segmentedControl setLabel:NSLocalizedString(@"Payload_tab",@"") forSegment:PKGPreferencesGeneralDistributionPackageComponentPanePayload];
	[_segmentedControl setLabel:NSLocalizedString(@"Scripts_tab",@"") forSegment:PKGPreferencesGeneralDistributionPackageComponentPaneScriptsAndResources];
	
	// Register for Notification
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidResize:) name:NSViewFrameDidChangeNotification object:self.view];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	PKGPreferencesGeneralPackageProjectPaneTag tTag;
	
	// Show the tab that was saved
	
	NSString * tRegistryKey=[NSString stringWithFormat:@"ui.package[%@].selected.segment",self.packageComponent.UUID];
	
	if ([self.documentRegistry objectForKey:tRegistryKey]==nil)
	{
		// Use the default tab
		
		PKGApplicationPreferences * tApplicationPreferences=[PKGApplicationPreferences sharedPreferences];
		
		tTag=tApplicationPreferences.defaultVisibleDistributionPackageComponentPane;
	}
	else
	{
		tTag=[self.documentRegistry integerForKey:tRegistryKey];
	}

	// Check whether this tag can be used
	
	if (self.packageComponent!=nil)
	{
		switch(self.packageComponent.type)
		{
			case PKGPackageComponentTypeProject:
				
				break;
				
			case PKGPackageComponentTypeImported:
			case PKGPackageComponentTypeReference:
				tTag=PKGPreferencesGeneralDistributionPackageComponentPaneSettings;
				
				[_segmentedControl setEnabled:NO forSegment:PKGPreferencesGeneralDistributionPackageComponentPanePayload];
				[_segmentedControl setEnabled:NO forSegment:PKGPreferencesGeneralDistributionPackageComponentPaneScriptsAndResources];
				
				break;
		}
	}
	
	[_segmentedControl selectSegmentWithTag:tTag];
	[self showTabViewWithTag:tTag];
	
	[_currentContentsViewController WB_viewWillAppear];
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

- (void)showTabViewWithTag:(PKGPreferencesGeneralDistributionPackageComponentPaneTag) inTag
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
		case PKGPreferencesGeneralDistributionPackageComponentPaneSettings:
			
			if (_settingsController==nil)
			{
				_settingsController=[[PKGPackageComponentSettingsViewController alloc] initWithDocument:self.document];
				_settingsController.packageComponent=self.packageComponent;
			}
			
			tNewSegmentViewController=_settingsController;
			
			break;
			
		case PKGPreferencesGeneralDistributionPackageComponentPanePayload:
			
			if (_payloadController==nil)
			{
				_payloadController=[[PKGPackageComponentPayloadViewController alloc] initWithDocument:self.document];
				_payloadController.payload=self.packageComponent.payload_safe;
				_payloadController.payloadHierarchyViewController.disclosedStateKey=self.packageComponent.payloadDisclosedStatesKey;
				_payloadController.payloadHierarchyViewController.selectionStateKey=self.packageComponent.payloadSelectionStatesKey;
				
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
			
		case PKGPreferencesGeneralDistributionPackageComponentPaneScriptsAndResources:
			
			if (_scriptsAndResourcesViewController==nil)
			{
				_scriptsAndResourcesViewController=[[PKGPackageComponentScriptsAndResourcesViewController alloc] initWithDocument:self.document];
				_scriptsAndResourcesViewController.scriptsAndResources=self.packageComponent.scriptsAndResources_safe;
				_scriptsAndResourcesViewController.additionalResourcesHierarchyViewController.disclosedStateKey=self.packageComponent.additionalResourcesDisclosedStatesKey;
				_scriptsAndResourcesViewController.additionalResourcesHierarchyViewController.selectionStateKey=self.packageComponent.additionalResourcesSelectionStatesKey;
			}
			
			tNewSegmentViewController=_scriptsAndResourcesViewController;
			
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
	
	if (tOldView!=tNewView)
	{
		[tOldView removeFromSuperview];
		[_contentsView addSubview:tNewView];
	}
	
	if (self.view.window!=nil)
	{
		[tNewSegmentViewController WB_viewDidAppear];
		[_currentContentsViewController WB_viewDidDisappear];
	}
	
	_currentContentsViewController=tNewSegmentViewController;
	
	[self.documentRegistry setInteger:inTag forKey:[NSString stringWithFormat:@"ui.package[%@].selected.segment",self.packageComponent.UUID]];
	
	[self.view.window makeFirstResponder:_currentContentsViewController];
}

- (IBAction)showTabView:(NSSegmentedControl *)sender
{
	[self showTabViewWithTag:sender.selectedSegment];
}

#pragma mark - View Menu

- (IBAction)showProjectSettingsTab:(id)sender
{
}

- (IBAction)showDistributionPresentationTab:(id)sender
{
}

- (IBAction)showDistributionRequirementsAndResourcesTab:(id)sender
{
}

- (IBAction)showPackageSettingsTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionPackageComponentPaneSettings];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionPackageComponentPaneSettings];
}

- (IBAction)showPackagePayloadTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionPackageComponentPanePayload];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionPackageComponentPanePayload];
}

- (IBAction)showPackageScriptsAndResourcesTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionPackageComponentPaneScriptsAndResources];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionPackageComponentPaneScriptsAndResources];
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
	[_currentContentsViewController performSelector:@selector(setDefaultDestination:) withObject:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=[inMenuItem action];
	
	// View Menu
	
	if (tAction==@selector(showProjectSettingsTab:) ||
		tAction==@selector(showDistributionPresentationTab:) ||
		tAction==@selector(showDistributionRequirementsAndResourcesTab:) ||
		tAction==@selector(showProjectCommentsTab:))
	{
		inMenuItem.hidden=YES;
		
		return NO;
	}
	
	if (tAction==@selector(showPackageSettingsTab:) ||
		tAction==@selector(showPackagePayloadTab:) ||
		tAction==@selector(showPackageScriptsAndResourcesTab:))
	{
		inMenuItem.keyEquivalentModifierMask=WBEventModifierFlagCommand;
		inMenuItem.hidden=NO;
		
		if (tAction==@selector(showPackageSettingsTab:))
		{
			inMenuItem.keyEquivalent=@"1";
			return YES;
		}
		
		if (tAction==@selector(showPackagePayloadTab:))
			inMenuItem.keyEquivalent=@"2";
		else
			inMenuItem.keyEquivalent=@"3";
		
		return (self.packageComponent.type==PKGPackageComponentTypeProject);
	}
	
	// Hierarchy Menu
	
	if (tAction==@selector(addFiles:) ||
		tAction==@selector(addNewFolder:) ||
		tAction==@selector(expandOneLevel:) ||
		tAction==@selector(expand:) ||
		tAction==@selector(expandAll:) ||
		tAction==@selector(contract:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGPackageComponentPayloadViewController.class]==NO &&
			[_currentContentsViewController isKindOfClass:PKGPackageComponentScriptsAndResourcesViewController.class]==NO)
			return NO;
		
		return [_currentContentsViewController validateMenuItem:inMenuItem];
	}
	
	if (tAction==@selector(switchHiddenFolderTemplatesVisibility:) ||
		tAction==@selector(setDefaultDestination:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGPackageComponentPayloadViewController.class]==NO)
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
