
#import "PKGPresentationSectionInstallationTypeViewController.h"

#import "PKGApplicationPreferences.h"

#import "NSTableView+Selection.h"
#import "NSOutlineView+Selection.h"

#import "NSIndexPath+Packages.h"

#import "NSMutableDictionary+Localizations.h"

#import "PKGInstallerApp.h"
#import "PKGInstallerSimulatorBundle.h"

#import "PKGDistributionProject.h"

#import "PKGChoiceTreeNode+UI.h"
#import "PKGChoiceItemOptionsDependencies+UI.h"
#import "PKGInstallationHierarchy+UI.h"
#import "PKGPresentationInstallationTypeStepSettings+UI.h"



#import "PKGInstallationTypeScrollView.h"
#import "PKGInstallationTypeOutlineView.h"
#import "PKGInstallationTypeTableHeaderView.h"
#import "PKGInstallationTypeCornerView.h"
#import "PKGInstallationTypeCheckBox.h"

#import "PKGCheckboxTableCellView.h"

#import "PKGPresentationBox.h"

#import "PKGInstallationHierarchyDataSource.h"

#define PKGPresentationSectionInstallationTypeOutlineViewMinimumHeight	121.0

NSString * const PKGPresentationSectionInstallationTypeIndentationColumnIdentifier=@"choice.indentation";

NSString * const PKGPresentationSectionInstallationTypeCurrentHierarchyKey=@"ui.project.presentation.installationType.hierarchy.current";

NSString * const PKGPresentationSectionInstallationTypeShowRawNamesKey=@"ui.project.presentation.installationType.showRawNames";

NSString * const PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey=@"ui.project.presentation.installationType.branches.disclosed.%@";

NSString * const PKGPresentationSectionInstallationTypeHierarchySelectionFormatKey=@"ui.project.presentation.installationType.branches.selection.%@";


@interface PKGPresentationSectionInstallationTypeViewController () <NSSplitViewDelegate,NSOutlineViewDelegate,PKGInstallationHierarchyDataSourceDelegate>
{
	IBOutlet NSSplitView * _splitView;
	
	IBOutlet NSTableColumn * _indentationColumn;
	
	IBOutlet NSTextField * _spaceRequiredLabel;
	
	IBOutlet NSTextField * _remainingLabel;
	
	IBOutlet NSTextView * _descriptionTextView;
	
	
	IBOutlet PKGPresentationBox * _hierarchyBox;
	
	IBOutlet NSPopUpButton * _hierarchyPopUpButton;
	
	IBOutlet NSPopUpButton * _installationTypeModePopUpButton;
	
	IBOutlet PKGInstallationTypeTableHeaderView * _headerView;
	PKGInstallationTypeCornerView * _cornerView;
	
	PKGPresentationInstallationTypeStepSettings * _settings;
	
	PKGDistributionProject * _distributionProject;
	
	
	BOOL _editingChoicesDependencies;
	
	BOOL _showRawNames;
	
	NSArray * _cachedButtonsArray;
	
	BOOL _restoringDiscloseStates;
	
	PKGInstallationHierarchyDataSource * _dataSource;
}

	@property (nonatomic,copy) NSString * currentHierarchyName;

	@property (readwrite) IBOutlet PKGInstallationTypeOutlineView * outlineView;

- (void)setHierarchyBoxHidden:(BOOL)inHidden;

- (void)refreshHierarchyPopUpButton;
- (void)refreshBorders;

- (IBAction)delete:(id)sender;

- (IBAction)group:(id)sender;
- (IBAction)ungroup:(id)sender;

- (IBAction)merge:(id)sender;
- (IBAction)separate:(id)sender;

- (IBAction)switchHierarchy:(id)sender;

- (IBAction)nothing:(id)sender;

- (IBAction)addHierarchy:(id)sender;
- (IBAction)duplicateHierarchy:(id)sender;
- (IBAction)removeHierarchy:(id)sender;


- (IBAction)switchShowRawNames:(id)sender;

- (IBAction)switchInstallationTypeMode:(id)sender;

- (void)archiveSelection;
- (void)restoreSelection;

- (void)expandItemIfPossible:(PKGChoiceTreeNode *)inChoiceTreeNode;
- (void)expandItem:(PKGChoiceTreeNode *)inChoiceTreeNode ifKeyOfDictionary:(NSDictionary *)inDictionary;
- (void)restoreDisclosedStates;

// Notifications

- (void)appleInternalModeDidChange:(NSNotification *)inNotification;

- (void)installationTypeSettingsDidChange:(NSNotification *)inNotification;

- (void)choiceDependenciesEditionWillBegin:(NSNotification *)inNotification;
- (void)choiceDependenciesEditionDidEnd:(NSNotification *)inNotification;

@end

@implementation PKGPresentationSectionInstallationTypeViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	if (self!=nil)
	{
		_distributionProject=((PKGDistributionProject *)inDocument.project);
		
		_settings=inPresentationSettings.installationTypeSettings;
		
		if (_settings==nil)
		{
			_settings=[[PKGPresentationInstallationTypeStepSettings alloc] initWithPackagesComponents:_distributionProject.packageComponents];
			
			inPresentationSettings.installationTypeSettings=_settings;
		}
		
		_dataSource=[PKGInstallationHierarchyDataSource new];
		_dataSource.delegate=self;
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
	{
		_cornerView=[[PKGInstallationTypeCornerView alloc] initWithFrame:self.outlineView.cornerView.frame];
		self.outlineView.cornerView=_cornerView;
	}
	else
	{
		// A COMPLETER
	}
	
	_indentationColumn.hidden=YES;
	
	self.outlineView.autoresizesOutlineColumn=NO;
	
	self.outlineView.dataSource=_dataSource;
	
	[self.outlineView registerForDraggedTypes:[PKGInstallationHierarchyDataSource supportedDraggedTypes]];
	
	
	[self setHierarchyBoxHidden:([PKGApplicationPreferences sharedPreferences].appleMode==NO)];
}

#pragma mark -

- (PKGPresentationStepSettings *)settings
{
	return _settings;
}

