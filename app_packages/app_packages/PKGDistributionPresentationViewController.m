
#import "PKGDistributionPresentationViewController.h"

#import "PKGPresentationWindowView.h"

#import "PKGPresentationListView.h"

#import "PKGPresentationImageView.h"

#import "PKGRightInspectorView.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGPresentationTitleSettings.h"

#import "PKGPresentationLocalizableStepSettings+UI.h"

#import "PKGInstallerApp.h"

#import "PKGInstallerPlugin.h"

#import "PKGLocalizationUtilities.h"

#import "PKGLanguageConverter.h"

#import "NSAlert+block.h"

#import "NSIndexSet+Analysis.h"

#import "PKGPresentationPluginButton.h"

#import "PKGApplicationPreferences.h"

#import "PKGOwnershipAndReferenceStyleViewController.h"
#import "PKGOwnershipAndReferenceStylePanel.h"

@interface PKGDistributionPresentationOpenPanelDelegate : NSObject<NSOpenSavePanelDelegate>
{
	NSFileManager * _fileManager;
}

	@property NSArray * plugInsPaths;

@end

@implementation PKGDistributionPresentationOpenPanelDelegate

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_fileManager=[NSFileManager defaultManager];
	}
	
	return self;
}

- (BOOL)panel:(NSOpenPanel *)inPanel shouldEnableURL:(NSURL *)inURL
{
	if (inURL.isFileURL==NO)
		return NO;
	
	NSString * tPath=inURL.path;
	
	if ([tPath.pathExtension caseInsensitiveCompare:@"bundle"]==NSOrderedSame)
	{
		if ([self.plugInsPaths indexOfObjectPassingTest:^BOOL(NSString * bPlugInPath,NSUInteger bIndex,BOOL * bOutStop){
			
			return ([bPlugInPath caseInsensitiveCompare:tPath]==NSOrderedSame);
			
		}]!=NSNotFound)
			return NO;
		
		BOOL isDirectory;
		
		[_fileManager fileExistsAtPath:tPath isDirectory:&isDirectory];
		
		if (isDirectory==NO)
			return NO;
		
		NSBundle * tBundle=[NSBundle bundleWithPath:tPath];
		
		return [[tBundle objectForInfoDictionaryKey:@"InstallerSectionTitle"] isKindOfClass:NSString.class];
	}
	
	BOOL isDirectory;
	
	[_fileManager fileExistsAtPath:tPath isDirectory:&isDirectory];
	
	return (isDirectory==YES);
}

@end

NSString * const PKGDistributionPresentationCurrentPreviewLanguage=@"ui.project.presentation.preview.language";

NSString * const PKGDistributionPresentationSelectedStep=@"ui.project.presentation.step.selected";

NSString * const PKGDistributionPresentationSectionsInternalPboardType=@"fr.whitebox.packages.internal.distribution.presentation.sections";

@interface PKGDistributionPresentationViewController () <PKGPresentationImageViewDelegate,PKGPresentationListViewDataSource,PKGPresentationListViewDelegate>
{
	IBOutlet PKGPresentationWindowView * _windowView;
	
	IBOutlet PKGPresentationImageView * _backgroundView;
	
	IBOutlet PKGPresentationListView * _listView;
	
	IBOutlet NSTextField * _chapterTitleView;
	
	IBOutlet NSButton * _printButton;
	
	IBOutlet NSButton * _saveButton;
	
	IBOutlet NSButton * _goBackButton;
	
	IBOutlet NSButton * _continueButton;
	
	IBOutlet PKGRightInspectorView * _rightView;
	
	
	IBOutlet PKGPresentationPluginButton * _pluginAddButton;
	IBOutlet PKGPresentationPluginButton * _pluginRemoveButton;
	
	IBOutlet NSPopUpButton * _languagePreviewPopUpButton;
	
	
	PKGDistributionPresentationOpenPanelDelegate * _openPanelDelegate;
	
	NSArray * _supportedLocalizations;
	
	NSString * _currentPreviewLanguage;
	
	NSIndexSet * _internalDragData;
}

- (void)updateBackgroundView;
- (void)updateTitleViews;

- (IBAction)addPlugin:(id)sender;
- (IBAction)removePlugin:(id)sender;

- (IBAction)switchPreviewLanguage:(NSPopUpButton *)sender;

@end

@implementation PKGDistributionPresentationViewController

