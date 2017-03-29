/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementViewControllerFiles.h"

#import "PKGRequirement_Files+Constants.h"

#import "PKGAbsolutePathFormatter.h"

#import "NSArray+WBExtensions.h"
#import "NSTableView+Selection.h"

@interface PKGRequirementViewControllerFiles () <NSTableViewDataSource,NSTableViewDelegate,NSTextFieldDelegate>
{
	IBOutlet NSPopUpButton * _selectorPopupButton;
	
	IBOutlet NSPopUpButton * _conditionPopupButton;
	
	IBOutlet NSPopUpButton * _diskTypePopupButton;
	
	IBOutlet NSTableView * _tableView;
	
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
	
	// Data
	
	PKGAbsolutePathFormatter * _cachedFormatter;
	
	NSMutableArray * _cachedFiles;
	
	NSMutableDictionary * _settings;
}

- (void)_mergeFiles:(NSArray *)inPaths;

- (void)_removeSelectedFiles;


- (IBAction)switchSelector:(id)sender;

- (IBAction)switchCondition:(id)sender;

- (IBAction)switchDiskType:(id)sender;

- (IBAction)setFilePath:(id)sender;


- (IBAction)addFile:(id)sender;

- (IBAction)addExistingFile:(id)sender;

- (IBAction)delete:(id)sender;

@end


@implementation PKGRequirementViewControllerFiles

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_cachedFormatter=[PKGAbsolutePathFormatter new];
	}
	
	return self;
}

#pragma mark -

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	[_tableView registerForDraggedTypes:@[NSFilenamesPboardType]];
}

#pragma mark -

- (void)setSettings:(NSDictionary *)inSettings
{
	_settings=[inSettings mutableCopy];
	
	[self refreshUI];
}

- (NSDictionary *)settings
{
	return [_settings copy];
}

#pragma mark -

- (void)refreshUI
{
	NSInteger tTag;
	
	// Selector
	
	NSNumber * tNumber=_settings[PKGRequirementFilesSelectorKey];
	
	tTag=(tNumber==nil) ? PKGRequirementFilesSelectorAny : [tNumber integerValue];
	
	[_selectorPopupButton selectItemWithTag:tTag];
	
	// Condition
	
	tNumber=_settings[PKGRequirementFilesConditionKey];
	
	tTag=(tNumber==nil) ? PKGRequirementFilesConditionExist : [tNumber integerValue];
	
	[_conditionPopupButton selectItemWithTag:tTag];
	
	// Disk Type
	
	tNumber=_settings[PKGRequirementFilesTargetDiskKey];
	
	tTag=(tNumber==nil) ? PKGRequirementFilesTargetDestinationDisk : [tNumber integerValue];

	[_diskTypePopupButton selectItemWithTag:tTag];
	
	// Files
	
	_cachedFiles=[_settings[PKGRequirementFilesListKey] mutableCopy];
	
	[_cachedFiles sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	_addButton.enabled=YES;
	_removeButton.enabled=NO;
	
	[_tableView reloadData];
	
	[_tableView deselectAll:self];
}

#pragma mark -

- (NSDictionary *)defaultSettings
{
	return @{PKGRequirementFilesSelectorKey:@(PKGRequirementFilesSelectorAny),
			 PKGRequirementFilesConditionKey:@(PKGRequirementFilesConditionExist),
			 PKGRequirementFilesTargetDiskKey:@(PKGRequirementFilesTargetDestinationDisk),
			 PKGRequirementFilesListKey:@[]};
}

- (PKGRequirementType)requirementType
{
	NSNumber * tNumber=_settings[PKGRequirementFilesTargetDiskKey];
	
	if (tNumber!=nil)
	{
		NSInteger tDiskType=[tNumber integerValue];
		
		if (tDiskType==PKGRequirementFilesTargetStartupDisk)
			return PKGRequirementTypeInstallation;
		
		if (tDiskType==PKGRequirementFilesTargetDestinationDisk)
			return PKGRequirementTypeTarget;
	}
	
	return PKGRequirementTypeUndefined;
}

#pragma mark -

- (NSView *)previousKeyView
{
	return _tableView;
}

- (void)setNextKeyView:(NSView *) inView
{
	_tableView.nextKeyView=inView;
}

#pragma mark -

- (void)_mergeFiles:(NSArray *)inPaths
{
	if (inPaths.count==0)
		return;
	
	NSUInteger tCount=_cachedFiles.count;
	
	[_cachedFiles WB_mergeWithArray:inPaths];
	
	if (_cachedFiles.count==tCount)
		return;
	
	[_cachedFiles sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	[_tableView deselectAll:self];
	
	[_tableView reloadData];
	
	NSIndexSet * tIndexSet=[_cachedFiles indexesOfObjectsPassingTest:^BOOL(NSString * bPath,NSUInteger bIndex,BOOL * bOutStop) {
	
		return [inPaths containsObject:bPath];
	
	}];
	
	[_tableView selectRowIndexes:tIndexSet byExtendingSelection:NO];
	
	[_removeButton setEnabled:NO];
}

- (void)_removeSelectedFiles
{
	NSIndexSet * tIndexSet=[_tableView selectedRowIndexes];
	
	[_tableView deselectAll:self];
	
	if (tIndexSet!=nil)
	{
		[_cachedFiles removeObjectsAtIndexes:tIndexSet];
		
		[_tableView reloadData];
		
		[_removeButton setEnabled:NO];
	}
}

#pragma mark -

- (IBAction)switchSelector:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementFilesSelectorKey]=@(tTag);
}

