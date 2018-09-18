/*
 Copyright (c) 2009-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLocatorViewControllerJavaScript.h"

#import "PKGLocator_JavaScript+Constants.h"

#import "ICSourceTextTopView.h"
#import "ICSourceTextView.h"
#import "ICSourceTextViewDelegate.h"

@interface PKGLocatorViewControllerJavaScript () <NSComboBoxDataSource,NSTableViewDataSource>
{
	IBOutlet ICSourceTextTopView * _topView;
	
	IBOutlet ICSourceTextView * _textView;
	
	IBOutlet ICSourceTextViewDelegate * _textViewDelegate;
	
	
	IBOutlet NSComboBox * _functionsComboBox;
	
	IBOutlet NSTableView * _argumentsTableView;
	
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
	
	// Data
	
	NSMutableDictionary * _settings;
	
	NSMutableArray * _cachedParameters;
	
	NSArray * _cachedFunctionPrototypes;
	
	NSArray * _cachedFunctionPrototypeParameters;
}

- (IBAction)setFunctionName:(id)sender;

- (IBAction)setParameterValue:(id)sender;

- (IBAction)addParameter:(id)sender;

- (IBAction)removeParameters:(id)sender;

// Notifications

- (void)functionsListDidChange:(NSNotification *) inNotification;

@end

@implementation PKGLocatorViewControllerJavaScript

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_topView.drawsTop=YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(functionsListDidChange:)
											     name:ICJavaScriptFunctionsListDidChangeNotification
											   object:_textViewDelegate];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	_addButton.enabled=YES;
	_removeButton.enabled=NO;
	
	[_argumentsTableView reloadData];
}

#pragma mark -

- (void)refreshUI
{
	// Shared Source Code
	
	NSString * tString=[_settings[PKGLocatorJavaScriptSourceCodeKey] copy];
	
	if (tString!=nil)
	{
		_textView.string=tString;
		
		[_textViewDelegate textDidChange:nil];
	}
	
	// Function
	
	tString=_settings[PKGLocatorJavaScriptFunctionKey];
	
	_functionsComboBox.stringValue=(tString!=nil) ? tString : @"";
	
	// Parameters
}

#pragma mark -

- (void)setSettings:(NSDictionary *)inSettings
{
	_settings=[inSettings mutableCopy];
	
	if (inSettings[PKGLocatorJavaScriptParametersKey]==nil)
		_settings[PKGLocatorJavaScriptParametersKey]=[NSMutableArray array];
	else
		_settings[PKGLocatorJavaScriptParametersKey]=[inSettings[PKGLocatorJavaScriptParametersKey] mutableCopy];
	
	_cachedParameters=_settings[PKGLocatorJavaScriptParametersKey];
	
	
	[self refreshUI];
}

- (NSDictionary *)settings
{
	_settings[PKGLocatorJavaScriptSourceCodeKey]=[_textView.string copy];
	
	return [_settings copy];
}

#pragma mark -

- (BOOL)isResizableWindow
{
	return YES;
}

- (NSDictionary *)defaultSettingsWithCommonValues:(NSDictionary *) inDictionary
{
	return [NSDictionary dictionary];
}

- (NSView *)previousKeyView
{
	return _textView;
}

- (void)setNextKeyView:(NSView *) inView
{
	[_argumentsTableView setNextKeyView:inView];
}

#pragma mark -

- (CGFloat) minHeight
{
	return 340.0;
}

#pragma mark - NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *) inComboBox
{
	if (_cachedFunctionPrototypes!=nil)
		return _cachedFunctionPrototypes.count;
	
	return 0;
}

- (id)comboBox:(NSComboBox *) inComboBox objectValueForItemAtIndex:(NSInteger) inIndex
{
	if (_cachedFunctionPrototypes!=nil && inIndex<_cachedFunctionPrototypes.count)
		return _cachedFunctionPrototypes[inIndex];
	
	return nil;
}

- (NSUInteger)comboBox:(NSComboBox *) inComboBox indexOfItemWithStringValue:(NSString *) inString
{
	if (_cachedFunctionPrototypes!=nil)
		return [_cachedFunctionPrototypes indexOfObject:inString];
	
	return NSNotFound;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView!=_argumentsTableView)
		return 0;
	
	if (_cachedFunctionPrototypeParameters.count>_cachedParameters.count)
		return _cachedFunctionPrototypeParameters.count;
	
	return _cachedParameters.count;
}

#pragma mark -  NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=_argumentsTableView)
		return nil;
	
	NSString * tTableColumnIdentifier=[inTableColumn identifier];
	NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	if ([tTableColumnIdentifier isEqualToString:@"parameter"]==YES)
	{
		if (inRow<_cachedParameters.count)
		{
			NSString * tParameter=_cachedParameters[inRow];
			
			tTableCellView.textField.stringValue=tParameter;
		}
		
		if (inRow<_cachedFunctionPrototypeParameters.count)
		{
			tTableCellView.textField.placeholderString=_cachedFunctionPrototypeParameters[inRow];
		}
		
		return tTableCellView;
	}
	
	return nil;
}

#pragma mark -

- (IBAction)setFunctionName:(id) sender
{
	[self controlTextDidChange:[NSNotification notificationWithName:NSTextDidChangeNotification object:_functionsComboBox]];
	
	NSString * tString=_functionsComboBox.stringValue;
	
	if (tString!=nil)
		_settings[PKGLocatorJavaScriptFunctionKey]=tString;
}

- (IBAction)setParameterValue:(NSTextField *)sender
{
	NSInteger tRow=[_argumentsTableView rowForView:sender];
	
	if (tRow==-1)
		return;
	
	NSString * tParameter=sender.stringValue;
	
	NSUInteger tCount=_cachedParameters.count;
	
	if (tRow>=tCount)
	{
		for(NSUInteger tIndex=tCount;tIndex<tRow;tIndex++)
			[_cachedParameters addObject:[NSMutableString string]];
		
		[_cachedParameters addObject:tParameter];
	}
	else
	{
		[_cachedParameters replaceObjectAtIndex:tRow withObject:tParameter];
	}
}

- (IBAction)addParameter:(id) sender
{
	NSMutableString * tNewParameter=[NSMutableString string];
	
	[self.view.window makeFirstResponder:nil];
	
	[_cachedParameters addObject:tNewParameter];
	
	[_argumentsTableView deselectAll:self];
	
	[_argumentsTableView reloadData];
	
	NSInteger tIndex=[_cachedParameters indexOfObjectIdenticalTo:tNewParameter];
	
	if (tIndex!=NSNotFound)
	{
		[_argumentsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
		
		[_argumentsTableView scrollRowToVisible:tIndex];
		
		[_argumentsTableView editColumn:[_argumentsTableView columnWithIdentifier:@"parameter"] row:tIndex withEvent:nil select:YES];
	}
}

- (IBAction)removeParameters:(id) sender
{
	NSIndexSet * tIndexSet=_argumentsTableView.selectedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	[_cachedParameters removeObjectsAtIndexes:tIndexSet];
	
	[_argumentsTableView deselectAll:self];
	
	[_argumentsTableView reloadData];
}

#pragma mark - Notifications

- (void)controlTextDidChange:(NSNotification *) inNotification
{
	if ([inNotification object]==_functionsComboBox)
	{
		NSString * tFunctionName=_functionsComboBox.stringValue;
		
		_cachedFunctionPrototypeParameters=nil;
		
		if (tFunctionName!=nil)
			_cachedFunctionPrototypeParameters=[_textViewDelegate parametersForFunctionNamed:tFunctionName];
		
		[_argumentsTableView reloadData];
	}
}

- (void)functionsListDidChange:(NSNotification *) inNotification
{
	_cachedFunctionPrototypes=nil;
	
	// Refresh Combox Box Menu

	_cachedFunctionPrototypes=[_textViewDelegate sortedFunctionsList];
	
	NSString * tFunctionName=_functionsComboBox.stringValue;
	
	[_functionsComboBox reloadData];
	
	
	_cachedFunctionPrototypeParameters=nil;
	
	if (tFunctionName!=nil)
		_cachedFunctionPrototypeParameters=[_textViewDelegate parametersForFunctionNamed:tFunctionName];
	
	[_argumentsTableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=_argumentsTableView)
		return;
	
	_removeButton.enabled=([_argumentsTableView numberOfSelectedRows]!=0);
}

@end
