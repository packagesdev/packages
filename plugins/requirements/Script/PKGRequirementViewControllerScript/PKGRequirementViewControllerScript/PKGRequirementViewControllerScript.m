/*
Copyright (c) 2008-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGRequirementViewControllerScript.h"

#import "PKGIntegerFormatter.h"

#import "PKGRequirement_Script+Constants.h"

#import "PKGFilePathTextField.h"

@interface PKGRequirementViewControllerScript () <PKGFilePathTextFieldDelegate,NSTableViewDataSource,NSTableViewDelegate>
{
	IBOutlet PKGFilePathTextField * _scriptPathTextField;
	
	IBOutlet NSButton * _embedCheckBox;
	
	IBOutlet NSTextField * _embeddedWarningLabel;
	
	IBOutlet NSTableView * _tableView;
	
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
	
	IBOutlet NSPopUpButton * _comparatorPopupButton;
	
	IBOutlet NSTextField * _returnValueTextField;
	
	// Data
	
	NSMutableArray * _cachedArguments;
}

- (IBAction)updateScriptPath:(id) sender;

- (IBAction)selectScriptPath:(id) sender;

- (IBAction)revealScriptPathInFinder:(id) sender;

- (IBAction)switchEmbed:(id) sender;

- (IBAction)addArgument:(id) sender;

- (IBAction)removeArgument:(id) sender;

- (IBAction)switchComparator:(id) sender;

- (IBAction)setReturnValue:(id) sender;

@end

@implementation PKGRequirementViewControllerScript

+ (NSDictionary *)pasteboardDictionaryFromDictionary:(NSDictionary *)inDictionary converter:(id<PKGFilePathConverter>)inConverter
{
	NSMutableDictionary * tMutablePasteboardDictionary=[inDictionary mutableCopy];
	
	NSDictionary * tScriptPathRepresentation=tMutablePasteboardDictionary[PKGRequirementScriptPathKey];
	
	PKGFilePath * tFilePath=[[PKGFilePath alloc] initWithRepresentation:tScriptPathRepresentation error:NULL];
	
	if (tFilePath==nil)
		return [tMutablePasteboardDictionary copy];
	
	PKGFilePathType tSavedFileType=tFilePath.type;
	
	if ([inConverter shiftTypeOfFilePath:tFilePath toType:PKGFilePathTypeAbsolute]==YES)
	{
		tFilePath.type=tSavedFileType;	// We keep the previous type so that we can convert the path back
		tMutablePasteboardDictionary[PKGRequirementScriptPathKey]=[tFilePath representation];
	}
	
	return [tMutablePasteboardDictionary copy];
}

+ (NSDictionary *)dictionaryFromPasteboardDictionary:(NSDictionary *)inPasteboardDictionary converter:(id<PKGFilePathConverter>)inConverter
{
	NSMutableDictionary * tMutableDictionary=[inPasteboardDictionary mutableCopy];
	
	NSDictionary * tScriptPathRepresentation=tMutableDictionary[PKGRequirementScriptPathKey];
	
	PKGFilePath * tFilePath=[[PKGFilePath alloc] initWithRepresentation:tScriptPathRepresentation error:NULL];
	
	if (tFilePath==nil)
		return [tMutableDictionary copy];
	
	PKGFilePathType tSavedFileType=tFilePath.type;
	
	tFilePath.type=PKGFilePathTypeAbsolute;
	
	if ([inConverter shiftTypeOfFilePath:tFilePath toType:tSavedFileType]==YES)
		tMutableDictionary[PKGRequirementScriptPathKey]=[tFilePath representation];
	
	return [tMutableDictionary copy];
}

- (void)awakeFromNib
{
	// Return Value
	
	PKGIntegerFormatter * tFormatter=[PKGIntegerFormatter new];
	
	if (tFormatter!=nil)
		[_returnValueTextField setFormatter:tFormatter];
	
	// Array
	
	NSTableColumn * tTableColumn = [_tableView tableColumnWithIdentifier:@"State"];
    
	if (tTableColumn!=nil)
	{
		NSButtonCell * tButttonCell= [[NSButtonCell alloc] initTextCell:@""];
		
		if (tButttonCell!=nil)
		{
			[tButttonCell setButtonType: NSSwitchButton];
			tButttonCell.controlSize=NSMiniControlSize;
			tButttonCell.editable=YES;
			tButttonCell.imagePosition=NSImageOnly;
			
			[tTableColumn setDataCell:tButttonCell];
		}
	}
	
	// Name
	
	tTableColumn = [_tableView tableColumnWithIdentifier:@"Value"];
    
	if (tTableColumn!=nil)
	{
		NSCell * tTextFieldCell= [tTableColumn dataCell];
		
		tTextFieldCell.font=[NSFont systemFontOfSize:11.0f];
	}
}

#pragma mark -

- (void)updateUI
{
	NSInteger tTag=PKGRequirementComparatorIsEqual;
	
	// Embed
	
	[_embeddedWarningLabel setHidden:YES];
	
	NSNumber * tNumber=self.settings[PKGRequirementScriptEmbeddedKey];
	NSInteger tState=NSOnState;
	
	if (tNumber!=nil)
		tState=([tNumber boolValue]==YES) ? NSOnState : NSOffState;
	
	[_embedCheckBox setState:tState];
	
	if (tState==NSOnState)
	{
		if ([self.project isFlat]==YES)
			[_embeddedWarningLabel setHidden:NO];
	}
	
	// Script Path
	
	_scriptPathTextField.pathConverter=self.filePathConverter;
	
	NSDictionary * tScriptPathRepresentation=self.settings[PKGRequirementScriptPathKey];
	
	PKGFilePath * tFilePath=[[PKGFilePath alloc] initWithRepresentation:tScriptPathRepresentation error:NULL];
	
	if (tFilePath==nil)
	{
		self.settings[PKGRequirementScriptPathKey]=[NSDictionary dictionary];
		
		tFilePath=[[PKGFilePath alloc] init];
	}
	
	if (tFilePath!=nil)
	{
		[_scriptPathTextField setFilePath:tFilePath];
		
		
		PKGFilePathType tType=tFilePath.type;
		
		if (tType!=PKGFilePathTypeAbsolute)
		{
			self.settings[PKGRequirementScriptEmbeddedKey]=@(YES);
						  
			[_embedCheckBox setEnabled:NO];

			[_embedCheckBox setState:NSOnState];
		}
		else
		{
			[_embedCheckBox setEnabled:YES];
		}
	}
	
	// Arguments
	
	_cachedArguments=self.settings[PKGRequirementScriptArgumentsListKey];
	
	[_addButton setEnabled:YES];
	
	[_removeButton setEnabled:NO];
	
	[_tableView reloadData];
	
	[_tableView deselectAll:self];
	
	// Comparator
	
	tNumber=self.settings[PKGRequirementScriptReturnValueComparatorKey];
	
	if (tNumber!=nil)
		tTag=[tNumber integerValue];
	
	if ([_comparatorPopupButton selectItemWithTag:tTag]==NO)
	{
		// A COMPLETER
	}
	
	// Return Value
	
	tNumber=self.settings[PKGRequirementScriptReturnValueKey];
	
	if (tNumber==nil)
		[_returnValueTextField setStringValue:@"0"];
	else
		[_returnValueTextField setStringValue:[tNumber stringValue]];
}

#pragma mark -

- (NSDictionary *)defaultSettings
{
	return @{PKGRequirementScriptEmbeddedKey:@(YES),
			 PKGRequirementScriptArgumentsListKey:@[],
			 PKGRequirementScriptReturnValueComparatorKey:@(PKGRequirementComparatorIsEqual),
			 PKGRequirementScriptReturnValueKey:@(0)};
}

- (PKGRequirementType)requirementType
{
	return PKGRequirementTypeUndefined;
}

- (NSView *)previousKeyView
{
	return _scriptPathTextField;
}

- (void)setNextKeyView:(NSView *) inView
{
	[_returnValueTextField setNextKeyView:inView];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *) inTableView
{
	if (inTableView!=_tableView)
		return 0;
	
	return [_cachedArguments count];
}

- (id)tableView:(NSTableView *) inTableView objectValueForTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	if (inTableView!=_tableView)
		return nil;
	
	if (_cachedArguments!=nil)
	{
		NSString * tColumnIdentifier=[inTableColumn identifier];
		
		NSMutableDictionary * tDictionary=_cachedArguments[inRowIndex];
		
		if ([tColumnIdentifier isEqualToString: @"State"]==YES)
			return tDictionary[PKGRequirementScriptArgumentEnabledKey];
		
		if ([tColumnIdentifier isEqualToString: @"Value"]==YES)
			return tDictionary[PKGRequirementScriptArgumentValueKey];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *) inTableView setObjectValue:(id) object forTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	if (inTableView!=_tableView)
		return;
	
	if (_cachedArguments!=nil)
	{
		NSString * tColumnIdentifier=[inTableColumn identifier];
		
		NSMutableDictionary * tDictionary=_cachedArguments[inRowIndex];
		
		if ([tColumnIdentifier isEqualToString: @"State"]==YES)
		{
			NSNumber * tNumber=tDictionary[PKGRequirementScriptArgumentEnabledKey];
			
			if ([tNumber boolValue]!=[object boolValue])
				[tDictionary setObject:object forKey:PKGRequirementScriptArgumentEnabledKey];
		}
		else if ([tColumnIdentifier isEqualToString: @"Value"]==YES)
		{
			[tDictionary setObject:object forKey:PKGRequirementScriptArgumentValueKey];
		}
	}
}

- (void)control:(NSControl *) inControl didFailToValidatePartialString:(NSString *) inPartialString errorDescription:(NSString *) inError
{
	if (inError!=nil && [inError isEqualToString:@"NSBeep"]==YES)
		NSBeep();
}

#pragma mark -

- (IBAction)updateScriptPath:(id) sender
{
	NSDictionary * tScriptPathRepresentation=self.settings[PKGRequirementScriptPathKey];
	
	PKGFilePath * tFilePath=[[PKGFilePath alloc] initWithRepresentation:tScriptPathRepresentation error:NULL];
	
	if (tFilePath!=nil)
	{
		PKGFilePath * tNewFilePath=[_scriptPathTextField filePath];
		
		if (tNewFilePath==nil)
		{
			// A COMPLETER
			
			return;
		}
		
		if ([tNewFilePath isEqualToFilePath:tFilePath]==NO)
		{
			if (tNewFilePath.type!=PKGFilePathTypeAbsolute)
			{
				self.settings[PKGRequirementScriptEmbeddedKey]=@(YES);
				
				[_embedCheckBox setState:NSOnState];
				
				[_embedCheckBox setEnabled:NO];
				
				if ([self.project isFlat]==YES)
					[_embeddedWarningLabel setHidden:NO];
			}
			else
			{
				[_embedCheckBox setEnabled:YES];
			}
			
			self.settings[PKGRequirementScriptPathKey]=[tNewFilePath representation];
		}
	}
}

- (IBAction)selectScriptPath:(id) sender
{
    NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
    
	tOpenPanel.prompt=NSLocalizedStringFromTableInBundle(@"Choose", @"Localizable", [NSBundle bundleForClass:[self class]], @"No comment");
	
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:[_scriptPathTextField filePath]];
	
	tOpenPanel.directoryURL=[NSURL fileURLWithPath:tAbsolutePath];
 
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult==NSFileHandlingPanelOKButton)
		{
			PKGFilePath * tNewFilePath=[self.filePathConverter filePathForAbsolutePath:[tOpenPanel.URL path] type:[_scriptPathTextField filePath].type];
			
			[_scriptPathTextField setFilePath:tNewFilePath];
			
			[self updateScriptPath:_scriptPathTextField];
		}
	}];
	
}

- (IBAction)revealScriptPathInFinder:(id) sender
{
    [[NSWorkspace sharedWorkspace] selectFile:[self.filePathConverter absolutePathForFilePath:[_scriptPathTextField filePath]] inFileViewerRootedAtPath:@""];
}

- (IBAction)switchEmbed:(id) sender
{
	NSInteger tState=[sender state];
	
	self.settings[PKGRequirementScriptEmbeddedKey]=@(tState==NSOnState);
	
	[_embeddedWarningLabel setHidden:YES];
	
	if (tState==NSOnState)
	{
		if ([self.project isFlat]==YES)
			[_embeddedWarningLabel setHidden:NO];
	}
}

- (IBAction)addArgument:(id) sender
{
	NSUInteger tRowIndex=[_cachedArguments count];
	
	[_cachedArguments addObject:@{PKGRequirementScriptArgumentEnabledKey:@(YES),
								  PKGRequirementScriptArgumentValueKey:@""}];
	
	[_tableView deselectAll:self];
	
	[_tableView reloadData];
	
	[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRowIndex] byExtendingSelection:NO];
	
	[_tableView editColumn:1 row:tRowIndex withEvent:nil select:YES];
}

- (IBAction)removeArgument:(id) sender
{
	NSIndexSet * tIndexSet=[_tableView selectedRowIndexes];
	
	[_tableView deselectAll:self];
	
	if (tIndexSet!=nil)
	{
		[_cachedArguments removeObjectsAtIndexes:tIndexSet];
		
		[_tableView reloadData];
		
		[_removeButton setEnabled:NO];
	}
}

- (IBAction)switchComparator:(id) sender
{
	NSInteger tTag=[[sender selectedItem] tag];
	
	self.settings[PKGRequirementScriptReturnValueComparatorKey]=@(tTag);
}

- (IBAction)setReturnValue:(id) sender
{
	NSString * tStringValue=[_returnValueTextField stringValue];
	
	NSNumber * tNumber=[NSNumber numberWithInteger:[tStringValue integerValue]];
	
	if (tNumber!=nil)
		self.settings[PKGRequirementScriptReturnValueKey]=tNumber;
}

#pragma mark - PKGFilePathTextFieldDelegate

- (BOOL)filePathTextField:(PKGFilePathTextField *)inFilePathTextField shouldAcceptFile:(NSString *)inPath
{
	if (inFilePathTextField!=_scriptPathTextField)
		return NO;
	
	BOOL isDirectory;
		
	return ([[NSFileManager defaultManager] fileExistsAtPath:inPath isDirectory:&isDirectory]==NO && isDirectory==NO);
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *) inNotification
{
    if ([inNotification object]==_tableView)
		[_removeButton setEnabled:([_tableView numberOfSelectedRows]!=0)];
}
@end
