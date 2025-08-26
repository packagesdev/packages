#import "PKGRequirementViewControllerDiskSpace.h"

#import "PKGDiskSpaceFormatter.h"

#import "PKGRequirement_DiskSpace+Constants.h"

@interface PKGRequirementViewControllerDiskSpace ()
{
	IBOutlet NSTextField * _minimumValueTextField;
	
	IBOutlet NSPopUpButton * _unitPopUpButton;
	
	NSMutableDictionary * _settings;
}

- (IBAction)setMinimumValue:(id) sender;

- (IBAction)switchUnit:(id) sender;

@end

@implementation PKGRequirementViewControllerDiskSpace

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_minimumValueTextField.formatter=[PKGDiskSpaceFormatter new];
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
	// Minimum Size Value
		
	NSNumber * tNumber=_settings[PKGRequirementDiskSpaceMinimumSizeValueKey];
	NSString * tStringValue=@"100";
	
	if (tNumber!=nil)
		tStringValue=tNumber.stringValue;
	
	_minimumValueTextField.stringValue=tStringValue;
	
	// Minimum Size Unit
	
	tNumber=_settings[PKGRequirementDiskSpaceMinimumSizeUnitKey];
	
	NSInteger tTag=PKGRequirementDiskSpaceSizeUnitMB;
	
	if (tNumber!=nil)
		tTag=[tNumber integerValue];
	
	[_unitPopUpButton selectItemWithTag:tTag];
}

#pragma mark -

- (NSDictionary *)defaultSettings;
{
	return @{PKGRequirementDiskSpaceMinimumSizeValueKey:@(100),
			 PKGRequirementDiskSpaceMinimumSizeUnitKey:@(PKGRequirementDiskSpaceSizeUnitMB)};
}

- (PKGRequirementType)requirementType
{
	return PKGRequirementTypeTarget;
}

#pragma mark -

- (NSView *)previousKeyView
{
	return _minimumValueTextField;
}

- (void)setNextKeyView:(NSView *) inView
{
	_minimumValueTextField.nextKeyView=inView;
}

- (void)control:(NSControl *) inControl didFailToValidatePartialString:(NSString *) inPartialString errorDescription:(NSString *) inError
{
	if (inError!=nil && [inError isEqualToString:@"NSBeep"]==YES)
		NSBeep();
}

#pragma mark -

- (IBAction)setMinimumValue:(NSTextField *) sender
{
	NSString * tStringValue=_minimumValueTextField.stringValue;
	
	_settings[PKGRequirementDiskSpaceMinimumSizeValueKey]=@(tStringValue.intValue);
}

- (IBAction)switchUnit:(NSPopUpButton *) sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementDiskSpaceMinimumSizeUnitKey]=@(tTag);
}

@end