- (NSString *)sectionPaneTitle
{
	NSString * tTitleFormat=nil;
	
	if (_settings.mode==PKGPresentationInstallationTypeStandardInstallOnly)
		tTitleFormat=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"StandardTitle" localization:self.localization];
	else
		tTitleFormat=[[[PKGInstallerApp installerApp] pluginWithSectionName:PKGPresentationSectionInstallationTypeName] stringForKey:@"CustomTitle" localization:self.localization];
	
	if (tTitleFormat==nil)
		return nil;
		
	return [NSString stringWithFormat:tTitleFormat,[[NSFileManager defaultManager] displayNameAtPath:@"/"]];
}

- (void)setCurrentHierarchyName:(NSString *)inCurrentHierarchyName
{
	if (inCurrentHierarchyName==nil)
		return;
	
	if ([_currentHierarchyName isEqualToString:inCurrentHierarchyName]==YES)
		return;
	
	_currentHierarchyName=[inCurrentHierarchyName copy];
	
	// Borders and PopUp Update
	
	_installationTypeModePopUpButton.enabled=([PKGPresentationInstallationTypeStepSettings hierarchyTypeForName:inCurrentHierarchyName]==PKGInstallationHierarchyInstaller);
	
	[self refreshBorders];
	
	// Choices OutlineView update
	
	_dataSource.installationHierarchy=_settings.hierarchies[inCurrentHierarchyName];
	
	[self.outlineView deselectAll:self];
	
	[self.outlineView reloadData];
	
	// Restore Disclosed State
	
	[self restoreDisclosedStates];
	
	// Restore Selection
	
	[self restoreSelection];
	
	// Source List Update
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGInstallationHierarchyRemovedPackagesListDidChangeNotification
														object:self.document
													  userInfo:@{PKGInstallationHierarchyRemovedPackagesUUIDsKey:_dataSource.installationHierarchy.removedPackagesChoices.allKeys}];
	
	self.documentRegistry[PKGPresentationSectionInstallationTypeCurrentHierarchyKey]=inCurrentHierarchyName;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_showRawNames=[self.documentRegistry boolForKey:PKGPresentationSectionInstallationTypeShowRawNamesKey];
	
	NSString * tCurrentHierarchyName=self.documentRegistry[PKGPresentationSectionInstallationTypeCurrentHierarchyKey];
	
	if (tCurrentHierarchyName==nil)
		tCurrentHierarchyName=self.documentRegistry[PKGPresentationSectionInstallationTypeCurrentHierarchyKey]=PKGPresentationInstallationTypeInstallerHierarchyKey;
	
	self.currentHierarchyName=tCurrentHierarchyName;
	
	[self refreshHierarchyPopUpButton];
	
	// Refresh Localization
	
	[self refreshUIForLocalization:self.localization];
	
	// Accessory View
	
	[_installationTypeModePopUpButton selectItemWithTag:_settings.mode];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appleInternalModeDidChange:) name:PKGPreferencesAdvancedAppleModeStateDidChangeNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(installationTypeSettingsDidChange:) name:PKGPresentationInstallationTypeStepSettingsDidChangeNotification object:self.document];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(choiceDependenciesEditionWillBegin:) name:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:self.document];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(choiceDependenciesEditionDidEnd:) name:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:self.document];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	// Archive Selection
	
	[self archiveSelection];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesAdvancedAppleModeStateDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPresentationInstallationTypeStepSettingsDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGInstallationHierarchyRemovedPackagesListDidChangeNotification object:self.document];
}

#pragma mark -

- (void)updateButtons:(NSArray *)inButtonsArray
{
	if (_settings==nil || inButtonsArray.count!=4)
		return;
	
	_cachedButtonsArray=inButtonsArray;
	
	// Print / Customize
	
	NSButton * tButton=inButtonsArray[PKGPresentationSectionButtonPrint];
	
	tButton.title=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Standard Install" localization:self.localization];
	
	NSRect tFrame=tButton.frame;
	
	[tButton sizeToFit];
	
	tFrame.size.width=NSWidth(tButton.frame);
	
	if (tFrame.size.width<=PKGAppkitMinimumPushButtonWidth)
		tFrame.size.width=PKGAppkitMinimumPushButtonWidth;
	
	tFrame.size.width+=12.0;
	
	tButton.frame=tFrame;
	
	tButton.hidden=(_settings.mode!=PKGPresentationInstallationTypeStandardOrCustomInstall);
	
	// Save
	
	tButton=inButtonsArray[PKGPresentationSectionButtonSave];
	
	tButton.hidden=YES;
	
	// Continue
	
	tButton=inButtonsArray[PKGPresentationSectionButtonContinue];
	
	tButton.hidden=NO;
	tButton.title=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Continue" localization:self.localization];
	
	tFrame=tButton.frame;
	
	CGFloat tMaxX=NSMaxX(tFrame);
	
	[tButton sizeToFit];
	
	tFrame.size.width=NSWidth(tButton.frame);
	
	if (tFrame.size.width<=PKGAppkitMinimumPushButtonWidth)
		tFrame.size.width=PKGAppkitMinimumPushButtonWidth;
	
	tFrame.size.width+=12.0;
	
	tFrame.origin.x=tMaxX-NSWidth(tFrame);
	
	tButton.frame=tFrame;
	
	tMaxX=NSMinX(tFrame);
	
	// Go Back
	
	tButton=inButtonsArray[PKGPresentationSectionButtonGoBack];
	
	tButton.hidden=NO;
	tButton.title=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Go Back" localization:self.localization];
	
	tFrame=[tButton frame];
	
	[tButton sizeToFit];
	
	tFrame.size.width=NSWidth(tButton.frame);
	
	if (tFrame.size.width<=PKGAppkitMinimumPushButtonWidth)
		tFrame.size.width=PKGAppkitMinimumPushButtonWidth;
	
	tFrame.size.width+=12.0;
	
	tFrame.origin.x=tMaxX-NSWidth(tFrame)+4.0;
	
	tButton.frame=tFrame;
	
	[tButton.superview setNeedsDisplay:YES];
}

- (void)refreshBorders
{
	if (self.currentHierarchyName==nil || _settings==nil)
		return;
	
	BOOL tCustomModeWillBeInvisible=NO;
	
	if ([self.currentHierarchyName isEqualToString:PKGPresentationInstallationTypeInstallerHierarchyKey]==YES)
		tCustomModeWillBeInvisible=(_settings.mode==PKGPresentationInstallationTypeStandardInstallOnly);
	
	((PKGInstallationTypeScrollView *)self.outlineView.enclosingScrollView).dashedBorder=tCustomModeWillBeInvisible;
	
	_headerView.dashedBorder=tCustomModeWillBeInvisible;
	
	if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
		_cornerView.dashedBorder=tCustomModeWillBeInvisible;
	
	((PKGInstallationTypeScrollView *)_descriptionTextView.enclosingScrollView).dashedBorder=tCustomModeWillBeInvisible;
	
	[_splitView setNeedsDisplay:YES];
}

