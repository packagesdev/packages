/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationLocalizationsFilePathViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGPresentationStepSettings+UI.h"
#import "PKGPresentationLocalizableStepSettings+UI.h"

#import "PKGPopUpButtonTableCellView.h"

#import "PKGLocalizationUtilities.h"

#import "NSTableView+Selection.h"

#import "NSFileManager+FileTypes.h"

typedef NS_ENUM(NSUInteger, PKGLocalizationFilePathMenuActionType) {
	PKGLocalizationFilePathMenuActionTypeNone=-1,
	PKGLocalizationFilePathMenuActionTypeOpenWithFinder=1,
	PKGLocalizationFilePathMenuActionTypeShowInFinder=2,
	PKGLocalizationFilePathMenuActionTypeChoose=3
};

#define PKGLocalizationFilePathMenuActionSeparatorTag	-2

@interface PKGPresentationLocalizationsFilePathOpenPanelDelegate : NSObject<NSOpenSavePanelDelegate>
{
	NSFileManager * _fileManager;
}

@end

@implementation PKGPresentationLocalizationsFilePathOpenPanelDelegate

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_fileManager=[NSFileManager defaultManager];
	}
	
	return self;
}

#pragma mark -

- (BOOL)panel:(NSOpenPanel *)inPanel shouldEnableURL:(NSURL *)inURL
{
	if (inURL.isFileURL==NO)
		return NO;
	
	NSString * tPath=inURL.path;
	
	BOOL tIsDirectory=NO;
	
	[_fileManager fileExistsAtPath:tPath isDirectory:&tIsDirectory];
	
	if (tIsDirectory==YES)
		return YES;
	
	BOOL tTextDocumentFormatSupported=[_fileManager WB_fileAtPath:tPath matchesTypes:[PKGPresentationLocalizableStepSettings textDocumentTypes]];
	
	if (tTextDocumentFormatSupported==YES)
		return YES;
	
	return tTextDocumentFormatSupported;
}

@end

@interface PKGPresentationLocalizationsFilePathViewController () <NSTableViewDelegate>
{
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	
	IBOutlet NSView * _warningDisparateDocumentsTypesView;
	
	PKGPresentationLocalizationsFilePathOpenPanelDelegate * _openPanelDelegate;
}

	@property (readwrite) IBOutlet NSTableView * tableView;

- (IBAction)switchLanguage:(id)sender;

- (IBAction)switchPathType:(id)sender;

- (IBAction)pathAction:(id)sender;

- (IBAction)addLocalization:(id)sender;
- (IBAction)delete:(id)sender;

// Notifications

- (void)windowStateDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationLocalizationsFilePathViewController

- (void)setDataSource:(PKGPresentationLocalizationsFilePathDataSource *)inDataSource
{
	if (_dataSource==inDataSource)
		return;
	
	_dataSource=inDataSource;
	
	if (self.tableView!=nil)
		self.tableView.dataSource=inDataSource;
}

#pragma mark -

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_warningDisparateDocumentsTypesView.hidden=YES;
	
	self.tableView.delegate=self;
	
	[self.tableView registerForDraggedTypes:[PKGPresentationLocalizationsFilePathDataSource supportedDraggedTypes]];
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	self.tableView.dataSource=self.dataSource;
	
	[self refreshUI];
	
	_warningDisparateDocumentsTypesView.hidden=[self.dataSource sameFileTypeForAllLocalizations];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidResignMainNotification object:self.view.window];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.view.window];
}

- (void)refreshUI
{
	[self.tableView reloadData];
	
	_addButton.enabled=(_dataSource.localizations.count<[PKGLocalizationUtilities englishLanguages].count);
}

#pragma mark -

- (IBAction)switchLanguage:(NSPopUpButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	[_dataSource tableView:self.tableView setLanguageTag:sender.selectedTag forItemAtRow:tEditedRow];
}

- (IBAction)switchPathType:(NSPopUpButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGFilePath * tFilePath=[_dataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	if (tFilePath==nil)
		return;
	
	NSInteger tTag=sender.selectedItem.tag;
	
	if (tTag==tFilePath.type)
		return;
	
	tFilePath.type=tTag;
	
	[_dataSource tableView:self.tableView setValue:tFilePath forItemAtRow:tEditedRow];
}

- (IBAction)pathAction:(NSPopUpButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGLocalizationFilePathMenuActionType tActionType=sender.selectedItem.tag;
	
	if (tActionType==PKGLocalizationFilePathMenuActionTypeNone)
		return;
	
	PKGFilePath * tFilePath=[_dataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	if (tFilePath==nil)
		return;
	
	NSString * tAbsolutePath=(tFilePath.isSet==YES) ? [self.filePathConverter absolutePathForFilePath:tFilePath] : nil;
	
	switch(tActionType)
	{
		case PKGLocalizationFilePathMenuActionTypeOpenWithFinder:
		{
			if (tAbsolutePath!=nil)
				[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:tAbsolutePath]];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[sender selectItemAtIndex:0];
			});
			
			return;
		}
			
		case PKGLocalizationFilePathMenuActionTypeShowInFinder:
		{
			if (tAbsolutePath!=nil)
				[[NSWorkspace sharedWorkspace] selectFile:tAbsolutePath inFileViewerRootedAtPath:@""];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[sender selectItemAtIndex:0];
			});
			
			return;
		}
			
		default:
			
			break;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		
		NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
		
		tOpenPanel.canChooseFiles=YES;
		tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
		
		self->_openPanelDelegate=[PKGPresentationLocalizationsFilePathOpenPanelDelegate new];
		
		tOpenPanel.delegate=self->_openPanelDelegate;
		
		if (tAbsolutePath!=nil)
			tOpenPanel.directoryURL=[NSURL fileURLWithPath:[tAbsolutePath stringByDeletingLastPathComponent] isDirectory:YES];
		
		[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
			
			if (bResult!=WBFileHandlingPanelOKButton)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					
					[sender selectItemAtIndex:0];
				});
				
				return;
			}
			
			NSArray * tPaths=[tOpenPanel.URLs WB_arrayByMappingObjectsUsingBlock:^(NSURL * bURL,NSUInteger bIndex){
				
				return bURL.path;
			}];
			
			PKGFilePath * tNewFilePath=[self.filePathConverter filePathForAbsolutePath:tPaths[0] type:tFilePath.type];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[self->_dataSource tableView:self.tableView setValue:tNewFilePath forItemAtRow:tEditedRow];
				
				[sender selectItemAtIndex:0];
			});
		}];
	});
}

