/*
 Copyright (c) 2009-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementViewControllerJavaScript.h"

#import "PKGRequirement_JavaScript+Constants.h"

#import "ICSourceTextView.h"
#import "ICSourceTextViewDelegate.h"

#import "ICSourceTextView+Constants.h"


@interface PKGRequirementViewControllerJavaScript () <NSComboBoxDataSource,NSTableViewDataSource,NSTableViewDelegate>
{
	IBOutlet ICSourceTextView * _sourceTextView;
	
	IBOutlet ICSourceTextViewDelegate * _sourceTextViewDelegate;
	
	
	IBOutlet NSComboBox * _functionsComboBox;
	
	IBOutlet NSTableView * _argumentsTableView;
	
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
	
	IBOutlet NSPopUpButton * _returnValuePopUpButton;
	
	// Data
	
	NSMutableDictionary * _settings;
	
	NSMutableArray * _cachedParameters;
	
	NSArray * _cachedFunctionPrototypes;
	
	NSArray * _cachedFunctionPrototypeParameters;
}

- (IBAction)setFunctionName:(id)sender;

- (IBAction)setParameterValue:(id)sender;

- (IBAction)addParameter:(id)sender;
- (IBAction)delete:(id)sender;

- (IBAction)switchReturnValue:(id)sender;

// Notifications

- (void)functionsListDidChange:(NSNotification *)inNotification;
- (void)showDocumentationForKeyword:(NSNotification *)inNotification;

@end

@implementation PKGRequirementViewControllerJavaScript

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(functionsListDidChange:)
											     name:ICJavaScriptFunctionsListDidChangeNotification
											   object:_sourceTextViewDelegate];
											   
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showDocumentationForKeyword:)
											     name:ICSourceTextViewWillShowKeywordDocumentationNotification
											   object:_sourceTextView];
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
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
	
	NSString * tString=[self.project.sharedProjectData[PKGRequirementJavaScriptSharedSourceCodeKey] copy];
	
	if (tString!=nil)
	{
		_sourceTextView.string=tString;

		[_sourceTextViewDelegate textDidChange:nil];
		[_sourceTextView IC_textDidChange:nil];
	}
	
	// Function
	
	tString=_settings[PKGRequirementJavaScriptFunctionKey];
	
	_functionsComboBox.stringValue=tString ? : @"";
	
	// Parameters
	
	// Return Value
	
	NSNumber * tNumber=_settings[PKGRequirementJavaScriptReturnValueKey];
	
	PKGJavaScriptReturnValue tTag=(tNumber==nil) ? PKGJavaScriptReturnTrue : tNumber.integerValue;
	
	[_returnValuePopUpButton selectItemWithTag:tTag];
}

- (NSDictionary *)settings
{
	self.project.sharedProjectData[PKGRequirementJavaScriptSharedSourceCodeKey]=[_sourceTextView.string copy];
	
	return [_settings copy];
}

- (void)setSettings:(NSDictionary *)inSettings
{
	_settings=[inSettings mutableCopy];
	
	if (inSettings[PKGRequirementJavaScriptParametersKey]==nil)
		_settings[PKGRequirementJavaScriptParametersKey]=[NSMutableArray array];
	else
		_settings[PKGRequirementJavaScriptParametersKey]=[inSettings[PKGRequirementJavaScriptParametersKey] mutableCopy];
	
	_cachedParameters=_settings[PKGRequirementJavaScriptParametersKey];
}

#pragma mark -

- (BOOL)isResizableWindow
{
	return YES;
}

- (NSDictionary *)defaultSettings
{
	return @{};
}

- (PKGRequirementType)requirementType
{
	return PKGRequirementTypeUndefined;
}

- (NSView *)previousKeyView
{
	return _sourceTextView;
}

- (void)setNextKeyView:(NSView *)inView
{
	_argumentsTableView.nextKeyView=inView;
}

#pragma mark -

- (CGFloat)minHeight
{
	return 310.0;
}

#pragma mark - NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)inComboBox
{
	if (_cachedFunctionPrototypes!=nil)
		return _cachedFunctionPrototypes.count;
	
	return 0;
}

- (id)comboBox:(NSComboBox *)inComboBox objectValueForItemAtIndex:(NSInteger)inIndex
{
	if (_cachedFunctionPrototypes!=nil && inIndex<_cachedFunctionPrototypes.count)
		return _cachedFunctionPrototypes[inIndex];
	
	return nil;
}

- (NSUInteger)comboBox:(NSComboBox *)inComboBox indexOfItemWithStringValue:(NSString *)inString
{
	if (_cachedFunctionPrototypes!=nil)
		return [_cachedFunctionPrototypes indexOfObject:inString];
	
	return NSNotFound;
}

/*- (NSString *)comboBox:(NSComboBox *) inComboBox completedString:(NSString *) inString
{
}*/

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
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	if (inRow<_cachedParameters.count)
		tTableCellView.textField.stringValue=_cachedParameters[inRow];
	
	if (inRow<_cachedFunctionPrototypeParameters.count)
		tTableCellView.textField.placeholderString=_cachedFunctionPrototypeParameters[inRow];
	
	return tTableCellView;
}

