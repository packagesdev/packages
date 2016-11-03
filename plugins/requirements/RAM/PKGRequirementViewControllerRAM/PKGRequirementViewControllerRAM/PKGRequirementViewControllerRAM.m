#import "PKGRequirementViewControllerRAM.h"

#import "PKGRequirement_RAM+Constants.h"

@interface PKGRequirementViewControllerRAM ()
{
	IBOutlet NSSlider * _minimumRAMSlider;
}

- (IBAction)setMinimumRAM:(id) sender;

@end

@implementation PKGRequirementViewControllerRAM

- (void)updateUI
{
	// Mimimum Size Index
	
	NSNumber * tNumber=self.settings[PKGRequirementRAMMinimumSizeIndexKey];
	
	NSInteger tIndex;
	
	if (tNumber==nil)
		tIndex=PKGRequirementRAMMinimumSize512MBIndex;
	else
		tIndex=[tNumber integerValue];
	
	[_minimumRAMSlider setIntegerValue:tIndex];
}

#pragma mark -

- (NSDictionary *)defaultSettings
{
	return @{PKGRequirementRAMMinimumSizeIndexKey:@(PKGRequirementRAMMinimumSize512MBIndex)};
}

- (PKGRequirementType)requirementType
{
	return PKGRequirementTypeInstallation;
}

#pragma mark -

- (IBAction)setMinimumRAM:(id) sender
{
	NSInteger tIndex=[sender integerValue];
	
	self.settings[PKGRequirementRAMMinimumSizeIndexKey]=@(tIndex);
}

@end
