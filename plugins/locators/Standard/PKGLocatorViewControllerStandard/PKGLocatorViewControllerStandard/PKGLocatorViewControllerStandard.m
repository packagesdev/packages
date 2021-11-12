/*
 Copyright (c) 2016-201, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLocatorViewControllerStandard.h"

#import "PKGLocator_Standard+Constants.h"

#import "PKGBundleIdentifierFormatter.h"

@interface PKGLocatorViewControllerStandard ()
{
	IBOutlet NSTextField * _bundleIdentifierTextField;
	
	IBOutlet NSTextField * _defaultPathTextField;
	
	IBOutlet NSButton * _defaultPathCheckBox;
	
	NSMutableDictionary * _settings;
}

- (IBAction)setBundleIdentifier:(id)sender;

- (IBAction)setDefaultPath:(id)sender;

- (IBAction)switchUseDefaultPath:(id)sender;

@end

@implementation PKGLocatorViewControllerStandard

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	PKGBundleIdentifierFormatter * tFormatter=[PKGBundleIdentifierFormatter new];
    tFormatter.allowsUserDefinedSettingsCharacters=NO;
    
	_bundleIdentifierTextField.formatter=tFormatter;
}

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
	NSString * tString=_settings[PKGLocatorStandardBundleIdentifierKey];
	
	_bundleIdentifierTextField.stringValue=(tString!=nil) ? tString : @"";

	
	_defaultPathCheckBox.enabled=NO;
	_defaultPathCheckBox.state=NSOffState;
	
	tString=_settings[PKGLocatorStandardDefaultPathKey];
	
	if (tString!=nil)
	{
		_defaultPathTextField.stringValue=tString;
		
		if (tString.length>0)
		{
			NSNumber * tNumber=_settings[PKGLocatorStandardPreferDefaultPathKey];
			
			_defaultPathCheckBox.enabled=YES;
			
			_defaultPathCheckBox.state=(tNumber.boolValue==YES) ? NSOnState : NSOffState;
		}
	}
	else
	{
		_defaultPathTextField.stringValue=@"";
	}
}

#pragma mark -

- (NSDictionary *)defaultSettingsWithCommonValues:(NSDictionary *) inDictionary
{
	if (inDictionary==nil)
		return nil;
	
	NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	NSString * tString=inDictionary[PKGLocatorCommonValueBundleIdentifierKey];
	
	if (tString!=nil)
		tMutableDictionary[PKGLocatorStandardBundleIdentifierKey]=tString;
	
	tString=inDictionary[PKGLocatorCommonValuePathKey];
	
	if (tString!=nil)
		tMutableDictionary[PKGLocatorStandardDefaultPathKey]=tString;
	
	return [tMutableDictionary copy];
}



- (NSView *)previousKeyView
{
	return _bundleIdentifierTextField;
}

- (void)setNextKeyView:(NSView *) inView
{
	[_defaultPathTextField setNextKeyView:inView];
}

#pragma mark -

- (IBAction)setBundleIdentifier:(NSTextField *) sender
{
	NSString * tStringValue=sender.stringValue;
	
	if (tStringValue!=nil)
		_settings[PKGLocatorStandardBundleIdentifierKey]=tStringValue;
}

- (IBAction)setDefaultPath:(NSTextField *) sender
{
	NSString * tStringValue=sender.stringValue;
	
	if (tStringValue!=nil)
		_settings[PKGLocatorStandardDefaultPathKey]=tStringValue;
}

- (IBAction)switchUseDefaultPath:(id) sender
{
	_settings[PKGLocatorStandardPreferDefaultPathKey]=@(_defaultPathCheckBox.state==NSOnState);
}

#pragma mark -

- (void)control:(NSControl *) inControl didFailToValidatePartialString:(NSString *) inPartialString errorDescription:(NSString *) inError
{
	if (inError!=nil && [inError isEqualToString:@"NSBeep"]==YES)
		NSBeep();
}

- (void)controlTextDidChange:(NSNotification *) inNotification
{
	if (inNotification.object==_defaultPathTextField)
	{
		BOOL tValue=(_defaultPathTextField.stringValue.length>0);
		
		_defaultPathCheckBox.enabled=tValue;
		
		if (tValue==NO)
		{
			_defaultPathCheckBox.state=NSOffState;
			
			_settings[PKGLocatorStandardPreferDefaultPathKey]=@(NO);
		}
	}
}

@end
