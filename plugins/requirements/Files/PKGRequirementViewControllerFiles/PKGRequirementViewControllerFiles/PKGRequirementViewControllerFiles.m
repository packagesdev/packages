#import "PKGRequirementViewControllerFiles.h"

#import "PKGRequirement_Files+Constants.h"

#import "PKGAbsolutePathFormatter.h"

#import "NSArray+WBExtensions.h"

@interface PKGRequirementViewControllerFiles ()
{
	IBOutlet NSPopUpButton * _selectorPopupButton;
	
	IBOutlet NSPopUpButton * _conditionPopupButton;
	
	IBOutlet NSPopUpButton * _diskTypePopupButton;
	
	IBOutlet NSTableView * _tableView;
	
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
	
	// Data
	
	NSMutableArray * _cachedFiles;
}

- (void)_mergeFiles:(NSArray *)inPaths;

- (void)_removeSelectedFiles;


- (IBAction)switchSelector:(id) sender;

- (IBAction)switchCondition:(id) sender;

- (IBAction)switchDiskType:(id) sender;


- (IBAction)addFile:(id) sender;

- (IBAction)addExistingFile:(id) sender;

- (IBAction)removeFile:(id) sender;

@end


@implementation PKGRequirementViewControllerFiles

- (NSString *)nibName
{
	return @"MainView";
}