- (IBAction)addLocalization:(id)sender
{
	[self.view.window makeFirstResponder:self.tableView];
	
	[_dataSource addNewItem:self.tableView];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=(tIndexSet.count==1) ? NSLocalizedString(@"Do you really want to remove this localization?",@"No comment") : NSLocalizedString(@"Do you really want to remove these localizations?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		[self->_dataSource tableView:self.tableView removeItemsAtIndexes:tIndexSet];
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *) inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(delete:))
	{
		NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
		
		return (tIndexSet.count>0);
	}
	
	if (tAction==@selector(switchLanguage:))
	{
		if (inMenuItem.state==WBControlStateValueOn)
			return YES;
		
		return ([[_dataSource availableLanguageTagsSet] containsIndex:inMenuItem.tag]==YES);
	}
	
	return YES;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	
	if ([tTableColumnIdentifier isEqualToString:@"item.language"]==YES)
	{
		PKGPopUpButtonTableCellView * tLanguageView=(PKGPopUpButtonTableCellView *)[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		NSString * tLanguage=[_dataSource tableView:self.tableView languageAtRow:inRow];
		
		NSUInteger tIndex=[[PKGLocalizationUtilities englishLanguages] indexOfObject:tLanguage];
		
		if (tIndex==NSNotFound)
			return nil;
		
		[tLanguageView.popUpButton selectItemWithTag:tIndex];
		
		return tLanguageView;
	}
	
	PKGFilePath * tFilePath=[_dataSource tableView:self.tableView itemAtRow:inRow];
	
	if (tFilePath==nil)
		return nil;
	
	if ([tTableColumnIdentifier isEqualToString:@"path.type"]==YES)
	{
		PKGPopUpButtonTableCellView * tTypeView=(PKGPopUpButtonTableCellView *)[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		[tTypeView.popUpButton selectItemWithTag:tFilePath.type];
		
		return tTypeView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"path.string"]==YES)
	{
		PKGPopUpButtonTableCellView * tTypeView=(PKGPopUpButtonTableCellView *)[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		NSMenu * tMenu=tTypeView.popUpButton.menu;
		
		tTypeView.popUpButton.toolTip=nil;
		
		BOOL tShowAdditionalActions=NO;
		
		if (tFilePath.isSet==YES)
		{
			tTypeView.popUpButton.toolTip=tFilePath.string;
			
			
			
			NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tFilePath];
			
			if (tAbsolutePath!=nil && [[NSFileManager defaultManager] fileExistsAtPath:tAbsolutePath]==YES)
			{
				tShowAdditionalActions=YES;
				[tMenu itemWithTag:PKGLocalizationFilePathMenuActionTypeNone].attributedTitle=[[NSAttributedString alloc] initWithString:tFilePath.string.lastPathComponent
																															  attributes:@{NSForegroundColorAttributeName:[NSColor controlTextColor]}];
			}
			else
			{
				[tMenu itemWithTag:PKGLocalizationFilePathMenuActionTypeNone].attributedTitle=[[NSAttributedString alloc] initWithString:tFilePath.string.lastPathComponent
																															  attributes:@{NSForegroundColorAttributeName:[NSColor redColor]}];
			}
		}
		else
		{
			[tMenu itemWithTag:PKGLocalizationFilePathMenuActionTypeNone].attributedTitle=nil;	// Needed to work around a bug in AppKit.
			[tMenu itemWithTag:PKGLocalizationFilePathMenuActionTypeNone].title=@"-";
		}
		
		[tMenu itemWithTag:PKGLocalizationFilePathMenuActionTypeOpenWithFinder].hidden=!tShowAdditionalActions;
		[tMenu itemWithTag:PKGLocalizationFilePathMenuActionTypeShowInFinder].hidden=!tShowAdditionalActions;
		[tMenu itemWithTag:PKGLocalizationFilePathMenuActionSeparatorTag].hidden=!tShowAdditionalActions;
		
		return tTypeView;
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=self.tableView)
		return;
	
	_addButton.enabled=(_dataSource.localizations.count<[PKGLocalizationUtilities englishLanguages].count);
	
	NSIndexSet * tSelectionIndexSet=self.tableView.selectedRowIndexes;
	
	// Delete button state
	
	_removeButton.enabled=(tSelectionIndexSet.count>0);
}

// Notifications

- (void)localizationsDidChange:(NSNotification *)inNotification
{
	_warningDisparateDocumentsTypesView.hidden=[self.dataSource sameFileTypeForAllLocalizations];
}

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	[self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.tableView numberOfRows])] columnIndexes:[NSIndexSet indexSetWithIndex:[self.tableView columnWithIdentifier:@"path.string"]]];
}

@end