- (void)refreshHierarchyPopUpButton
{
	// Remove all items
	
	[_hierarchyPopUpButton removeAllItems];
	
	// Set new menu
	
	NSMenu * tHierarchyMenu=[[NSMenu alloc] initWithTitle:@""];
	
	PKGInstallationHierarchyType tSelectedTag=PKGInstallationHierarchyInstaller;
	
	NSDictionary * tHierarchiesDictionary=_settings.hierarchies;
	
	if (tHierarchiesDictionary!=nil)
	{
		// Installer?
		
		if (tHierarchiesDictionary[PKGPresentationInstallationTypeInstallerHierarchyKey]!=nil)
		{
			NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(PKGPresentationInstallationTypeInstallerHierarchyKey, @"Presentation",@"No comment")
															  action:@selector(switchHierarchy:)
													   keyEquivalent:@""];
			

			tMenuItem.target=self;
			tMenuItem.tag=PKGInstallationHierarchyInstaller;
			
			NSImage * tImage=[PKGInstallationHierarchy iconForHierarchyType:PKGInstallationHierarchyInstaller];
			tImage.size=NSMakeSize(16.0,16.0);
			
			tMenuItem.image=tImage;
			
			[tHierarchyMenu addItem:tMenuItem];
		}
		
		// Software Update?
		
		if (tHierarchiesDictionary[PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey]!=nil)
		{
			NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey, @"Presentation",@"No comment")
												 action:@selector(switchHierarchy:)
										  keyEquivalent:@""];
			
			tMenuItem.target=self;
			tMenuItem.tag=PKGInstallationHierarchySoftwareUpdate;
			
			NSImage * tImage=[PKGInstallationHierarchy iconForHierarchyType:PKGInstallationHierarchySoftwareUpdate];
			tImage.size=NSMakeSize(16.0,16.0);
			
			tMenuItem.image=tImage;

			[tHierarchyMenu addItem:tMenuItem];
			
			if ([self.currentHierarchyName isEqualToString:PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey]==YES)
			{
				tSelectedTag=PKGInstallationHierarchySoftwareUpdate;
			}
		}
		
		// Invisible?
		
		if (tHierarchiesDictionary[PKGPresentationInstallationTypeInvisibleHierarchyKey]!=nil)
		{
			NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(PKGPresentationInstallationTypeInvisibleHierarchyKey, @"Presentation",@"No comment")
												 action:@selector(switchHierarchy:)
										  keyEquivalent:@""];
			
			tMenuItem.target=self;
			tMenuItem.tag=PKGInstallationHierarchyInvisible;
			
			NSImage * tImage=[PKGInstallationHierarchy iconForHierarchyType:PKGInstallationHierarchyInvisible];
			tImage.size=NSMakeSize(16.0,16.0);
			
			tMenuItem.image=tImage;
			
			[tHierarchyMenu addItem:tMenuItem];
			
			if ([self.currentHierarchyName isEqualToString:PKGPresentationInstallationTypeInvisibleHierarchyKey]==YES)
			{
				tSelectedTag=PKGInstallationHierarchyInvisible;
			}
		}
		
		// Separator
		
		[tHierarchyMenu addItem:[NSMenuItem separatorItem]];
		
		if (tHierarchiesDictionary.count<PKGInstallationHierarchyTypesCount)
		{
			// Add
			
			NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Add Hierarchy", @"Presentation",@"No comment")
												 action:@selector(nothing:)
										  keyEquivalent:@""];
			
			NSMenu * tSubMenu=[[NSMenu alloc] initWithTitle:@""];
			
			NSMutableArray * tArray=[[PKGPresentationInstallationTypeStepSettings allHierarchiesNames] mutableCopy];
			
			NSArray * tKeys=tHierarchiesDictionary.allKeys;
			
			[tArray removeObjectsInArray:tKeys];
			
			if (tArray.count>0)
			{
				// Installer?
				
				if ([tArray containsObject:PKGPresentationInstallationTypeInstallerHierarchyKey]==YES)
				{
					NSMenuItem * tSubMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(PKGPresentationInstallationTypeInstallerHierarchyKey, @"Presentation",@"No comment")
														 action:@selector(addHierarchy:)
												  keyEquivalent:@""];
					
					tSubMenuItem.target=self;
					tSubMenuItem.tag=PKGInstallationHierarchyInstaller;
					
					NSImage * tImage=[PKGInstallationHierarchy iconForHierarchyType:PKGInstallationHierarchyInstaller];
					tImage.size=NSMakeSize(16.0,16.0);
					
					tSubMenuItem.image=tImage;
					
					[tSubMenu addItem:tSubMenuItem];
				}
				
				// Software Update?
				
				if ([tArray containsObject:PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey]==YES)
				{
					NSMenuItem * tSubMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey, @"Presentation",@"No comment")
														 action:@selector(addHierarchy:)
												  keyEquivalent:@""];
					
					tSubMenuItem.target=self;
					tSubMenuItem.tag=PKGInstallationHierarchySoftwareUpdate;
					
					NSImage * tImage=[PKGInstallationHierarchy iconForHierarchyType:PKGInstallationHierarchySoftwareUpdate];
					tImage.size=NSMakeSize(16.0,16.0);
					
					tSubMenuItem.image=tImage;
					
					[tSubMenu addItem:tSubMenuItem];
				}
				
				// Invisible?
				
				if ([tArray containsObject:PKGPresentationInstallationTypeInvisibleHierarchyKey]==YES)
				{
					NSMenuItem * tSubMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(PKGPresentationInstallationTypeInvisibleHierarchyKey, @"Presentation",@"No comment")
														 action:@selector(addHierarchy:)
												  keyEquivalent:@""];
					
					tSubMenuItem.target=self;
					tSubMenuItem.tag=PKGInstallationHierarchyInvisible;
					
					NSImage * tImage=[PKGInstallationHierarchy iconForHierarchyType:PKGInstallationHierarchyInvisible];
					tImage.size=NSMakeSize(16.0,16.0);
					
					tSubMenuItem.image=tImage;
					
					[tSubMenu addItem:tSubMenuItem];
				}
				
				[tMenuItem setSubmenu:tSubMenu];
			}
			
			tMenuItem.tag=-1;
			tMenuItem.target=self;
			
			[tHierarchyMenu addItem:tMenuItem];
		}
		
		// Remove
		
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Remove...", @"Presentation", @"No comment")
											 action:@selector(removeHierarchy:)
									  keyEquivalent:@""];
		
		tMenuItem.target=self;
		
		NSImage * tImage=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarDeleteIcon)];
		tImage.size=NSMakeSize(16.0,16.0);
		
		tMenuItem.image=tImage;//[NSImage imageNamed:@"DeleteSmall"];
		
		[tHierarchyMenu addItem:tMenuItem];
	}
	
	_hierarchyPopUpButton.menu=tHierarchyMenu;
	
	[_hierarchyPopUpButton selectItemWithTag:tSelectedTag];
	
	_installationTypeModePopUpButton.enabled=(tSelectedTag==PKGInstallationHierarchyInstaller);
}