- (instancetype)initWithNibName:(NSString *)inNibName bundle:(NSBundle *)inBundle
{
	self=[super initWithNibName:inNibName bundle:inBundle];
	
	if (self!=nil)
	{
		_supportedLocalizations=[[PKGInstallerApp installerApp] supportedLocalizations];
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_backgroundView.presentationDelegate=self;
	
	_listView.dataSource=self;
	_listView.delegate=self;
	
	[_listView registerForDraggedTypes:@[PKGDistributionPresentationSectionsInternalPboardType,NSFilenamesPboardType]];
	
	// Plugin Buttons
	
	_pluginAddButton.pluginButtonType=PKGPlusButton;
	_pluginRemoveButton.pluginButtonType=PKGMinusButton;
	
	// Build the Preview In Menu
	
	NSMenu * tLanguagesMenu=_languagePreviewPopUpButton.menu;
	
	[tLanguagesMenu removeAllItems];
	
	[_supportedLocalizations enumerateObjectsUsingBlock:^(PKGInstallerAppLocalization * bLocalization, NSUInteger bIndex, BOOL *bOutStop) {
		
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:bLocalization.localizedName action:nil keyEquivalent:@""];
		tMenuItem.image=bLocalization.flagIcon;
		tMenuItem.tag=bIndex;
		
		[tLanguagesMenu addItem:tMenuItem];
	}];
	
	_languagePreviewPopUpButton.menu=tLanguagesMenu;
}

#pragma mark -

- (void)setDistributionProject:(PKGDistributionProject *)inDistributionProject
{
	if (_distributionProject!=inDistributionProject)
	{
		_distributionProject=inDistributionProject;
		
		[self refreshUI];
	}
}

- (void)setPresentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	if (_presentationSettings!=inPresentationSettings)
	{
		_presentationSettings=inPresentationSettings;
		
		[self.presentationSettings sections_safe];	// Useful to make sure there is a list of steps;
	
		[self refreshUI];
	}
}

#pragma mark -

- (void)updateBackgroundView
{
	void (^displayDefaultImage)() = ^{
		
		// A COMPLETER (check if image is shown on 10.8 or later)
		
		_backgroundView.image=nil;
	};
	
	void (^displayImageNotFound)() = ^{
		
		// A COMPLETER (find the ? image)
		
		_backgroundView.image=nil;
	};
	
	PKGPresentationBackgroundSettings * tBackgroundSettings=[_presentationSettings backgroundSettings_safe];
	
	if (tBackgroundSettings.showCustomImage==NO)
	{
		displayDefaultImage();
		
		return;
	}
	
	_backgroundView.imageAlignment=tBackgroundSettings.imageAlignment;
	_backgroundView.imageScaling=tBackgroundSettings.imageScaling;
	
	PKGFilePath * tFilePath=tBackgroundSettings.imagePath;
	
	if (tFilePath==nil)
	{
		displayDefaultImage();
		
		return;
	}
	
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tFilePath];
	
	if (tAbsolutePath==nil)
	{
		displayImageNotFound();
		
		return;
	}
	
	NSImage * tImage=[[NSImage alloc] initWithContentsOfFile:tAbsolutePath];
	
	if (tImage==nil)
	{
		displayImageNotFound();
		
		return;
	}
	
	_backgroundView.image=tImage;
}

- (void)updateTitleViews
{
	// Refresh Chapter Title View
	
	/*NSString * tPaneTitle=[currentViewController_ paneTitleForLanguage:currentPreviewLanguage_];
	
	_chapterTitleView.stringValue=(tPaneTitle!=nil) ? tPaneTitle : @"";*/
	
	// Refresh Fake Window Title
	
	PKGPresentationTitleSettings * tTitleSettings=[self.presentationSettings titleSettings_safe];
	
	NSString * tMostAppropriateLocalizedTitle=[tTitleSettings valueForLocalization:_currentPreviewLanguage exactMatch:NO];
	
	if (tMostAppropriateLocalizedTitle==nil)
		tMostAppropriateLocalizedTitle=self.document.fileURL.path.lastPathComponent.stringByDeletingPathExtension;
	
	if (tMostAppropriateLocalizedTitle!=nil)
	{
		NSString * tTitleFormat=[[PKGInstallerApp installerApp] localizedStringForKey:@"WindowTitle" localization:_currentPreviewLanguage];
		
		_windowView.title=(tTitleFormat!=nil) ? [NSString stringWithFormat:tTitleFormat,tMostAppropriateLocalizedTitle] : tMostAppropriateLocalizedTitle;
	}
	else
	{
		_windowView.title=@"-";
	}
}

