#import "PKGRequirementViewControllerJavaScript.h"

#import "PKGRequirement_JavaScript+Constants.h"

#import "ICSourceTextView.h"
#import "ICSourceTextViewDelegate.h"

#import "ICSourceTextView+Constants.h"

@interface PKGRequirementViewControllerJavaScript () <NSTableViewDataSource,NSComboBoxDataSource>
{
	IBOutlet ICSourceTextView * _sourceTextView;
	
	IBOutlet ICSourceTextViewDelegate * _sourceTextViewDelegate;
	
	
	IBOutlet NSComboBox * _functionsComboBox;
	
	IBOutlet NSTableView * _argumentsTableView;
	
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
	
	IBOutlet NSPopUpButton * _returnValuePopUpButton;
	
	// Data
	
	NSMutableArray * _cachedParameters;
	
	NSArray * _cachedFunctionPrototypes;
	
	NSArray * _cachedFunctionPrototypeParameters;
}

- (IBAction) setFunctionName:(id) sender;

- (IBAction) addParameter:(id) sender;
- (IBAction) removeParameters:(id) sender;

- (IBAction) switchReturnValue:(id) sender;

// Notifications

- (void) functionsListDidChange:(NSNotification *) inNotification;
- (void) showDocumentationForKeyword:(NSNotification *) inNotification;

@end

@implementation PKGRequirementViewControllerJavaScript

- (void) awakeFromNib
{
	/*NSTableColumn * tTableColumn = nil;
	
	// Path Names
    
    tTableColumn = [_argumentsTableView tableColumnWithIdentifier:@"Value"];
	
	if (tTableColumn!=nil)
	{
		NSCell * tTextFieldCell;
		
		tTextFieldCell = [tTableColumn dataCell];
		
		if (tTextFieldCell!=nil)
		{
			[tTextFieldCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
		}
	}*/
	
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

- (void)updateUI
{
	// Shared Source Code
	
	NSString * tString=[self.project.sharedProjectData[PKGRequirementJavaScriptSharedSourceCodeKey] copy];
	
	if (tString!=nil)
	{
		[_sourceTextView setString:tString];

		[_sourceTextViewDelegate textDidChange:nil];
		[_sourceTextView IC_textDidChange:nil];
	}
	
	// Function
	
	tString=self.settings[PKGRequirementJavaScriptFunctionKey];
	
	[_functionsComboBox setStringValue:tString ? : @""];
	
	// Parameters
	
	_cachedParameters=self.settings[PKGRequirementJavaScriptParametersKey];
	
	if (_cachedParameters==nil)
	{
		_cachedParameters=[NSMutableArray array];
		
		self.settings[PKGRequirementJavaScriptParametersKey]=_cachedParameters;
	}
	
	[_addButton setEnabled:YES];
	
	[_removeButton setEnabled:NO];
	
	[_argumentsTableView reloadData];
	
	[_argumentsTableView deselectAll:self];
	
	// Return Value
	
	NSNumber * tNumber=self.settings[PKGRequirementJavaScriptReturnValueKey];
	
	PKGJavaScriptReturnValue tTag=(tNumber==nil) ? PKGJavaScriptReturnTrue : [tNumber integerValue];
	
	[_returnValuePopUpButton selectItemWithTag:tTag];
}

- (NSMutableDictionary *)settings
{
	self.project.sharedProjectData[PKGRequirementJavaScriptSharedSourceCodeKey]=[[_sourceTextView string] copy];
	
	return [super settings];
}

#pragma mark -

- (BOOL)windowCanBeResized
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

- (void)setNextKeyView:(NSView *) inView
{
	[_argumentsTableView setNextKeyView:inView];
}

#pragma mark -

- (CGFloat)minHeight
{
	return 310.0f;
}

#pragma mark - NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *) inComboBox
{
	if (_cachedFunctionPrototypes!=nil)
		return [_cachedFunctionPrototypes count];
	
	return 0;
}

- (id)comboBox:(NSComboBox *) inComboBox objectValueForItemAtIndex:(NSInteger) inIndex
{
	if (_cachedFunctionPrototypes!=nil && inIndex<[_cachedFunctionPrototypes count])
		return [_cachedFunctionPrototypes objectAtIndex:inIndex];
	
	return nil;
}

- (NSUInteger)comboBox:(NSComboBox *) inComboBox indexOfItemWithStringValue:(NSString *) inString
{
	if (_cachedFunctionPrototypes!=nil)
		return [_cachedFunctionPrototypes indexOfObject:inString];
	
	return NSNotFound;
}

/*- (NSString *)comboBox:(NSComboBox *) inComboBox completedString:(NSString *) inString
{
}*/

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *) inTableView
{
	if (inTableView!=_argumentsTableView)
		return 0;
	
	NSUInteger tParametersCount=0;
	NSUInteger tPrototypeParametersCount=0;
	
	if (_cachedParameters!=nil)
		tParametersCount=[_cachedParameters count];
	
	if (_cachedFunctionPrototypeParameters!=nil)
		tPrototypeParametersCount=[_cachedFunctionPrototypeParameters count];
	
	if (tPrototypeParametersCount>tParametersCount)
		return tPrototypeParametersCount;
	
	return tParametersCount;
}