- (void)refreshUIForLocalization:(NSString *)inLocalization
{
	if (_splitView==nil)
		return;
	
	// Column Headers
	
	NSTableColumn * tTableColumn=[self.outlineView tableColumnWithIdentifier:@"choice.name"];
	
	NSString * tTitle=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Package Name" localization:inLocalization];
	
	if (_showRawNames==YES)
		tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" - <RAW>", @"Presentation", @"")];
	
	[[tTableColumn headerCell] setTitle:tTitle];
	
	tTableColumn=[self.outlineView tableColumnWithIdentifier:@"choice.action"];
	[[tTableColumn headerCell] setTitle:[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Package Action" localization:inLocalization]];
	
	tTableColumn=[self.outlineView tableColumnWithIdentifier:@"choice.size"];
	[[tTableColumn headerCell] setTitle:[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Package Size" localization:inLocalization]];
	
    [self.outlineView.headerView setNeedsDisplay:YES];
    
	// Space Labels
	
	_spaceRequiredLabel.stringValue=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Space Required:" localization:inLocalization];
	
	_remainingLabel.stringValue=[[PKGInstallerSimulatorBundle installerSimulatorBundle] localizedStringForKey:@"Remaining:" localization:inLocalization];
	
	// OutlineView
	
	[self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfRows)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfColumns)]];
	
	// Description
	
	[self outlineViewSelectionDidChange:[NSNotification notificationWithName:NSOutlineViewSelectionDidChangeNotification object:self.outlineView userInfo:nil]];
}

#pragma mark -

- (void)archiveSelection
{
	NSIndexSet * tIndexSet=self.outlineView.selectedRowIndexes;
	
	if (tIndexSet==nil)
		return;
	
	__block NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[tIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex, BOOL *bOutStop) {
		
		PKGChoiceTreeNode * tTreeNode=[self.outlineView itemAtRow:bIndex];
		
		if (tTreeNode==nil)
			return;
		
		NSString * tChoiceUUID=tTreeNode.choiceUUID;
		
		if (tChoiceUUID!=nil)
			[tMutableArray addObject:tChoiceUUID];
	}];
	
	self.documentRegistry[[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchySelectionFormatKey,self.currentHierarchyName]]=tMutableArray;
}

- (void)restoreSelection
{
	NSArray * tArray=self.documentRegistry[[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchySelectionFormatKey,self.currentHierarchyName]];
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	for(NSString * tChoiceUUID in tArray)
	{
		PKGChoiceTreeNode * tChoiceNode=[_dataSource itemWithChoiceUUID:tChoiceUUID];
		
		if (tChoiceNode!=nil)
		{
			NSInteger tRow=[self.outlineView rowForItem:tChoiceNode];
			
			if (tRow!=-1)
				[tMutableIndexSet addIndex:tRow];
		}
	}
	
	[self.outlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NSOutlineViewSelectionDidChangeNotification object:self.outlineView];
}

#pragma mark -

- (void)expandItemIfPossible:(PKGChoiceTreeNode *)inChoiceTreeNode
{
	if (inChoiceTreeNode==nil)
	{
		for(PKGChoiceTreeNode * tRootTreeNode in _dataSource.installationHierarchy.choicesForest.rootNodes.array)
			[self expandItemIfPossible:tRootTreeNode];
	
		return;
	}
	
	if (inChoiceTreeNode.isLeaf==YES)
		return;
	
	[self.outlineView expandItem:inChoiceTreeNode];
	
	for(PKGChoiceTreeNode * tChoiceTreeNode in [inChoiceTreeNode children])
	{
		[self expandItemIfPossible:tChoiceTreeNode];
	}
}

- (void)expandItem:(PKGChoiceTreeNode *)inChoiceTreeNode ifKeyOfDictionary:(NSDictionary *)inDictionary
{
	if (inChoiceTreeNode==nil || inDictionary.count==0)
		return;
	
	if (inChoiceTreeNode.isLeaf==YES)
		return;
	
	NSString * tChoiceUUID=inChoiceTreeNode.choiceUUID;
	
	// Always expand first and then collapse if not expanded (this allows us expand the children correctly)
	
	[self.outlineView expandItem:inChoiceTreeNode];
	
	// Check children
	
	NSArray * tChildren=[inChoiceTreeNode children];
	
	for(PKGChoiceTreeNode * tChoiceTreeNode in tChildren)
		[self expandItem:tChoiceTreeNode ifKeyOfDictionary:inDictionary];
	

	NSNumber * tNumber=inDictionary[tChoiceUUID];
	
	if (tNumber==nil || [tNumber boolValue]==NO)
		[self.outlineView collapseItem:inChoiceTreeNode];
}

- (void)restoreDisclosedStates
{
	NSString * tKey=[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey,self.currentHierarchyName];
	
	NSMutableDictionary * tDisclosedDictionary=self.documentRegistry[tKey];
	
	if (tDisclosedDictionary==nil)
	{
		// Disclose everything
		
		[self expandItemIfPossible:nil];
		
		return;
	}
	
	_restoringDiscloseStates=YES;
	
	for(PKGChoiceTreeNode * tRootTreeNode in _dataSource.installationHierarchy.choicesForest.rootNodes.array)
		[self expandItem:tRootTreeNode ifKeyOfDictionary:tDisclosedDictionary];
	
	_restoringDiscloseStates=NO;
}