- (void)refreshUI
{
	if (_backgroundView==nil)
		return;
	
	if (self.distributionProject!=nil)
	{
		// Proxy Icon
		
		NSImage * tImage=[[PKGInstallerApp installerApp] iconForPackageType:(self.distributionProject.isFlat==YES) ? PKGInstallerAppDistrbutionFlat : PKGInstallerAppDistributionBundle];
		
		_windowView.proxyIcon=tImage;
	}
	
	if (_presentationSettings!=nil)
	{
		// Background View
		
		[self updateBackgroundView];
		
		// A COMPLETER
		
		// Title Views
		
		[self updateTitleViews];
		
		// List View
		
		[_listView reloadData];
		
		// Language PopUpButton
		
		NSUInteger tLocalizationIndex=[_supportedLocalizations indexOfObjectPassingTest:^BOOL(PKGInstallerAppLocalization * bLocalization, NSUInteger bIndex, BOOL *bOutStop) {
		
			return [_currentPreviewLanguage isEqualToString:bLocalization.englishName];
			
		}];
		
		[_languagePreviewPopUpButton selectItemWithTag:(tLocalizationIndex!=NSNotFound) ? tLocalizationIndex : 0];
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_currentPreviewLanguage=self.documentRegistry[PKGDistributionPresentationCurrentPreviewLanguage];
	
	if (_currentPreviewLanguage==nil)
	{
		NSMutableArray * tEnglishLanguageNames=[PKGLocalizationUtilities englishLanguages];
		
		if (tEnglishLanguageNames!=nil)
		{
			NSArray * tPreferedLocalizations=(__bridge_transfer NSArray *) CFBundleCopyPreferredLocalizationsFromArray((__bridge CFArrayRef) tEnglishLanguageNames);
			
			if (tPreferedLocalizations.count>0)
				_currentPreviewLanguage=[tPreferedLocalizations.firstObject copy];
		}
		
		if (_currentPreviewLanguage==nil)
			_currentPreviewLanguage=@"English";
		
		if (_currentPreviewLanguage!=nil)
			self.documentRegistry[PKGDistributionPresentationCurrentPreviewLanguage]=[_currentPreviewLanguage copy];
	}
	
	[self refreshUI];
	
	// A COMPLETER
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// A COMPLETER
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidResignMainNotification object:self.view.window];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.view.window];
	
	// A COMPLETER
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	// A COMPLETER
}

#pragma mark -

- (IBAction)addPlugin:(id)sender
{
	NSMutableArray * tSections=self.presentationSettings.sections;
	
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.canChooseFiles=YES;
	tOpenPanel.canChooseDirectories=NO;
	tOpenPanel.allowsMultipleSelection=YES;
	
	_openPanelDelegate=[PKGDistributionPresentationOpenPanelDelegate new];
	
	_openPanelDelegate.plugInsPaths=[tSections WB_arrayByMappingObjectsLenientlyUsingBlock:^NSString *(PKGPresentationSection * bPresentationSection, NSUInteger bIndex) {
		
		PKGFilePath * tFilePath=bPresentationSection.pluginPath;
		
		if (tFilePath==nil)
			return nil;
		
		return [self.filePathConverter absolutePathForFilePath:tFilePath];
	}];
	
	tOpenPanel.delegate=_openPanelDelegate;
	
	tOpenPanel.prompt=NSLocalizedString(@"Add",@"No comment");
	
	__block PKGFilePathType tReferenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	PKGOwnershipAndReferenceStyleViewController * tOwnershipAndReferenceStyleViewController=nil;
	
	if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
	{
		tOwnershipAndReferenceStyleViewController=[PKGOwnershipAndReferenceStyleViewController new];
		
		tOwnershipAndReferenceStyleViewController.canChooseOwnerAndGroupOptions=NO;
		tOwnershipAndReferenceStyleViewController.referenceStyle=tReferenceStyle;
		
		NSView * tAccessoryView=tOwnershipAndReferenceStyleViewController.view;
		
		tOpenPanel.accessoryView=tAccessoryView;
	}
	
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult!=NSFileHandlingPanelOKButton)
			return;
		
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
			tReferenceStyle=tOwnershipAndReferenceStyleViewController.referenceStyle;
		
		NSArray * tPaths=[tOpenPanel.URLs WB_arrayByMappingObjectsUsingBlock:^(NSURL * bURL,NSUInteger bIndex){
			
			return bURL.path;
		}];
		
		__block BOOL tModified=NO;
		__block NSInteger tInsertionIndex=_listView.selectedStep+1;
		
		[tPaths enumerateObjectsUsingBlock:^(NSString * bPath, NSUInteger bIndex, BOOL *bOutStop) {
			
			NSBundle * tBundle=[NSBundle bundleWithPath:bPath];
			
			if (tBundle==nil)
			{
				// A COMPLETER
				
				return;
			}
			
			PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:bPath type:tReferenceStyle];
			
			if (tFilePath==nil)
			{
				// A COMPLETER
				
				return;
			}
			
			PKGPresentationSection * tPresentationSection=[[PKGPresentationSection alloc] initWithPluginPath:tFilePath];
			
			[tSections insertObject:tPresentationSection atIndex:tInsertionIndex];
			
			tInsertionIndex++;
			
			tModified=YES;
		}];
		
		if (tModified==YES)
		{
			[_listView reloadData];
			
			[self noteDocumentHasChanged];
		}
	}];
}

