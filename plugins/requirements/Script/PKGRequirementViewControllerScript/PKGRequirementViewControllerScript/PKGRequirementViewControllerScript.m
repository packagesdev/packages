/*
Copyright (c) 2008-2025, Stephane Sudre
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

#import "PKGTableViewDataSource.h"
#import "PKGCheckboxTableCellView.h"

#import "NSArray+WBExtensions.h"
#import "NSTableView+Selection.h"

#import "PKGReplaceableStringFormatter.h"

@interface PKGScriptArgument : NSObject <PKGObjectProtocol>

	@property BOOL state;

	@property (copy) NSString * value;

@end

@implementation PKGScriptArgument

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_state=YES;
		_value=@"";
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		NSNumber * tNumber=inRepresentation[PKGRequirementScriptArgumentEnabledKey];	// can be nil
		
		PKGClassCheckNumberValueForKey(tNumber,PKGRequirementScriptArgumentEnabledKey);
		
		_state=tNumber.boolValue;
		
		NSString * tString=inRepresentation[PKGRequirementScriptArgumentValueKey];
		
		PKGClassCheckStringValueForKey(tString,PKGRequirementScriptArgumentValueKey);	// can be nil ?? / A COMPLETER
		
		_value=[tString copy];
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGRequirementScriptArgumentEnabledKey]=@(self.state);
	
	tRepresentation[PKGRequirementScriptArgumentValueKey]=[self.value copy];
	
	return tRepresentation;
}

@end

@interface PKGRequirementViewControllerScript () <PKGFilePathTextFieldDelegate,NSTableViewDelegate,PKGStringReplacer>
{
	IBOutlet PKGFilePathTextField * _scriptPathTextField;
	
	IBOutlet NSButton * _embedCheckBox;
	
	IBOutlet NSTextField * _embeddedWarningLabel;

	
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
	
	IBOutlet NSPopUpButton * _comparatorPopupButton;
	
	IBOutlet NSTextField * _returnValueTextField;
	
	// Data
	
	PKGTableViewDataSource * _dataSource;
	
	NSMutableArray * _arguments;
	
	NSMutableDictionary * _settings;
    
    PKGReplaceableStringFormatter * _cachedFormatter;
}

	@property (readwrite) IBOutlet NSTableView * tableView;

- (IBAction)updateScriptPath:(id)sender;

- (IBAction)selectScriptPath:(id)sender;

- (IBAction)showInFinder:(id)sender;

- (IBAction)switchEmbed:(id) sender;

- (IBAction)switchArgumentState:(id)sender;

- (IBAction)setArgumentValue:(id)sender;

- (IBAction)addArgument:(id)sender;

- (IBAction)delete:(id)sender;

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

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _cachedFormatter=[PKGReplaceableStringFormatter new];
        _cachedFormatter.keysReplacer=self;
    }
    
    return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	[self.tableView registerForDraggedTypes:@[PPKGTableViewDataSourceInternalPboardType]];
	
	// Return Value
	
	_returnValueTextField.formatter=[PKGIntegerFormatter new];
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	self.tableView.dataSource=_dataSource;
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	_addButton.enabled=YES;
	_removeButton.enabled=NO;
	
	[self.tableView reloadData];
}

#pragma mark -

- (void)setSettings:(NSDictionary *)inSettings
{
	_settings=[inSettings mutableCopy];
	
	_arguments=[[_settings[PKGRequirementScriptArgumentsListKey] WB_arrayByMappingObjectsUsingBlock:^PKGScriptArgument *(NSDictionary * bArgumentDictionary,NSUInteger bIndex){
	
		return [[PKGScriptArgument alloc] initWithRepresentation:bArgumentDictionary error:NULL];
	}] mutableCopy];
	
	_dataSource=[[PKGTableViewDataSource alloc] initWithItems:_arguments];
	
	self.tableView.dataSource=_dataSource;
	
	[self refreshUI];
}

- (NSDictionary *)settings
{
	_settings[PKGRequirementScriptArgumentsListKey]=[_arguments WB_arrayByMappingObjectsUsingBlock:^NSDictionary *(PKGScriptArgument * bScriptArgument,NSUInteger bIndex){
	
		return [bScriptArgument representation];
	}];
	
	return [_settings copy];
}

- (void)refreshUI
{
	NSInteger tTag=PKGRequirementComparatorIsEqual;
	
	// Embed
	
	_embeddedWarningLabel.hidden=YES;
	
	NSNumber * tNumber=_settings[PKGRequirementScriptEmbeddedKey];
	NSInteger tState=NSOnState;
	
	if (tNumber!=nil)
		tState=(tNumber.boolValue==YES) ? NSOnState : NSOffState;
	
	_embedCheckBox.state=tState;
	
	if (tState==NSOnState)
	{
		if (self.project.isFlat==YES)
			_embeddedWarningLabel.hidden=NO;
	}
	
	// Script Path
	
	_scriptPathTextField.pathConverter=self.objectTransformer;
	
	NSDictionary * tScriptPathRepresentation=_settings[PKGRequirementScriptPathKey];
	
	PKGFilePath * tFilePath=[[PKGFilePath alloc] initWithRepresentation:tScriptPathRepresentation error:NULL];
	
	if (tFilePath==nil)
	{
		_settings[PKGRequirementScriptPathKey]=[NSDictionary dictionary];
		
		tFilePath=[PKGFilePath new];
	}
	
	if (tFilePath!=nil)
	{
		_scriptPathTextField.filePath=tFilePath;
		

		PKGFilePathType tType=tFilePath.type;
		
		if (tType!=PKGFilePathTypeAbsolute)
		{
			_settings[PKGRequirementScriptEmbeddedKey]=@(YES);
						  
			_embedCheckBox.enabled=NO;
			_embedCheckBox.state=NSOnState;
		}
		else
		{
			_embedCheckBox.enabled=YES;
		}
	}
	
	// Arguments
	
	_addButton.enabled=YES;
	
	_removeButton.enabled=NO;
	
	[self.tableView reloadData];
	
	[self.tableView deselectAll:self];
	
	// Comparator
	
	tNumber=_settings[PKGRequirementScriptReturnValueComparatorKey];
	
	if (tNumber!=nil)
		tTag=tNumber.integerValue;
	
	if ([_comparatorPopupButton selectItemWithTag:tTag]==NO)
	{
		// A COMPLETER
	}
	
	// Return Value
	
	tNumber=_settings[PKGRequirementScriptReturnValueKey];
	
	if (tNumber==nil)
		_returnValueTextField.stringValue=@"0";
	else
		_returnValueTextField.stringValue=tNumber.stringValue;
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
	_returnValueTextField.nextKeyView=inView;
}

#pragma mark -

- (IBAction)updateScriptPath:(id) sender
{
	NSDictionary * tScriptPathRepresentation=_settings[PKGRequirementScriptPathKey];
	
	PKGFilePath * tFilePath=[[PKGFilePath alloc] initWithRepresentation:tScriptPathRepresentation error:NULL];
	
	if (tFilePath!=nil)
	{
		PKGFilePath * tNewFilePath=_scriptPathTextField.filePath;
		
		if (tNewFilePath==nil)
		{
			// A COMPLETER
			
			return;
		}
		
		if ([tNewFilePath isEqualToFilePath:tFilePath]==NO)
		{
			if (tNewFilePath.type!=PKGFilePathTypeAbsolute)
			{
				_settings[PKGRequirementScriptEmbeddedKey]=@(YES);
				
				_embedCheckBox.state=NSOnState;
				
				_embedCheckBox.enabled=NO;
				
				if ([self.project isFlat]==YES)
					_embeddedWarningLabel.hidden=NO;
			}
			else
			{
				_embedCheckBox.enabled=YES;
			}
			
			_settings[PKGRequirementScriptPathKey]=[tNewFilePath representation];
		}
	}
}

- (IBAction)selectScriptPath:(id) sender
{
    NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
    
	tOpenPanel.prompt=NSLocalizedStringFromTableInBundle(@"Choose", @"Localizable", [NSBundle bundleForClass:[self class]], @"No comment");
	
	NSString * tAbsolutePath=[self.objectTransformer absolutePathForFilePath:_scriptPathTextField.filePath];
	
	tOpenPanel.directoryURL=[NSURL fileURLWithPath:tAbsolutePath];
 
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult==NSFileHandlingPanelOKButton)
		{
			PKGFilePath * tNewFilePath=[self.objectTransformer filePathForAbsolutePath:tOpenPanel.URL.path type:self->_scriptPathTextField.filePath.type];
			
			self->_scriptPathTextField.filePath=tNewFilePath;
			
			[self updateScriptPath:self->_scriptPathTextField];
		}
	}];
	
}

- (IBAction)showInFinder:(id) sender
{
    [[NSWorkspace sharedWorkspace] selectFile:[self.objectTransformer absolutePathForFilePath:_scriptPathTextField.filePath] inFileViewerRootedAtPath:@""];
}

- (IBAction)switchEmbed:(NSButton *) sender
{
	NSInteger tState=sender.state;
	
	_settings[PKGRequirementScriptEmbeddedKey]=@(tState==NSOnState);
	
	_embeddedWarningLabel.hidden=YES;
	
	if (tState==NSOnState)
	{
		if (self.project.isFlat==YES)
			_embeddedWarningLabel.hidden=NO;
	}
}

- (IBAction)switchArgumentState:(NSButton *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGScriptArgument * tScriptArgument=[_dataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	BOOL tNewState=(sender.state==NSOnState);
	
	if (tScriptArgument.state==tNewState)
		return;
	
	tScriptArgument.state=tNewState;
}

- (IBAction)setArgumentValue:(NSTextField *)sender
{
	NSInteger tEditedRow=[self.tableView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	PKGScriptArgument * tScriptArgument=[_dataSource tableView:self.tableView itemAtRow:tEditedRow];
	
	tScriptArgument.value=sender.objectValue;
}

- (IBAction)addArgument:(id)sender
{
	[self.view.window makeFirstResponder:self.tableView];
	
	PKGScriptArgument * tScriptArgument=[PKGScriptArgument new];
	
	[_dataSource tableView:self.tableView addItem:tScriptArgument];
	
	// Enter edition mode
	
	NSInteger tRow=self.tableView.selectedRow;
	
	if (tRow==-1)
		return;
	
	[self.tableView scrollRowToVisible:tRow];
	
	[self.tableView editColumn:[self.tableView columnWithIdentifier:@"argument.value"] row:tRow withEvent:nil select:YES];
}

- (IBAction)delete:(id)sender
{
	[_dataSource tableView:self.tableView removeItems:[_dataSource tableView:self.tableView itemsAtRowIndexes:self.tableView.WB_selectedOrClickedRowIndexes]];
}

- (IBAction)switchComparator:(NSPopUpButton *) sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementScriptReturnValueComparatorKey]=@(tTag);
}

- (IBAction)setReturnValue:(id)sender
{
	NSString * tStringValue=_returnValueTextField.stringValue;
	
	NSNumber * tNumber=@(tStringValue.integerValue);
	
	if (tNumber!=nil)
		_settings[PKGRequirementScriptReturnValueKey]=tNumber;
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(delete:))
	{
		NSIndexSet * tIndexSet=self.tableView.WB_selectedOrClickedRowIndexes;
		
		return (tIndexSet.count>0);
	}
	
	if (tAction==@selector(showInFinder:))
	{
		PKGFilePath * tNewFilePath=_scriptPathTextField.filePath;
		
		return (tNewFilePath.string.length>0);
	}
	
	return YES;
}

#pragma mark - NSTableViewDataDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	PKGScriptArgument * tScriptArgument=[_dataSource tableView:self.tableView itemAtRow:inRow];
	
	if (tScriptArgument==nil)
		return nil;
	
	PKGCheckboxTableCellView * tCheckBoxView=(PKGCheckboxTableCellView *)tTableCellView;
		
	tCheckBoxView.checkbox.state=(tScriptArgument.state==YES) ? NSOnState : NSOffState;
    
    tTableCellView.textField.formatter=_cachedFormatter;
    tTableCellView.textField.objectValue=@"";
	tTableCellView.textField.objectValue=tScriptArgument.value;
	tTableCellView.textField.editable=YES;
		
	return tCheckBoxView;
}

#pragma mark - NSControlTextEditingDelegate

- (void)control:(NSControl *) inControl didFailToValidatePartialString:(NSString *) inPartialString errorDescription:(NSString *) inError
{
	if (inError!=nil && [inError isEqualToString:@"NSBeep"]==YES)
		NSBeep();
}

#pragma mark - PKGFilePathTextFieldDelegate

- (BOOL)filePathTextField:(PKGFilePathTextField *)inFilePathTextField shouldAcceptFile:(NSString *)inPath
{
	if (inFilePathTextField!=_scriptPathTextField)
		return NO;
	
	BOOL isDirectory;
		
	return ([[NSFileManager defaultManager] fileExistsAtPath:inPath isDirectory:&isDirectory]==NO && isDirectory==NO);
}

#pragma mark - PKGStringReplacer

- (NSString *)stringByReplacingKeysInString:(NSString *)inString
{
    return [self.objectTransformer stringByReplacingKeysInString:inString];
}

#pragma mark - Notifications

- (void)tableViewSelectionDidChange:(NSNotification *) inNotification
{
    if (inNotification.object!=self.tableView)
		return;
	
	_removeButton.enabled=(self.tableView.numberOfSelectedRows>0);
}

@end
