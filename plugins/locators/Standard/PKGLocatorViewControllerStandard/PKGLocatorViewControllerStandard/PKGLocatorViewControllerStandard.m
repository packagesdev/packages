#import "PKGLocatorViewControllerStandard.h"

#import "PKGLocator_Standard+Constants.h"

#import "PKGBundleIdentifierFormatter.h"

@interface PKGLocatorViewControllerStandard ()
{
	IBOutlet NSTextField * _bundleIdentifierTextField;
	
	IBOutlet NSTextField * _defaultPathTextField;
	
	IBOutlet NSButton * _defaultPathCheckBox;
}

- (IBAction)setBundleIdentifier:(id) sender;

- (IBAction)setDefaultPath:(id) sender;

- (IBAction)switchUseDefaultPath:(id) sender;

@end

@implementation PKGLocatorViewControllerStandard

- (void)awakeFromNib
{
	PKGBundleIdentifierFormatter * tFormatter=[PKGBundleIdentifierFormatter new];
	
	[_bundleIdentifierTextField setFormatter:tFormatter];
}

- (NSString *)nibName
{
	return @"MainView";
}

#pragma mark -

- (void)updateUI
{
	NSString * tString=self.settings[PKGLocatorStandardBundleIdentifierKey];
	
	[_bundleIdentifierTextField setStringValue:(tString!=nil) ? tString : @""];

	
	[_defaultPathCheckBox setEnabled:NO];
	
	[_defaultPathCheckBox setState:NSOffState];
	
	tString=self.settings[PKGLocatorStandardDefaultPathKey];
	
	if (tString!=nil)
	{
		[_defaultPathTextField setStringValue:tString];
		
		if ([tString length]>0)
		{
			NSNumber * tNumber=self.settings[PKGLocatorStandardPreferDefaultPathKey];
			
			[_defaultPathCheckBox setEnabled:YES];
			
			[_defaultPathCheckBox setState:([tNumber boolValue]==YES) ? NSOnState : NSOffState];
		}
	}
	else
	{
		[_defaultPathTextField setStringValue:@""];
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

- (IBAction)setBundleIdentifier:(id) sender
{
	NSString * tStringValue=[_bundleIdentifierTextField stringValue];
	
	if (tStringValue!=nil)
		self.settings[PKGLocatorStandardBundleIdentifierKey]=tStringValue;
}

- (IBAction)setDefaultPath:(id) sender
{
	NSString * tStringValue=[_defaultPathTextField stringValue];
	
	if (tStringValue!=nil)
		self.settings[PKGLocatorStandardDefaultPathKey]=tStringValue;
}

- (IBAction)switchUseDefaultPath:(id) sender
{
	self.settings[PKGLocatorStandardPreferDefaultPathKey]=@([_defaultPathCheckBox state]==NSOnState);
}

#pragma mark -

- (void)control:(NSControl *) inControl didFailToValidatePartialString:(NSString *) inPartialString errorDescription:(NSString *) inError
{
	if (inError!=nil && [inError isEqualToString:@"NSBeep"]==YES)
		NSBeep();
}

- (void)controlTextDidChange:(NSNotification *) inNotification
{
	if ([inNotification object]==_defaultPathTextField)
	{
		BOOL tValue=([[_defaultPathTextField stringValue] length]>0);
		
		[_defaultPathCheckBox setEnabled:tValue];
		
		if (tValue==NO)
		{
			[_defaultPathCheckBox setState:NSOffState];
			
			self.settings[PKGLocatorStandardPreferDefaultPathKey]=@(NO);
		}
	}
}

@end