- (id)tableView:(NSTableView *) inTableView objectValueForTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	if (inTableView!=_argumentsTableView)
		return nil;
	
	if (_cachedParameters==nil)
		return nil;
	
	NSString * tColumnIdentifier=[inTableColumn identifier];
	
	if ([tColumnIdentifier isEqualToString:@"Value"]==YES)
	{
		if (inRowIndex<[_cachedParameters count])
		{
			NSMutableString * tMutableString=[[_cachedParameters objectAtIndex:inRowIndex] mutableCopy];
			
			if (tMutableString!=nil)
			{
				CFStringTrimWhitespace((CFMutableStringRef) tMutableString);
			
				if ([tMutableString length]>0)
					return tMutableString;
			}
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *) inTableView setObjectValue:(id) object forTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	if (inTableView!=_argumentsTableView)
		return;
	
	NSString * tColumnIdentifier=[inTableColumn identifier];
	
	if ([tColumnIdentifier isEqualToString:@"Value"]==YES)
	{
		if (_cachedParameters!=nil)
		{
			NSUInteger tCount=[_cachedParameters count];
			
			if (inRowIndex>=tCount)
			{
				for(NSUInteger tIndex=tCount;tIndex<inRowIndex;tIndex++)
					[_cachedParameters addObject:@""];
				
				[_cachedParameters addObject:object];
			}
			else
			{
				[_cachedParameters replaceObjectAtIndex:inRowIndex withObject:object];
			}
		}
	}
}

- (void)tableView:(NSTableView *) inTableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	if (inTableView!=_argumentsTableView)
		return;
	
	NSString * tColumnIdentifier=[inTableColumn identifier];
	
	if ([tColumnIdentifier isEqualToString:@"Value"]==YES)
	{
		if (_cachedFunctionPrototypeParameters!=nil)
		{
			if (inRowIndex<[_cachedFunctionPrototypeParameters count])
			{
				NSTextFieldCell * tTextFieldCell = (NSTextFieldCell *) cell;
			
				[tTextFieldCell setPlaceholderString:[_cachedFunctionPrototypeParameters objectAtIndex:inRowIndex]];
			}
		}
	}
}

#pragma mark -

- (IBAction)setFunctionName:(id) sender
{
	[self controlTextDidChange:[NSNotification notificationWithName:NSTextDidChangeNotification object:_functionsComboBox]];
	
	NSString * tString=[_functionsComboBox stringValue];
	
	if (tString!=nil)
		self.settings[PKGRequirementJavaScriptFunctionKey]=tString;
}

- (IBAction)addParameter:(id) sender
{
	NSUInteger tRowIndex=[_cachedParameters count];

	[_cachedParameters addObject:@""];
	
	[_argumentsTableView deselectAll:self];
			
	[_argumentsTableView reloadData];
	
	[_argumentsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRowIndex] byExtendingSelection:NO];
				
	[_argumentsTableView editColumn:0 row:tRowIndex withEvent:nil select:YES];
}

- (IBAction)removeParameters:(id) sender
{
	NSIndexSet * tIndexSet=[_argumentsTableView selectedRowIndexes];
	
	if (tIndexSet!=nil)
	{
		[_cachedParameters removeObjectsAtIndexes:tIndexSet];
	
		[_argumentsTableView deselectAll:self];
		
		[_argumentsTableView reloadData];
		
		//[IBremoveButton_ setEnabled:NO];
	}
}

- (IBAction)switchReturnValue:(id) sender
{
	NSInteger tTag=[[sender selectedItem] tag];
	
	self.settings[PKGRequirementJavaScriptReturnValueKey]=@(tTag);
}

#pragma mark -

- (void)controlTextDidChange:(NSNotification *) inNotification
{
	if ([inNotification object]==_functionsComboBox)
	{
		NSString * tFunctionName;
		
		tFunctionName=[_functionsComboBox stringValue];
		
		_cachedFunctionPrototypeParameters=nil;
		
		if (tFunctionName!=nil)
			_cachedFunctionPrototypeParameters=[[_sourceTextViewDelegate parametersForFunctionNamed:tFunctionName] copy];
		
		[_argumentsTableView reloadData];
	}
}

- (void)functionsListDidChange:(NSNotification *) inNotification
{
	// Refresh Combox Box Menu

	_cachedFunctionPrototypes=[[_sourceTextViewDelegate sortedFunctionsList] copy];
	
	NSString * tFunctionName=[_functionsComboBox stringValue];
	
	[_functionsComboBox reloadData];
	
	_cachedFunctionPrototypeParameters=nil;
	
	if (tFunctionName!=nil)
		_cachedFunctionPrototypeParameters=[[_sourceTextViewDelegate parametersForFunctionNamed:tFunctionName] copy];
	
	[_argumentsTableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *) inNotification
{
    if ([inNotification object]==_argumentsTableView)
		[_removeButton setEnabled:([_argumentsTableView numberOfSelectedRows]!=0)];
}

- (void)showDocumentationForKeyword:(NSNotification *) inNotification
{
	if ([inNotification object]==_sourceTextView)
    {
		NSString * tKeyword=[[inNotification userInfo] objectForKey:ICSourceTextViewKeywordKey];
		
		if ([tKeyword length]>0)
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
					NSUInteger tCount=[tOccurrences count];
					
					if (tCount==1)
					{
						NSDictionary * tDictionary=[tOccurrences firstObject];
						
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
}

@end