- (IBAction)removePlugin:(id)sender
{
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=NSLocalizedString(@"Do you really want to remove this Installer plugin?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert WB_beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		NSInteger tSelectedStep=_listView.selectedStep;
		
		if (tSelectedStep<0 || tSelectedStep>=self.presentationSettings.sections.count)
			return;
		
		[self.presentationSettings.sections removeObjectAtIndex:tSelectedStep];
		
		[_listView reloadData];
		
		// Find the first selectable Step
		
		NSInteger tIndex=tSelectedStep;
		
		if (tIndex==0)
		{
			[_listView selectStep:0];
		}
		else
		{
			tIndex=tSelectedStep-1;
			
			for (;tIndex>=0;tIndex--)
			{
				if ([self presentationListView:_listView shouldSelectStep:tIndex]==YES)
				{
					[_listView selectStep:tIndex];
					
					break;
				}
			}
		}
		
		// Refresh the list view
		
		[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:_listView]];
		
		[self noteDocumentHasChanged];
	}];
}

- (IBAction)switchPreviewLanguage:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	NSString * tNewLanguage=((PKGInstallerAppLocalization *)_supportedLocalizations[tTag]).englishName;
	
	if ([tNewLanguage isEqualToString:_currentPreviewLanguage]==NO)
	{
		_currentPreviewLanguage=[tNewLanguage copy];
		
		self.documentRegistry[PKGDistributionPresentationCurrentPreviewLanguage]=[_currentPreviewLanguage copy];
		
		// Refresh Window title and Pane title
		
		[self updateTitleViews];
		
		
		/*if (currentViewController_!=nil)
		{
			// Refresh Buttons
			
			[currentViewController_ prepareButtons:navigationButtonsArray_ forLanguage:_currentPreviewLanguage];
			
			// Refresh Pane View
			
			[currentViewController_ refreshViewForLanguage:_currentPreviewLanguage];
		}*/
		
		// Refresh List View
		
		[_listView reloadData];
	}
}

#pragma mark - PKGPresentationListViewDataSource

- (NSInteger)numberOfStepsInPresentationListView:(PKGPresentationListView *)inPresentationListView
{
	if (inPresentationListView!=_listView)
		return 0;
	
	return self.presentationSettings.sections.count;
}

- (id)presentationListView:(PKGPresentationListView *)inPresentationListView objectForStep:(NSInteger)inStep
{
	if (inPresentationListView!=_listView)
		return nil;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	if (tPresentationSection.pluginPath!=nil)
	{
		// It's a plugin step
		
		NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tPresentationSection.pluginPath];
		
		if (tAbsolutePath==nil)
		{
			// A COMPLETER
			
			return nil;
		}
		
		PKGInstallerPlugin * tInstallerPlugin=[[PKGInstallerPlugin alloc] initWithBundleAtPath:tAbsolutePath];
		
		if (tInstallerPlugin==nil)
		{
			return NSLocalizedStringFromTable(@"Not Found",@"Presentation",@"");
		}
		
		NSString * tSectionTitle=[tInstallerPlugin sectionTitleForLocalization:_currentPreviewLanguage];
		
		return (tSectionTitle!=nil) ? tSectionTitle : NSLocalizedStringFromTable(@"Not Found",@"Presentation",@"");
	}
	else
	{
		return [[[PKGInstallerApp installerApp] pluginWithSectionName:tPresentationSection.installerPluginName] sectionTitleForLocalization:_currentPreviewLanguage];
	}
	
	return nil;
}

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView writeStep:(NSInteger) inStep toPasteboard:(NSPasteboard*) inPasteboard
{
	if (_listView!=inPresentationListView)
		return NO;

	if (inStep<0 || inStep>=self.presentationSettings.sections.count)
		return NO;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	if (tPresentationSection.pluginPath==nil)
		return NO;
	
	_internalDragData=[NSIndexSet indexSetWithIndex:inStep];
	
	[inPasteboard declareTypes:@[PKGDistributionPresentationSectionsInternalPboardType] owner:self];
	
	[inPasteboard setData:[NSData data] forType:PKGDistributionPresentationSectionsInternalPboardType];
	
	return YES;
}

