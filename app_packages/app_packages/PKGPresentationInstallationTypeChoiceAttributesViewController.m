
#import "PKGPresentationInstallationTypeChoiceAttributesViewController.h"

#import "PKGPresentationLocalizationsDataSource.h"

#import "PKGPresentationLocalizedStringsViewController.h"

#import "PKGChoiceTreeNode+UI.h"

#import "NSPopUpButton+OptimizedSize.h"

#import "PKGPresentationInstallationTypeStepSettings+UI.h"

typedef NS_ENUM(NSInteger, PKGVisibilityTag)
{
	PKGVisibleTag=0,
	PKGInvisibleTag=1
};

@interface PKGPresentationInstallationTypeChoiceAttributesViewController () <PKGPresentationLocalizationsDataSourceDelegate>
{
	IBOutlet NSView * _titlesSectionView;
	
	IBOutlet NSView * _descriptionsSectionView;
	
	IBOutlet NSView * _extendedAttributesSectionView_;
	
	IBOutlet NSPopUpButton * _choiceVisibilityPopUpButton;
	
	IBOutlet NSPopUpButton * _choicePackageStatePopUpButton;
	
	IBOutlet NSButton * _choicePackageStateEditButton;
	
	
	PKGPresentationLocalizedStringsViewController * _localizedTitlesViewController;
	
	PKGPresentationLocalizedStringsViewController * _localizeDescriptionsViewController;
}

- (IBAction)switchPackageVisibility:(id)sender;

- (IBAction)switchPackageState:(id)sender;

- (IBAction)editChoiceState:(id)sender;

@end

@implementation PKGPresentationInstallationTypeChoiceAttributesViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_localizedTitlesViewController=[PKGPresentationLocalizedStringsViewController new];
	_localizedTitlesViewController.label=NSLocalizedStringFromTable(@"Title", @"Presentation",@"");
	_localizedTitlesViewController.informationLabel=NSLocalizedStringFromTable(@"Click + to add a title localization.", @"Presentation",@"");
	
	if (self.choiceTreeNode!=nil)
	{
		PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
		
		PKGPresentationLocalizationsDataSource * tDataSource=[PKGPresentationLocalizationsDataSource new];
		
		tDataSource.localizations=tChoiceItem.localizedTitles;
		tDataSource.delegate=self;
		
		_localizedTitlesViewController.dataSource=tDataSource;
	}
	
	_localizedTitlesViewController.view.frame=_titlesSectionView.bounds;
	
	[_titlesSectionView addSubview:_localizedTitlesViewController.view];
	
	_localizeDescriptionsViewController=[PKGPresentationLocalizedStringsViewController new];
	_localizeDescriptionsViewController.label=NSLocalizedStringFromTable(@"Description", @"Presentation",@"");
	_localizeDescriptionsViewController.informationLabel=NSLocalizedStringFromTable(@"Click + to add a description localization.\nUse alt+return for line breaks.", @"Presentation",@"");
	
	if (self.choiceTreeNode!=nil)
	{
		PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
		
		PKGPresentationLocalizationsDataSource * tDataSource=[PKGPresentationLocalizationsDataSource new];
		
		tDataSource.localizations=tChoiceItem.localizedDescriptions;
		tDataSource.delegate=self;
		
		_localizeDescriptionsViewController.dataSource=tDataSource;
	}
	
	_localizeDescriptionsViewController.view.frame=_descriptionsSectionView.bounds;
	_localizeDescriptionsViewController.tableView.rowHeight=40.0;
	
	
	[_descriptionsSectionView addSubview:_localizeDescriptionsViewController.view];
}

#pragma mark -

- (void)setChoiceTreeNode:(PKGChoiceTreeNode *)inChoiceTreeNode
{
	_choiceTreeNode=inChoiceTreeNode;
	
	if (_localizedTitlesViewController!=nil)
	{
		PKGChoiceItem * tChoiceItem=[_choiceTreeNode representedObject];
		
		PKGPresentationLocalizationsDataSource * tDataSource=[PKGPresentationLocalizationsDataSource new];
		
		tDataSource.localizations=tChoiceItem.localizedTitles;
		tDataSource.delegate=self;
		
		_localizedTitlesViewController.dataSource=tDataSource;
	}
	
	if (_localizeDescriptionsViewController!=nil)
	{
		PKGChoiceItem * tChoiceItem=[_choiceTreeNode representedObject];
		
		PKGPresentationLocalizationsDataSource * tDataSource=[PKGPresentationLocalizationsDataSource new];
		
		tDataSource.localizations=tChoiceItem.localizedDescriptions;
		tDataSource.delegate=self;
		
		_localizeDescriptionsViewController.dataSource=tDataSource;
	}
	
	[self refreshUI];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[_localizedTitlesViewController WB_viewWillAppear];
	
	[_localizeDescriptionsViewController WB_viewWillAppear];
	
	[self refreshUI];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[_localizedTitlesViewController WB_viewDidAppear];
	
	[_localizeDescriptionsViewController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_localizedTitlesViewController WB_viewWillDisappear];
	
	[_localizeDescriptionsViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_localizedTitlesViewController WB_viewDidDisappear];
	
	[_localizeDescriptionsViewController WB_viewDidDisappear];
}