- (IBAction)switchCondition:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementFilesConditionKey]=@(tTag);
}

- (IBAction)switchDiskType:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementFilesTargetDiskKey]=@(tTag);
	
	[self noteCheckTypeChange];
}

- (IBAction)setFilePath:(NSTextField *)sender
{
	NSUInteger tEditedRow=[_tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;

	NSString * tNewFilePath=sender.stringValue;
	
	NSUInteger tIndex=[_cachedFiles indexOfObject:tNewFilePath];
	
	if (tIndex==tEditedRow)
		return;
	
	if (tIndex!=NSNotFound)
	{
		NSBeep();
		
		[_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tEditedRow] columnIndexes:[NSIndexSet indexSetWithIndex:[_tableView columnWithIdentifier:@"file.path"]]];
		
		return;
	}
	
	_cachedFiles[tEditedRow]=tNewFilePath;
	
	[_cachedFiles sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	[_tableView deselectAll:self];
	
	[_tableView reloadData];
	
	[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_cachedFiles indexOfObject:tNewFilePath]] byExtendingSelection:NO];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(delete:))
	{
		NSIndexSet * tIndexSet=_tableView.WB_selectedOrClickedRowIndexes;
		
		return (tIndexSet.count>0);
	}
	
	return YES;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView==_tableView)
		return _cachedFiles.count;
	
	return 0;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=_tableView || inTableColumn==nil)
		return nil;
	
	if (inRow>=_cachedFiles.count)
		return nil;
	
	NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:@"file.path" owner:self];
	
	tTableCellView.textField.editable=YES;
	tTableCellView.textField.formatter=_cachedFormatter;
	tTableCellView.textField.stringValue=_cachedFiles[inRow];
	tTableCellView.textField.delegate=self;
	
	return tTableCellView;
}

- (void)control:(NSControl *) inControl didFailToValidatePartialString:(NSString *) inPartialString errorDescription:(NSString *) inError
{
	if (inError!=nil && [inError isEqualToString:@"NSBeep"]==YES)
		NSBeep();
}

#pragma mark -

- (NSDragOperation)tableView:(NSTableView*)inTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)inRow proposedDropOperation:(NSTableViewDropOperation)inOperation
{
	if (inTableView!=_tableView || _cachedFiles==nil)
		return NSDragOperationNone;

	NSPasteboard * tPasteBoard=[info draggingPasteboard];

	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
					
		for(NSString * tPath in tArray)
		{
			if ([_cachedFiles containsObject:tPath]==NO)
			{
				[_tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
				
				return NSDragOperationCopy;
			}
		}
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*) inTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)inRow dropOperation:(NSTableViewDropOperation)inOperation
{
	if (inTableView!=_tableView || _cachedFiles==nil)
		return NO;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];

	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		NSArray * tArray=[tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		[self _mergeFiles:tArray];
		
		return YES;
	}
	
	return NO;
}

#pragma mark -

- (void)optionKeyStateDidChange:(BOOL)isOptionKeyPressed
{
	if (isOptionKeyPressed==YES)
		[_addButton setAction:@selector(addExistingFile:)];
	else
		[_addButton setAction:@selector(addFile:)];
}

- (IBAction)addFile:(id) sender
{
	NSUInteger tRowIndex=_cachedFiles.count;

	[_cachedFiles addObject:@"/"];
	
	[_tableView deselectAll:self];
			
	[_tableView reloadData];
	
	[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRowIndex] byExtendingSelection:NO];
				
	[_tableView editColumn:0 row:tRowIndex withEvent:nil select:YES];
}

- (IBAction)addExistingFile:(id) sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];

	NSString * tLabel=NSLocalizedStringFromTableInBundle(@"Add",@"Localizable",[NSBundle bundleForClass:[self class]],@"No comment");
	
	tOpenPanel.canChooseDirectories=YES;
	tOpenPanel.showsHiddenFiles=YES;
	tOpenPanel.title=tLabel;
	tOpenPanel.prompt=tLabel;
	tOpenPanel.allowsMultipleSelection=YES;

	[tOpenPanel beginWithCompletionHandler:^(NSInteger bResult){
	
		if (bResult!=NSFileHandlingPanelOKButton)
			return;
		
		NSArray * tPaths=[tOpenPanel.URLs WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSURL * bURL,NSUInteger bIndex){
		
			if (bURL.isFileURL==NO)
				return nil;
			
			return bURL.path;
				
		}];
		
		[self _mergeFiles:tPaths];
	}];
}

- (IBAction)delete:(id)sender
{
	NSAlert * tAlert=[NSAlert new];
	
	if ([_tableView numberOfSelectedRows]==1)
		tAlert.messageText=NSLocalizedStringFromTableInBundle(@"Do you really want to remove this item?",@"Localizable",[NSBundle bundleForClass:[self class]],@"No comment");
	else
		tAlert.messageText=NSLocalizedStringFromTableInBundle(@"Do you really want to remove these items?",@"Localizable",[NSBundle bundleForClass:[self class]],@"No comment");
	
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	if ([tAlert runModal]==NSAlertFirstButtonReturn)
		[self _removeSelectedFiles];
}

#pragma mark - Notifications

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
    if (inNotification.object==_tableView)
		_removeButton.enabled=(_tableView.numberOfSelectedRows!=0);
}

@end