- (NSDragOperation)presentationListView:(PKGPresentationListView*)inPresentationListView validateDrop:(id <NSDraggingInfo>)info proposedStep:(NSInteger)inStep
{
	if (_listView!=inPresentationListView)
		return NSDragOperationNone;
	
	if (inStep<0 || inStep>=self.presentationSettings.sections.count)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[PKGDistributionPresentationSectionsInternalPboardType]]!=nil)
	{
		// We need to check it's an internal drag
		
		if (_listView==[info draggingSource])
		{
			// Check that the step is acceptable
			
			if ([_internalDragData WB_containsOnlyOneRange]==YES)
			{
				NSUInteger tFirstIndex=_internalDragData.firstIndex;
				NSUInteger tLastIndex=_internalDragData.lastIndex;
				
				if (inStep>=tFirstIndex && inStep<=(tLastIndex+1))
					return NSDragOperationNone;
			}
			else
			{
				if ([_internalDragData containsIndex:(inStep-1)]==YES)
					return NSDragOperationNone;
			}
			
			return NSDragOperationMove;
		}
		
		return NSDragOperationNone;
	}
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		// We need to check that the plugins are not already in the list
		
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tArray.count==0)
			return NSDragOperationNone;
		
		NSMutableArray * tExistingPlugins=[self.presentationSettings.sections WB_arrayByMappingObjectsLenientlyUsingBlock:^NSString *(PKGPresentationSection * bPresentationSection, NSUInteger bIndex) {
			
			PKGFilePath * tFilePath=bPresentationSection.pluginPath;
			
			if (tFilePath==nil)
				return nil;
			
			return [self.filePathConverter absolutePathForFilePath:tFilePath];
		}];
		
		NSFileManager * tFileManager=[NSFileManager defaultManager];
		
		for(NSString * tPath in tArray)
		{
			if ([tPath.pathExtension caseInsensitiveCompare:@"bundle"]!=NSOrderedSame)
				return NSDragOperationNone;
			
			if ([tExistingPlugins indexOfObjectPassingTest:^BOOL(NSString * bPlugInPath,NSUInteger bIndex,BOOL * bOutStop){
				
				return ([bPlugInPath caseInsensitiveCompare:tPath]==NSOrderedSame);
				
			}]!=NSNotFound)
				return NSDragOperationNone;
				
			BOOL isDirectory;
			
			[tFileManager fileExistsAtPath:tPath isDirectory:&isDirectory];
			
			if (isDirectory==NO)
				return NSDragOperationNone;
				
			NSBundle * tBundle=[NSBundle bundleWithPath:tPath];
			
			if ([[tBundle objectForInfoDictionaryKey:@"InstallerSectionTitle"] isKindOfClass:NSString.class]==NO)
				return NSDragOperationNone;
		}
		
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (BOOL)presentationListView:(PKGPresentationListView*)inPresentationListView acceptDrop:(id <NSDraggingInfo>)info step:(NSInteger)inStep
{
	if (_listView!=inPresentationListView)
		return NO;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
		
	if ([tPasteBoard availableTypeFromArray:@[PKGDistributionPresentationSectionsInternalPboardType]]!=nil)
	{
		// Switch Position of Installer Plugin
		
		NSArray * tSections=[self.presentationSettings.sections objectsAtIndexes:_internalDragData];
		
		[self.presentationSettings.sections removeObjectsAtIndexes:_internalDragData];
		
		NSUInteger tIndex=[_internalDragData firstIndex];
		
		while (tIndex!=NSNotFound)
		{
			if (tIndex<inStep)
				inStep--;
			
			tIndex=[_internalDragData indexGreaterThanIndex:tIndex];
		}
		
		NSIndexSet * tNewIndexSet=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inStep, _internalDragData.count)];
		
		[self.presentationSettings.sections insertObjects:tSections atIndexes:tNewIndexSet];
		
		_internalDragData=nil;
		
		// Refresh the list view
		
		[_listView reloadData];
		
		[_listView selectStep:inStep];
				
		[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:_listView]];
				
		[self noteDocumentHasChanged];
		
		return YES;
	}
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		// Add Installer Plugins
		
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		BOOL (^importPlugins)(PKGFilePathType) = ^BOOL(PKGFilePathType bPathType) {
		
			NSArray * tNewSections=[tArray WB_arrayByMappingObjectsUsingBlock:^id(NSString * bPath, NSUInteger bIndex) {
				
				PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:bPath type:bPathType];
				
				return [[PKGPresentationSection alloc] initWithPluginPath:tFilePath];
			}];
			
			if (tNewSections==nil)
				return NO;
			
			[self.presentationSettings.sections insertObjects:tNewSections atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inStep, tNewSections.count)]];
			
			// Refresh the list view
			
			[_listView reloadData];
			
			[_listView selectStep:inStep];
			
			[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:_listView]];
			
			[self noteDocumentHasChanged];
			
			/*if ([tArray count]==1)
			{
				[IBinstallationStepsView_ selectStepAtIndex:inStep];
				
				[self presentationListViewSelectionDidChange:[NSNotification notificationWithName:PKGPresentationListViewSelectionDidChangeNotification object:_listView]];
			}
			else
			{
				[[IBinstallationStepsView_ window] invalidateCursorRectsForView:IBinstallationStepsView_];
				
				[IBinstallationStepsView_ setNeedsDisplay:YES];
			}*/
			
			[self noteDocumentHasChanged];
			
			return YES;
		};
		
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==NO)
			return importPlugins([PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle);
		
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		 
		tPanel.canChooseOwnerAndGroupOptions=NO;
		tPanel.keepOwnerAndGroup=NO;
		tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		 
		[tPanel beginSheetModalForWindow:_listView.window completionHandler:^(NSInteger bReturnCode){
			
			if (bReturnCode==PKGOwnershipAndReferenceStylePanelCancelButton)
				return;
			
			importPlugins(tPanel.referenceStyle);
		}];
		
		return YES;		// It may at the end not be accepted by the completion handler from the sheet
	}
	
	return NO;
}

