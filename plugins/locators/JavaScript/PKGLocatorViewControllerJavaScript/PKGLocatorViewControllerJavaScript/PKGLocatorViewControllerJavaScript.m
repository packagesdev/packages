#import "PKGLocatorViewControllerJavaScript.h"

#import "PKGLocator_JavaScript+Constants.h"

#import "ICSourceTextView.h"
#import "ICSourceTextViewDelegate.h"

@interface PKGLocatorViewControllerJavaScript () <NSComboBoxDataSource,NSTableViewDataSource>
{
	IBOutlet ICSourceTextView * _textView;
	
	IBOutlet ICSourceTextViewDelegate * _textViewDelegate;
	
	
	IBOutlet NSComboBox * _functionsComboBox;
	
	IBOutlet NSTableView * _tableView;
	
	IBOutlet NSButton * _addButton;
	
	IBOutlet NSButton * _removeButton;
	
	// Data
	
	NSMutableDictionary * _settings;
	
	NSMutableArray * _cachedParameters;
	
	NSArray * _cachedFunctionPrototypes;
	
	NSArray * _cachedFunctionPrototypeParameters;
}

- (IBAction)setFunctionName:(id) sender;

- (IBAction)addParameter:(id) sender;

- (IBAction)removeParameters:(id) sender;

// Notifications

- (void)functionsListDidChange:(NSNotification *) inNotification;

@end

@implementation PKGLocatorViewControllerJavaScript

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(functionsListDidChange:)
											     name:ICJavaScriptFunctionsListDidChangeNotification
											   object:_textViewDelegate];
}

- (void)setSettings:(NSDictionary *)inSettings
{
	_settings=[inSettings mutableCopy];
	
	[self refreshUI];
}

- (NSDictionary *)settings
{
	_settings[PKGLocatorJavaScriptSourceCodeKey]=[_textView.string copy];
	
	return [_settings copy];
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
	
	_cachedParameters=_settings[PKGLocatorJavaScriptParametersKey];
	
	if (_cachedParameters==nil)
	{
		_cachedParameters=[NSMutableArray array];
		
		_settings[PKGLocatorJavaScriptParametersKey]=[NSMutableArray array];
	}
	
	[_addButton setEnabled:YES];
	
	[_removeButton setEnabled:NO];
	
	[_tableView reloadData];
	
	[_tableView deselectAll:self];
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
	[_tableView setNextKeyView:inView];
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *) inTableView
{
    if (_tableView==inTableView)
	{
		NSUInteger tParametersCount=_cachedParameters.count;
		
		NSUInteger tPrototypeParametersCount=_cachedFunctionPrototypeParameters.count;
		
		if (tPrototypeParametersCount>tParametersCount)
			return tPrototypeParametersCount;
		
		return tParametersCount;
	}
	
	return 0;
}

- (id)tableView:(NSTableView *) inTableView objectValueForTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	if (_tableView==inTableView)
	{
		if (_cachedParameters!=nil)
		{
			NSString * tColumnIdentifier=inTableColumn.identifier;
			
			if ([tColumnIdentifier isEqualToString:@"Value"]==YES)
			{
				if (inRowIndex<_cachedParameters.count)
				{
					NSMutableString * tMutableString=[_cachedParameters[inRowIndex] mutableCopy];
					
					if (tMutableString!=nil)
					{
						CFStringTrimWhitespace((CFMutableStringRef) tMutableString);
					
						if (tMutableString.length>0)
							return tMutableString;
					}
				}
			}
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *) inTableView setObjectValue:(id) object forTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	if (_tableView==inTableView)
	{
		NSString * tColumnIdentifier=inTableColumn.identifier;
	
		if ([tColumnIdentifier isEqualToString:@"Value"]==YES)
		{
			if (_cachedParameters!=nil)
			{
				NSUInteger tCount=_cachedParameters.count;
				
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
}

- (void)tableView:(NSTableView *) inTableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) inTableColumn row:(NSInteger) inRowIndex
{
	NSString * tColumnIdentifier=[inTableColumn identifier];
	
	if ([tColumnIdentifier isEqualToString:@"Value"]==YES)
	{
		if (_cachedFunctionPrototypeParameters!=nil)
		{
			if (inRowIndex<[_cachedFunctionPrototypeParameters count])
			{
				NSTextFieldCell * tTextFieldCell= (NSTextFieldCell *) cell;
			
				[tTextFieldCell setPlaceholderString:[_cachedFunctionPrototypeParameters objectAtIndex:inRowIndex]];
			}
		}
	}
}

#pragma mark -

- (IBAction)setFunctionName:(id) sender
{
	[self controlTextDidChange:[NSNotification notificationWithName:NSTextDidChangeNotification object:_functionsComboBox]];
	
	NSString * tString=_functionsComboBox.stringValue;
	
	if (tString!=nil)
		_settings[PKGLocatorJavaScriptFunctionKey]=tString;
}

- (IBAction)addParameter:(id) sender
{
	NSUInteger tRowIndex=_cachedParameters.count;

	[_cachedParameters addObject:@""];
	
	[_tableView deselectAll:self];
			
	[_tableView reloadData];
	
	[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRowIndex] byExtendingSelection:NO];
				
	[_tableView editColumn:0 row:tRowIndex withEvent:nil select:YES];
}

- (IBAction)removeParameters:(id) sender
{
	NSIndexSet * tIndexSet=[_tableView selectedRowIndexes];
	
	if (tIndexSet!=nil)
	{
		[_cachedParameters removeObjectsAtIndexes:tIndexSet];
	
		[_tableView deselectAll:self];
		
		[_tableView reloadData];
	}
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
		
		[_tableView reloadData];
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
	
	[_tableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *) inNotification
{
    if ([inNotification object]==_tableView)
		[_removeButton setEnabled:([_tableView numberOfSelectedRows]!=0)];
}

@end