#pragma mark -

- (IBAction)setFunctionName:(id) sender
{
	[self controlTextDidChange:[NSNotification notificationWithName:NSTextDidChangeNotification object:_functionsComboBox]];
	
	NSString * tString=_functionsComboBox.stringValue;
	
	if (tString!=nil)
		_settings[PKGRequirementJavaScriptFunctionKey]=tString;
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

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=_argumentsTableView.selectedRowIndexes;
	
	if (tIndexSet.count<1)
		return;
	
	[_cachedParameters removeObjectsAtIndexes:tIndexSet];
	
	[_argumentsTableView deselectAll:self];
	
	[_argumentsTableView reloadData];
}

- (IBAction)switchReturnValue:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementJavaScriptReturnValueKey]=@(tTag);
}

#pragma mark -

- (void)controlTextDidChange:(NSNotification *) inNotification
{
	if (inNotification.object!=_functionsComboBox)
		return;
	
	NSString * tFunctionName=_functionsComboBox.stringValue;
	
	_cachedFunctionPrototypeParameters=nil;
	
	if (tFunctionName!=nil)
		_cachedFunctionPrototypeParameters=[[_sourceTextViewDelegate parametersForFunctionNamed:tFunctionName] copy];
	
	[_argumentsTableView reloadData];
}

- (void)functionsListDidChange:(NSNotification *) inNotification
{
	// Refresh Combox Box Menu

	_cachedFunctionPrototypes=[[_sourceTextViewDelegate sortedFunctionsList] copy];
	
	NSString * tFunctionName=_functionsComboBox.stringValue;
	
	[_functionsComboBox reloadData];
	
	_cachedFunctionPrototypeParameters=nil;
	
	if (tFunctionName!=nil)
		_cachedFunctionPrototypeParameters=[[_sourceTextViewDelegate parametersForFunctionNamed:tFunctionName] copy];
	
	[_argumentsTableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
    if (inNotification.object!=_argumentsTableView)
		return;
	
	_removeButton.enabled=(_argumentsTableView.numberOfSelectedRows!=0);
}

- (void)showDocumentationForKeyword:(NSNotification *) inNotification
{
	if (inNotification.object!=_sourceTextView)
		return;
	
	NSString * tKeyword=inNotification.userInfo[ICSourceTextViewKeywordKey];
	
	if (tKeyword.length>0)
	{
		static NSDictionary * sJavaScriptDocumentationReference=nil;
		
		if (sJavaScriptDocumentationReference==nil)
		{
			NSString * tPath=[[NSBundle bundleWithIdentifier:@"fr.whitebox.Packages.requirement.javascript.ui"] pathForResource:@"JavaScript_Help_DispatchList" ofType:@"plist"];
			
			if (tPath!=nil)
				sJavaScriptDocumentationReference=[[NSDictionary alloc] initWithContentsOfFile:tPath];
		}
		
		if (sJavaScriptDocumentationReference!=nil)
		{
			NSArray * tOccurrences=sJavaScriptDocumentationReference[tKeyword];
			
			if (tOccurrences!=nil)
			{
				NSUInteger tCount=tOccurrences.count;
				
				if (tCount==1)
				{
					NSDictionary * tDictionary=tOccurrences.firstObject;
					
					NSString * tURLString=tDictionary[@"URL"];
					
					if (tURLString!=nil)
					{
						NSURL * tURL=[NSURL URLWithString:tURLString];
						
						if (tURL!=nil)
							[[NSWorkspace sharedWorkspace] openURL:tURL];
					}
				}
				else if (tCount>1)
				{
					// A COMPLETER
				}
			}
		}
		else
		{
			NSBeep();
		}
	}
}

@end