#pragma mark - PKGPresentationListViewDelegate

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView shouldSelectStep:(NSInteger)inStep
{
	if (inPresentationListView!=_listView)
		return YES;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	return  ([tPresentationSection.name isEqualToString:PKGPresentationSectionTargetName]==NO &&
			 [tPresentationSection.name isEqualToString:PKGPresentationSectionInstallName]==NO);
}

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView stepWillBeVisible:(NSInteger)inStep
{
	if (inPresentationListView!=_listView)
		return YES;
	
	PKGPresentationSection * tPresentationSection=self.presentationSettings.sections[inStep];
	
	if (tPresentationSection.pluginPath!=nil)
		return YES;
	
	if ([tPresentationSection.name isEqualToString:PKGPresentationSectionReadMeName]==YES)
	{
		return [self.presentationSettings readMeSettings_safe].isCustomized;
	}
	
	if ([tPresentationSection.name isEqualToString:PKGPresentationSectionLicenseName]==YES)
	{
		return [self.presentationSettings licenseSettings_safe].isCustomized;
	}
	
	return YES;
}

#pragma mark - PKGPresentationImageViewDelegate

- (void)presentationImageView:(PKGPresentationImageView *)inImageView imagePathDidChange:(NSString *)inPath
{
	// A COMPLETER
}

#pragma mark - Notifications

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	/*if ([[currentViewController_ className] isEqualToString:@"ICPresentationViewInstallerPluginController"]==YES)
	{
		// Refresh Chapter Title View
		
		NSString * tPaneTitle=[currentViewController_ paneTitleForLanguage:_currentPreviewLanguage];
		
		[IBchapterTitleView_ setStringValue:(tPaneTitle!=nil) ? tPaneTitle : @""];
	}*/
	
	// Refresh Background
	
	[self updateBackgroundView];
}

- (void)presentationListViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=_listView)
		return;
	
	NSInteger tSelectedStep=_listView.selectedStep;
	
	if (tSelectedStep<0 || tSelectedStep>=self.presentationSettings.sections.count)
		return;
	
	PKGPresentationSection * tSelectedPresentationSection=self.presentationSettings.sections[tSelectedStep];
	
	_pluginRemoveButton.enabled=(tSelectedPresentationSection.pluginPath!=nil);
	
	// A COMPLETER
}

@end
