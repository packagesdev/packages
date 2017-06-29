
#import "PKGPresentationInstallationTypeChoiceDependenciesViewController.h"

#import "PKGDocumentWindowController.h"

#import "PKGChoiceItemOptionsDependencies+UI.h"

@interface PKGPresentationInstallationTypeChoiceDependenciesViewController ()
{
	IBOutlet id _choiceEnabledDependencyTextLabel;
	
	IBOutlet NSPopUpButton * _choiceEnabledDependencyPopupButton;
	
	IBOutlet id _choiceEnabledDependencyColonLabel;
	
	IBOutlet NSScrollView * _choiceEnabledDependencyScrollView;
	
	IBOutlet id _choiceEnabledDependencyView;
	
	IBOutlet id _choiceSelectedDependencyTextLabel;
	
	IBOutlet NSScrollView * _choiceSelectedDependencyScrollView;
	
	IBOutlet id _choiceSelectedDependencyView;
	
	
	IBOutlet NSView * _accessoryView;
}

- (IBAction)returnToInspector:(id)sender;

@end

@implementation PKGPresentationInstallationTypeChoiceDependenciesViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// A COMPLETER
}

#pragma mark -

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Add Return to Inspector button
	
	PKGDocumentWindowController * tDocumentWindowController=self.document.windowControllers.firstObject;
	
	[tDocumentWindowController setContentsOfRightAccessoryView:_accessoryView];
	
	// Register Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	// Remove Return to Inspector button
	
	PKGDocumentWindowController * tDocumentWindowController=self.document.windowControllers.firstObject;
	
	[tDocumentWindowController setContentsOfRightAccessoryView:nil];
	
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
}

#pragma mark -

