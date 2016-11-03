#import "PKGRequirementViewControllerDiskSpace.h"

#import "PKGDiskSpaceFormatter.h"

#import "PKGRequirement_DiskSpace+Constants.h"

@interface PKGRequirementViewControllerDiskSpace ()
{
	IBOutlet NSTextField * IBminimumValue_;
	
	IBOutlet NSPopUpButton * IBunit_;
}

- (IBAction)setMinimumValue:(id) sender;

- (IBAction)switchUnit:(id) sender;

@end

@implementation PKGRequirementViewControllerDiskSpace

- (NSString *)nibName
{
	return @"MainView";
}

- (void)awakeFromNib
{
	PKGDiskSpaceFormatter * tFormatter=[PKGDiskSpaceFormatter new];
	
	[IBminimumValue_ setFormatter:tFormatter];
}

- (void)updateUI
{
	// Minimum Size Value
		
	NSNumber * tNumber=self.settings[PKGRequirementDiskSpaceMinimumSizeValueKey];
	NSString * tStringValue=@"100";
	
	if (tNumber!=nil)
		tStringValue=[tNumber stringValue];
	
	[IBminimumValue_ setStringValue:tStringValue];
	
	// Minimum Size Unit
	
	tNumber=self.settings[PKGRequirementDiskSpaceMinimumSizeUnitKey];
	
	NSInteger tTag=PKGRequirementDiskSpaceSizeUnitMB;
	
	if (tNumber!=nil)
		tTag=[tNumber integerValue];
	
	[IBunit_ selectItemWithTag:tTag];
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
	return IBminimumValue_;
}

- (void)setNextKeyView:(NSView *) inView
{
	[IBminimumValue_ setNextKeyView:inView];
}

- (void)control:(NSControl *) inControl didFailToValidatePartialString:(NSString *) inPartialString errorDescription:(NSString *) inError
{
	if (inError!=nil && [inError isEqualToString:@"NSBeep"]==YES)
		NSBeep();
}

#pragma mark -

- (IBAction)setMinimumValue:(id) sender
{
	NSString * tStringValue=[IBminimumValue_ stringValue];
	
	self.settings[PKGRequirementDiskSpaceMinimumSizeValueKey]=@([tStringValue intValue]);
}

- (IBAction)switchUnit:(id) sender
{
	NSInteger tTag=[[sender selectedItem] tag];
	
	self.settings[PKGRequirementDiskSpaceMinimumSizeUnitKey]=@(tTag);
}

@end