#pragma mark -

- (void)setHierarchyBoxHidden:(BOOL)inHidden
{
	if (inHidden==NO)
	{
		_hierarchyBox.hidden=NO;
		return;
	}
	
	// We need to check that we are not already in a custom hierarchy situation
	
	NSDictionary * tHierarchiesDictionary=_settings.hierarchies;
	
	if (tHierarchiesDictionary[PKGPresentationInstallationTypeInstallerHierarchyKey]==nil ||
		tHierarchiesDictionary[PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey]!=nil ||
		tHierarchiesDictionary[PKGPresentationInstallationTypeInvisibleHierarchyKey]!=nil)
		return;
	
	_hierarchyBox.hidden=YES;
}



#pragma mark -

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	
	if (tIndexSet.count==1)
	{
		tAlert.messageText=NSLocalizedString(@"Do you really want to remove this item?",@"");
		tAlert.informativeText=NSLocalizedStringFromTable(@"This will also remove any dependency on this item for other items. This cannot be undone.", @"Presentation",@"");
	}
	else
	{
		tAlert.messageText=NSLocalizedString(@"Do you really want to remove these items?",@"");
		tAlert.informativeText=NSLocalizedStringFromTable(@"This will also remove any dependency on these items for other items. This cannot be undone.", @"Presentation",@"");
	}
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[_dataSource outlineView:self.outlineView removeItems:[self.outlineView WB_itemsAtRowIndexes:tIndexSet]];
	}];
}

- (IBAction)group:(id)sender
{
	[_dataSource outlineView:self.outlineView groupItems:[self.outlineView WB_selectedOrClickedItems]];
}

- (IBAction)ungroup:(id)sender
{
	PKGChoiceTreeNode * tGroupNode=[[self.outlineView WB_selectedOrClickedItems] firstObject];
	
	[_dataSource outlineView:self.outlineView ungroupItemsInGroup:tGroupNode];
	
	NSString * tKey=[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey,self.currentHierarchyName];
	
	NSMutableDictionary * tDisclosedDictionary=self.documentRegistry[tKey];
	
	[tDisclosedDictionary removeObjectForKey:tGroupNode.choiceUUID];
}

- (IBAction)merge:(id)sender
{
	[_dataSource outlineView:self.outlineView mergeItems:[self.outlineView WB_selectedOrClickedItems]];
}

- (IBAction)separate:(id)sender
{
	PKGChoiceTreeNode * tGroupNode=[[self.outlineView WB_selectedOrClickedItems] firstObject];
	
	[_dataSource outlineView:self.outlineView separateItemsMergedAsItem:tGroupNode];
	
	NSString * tKey=[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey,self.currentHierarchyName];
	
	NSMutableDictionary * tDisclosedDictionary=self.documentRegistry[tKey];
	
	[tDisclosedDictionary removeObjectForKey:tGroupNode.choiceUUID];
}

- (IBAction)switchShowRawNames:(id)sender
{
	_showRawNames=!_showRawNames;
	
	self.documentRegistry[PKGPresentationSectionInstallationTypeShowRawNamesKey]=@(_showRawNames);
	
	[self refreshUIForLocalization:self.localization];
	
	[self.outlineView.headerView setNeedsDisplay:YES];
	
	/*if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
	{
		_cornerView.mixedState=_showRawNames;
	}
	else
	{
	}*/
	
	[self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfRows)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfColumns)]];
}

- (IBAction)switchHierarchy:(NSPopUpButton *)sender
{
	PKGInstallationHierarchyType tTag=sender.tag;
	
	NSString * tHierarchyName=[PKGPresentationInstallationTypeStepSettings hierarchyNameForType:tTag];
	
	if ([tHierarchyName isEqualToString:self.currentHierarchyName]==YES)
		return;
	
	// Save the selection of the current hierarchy
	
	[self archiveSelection];
	
	self.currentHierarchyName=tHierarchyName;
}

- (IBAction)nothing:(id)sender
{
	if (self.currentHierarchyName!=nil)
		[_hierarchyPopUpButton selectItemWithTag:[[PKGPresentationInstallationTypeStepSettings allHierarchiesNames] indexOfObject:self.currentHierarchyName]];
}

- (IBAction)addHierarchy:(NSMenuItem *)sender
{
	PKGInstallationHierarchyType tTag=sender.tag;
	
	NSString * tNewHierarchyName=[PKGPresentationInstallationTypeStepSettings hierarchyNameForType:tTag];
	
	_settings.hierarchies[tNewHierarchyName]=[[PKGInstallationHierarchy alloc] initWithPackagesComponents:_distributionProject.packageComponents];
	
	[self noteDocumentHasChanged];
	
	dispatch_async(dispatch_get_main_queue(), ^{
	
		// Save the selection of the current hierarchy
		
		[self archiveSelection];
		
		self.currentHierarchyName=tNewHierarchyName;
		
		[self refreshHierarchyPopUpButton];
	});
}

- (IBAction)duplicateHierarchy:(NSMenuItem *)sender
{
	PKGInstallationHierarchyType tTag=sender.tag;
	
	NSString * tNewHierarchyName=[PKGPresentationInstallationTypeStepSettings hierarchyNameForType:tTag];
	
	PKGInstallationHierarchy * tCurrentHierarchy=_settings.hierarchies[self.currentHierarchyName];
	NSError * tError=nil;
	
	PKGInstallationHierarchy * tNewHierarchy=[[PKGInstallationHierarchy alloc] initWithRepresentation:tCurrentHierarchy.representation error:&tError];
	
	if (tNewHierarchy==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	// Remove localizations
	
	// A COMPLETER
	
	_settings.hierarchies[tNewHierarchyName]=tNewHierarchy;
	
	[self noteDocumentHasChanged];
	
	// Archive Selection
	
	[self archiveSelection];
	
	// Copy the disclosed state
	
	id tDisclosedStateRegistry=self.documentRegistry[[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey,self.currentHierarchyName]];
	
	if (tDisclosedStateRegistry!=nil)
		self.documentRegistry[[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey,tNewHierarchyName]]=[tDisclosedStateRegistry mutableCopy];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		self.currentHierarchyName=tNewHierarchyName;
		
		[self refreshHierarchyPopUpButton];
	});
}