- (IBAction)returnToInspector:(id)sender
{
	dispatch_async(dispatch_get_main_queue(), ^{
	
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:self.document];
	});
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	/*NSSize tIdealEnabledScrollSize;
	NSRect tLabelFrame;
	
	if (isGroup_==YES)
	{
		CGFloat tAvailableVertical=NSMinY(_choiceEnabledDependencyTextLabel.frame)-8.0 -20.0;
		
		NSRect tEnabledViewFrame=_choiceEnabledDependencyView.frame;
		
		NSSize tIdealEnabledScrollSize=[NSScrollView frameSizeForContentSize:tEnabledViewFrame.size hasHorizontalScroller:NO hasVerticalScroller:NO borderType:NSBezelBorder];
		
		if (tIdealEnabledScrollSize.width>NSWidth(_choiceEnabledDependencyScrollView.frame))
			tIdealEnabledScrollSize.height+=16.0;
		
		NSRect tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
		
		if (tIdealEnabledScrollSize.height>=tAvailableVertical)
		{
			tScrollViewFrame.origin.y=20.0;
			tScrollViewFrame.size.height=tAvailableVertical;
		}
		else
		{
			tScrollViewFrame.size.height=tIdealEnabledScrollSize.height;
			tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
		}
		
		_choiceEnabledDependencyScrollView.frame=tScrollViewFrame;
	}
	else
	{
		int tEnabledStateMode=ICDOCUMENT_PROJECT_PRESENTATION_INSTALLATION_TYPE_LIST_ITEM_OPTIONS_STATE_DEPENDENCY_ENABLED_STATE_ALWAYS;
		
		NSNumber * tNumber=[dictionary_ objectForKey:ICDOCUMENT_PROJECT_PRESENTATION_INSTALLATION_TYPE_LIST_ITEM_OPTIONS_STATE_DEPENDENCY_ENABLED_STATE_MODE];
		
		if (tNumber!=nil)
		{
			tEnabledStateMode=[tNumber intValue];
		}
		
		NSRect tSelectedViewFrame=_choiceSelectedDependencyView.frame;
		
		if (tEnabledStateMode==ICDOCUMENT_PROJECT_PRESENTATION_INSTALLATION_TYPE_LIST_ITEM_OPTIONS_STATE_DEPENDENCY_ENABLED_STATE_DEPENDENT)
		{
			tEnabledViewFrame=_choiceEnabledDependencyView.frame;
			
			tAvailableVertical=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0 -20.0 -NSHeight(_choiceSelectedDependencyTextLabel.bounds) -8.0 -20.0;
			
			tIdealEnabledScrollSize=[NSScrollView frameSizeForContentSize:tEnabledViewFrame.size hasHorizontalScroller:NO hasVerticalScroller:NO borderType:NSBezelBorder];
			
			if (tIdealEnabledScrollSize.width>NSWidth(_choiceEnabledDependencyScrollView.frame))
			{
				tIdealEnabledScrollSize.height+=16.0;
			}
			
			tIdealSelectedScrollSize=[NSScrollView frameSizeForContentSize:tSelectedViewFrame.size hasHorizontalScroller:NO hasVerticalScroller:NO borderType:NSBezelBorder];
			
			if (tIdealSelectedScrollSize.width>NSWidth(_choiceSelectedDependencyScrollView.frame))
			{
				tIdealSelectedScrollSize.height+=16.0;
			}
			
			if ((tIdealEnabledScrollSize.height+tIdealSelectedScrollSize.height)>=tAvailableVertical)
			{
				if (tIdealEnabledScrollSize.height<(tAvailableVertical*0.5))
				{
					tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tIdealEnabledScrollSize.height;
					
					tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tScrollViewFrame.size.height;
					
					[_choiceEnabledDependencyScrollView setFrame:tScrollViewFrame];
					
					
					tLabelFrame=_choiceSelectedDependencyTextLabel.frame;
					
					tLabelFrame.origin.y=NSMinY(_choiceEnabledDependencyScrollView.frame)-20.0-tLabelFrame.size.height;
					
					[_choiceSelectedDependencyTextLabel setFrame:tLabelFrame];
					
					
					tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tAvailableVertical-tIdealEnabledScrollSize.height;
					
					tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
					
					[_choiceSelectedDependencyScrollView setFrame:tScrollViewFrame];
					
					
				}
				else if (tIdealSelectedScrollSize.height<(tAvailableVertical*0.5))
				{
					tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tAvailableVertical-tIdealSelectedScrollSize.height;
					
					tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tScrollViewFrame.size.height;
					
					[_choiceEnabledDependencyScrollView setFrame:tScrollViewFrame];
					
					
					tLabelFrame=_choiceSelectedDependencyTextLabel.frame;
					
					tLabelFrame.origin.y=NSMinY(_choiceEnabledDependencyScrollView.frame)-20.0-tLabelFrame.size.height;
					
					[_choiceSelectedDependencyTextLabel setFrame:tLabelFrame];
					
					
					tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tIdealSelectedScrollSize.height;
					
					tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
					
					[_choiceSelectedDependencyScrollView setFrame:tScrollViewFrame];
				}
				else
				{
					// Proprotionnaly scale down
					
					CGFloat tRatio;
					
					tRatio=(tIdealEnabledScrollSize.height+tIdealSelectedScrollSize.height)/tAvailableVertical;
					
					tIdealEnabledScrollSize.height=_CGFloatRound(tIdealEnabledScrollSize.height/tRatio);
					
					tIdealSelectedScrollSize.height=tAvailableVertical-tIdealEnabledScrollSize.height;
					
					
					tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tIdealEnabledScrollSize.height;
					
					tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tScrollViewFrame.size.height;
					
					[_choiceEnabledDependencyScrollView setFrame:tScrollViewFrame];
					
					
					tLabelFrame=[_choiceSelectedDependencyTextLabel frame];
					
					tLabelFrame.origin.y=NSMinY([_choiceEnabledDependencyScrollView frame])-20.0-tLabelFrame.size.height;
					
					[_choiceSelectedDependencyTextLabel setFrame:tLabelFrame];
					
					
					tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tIdealSelectedScrollSize.height;
					
					tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
					
					[_choiceSelectedDependencyScrollView setFrame:tScrollViewFrame];
				}
			}
			else
			{
				tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
				
				tScrollViewFrame.size.height=tIdealEnabledScrollSize.height;
				
				tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tScrollViewFrame.size.height;
				
				[_choiceEnabledDependencyScrollView setFrame:tScrollViewFrame];
				
				
				tLabelFrame=_choiceSelectedDependencyTextLabel.frame;
				
				tLabelFrame.origin.y=NSMinY(_choiceEnabledDependencyScrollView.frame)-20.0-tLabelFrame.size.height;
				
				[_choiceSelectedDependencyTextLabel setFrame:tLabelFrame];
				
				
				tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
				
				tScrollViewFrame.size.height=tIdealSelectedScrollSize.height;
				
				tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
				
				[_choiceSelectedDependencyScrollView setFrame:tScrollViewFrame];
			}
		}
		else
		{
			// Set the position of the label view
			
			tLabelFrame=_choiceSelectedDependencyTextLabel.frame;
			
			tLabelFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tLabelFrame.size.height;
			
			_choiceSelectedDependencyTextLabel.frame=tLabelFrame;
			
			tAvailableVertical=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0 -NSHeight(_choiceSelectedDependencyTextLabel.bounds)-8.0       -20.0;
			
			tIdealSelectedScrollSize=[NSScrollView frameSizeForContentSize:tSelectedViewFrame.size hasHorizontalScroller:NO hasVerticalScroller:NO borderType:NSBezelBorder];
			
			if (tIdealSelectedScrollSize.width>NSWidth(_choiceSelectedDependencyScrollView.frame))
				tIdealSelectedScrollSize.height+=16.0;
			
			tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
			
			if (tIdealSelectedScrollSize.height>=tAvailableVertical)
			{
				tScrollViewFrame.size.height=tAvailableVertical;
				
				tScrollViewFrame.origin.y=20.0;
			}
			else
			{
				tScrollViewFrame.size.height=tIdealSelectedScrollSize.height;
				
				tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
			}
			
			[_choiceSelectedDependencyScrollView setFrame:tScrollViewFrame];
		}
	}*/
}

@end
