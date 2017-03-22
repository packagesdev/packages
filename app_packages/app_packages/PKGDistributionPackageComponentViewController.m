
#import "PKGDistributionPackageComponentViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGDistributionPackageComponentsSettingsViewController.h"
#import "PKGPackagePayloadViewController.h"
#import "PKGPackageScriptsAndResourcesViewController.h"

#import "PKGPackageComponent+Safe.h"

#import "NSAlert+Block.h"

@interface PKGDistributionPackageComponentViewController ()
{
	IBOutlet NSSegmentedControl * _segmentedControl;
	
	IBOutlet NSView * _contentView;
	
	PKGSegmentViewController * _currentContentController;
	
	PKGDistributionPackageComponentsSettingsViewController * _settingsController;
	PKGPackagePayloadViewController *_payloadController;
	PKGPackageScriptsAndResourcesViewController *_scriptsAndResourcesViewController;
}

- (void)showTabViewWithTag:(PKGPreferencesGeneralDistributionPackageComponentPaneTag) inTag;

- (IBAction)showTabView:(id)sender;

- (IBAction)showSettingsTab:(id)sender;
- (IBAction)showPayloadTab:(id)sender;
- (IBAction)showScriptsAndResourcesTab:(id)sender;

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

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender
{
	[_payloadController switchHiddenFolderTemplatesVisibility:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=[inMenuItem action];
	
	if (tAction==@selector(switchHiddenFolderTemplatesVisibility:))
	{
		if ([_currentContentController isKindOfClass:PKGPackagePayloadViewController.class]==NO)
			return NO;
		
		return [_currentContentController validateMenuItem:inMenuItem];
	}
	
	return YES;
}

#pragma mark -

- (void)showTabViewWithTag:(PKGPreferencesGeneralDistributionPackageComponentPaneTag) inTag
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
		case PKGPreferencesGeneralDistributionPackageComponentPaneSettings:
			
			if (_settingsController==nil)
			{
				_settingsController=[[PKGDistributionPackageComponentsSettingsViewController alloc] initWithDocument:self.document];
				_settingsController.packageComponent=self.packageComponent;
			}
			
			tNewSegmentViewController=_settingsController;
			
			break;
			
		case PKGPreferencesGeneralDistributionPackageComponentPanePayload:
			
			if (_payloadController==nil)
			{
				_payloadController=[[PKGPackagePayloadViewController alloc] initWithDocument:self.document];
				_payloadController.payload=self.packageComponent.payload_safe;
				
				if (_payloadController.payload==nil)
				{
					NSAlert * tAlert=[[NSAlert alloc] init];
					
					tAlert.messageText=@"Description forthcoming";		// A COMPLETER
					tAlert.informativeText=@"Description forthcoming";	// A COMPLETER
					
					[tAlert WB_beginSheetModalForWindow:self.view.window completionHandler:nil];
					
					return;
				}
			}
			
			tNewSegmentViewController=_payloadController;
			
			break;
			
		case PKGPreferencesGeneralDistributionPackageComponentPaneScriptsAndResources:
			
			if (_scriptsAndResourcesViewController==nil)
			{
				_scriptsAndResourcesViewController=[[PKGPackageScriptsAndResourcesViewController alloc] initWithDocument:self.document];
				_scriptsAndResourcesViewController.scriptsAndResources=self.packageComponent.scriptsAndResources_safe;
			}
			
			tNewSegmentViewController=_scriptsAndResourcesViewController;
			
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
	
	if (tOldView!=tNewView)
	{
		[tOldView removeFromSuperview];
		[_contentView addSubview:tNewView];
	}
	
	if (self.view.window!=nil)
	{
		[tNewSegmentViewController WB_viewDidAppear];
		[_currentContentController WB_viewDidDisappear];
	}
	
	_currentContentController=tNewSegmentViewController;
	
	[self.documentRegistry setInteger:inTag forKey:[NSString stringWithFormat:@"ui.package[%@].selected.segment",self.packageComponent.UUID]];
	
	[self.view.window makeFirstResponder:_currentContentController];
}

- (IBAction)showTabView:(NSSegmentedControl *)sender
{
	[self showTabViewWithTag:sender.selectedSegment];
}

#pragma mark -

- (IBAction)showSettingsTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionPackageComponentPaneSettings];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionPackageComponentPaneSettings];
}

- (IBAction)showPayloadTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionPackageComponentPanePayload];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionPackageComponentPanePayload];
}

- (IBAction)showScriptsAndResourcesTab:(id)sender
{
	[_segmentedControl selectSegmentWithTag:PKGPreferencesGeneralDistributionPackageComponentPaneScriptsAndResources];
	[self showTabViewWithTag:PKGPreferencesGeneralDistributionPackageComponentPaneScriptsAndResources];
}

#pragma mark - Notifications

- (void)viewDidResize:(NSNotification *)inNotification
{
	NSInteger tSegmentCount=[_segmentedControl segmentCount];
	
	NSRect tFrame=_segmentedControl.frame;
	
	tFrame.origin.x=-7.0f;
	tFrame.size.width=NSWidth(self.view.frame)+7.0f;
	
	CGFloat tSegmentWidth=tFrame.size.width/tSegmentCount;
	
	for(NSUInteger tIndex=0;tIndex<(tSegmentCount-1);tIndex++)
		[_segmentedControl setWidth:tSegmentWidth forSegment:tIndex];
	
	[_segmentedControl setWidth:tFrame.size.width-(tSegmentCount-1)*tSegmentWidth forSegment:(tSegmentCount-1)];
	
	_segmentedControl.frame=tFrame;
}
@end