- (void)awakeFromNib
{
	// Path Names
    
    NSTableColumn * tTableColumn = [_tableView tableColumnWithIdentifier:@"Path"];
	
	if (tTableColumn!=nil)
	{
		NSCell * tTextFieldCell= [tTableColumn dataCell];
		
		if (tTextFieldCell!=nil)
		{
			PKGAbsolutePathFormatter * tFormatter=[PKGAbsolutePathFormatter new];
			
			[tTextFieldCell setFormatter:tFormatter];
			
			[tTextFieldCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
		}
	}
	
	[_tableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

- (void)updateUI
{
	NSNumber * tNumber;
	NSInteger tTag;
	
	// Selector
	
	tNumber=self.settings[PKGRequirementFilesSelectorKey];
	
	tTag=(tNumber==nil) ? PKGRequirementFilesSelectorAny : [tNumber integerValue];
	
	[_selectorPopupButton selectItemWithTag:tTag];
	
	// Condition
	
	tNumber=self.settings[PKGRequirementFilesConditionKey];
	
	tTag=(tNumber==nil) ? PKGRequirementFilesConditionExist : [tNumber integerValue];
	
	[_conditionPopupButton selectItemWithTag:tTag];
	
	// Disk Type
	
	tNumber=self.settings[PKGRequirementFilesTargetDiskKey];
	
	tTag=(tNumber==nil) ? PKGRequirementFilesTargetDestinationDisk : [tNumber integerValue];

	[_diskTypePopupButton selectItemWithTag:tTag];
	
	// Files
	
	_cachedFiles=[self.settings[PKGRequirementFilesListKey] mutableCopy];
	
	[_cachedFiles sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	[_addButton setEnabled:YES];
	
	[_removeButton setEnabled:NO];
	
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
	NSNumber * tNumber=self.settings[PKGRequirementFilesTargetDiskKey];
	
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
	[_tableView setNextKeyView:inView];
}

#pragma mark -

- (void)_mergeFiles:(NSArray *)inPaths
{
	if ([inPaths count]==0)
		return;
	
	NSUInteger tCount=[_cachedFiles count];
	
	[_cachedFiles WB_mergeWithArray:inPaths];
	
	if ([_cachedFiles count]==tCount)
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

- (IBAction)switchSelector:(id) sender
{
	NSInteger tTag=[[sender selectedItem] tag];
	
	self.settings[PKGRequirementFilesSelectorKey]=@(tTag);
}

- (IBAction)switchCondition:(id) sender
{
	NSInteger tTag=[[sender selectedItem] tag];
	
	self.settings[PKGRequirementFilesConditionKey]=@(tTag);
}

- (IBAction)switchDiskType:(id) sender
{
	NSInteger tTag=[[sender selectedItem] tag];
	
	self.settings[PKGRequirementFilesTargetDiskKey]=@(tTag);
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *) inTableView
{
	if (inTableView==_tableView)
		return [_cachedFiles count];
	
	return 0;
}

- (id)tableView:(NSTableView *) inTableView objectValueForTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	if (inTableView==_tableView)
		return [_cachedFiles objectAtIndex:inRowIndex];
	
	return nil;
}

- (void)tableView:(NSTableView *) inTableView setObjectValue:(id) object forTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	if (inTableView==_tableView)
	{
		if (_cachedFiles!=nil)
		{
			NSUInteger tIndex=[_cachedFiles indexOfObject:object];
			
			if (tIndex!=inRowIndex)
			{
				if (tIndex!=NSNotFound)
				{
					NSBeep();
					
					return;
				}
				
				[_cachedFiles replaceObjectAtIndex:inRowIndex withObject:object];
					
				[_cachedFiles sortUsingSelector:@selector(caseInsensitiveCompare:)];
			
				[_tableView deselectAll:self];
			
				[_tableView reloadData];
			
				[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_cachedFiles indexOfObject:object]] byExtendingSelection:NO];
			}
		}
	}
}

- (void)control:(NSControl *) inControl didFailToValidatePartialString:(NSString *) inPartialString errorDescription:(NSString *) inError
{
	if (inError!=nil && [inError isEqualToString:@"NSBeep"]==YES)
		NSBeep();
}

#pragma mark -

- (BOOL)tableView:(NSTableView *) inTableView validateAction:(SEL) inSelector
{
	if (inTableView==_tableView)
	{
		if (inSelector==@selector(delete:))
			return [_removeButton isEnabled];
	}
	
	return NO;
}

- (void)tableView:(NSTableView *) inTableView deleteSelectedRowsWithConfirmationRequired:(BOOL) inConfirmationRequired
{
	if (inTableView==_tableView)
	{
		if (inConfirmationRequired==YES)
			[self removeFile:_removeButton];
		else
			[self _removeSelectedFiles];
	}
}

#pragma mark -

- (NSDragOperation)tableView:(NSTableView*) inTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger) inRow proposedDropOperation:(NSTableViewDropOperation) inOperation
{
	if (inTableView==_tableView)
	{
		if (_cachedFiles!=nil)
		{
			NSPasteboard * tPasteBoard=[info draggingPasteboard];
		
			if ([tPasteBoard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]!=nil)
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
		}
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*) inTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger) inRow dropOperation:(NSTableViewDropOperation) inOperation
{
	if (inTableView==_tableView)
	{
		if (_cachedFiles!=nil)
		{
			NSPasteboard * tPasteBoard=[info draggingPasteboard];
		
			if ([tPasteBoard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]!=nil)
			{
				NSArray * tArray=[tPasteBoard propertyListForType:NSFilenamesPboardType];
				
				[self _mergeFiles:tArray];
				
				return YES;
			}
		}
	}
	
	return NO;
}


#pragma mark -

- (void)optionKeyStateDidChange:(BOOL) isOptionKeyPressed
{
	if (isOptionKeyPressed==YES)
		[_addButton setAction:@selector(addExistingFile:)];
	else
		[_addButton setAction:@selector(addFile:)];
}

- (IBAction)addFile:(id) sender
{
	NSUInteger tRowIndex=[_cachedFiles count];

	[_cachedFiles addObject:@"/"];
	
	[_tableView deselectAll:self];
			
	[_tableView reloadData];
	
	[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRowIndex] byExtendingSelection:NO];
				
	[_tableView editColumn:0 row:tRowIndex withEvent:nil select:YES];
}

- (IBAction)addExistingFile:(id) sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	if (tOpenPanel==nil)
	{
		// A COMPLETER
		
		return;
	}
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



- (IBAction)removeFile:(id) sender
{
	NSAlert * tAlert=[[NSAlert alloc] init];
	
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

#pragma mark -

- (void) tableViewSelectionDidChange:(NSNotification *) inNotification
{
    if ([inNotification object]==_tableView)
		[_removeButton setEnabled:([_tableView numberOfSelectedRows]!=0)];
}

@end