- (void)refreshUI
{
	if (_choiceVisibilityPopUpButton==nil)
		return;
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemOptions * tOptions=tChoiceItem.options;
	
	// Visibility
	
	[_choiceVisibilityPopUpButton selectItemWithTag:(tOptions.hidden==YES) ? PKGInvisibleTag : PKGVisibleTag];
	
	// State
	
	[_choicePackageStatePopUpButton removeAllItems];
	
	NSMenu * tMenu=[[NSMenu allocWithZone:[NSMenu menuZone]] init];
	
	if (self.choiceTreeNode.isGenuineGroupChoice==YES)
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Always Enabled",@"Presentation",@"") action:nil keyEquivalent:@""];
		tMenuItem.tag=PKGEnabledChoiceGroupState;
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Always Disabled",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGDisabledChoiceGroupState];
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Dependent on Other Choices",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGDependentChoiceGroupState];
				
		[tMenu addItem:tMenuItem];
	}
	else
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Required",@"Presentation",@"") action:nil keyEquivalent:@""];
		tMenuItem.tag=PKGRequiredChoiceState;
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Selected",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGSelectedChoiceState];
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Unselected",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGUnselectedChoiceState];
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Dependent on Other Choices",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGDependentChoiceState];
		
		[tMenu addItem:tMenuItem];
	}
	
	_choicePackageStatePopUpButton.menu=tMenu;
	
	NSRect tFrame=_choicePackageStatePopUpButton.frame;
	
	tFrame.size.width=[_choicePackageStatePopUpButton optimizedSize].width;
	
	_choicePackageStatePopUpButton.frame=tFrame;
	
	[_choicePackageStatePopUpButton selectItemWithTag:tOptions.state];
	
	if (self.choiceTreeNode.isGenuineGroupChoice==YES)
		_choicePackageStateEditButton.hidden=(tOptions.state!=PKGDependentChoiceGroupState);
	else
		_choicePackageStateEditButton.hidden=(tOptions.state!=PKGDependentChoiceState);
}

#pragma mark -

- (IBAction)switchPackageVisibility:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemOptions * tOptions=tChoiceItem.options;
	
	if (tOptions.hidden==(tTag==PKGInvisibleTag))
		return;
	
	tOptions.hidden=(tTag==PKGInvisibleTag);
	
	if (tOptions.state==PKGUnselectedChoiceState)
	{
		tOptions.state=PKGSelectedChoiceState;
		[_choicePackageStatePopUpButton selectItemWithTag:tOptions.state];
	}
	
	[self noteDocumentHasChanged];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationInstallationTypeStepSettingsDidChangeNotification object:self.document userInfo:@{}];	// A COMPLETER
}

- (IBAction)switchPackageState:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemOptions * tOptions=tChoiceItem.options;
	
	if (tTag==tOptions.state)
		return;
	
	tOptions.state=tTag;
	
	if (tTag==PKGDependentChoiceState ||
		tTag==PKGDependentChoiceGroupState)
	{
		if (tTag==PKGDependentChoiceGroupState)
		{
			tOptions.stateDependencies=[PKGChoiceItemOptionsDependencies new];
			// A COMPLETER
		}
		else
		{
			tOptions.stateDependencies=[PKGChoiceItemOptionsDependencies new];
			tOptions.stateDependencies.enabledStateDependencyType=PKGEnabledStateDependencyTypeAlways;
		}
		
		_choicePackageStateEditButton.hidden=NO;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			/*[[NSNotificationCenter defaultCenter] postNotificationName:ICDOCUMENT_PROJECT_PRESENTATION_INSTALLATION_TYPE_CHOICE_EDIT_DIDREQUEST
																object:document_
															  userInfo:nil];*/
		});
	}
	else
	{
		tOptions.stateDependencies=nil;
		_choicePackageStateEditButton.hidden=YES;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationInstallationTypeStepSettingsDidChangeNotification object:self.document userInfo:@{}];	// A COMPLETER
	
	[self noteDocumentHasChanged];
}

- (IBAction)editChoiceState:(id)sender
{
	// A COMPLETER
}

#pragma mark - PKGPresentationLocalizationsDataSourceDelegate

- (id)defaultValueForLocalizationsDataSource:(PKGPresentationLocalizationsDataSource *)inDataSource
{
	return @"";
}

- (void)localizationsDidChange:(PKGPresentationLocalizationsDataSource *)inDataSource
{
	[self noteDocumentHasChanged];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationInstallationTypeStepSettingsDidChangeNotification object:self.document userInfo:@{}];	// A COMPLETER
}


@end