- (IBAction)removeHierarchy:(id)sender
{
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Do you really want to remove the \"%@\" hierachy?", @"Presentation", @"No comment"),NSLocalizedString(self.currentHierarchyName,@"No comment")];
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
		{
			[_hierarchyPopUpButton selectItemWithTag:[[PKGPresentationInstallationTypeStepSettings allHierarchiesNames] indexOfObject:self.currentHierarchyName]];
			return;
		}
		
		// Remove the disclosed state for this hiearchy
		
		[self.documentRegistry removeObjectForKey:[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey,self.currentHierarchyName]];
		
		// Remove the stored selection if needed
		
		[self.documentRegistry removeObjectForKey:[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchySelectionFormatKey,self.currentHierarchyName]];
		
		// Remove the hierarchy
		
		[_settings.hierarchies removeObjectForKey:self.currentHierarchyName];
		
		[[PKGPresentationInstallationTypeStepSettings allHierarchiesNames] enumerateObjectsUsingBlock:^(NSString * bHierarchyName, NSUInteger bIndex, BOOL *bOutStop) {
			
			if (_settings.hierarchies[bHierarchyName]!=nil)
			{
				*bOutStop=YES;
				
				[self noteDocumentHasChanged];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					
					self.currentHierarchyName=bHierarchyName;
					
					[self refreshHierarchyPopUpButton];
				});
			}
		}];
	}];
}

- (IBAction)switchInstallationTypeMode:(NSPopUpButton *)sender
{
	PKGPresentationInstallationTypeMode tMode=sender.selectedItem.tag;
	
	if (tMode==_settings.mode)
		return;
		
	_settings.mode=tMode;
	
	// Update the borders
	
	[self refreshBorders];
	
	// Update the buttons
	
	if (_cachedButtonsArray==nil)
		return;
	
	((NSButton *)_cachedButtonsArray[0]).hidden=(tMode!=PKGPresentationInstallationTypeStandardOrCustomInstall);
	
	[self noteDocumentHasChanged];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	if (_editingChoicesDependencies==YES)
		return NO;
	
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchInstallationTypeMode:))
		return YES;
	
	if (tAction==@selector(switchHierarchy:))
		return YES;
	
	if (tAction==@selector(nothing:))
	{
		inMenuItem.title=([NSApp currentEvent].modifierFlags & WBEventModifierFlagOption) ? NSLocalizedStringFromTable(@"Duplicate As Hierarchy", @"Presentation",@"") : NSLocalizedStringFromTable(@"Add Hierarchy", @"Presentation",@"");
		
		return YES;
	}
	
	if (tAction==@selector(addHierarchy:) ||
		tAction==@selector(duplicateHierarchy:))
	{
		inMenuItem.action=([NSApp currentEvent].modifierFlags & WBEventModifierFlagOption) ? @selector(duplicateHierarchy:) : @selector(addHierarchy:);
		
		return YES;
	}
	
	if (tAction==@selector(removeHierarchy:))
		return (_settings.hierarchies.count>1);
	
	NSIndexSet * tSelectionIndexSet=self.outlineView.WB_selectedOrClickedRowIndexes;
	
	if (tAction==@selector(delete:))
		return (tSelectionIndexSet.count>0);
	
	if (tAction==@selector(group:))
	{
		if (tSelectionIndexSet.count==0)
			return NO;
		
		NSArray * tSelectedItems=[self.outlineView WB_selectedOrClickedItems];
		
		if ([PKGTreeNode nodesAreSiblings:tSelectedItems]==NO)
			return NO;
		
		PKGChoiceTreeNode * tChoiceTreeNode=tSelectedItems.firstObject;
		
		return (tChoiceTreeNode.isMergedIntoPackagesChoice==NO);
	}
	
	if (tAction==@selector(ungroup:))
	{
		if (tSelectionIndexSet.count!=1)
			return NO;
		
		NSArray * tSelectedItems=[self.outlineView WB_selectedOrClickedItems];
		
		PKGChoiceTreeNode * tChoiceTreeNode=tSelectedItems.firstObject;
		
		return tChoiceTreeNode.isGenuineGroupChoice;
	}
	
	if (tAction==@selector(merge:))
	{
		if (tSelectionIndexSet.count<2)
			return NO;
		
		NSArray * tSelectedItems=[self.outlineView WB_selectedOrClickedItems];
		
		if ([PKGTreeNode nodesAreSiblings:tSelectedItems]==NO)
			return NO;
		
		NSUInteger tIndex=[tSelectedItems indexOfObjectPassingTest:^BOOL(PKGChoiceTreeNode * bChoiceTreeNode, NSUInteger bIndex, BOOL *bOutStop) {
			
			return (bChoiceTreeNode.isPackageChoice==NO);
		}];
		
		if (tIndex!=NSNotFound)
			return NO;
		
		PKGChoiceTreeNode * tChoiceTreeNode=tSelectedItems.firstObject;
		
		return (tChoiceTreeNode.isMergedIntoPackagesChoice==NO);
	}
	
	if (tAction==@selector(separate:))
	{
		if (tSelectionIndexSet.count!=1)
			return NO;
		
		NSArray * tSelectedItems=[self.outlineView WB_selectedOrClickedItems];
		
		PKGChoiceTreeNode * tChoiceTreeNode=tSelectedItems.firstObject;
		
		return tChoiceTreeNode.isMergedPackagesChoice;
	}
	
	if (tAction==@selector(switchShowRawNames:))
	{
		inMenuItem.title=(_showRawNames==YES) ? NSLocalizedStringFromTable(@"Hide Raw Names", @"Presentation",@"") : NSLocalizedStringFromTable(@"Show Raw Names", @"Presentation",@"");
		
		return YES;
	}
	
	return NO;
}

#pragma mark - NSSplitViewDelegate

