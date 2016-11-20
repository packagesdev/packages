/*
 Copyright (c) 2008-2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPreferencePaneTemplatesViewController.h"

#import "PKGProjectTemplateDefaultValuesSettings.h"

#import "PKGBundleIdentifierFormatter.h"

@interface PKGPreferencePaneTemplatesViewController () <NSTextFieldDelegate,NSTableViewDataSource,NSTableViewDelegate>
{
	IBOutlet NSTableView * _tableView;
	
	// Data
	
	NSArray * _keys;
}

- (IBAction)setTemplateValue:(id)sender;

@end

@implementation PKGPreferencePaneTemplatesViewController

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_keys=[PKGProjectTemplateDefaultValuesSettings sharedSettings].allKeys;
	}
	
	return self;
}

#pragma mark -

- (void)WB_viewWillAdd
{
	[_tableView reloadData];
}

- (IBAction)setTemplateValue:(id)sender
{
	NSInteger tRow=[_tableView rowForView:sender];
	
	if (tRow==-1 || tRow>=[_keys count])
		return;
	
	NSString * tKey=_keys[tRow];
	id tValue=[sender objectValue];
	
	if ([tKey isEqualToString:PKGProjectTemplateCompanyIdentifierPrefixKey]==YES)
	{
		NSString * tStringValue=tValue;
		
		if ([tStringValue hasSuffix:@"."]==YES)
			tValue=[tStringValue substringToIndex:[tStringValue length]-1];
	}
	
	[[PKGProjectTemplateDefaultValuesSettings sharedSettings] setValue:tValue forKey:tKey];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView==_tableView)
		return [_keys count];
	
	return 0;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView==_tableView)
	{
		NSString * tTableColumnIdentifier=[inTableColumn identifier];
		NSString * tKey=_keys[inRow];
		NSTableCellView * tView=[_tableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		if ([tTableColumnIdentifier isEqualToString:@"Key"]==YES)
		{
			[tView.textField setStringValue:NSLocalizedStringFromTable(tKey,@"Preferences",@"")];
			
			return tView;
		}

		if ([tTableColumnIdentifier isEqualToString: @"Value"]==YES)
		{
			[tView.textField setStringValue:[[PKGProjectTemplateDefaultValuesSettings sharedSettings] valueForKey:tKey]];
			
			if ([tKey isEqualToString:PKGProjectTemplateCompanyIdentifierPrefixKey]==YES)
				[tView.textField setFormatter:[PKGBundleIdentifierFormatter new]];
			
			return tView;
		}
	}
	
	return nil;
}

#pragma mark -

- (void)control:(NSControl *) inControl didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *) inErrorDescription
{
	if ([inErrorDescription isEqualToString:@"Error"]==YES)
		NSBeep();
}

@end