- (void)splitView:(NSSplitView *)inSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect tSplitViewFrame=inSplitView.frame;
	
	NSArray * tSubviews=inSplitView.subviews;
	
	NSView *tViewTop=tSubviews[0];
	
	NSRect tTopFrame=tViewTop.frame;
	
	NSView *tViewBottom=tSubviews[1];
	
	NSRect tBottomFrame=tViewBottom.frame;
	
	tTopFrame.size.height=NSHeight(tSplitViewFrame)-inSplitView.dividerThickness-NSHeight(tBottomFrame);
	
	if (NSHeight(tTopFrame)<PKGPresentationSectionInstallationTypeOutlineViewMinimumHeight)
	{
		tTopFrame.size.height=PKGPresentationSectionInstallationTypeOutlineViewMinimumHeight;
		
		tBottomFrame.size.height=NSHeight(tSplitViewFrame)-inSplitView.dividerThickness-NSHeight(tTopFrame);
		
		if (NSHeight(tBottomFrame)<0)
			tBottomFrame.size.height=0;
	}

	tBottomFrame.origin.x=0;
	tBottomFrame.origin.y=NSHeight(tTopFrame)+inSplitView.dividerThickness;
	tBottomFrame.size.width=NSWidth(tSplitViewFrame);
	
	tViewBottom.frame=tBottomFrame;
	
	
	tTopFrame.origin.x=0;
	tTopFrame.size.width=NSWidth(tSplitViewFrame);
	
	tViewTop.frame=tTopFrame;
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)inSubView
{
	return NO;
}

- (CGFloat)splitView:(NSSplitView *)inSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)inDividerIndex
{
	if (inDividerIndex==0)
		return PKGPresentationSectionInstallationTypeOutlineViewMinimumHeight;
	
	return 0;
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(PKGChoiceTreeNode *)inChoiceTreeNode
{
	if (inOutlineView!=self.outlineView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	NSTableCellView * tView=[inOutlineView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	if ([tTableColumnIdentifier isEqualToString:@"choice.name"]==YES)
	{
		PKGInstallationTypeCheckBox * tCheckBox=(PKGInstallationTypeCheckBox *)((PKGCheckboxTableCellView *)tView).checkbox;
		PKGInstallationTypeCheckBoxCell * tCheckBoxCell=tCheckBox.cell;
		BOOL tIsMergedPackageChoice=inChoiceTreeNode.isMergedIntoPackagesChoice;
		
		// Checkbox
		
		tCheckBox.imagePosition=(tIsMergedPackageChoice==YES) ? NSNoImage : NSImageLeft;
		
		tCheckBox.enabled=(inChoiceTreeNode.isEnabled && _editingChoicesDependencies==NO);
		
		PKGChoiceSelectedState tSelectedState=inChoiceTreeNode.selectedState;
		
		tCheckBox.state=(tSelectedState==PKGChoiceSelectedStateDependent) ? PKGChoiceSelectedStateOff : tSelectedState;
		
		tCheckBoxCell.invisible=inChoiceTreeNode.isInvisible;
		
		tCheckBoxCell.dependent=(tSelectedState==PKGChoiceSelectedStateDependent);
		
		// Label
		
		NSString * tStringValue=nil;
		BOOL tUsePackageName=NO;
        BOOL tReplaceKeys=YES;
        
		if (tIsMergedPackageChoice==YES || _showRawNames==YES)
		{
			tUsePackageName=YES;
		}
		else
		{
			tStringValue=[inChoiceTreeNode titleForLocalization:self.localization];
			
			if (tStringValue==nil)
				tUsePackageName=YES;
		}
		
		if (tUsePackageName==YES)
		{
			NSString * tPackageUUID=inChoiceTreeNode.packageUUID;
			
			if (tPackageUUID!=nil)
			{
				PKGPackageComponent * tPackageComponent=[_distributionProject packageComponentWithUUID:tPackageUUID];
				
				if (tPackageComponent!=nil)
                {
                    tStringValue=tPackageComponent.packageSettings.name;
                    
                    if (tPackageComponent.type==PKGPackageComponentTypeImported)
                        tReplaceKeys=NO;
                }
			}
		}
		
        if (tReplaceKeys==YES)
            tStringValue=[self stringByReplacingKeysInString:tStringValue];
        
		if (tStringValue==nil)
            tStringValue=[NSString stringWithFormat:@"Choice %@",[_dataSource indentationStringForItem:inChoiceTreeNode]];
        
		tCheckBox.title=tStringValue;
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"choice.action"]==YES)
	{
		tView.textField.stringValue=inChoiceTreeNode.choiceAction;
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"choice.size"]==YES)
	{
		tView.textField.stringValue=@"";
		
		return tView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:PKGPresentationSectionInstallationTypeIndentationColumnIdentifier]==YES)
	{
		tView.textField.stringValue=[_dataSource indentationStringForItem:inChoiceTreeNode];
		
		return tView;
	}

	return nil;
}

- (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)inOutlineView
{
	if (inOutlineView!=self.outlineView)
		return YES;
	
	return (_editingChoicesDependencies==NO);
}

- (void)outlineViewSelectionDidChange:(NSNotification *)inNotification
{
	NSIndexSet * tIndexSet=self.outlineView.selectedRowIndexes;
	
	if (tIndexSet.count!=1)
	{
		_descriptionTextView.string=@"";
		
		// Post Notification
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGInstallationHierarchySelectionDidChangeNotification
															object:self.document
														  userInfo:@{PKGInstallationHierarchySelectionTypeKey:@((tIndexSet.count==0) ? PKGInstallationHierarchySelectionEmpty: PKGInstallationHierarchySelectionMultiple)}];
		
		return;
	}
	
	PKGChoiceTreeNode * tSelectedChoiceTreeNode=[self.outlineView itemAtRow:self.outlineView.selectedRow];
	
	if (tSelectedChoiceTreeNode.isMergedIntoPackagesChoice==YES)
	{
		_descriptionTextView.string=@"";
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGInstallationHierarchySelectionDidChangeNotification
															object:self.document
														  userInfo:@{PKGInstallationHierarchySelectionTypeKey:@(PKGInstallationHierarchySelectionSingleNonEditable)}];
		
		return;
	}
	
	NSString * tLocalizedDescription=[self stringByReplacingKeysInString:[tSelectedChoiceTreeNode descriptionForLocalization:self.localization]];
	
	_descriptionTextView.string=(tLocalizedDescription==nil) ? @"" : [tLocalizedDescription copy];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGInstallationHierarchySelectionDidChangeNotification
														object:self.document
													  userInfo:@{PKGInstallationHierarchySelectionTypeKey:@(PKGInstallationHierarchySelectionSingle),
																 PKGInstallationHierarchySelectionItemKey:tSelectedChoiceTreeNode,
																 PKGInstallationHierarchyChoicesForestKey:((PKGInstallationHierarchy *)_settings.hierarchies[_currentHierarchyName]).choicesForest}];
}

- (void)outlineViewItemDidExpand:(NSNotification *)inNotification
{
	if (_restoringDiscloseStates==YES)
		return;
	
	if (inNotification.object!=self.outlineView)
		return;
	
	PKGChoiceTreeNode * tChoiceTreeNode=inNotification.userInfo[@"NSObject"];
	
	if (tChoiceTreeNode==nil)
		return;
	
	NSString * tChoiceUUID=tChoiceTreeNode.choiceUUID;
	
	if (tChoiceUUID==nil)
		return;
	
	NSString * tKey=[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey,self.currentHierarchyName];
		
	NSMutableDictionary * tDisclosedDictionary=self.documentRegistry[tKey];
		
	if (tDisclosedDictionary==nil)
	{
		tDisclosedDictionary=[NSMutableDictionary dictionary];
		self.documentRegistry[tKey]=tDisclosedDictionary;
	}
	
	tDisclosedDictionary[tChoiceUUID]=@(YES);
}

- (void)outlineViewItemWillCollapse:(NSNotification *)inNotification
{
	if (_restoringDiscloseStates==YES)
		return;
	
	if (inNotification.object!=self.outlineView)
		return;
	
	PKGChoiceTreeNode * tChoiceTreeNode=inNotification.userInfo[@"NSObject"];
	
	if (tChoiceTreeNode==nil)
		return;
	
	NSString * tChoiceUUID=tChoiceTreeNode.choiceUUID;
	
	if (tChoiceUUID==nil)
		return;
	
	NSString * tKey=[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey,self.currentHierarchyName];
	
	NSMutableDictionary * tDisclosedDictionary=self.documentRegistry[tKey];
	
	if (tDisclosedDictionary==nil)
		return;
	
	// Check whether the option/alt key is down or not
	
	NSEvent * tCurrentEvent=[NSApp currentEvent];
	
	if (tCurrentEvent==nil || ((tCurrentEvent.modifierFlags & WBEventModifierFlagOption)==0))
	{
		PKGChoiceTreeNode * tParentNode=tChoiceTreeNode;
		
		do
		{
			tParentNode=(PKGChoiceTreeNode *) [tParentNode parent];
			
			if (tParentNode==nil)
				break;
			
			NSString * tParentChoiceUUID=tParentNode.choiceUUID;
			
			NSNumber * tNumber=tDisclosedDictionary[tParentChoiceUUID];
			
			if (tNumber==nil || [tNumber boolValue]==NO)
			{
				// Parent is hidden
				
				return;
			}
		}
		while (1);
	}
	
	[tDisclosedDictionary removeObjectForKey:tChoiceUUID];
}

#pragma mark - PKGInstallationHierarchyDataSourceDelegate

- (NSMutableDictionary *)disclosedDictionary
{
	return self.documentRegistry[[NSString stringWithFormat:PKGPresentationSectionInstallationTypeHierarchyDisclosedStateFormatKey,self.currentHierarchyName]];
}

- (void)installationHierarchyDataDidChange:(PKGInstallationHierarchyDataSource *)inInstallationHierarchyDataSource
{
	[self noteDocumentHasChanged];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGInstallationHierarchyRemovedPackagesListDidChangeNotification
														object:self.document
													  userInfo:@{PKGInstallationHierarchyRemovedPackagesUUIDsKey:_dataSource.installationHierarchy.removedPackagesChoices.allKeys}];
}

#pragma mark - Notifications

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
    
    [self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.outlineView.numberOfRows)]
                                columnIndexes:[NSIndexSet indexSetWithIndex:[self.outlineView columnWithIdentifier:@"choice.name"]]];
    
    PKGChoiceTreeNode * tSelectedChoiceTreeNode=[self.outlineView itemAtRow:self.outlineView.selectedRow];
    
    if (tSelectedChoiceTreeNode.isMergedIntoPackagesChoice==YES)
    {
        _descriptionTextView.string=@"";
    }
    else
    {
        NSString * tLocalizedDescription=[self stringByReplacingKeysInString:[tSelectedChoiceTreeNode descriptionForLocalization:self.localization]];
        
        _descriptionTextView.string=(tLocalizedDescription==nil) ? @"" : [tLocalizedDescription copy];
    }
}


- (void)appleInternalModeDidChange:(NSNotification *)inNotification
{
	[self setHierarchyBoxHidden:([PKGApplicationPreferences sharedPreferences].appleMode==NO)];
}

- (void)installationTypeSettingsDidChange:(NSNotification *)inNotification
{
	// OutlineView
	
	[self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfRows)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfColumns)]];
	
	// Description
	
	PKGChoiceTreeNode * tSelectedChoiceTreeNode=[self.outlineView itemAtRow:self.outlineView.selectedRow];
	
	if (tSelectedChoiceTreeNode.isMergedIntoPackagesChoice==YES)
	{
		_descriptionTextView.string=@"";
	}
	else
	{
		NSString * tLocalizedDescription=[self stringByReplacingKeysInString:[tSelectedChoiceTreeNode descriptionForLocalization:self.localization]];
	
		_descriptionTextView.string=(tLocalizedDescription==nil) ? @"" : [tLocalizedDescription copy];
	}
}

- (void)choiceDependenciesEditionWillBegin:(NSNotification *)inNotification
{
	NSTableColumn * tTableColumn=[self.outlineView tableColumnWithIdentifier:@"choice.action"];
	tTableColumn.hidden=YES;
	
	tTableColumn=[self.outlineView tableColumnWithIdentifier:@"choice.size"];
	tTableColumn.hidden=YES;
	
	_indentationColumn.hidden=NO;
	
	[self.outlineView sizeLastColumnToFit];
	
	[self.outlineView unregisterDraggedTypes];
	
	_editingChoicesDependencies=YES;
	
	[self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfRows)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfColumns)]];
}

- (void)choiceDependenciesEditionDidEnd:(NSNotification *)inNotification
{
	NSTableColumn * tTableColumn=[self.outlineView tableColumnWithIdentifier:@"choice.action"];
	tTableColumn.hidden=NO;
	
	tTableColumn=[self.outlineView tableColumnWithIdentifier:@"choice.size"];
	tTableColumn.hidden=NO;
	
	_indentationColumn.hidden=YES;
	
	[self.outlineView registerForDraggedTypes:[PKGInstallationHierarchyDataSource supportedDraggedTypes]];
	
	_editingChoicesDependencies=NO;
	
	[self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfRows)] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.outlineView.numberOfColumns)]];
}

@end
