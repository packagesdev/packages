#import "PKGRequirementViewControllerCPU.h"

#import "PKGRequirement_CPU+Constants.h"

@interface PKGRequirementViewControllerCPU ()
{
	IBOutlet NSSegmentedControl * _minimumCPUCoresCountSegmentedControl;
	
	IBOutlet NSSegmentedControl * _CPUArchitectureSegmentedControl;
	
	IBOutlet NSSegmentedControl * _PowerPCArchitectureSegmentedControl;
	
	IBOutlet NSSegmentedControl * _IntelArchitectureSegmentedControl;
	
	IBOutlet NSPopUpButton * _minimumCPUFrequencyPopupButton;
}

- (IBAction)switchMinimumCPUCoresCount:(id) sender;

- (IBAction)switchCPUArchitecture:(id) sender;

- (IBAction)switchPowerPCArchitecture:(id) sender;

- (IBAction)switchIntelArchitecture:(id) sender;

- (IBAction)switchMinimumCPUFrequency:(id) sender;

@end

@implementation PKGRequirementViewControllerCPU

- (NSString *)nibName
{
	return @"MainView";
}

- (void)updateUI
{
	NSNumber * tNumber;
	NSInteger tTag;
	NSInteger tSubTag;
	
	// Minimum Number of CPU Cores
	
	tNumber=self.settings[PKGRequirementCPUMinimumCPUCoresCountKey];
	
	if (tNumber==nil)
		tTag=1;
	else
		tTag=[tNumber integerValue];
	
	[_minimumCPUCoresCountSegmentedControl selectSegmentWithTag:tTag];
	
	// CPU Family
	
	tNumber=[self.settings objectForKey:PKGRequirementCPUArchitectureFamilyKey];
	
	tTag=(tNumber==nil) ? 1 : [tNumber integerValue];
	
	[_CPUArchitectureSegmentedControl selectSegmentWithTag:tTag];
	
	// PowerPC
	
	if (tTag==PKGRequirementCPUFamilyIntel)
	{
		[_PowerPCArchitectureSegmentedControl setEnabled:NO];
		
		[_PowerPCArchitectureSegmentedControl selectSegmentWithTag:PKGRequirementCPUGenerationAny];
	}
	else
	{
		tNumber=[self.settings objectForKey:PKGRequirementCPUPowerPCArchitectureTypeKey];
		
		tSubTag=(tNumber==nil) ? PKGRequirementCPUGenerationAny : [tNumber integerValue];
	
		[_PowerPCArchitectureSegmentedControl selectSegmentWithTag:tSubTag];
	}
	
	// Intel
	
	if (tTag==PKGRequirementCPUFamilyPowerPC)
	{
		[_IntelArchitectureSegmentedControl setEnabled:NO];
		
		[_IntelArchitectureSegmentedControl selectSegmentWithTag:PKGRequirementCPUGenerationAny];
	}
	else
	{
		tNumber=[self.settings objectForKey:PKGRequirementCPUIntelArchitectureTypeKey];
		
		tSubTag=(tNumber==nil) ? PKGRequirementCPUGenerationAny : [tNumber integerValue];
	
		[_IntelArchitectureSegmentedControl selectSegmentWithTag:tSubTag];
	}
	
	// Minimum CPU Frequency
	
	tNumber=self.settings[PKGRequirementCPUMinimumFrequencyKey];
	
	tTag=(tNumber==nil) ? CPU_MINIMUM_FREQUENCY : [tNumber integerValue];
	
	[_minimumCPUFrequencyPopupButton selectItemWithTag:tTag];
}

#pragma mark -

- (NSDictionary *)defaultSettings
{
	return @{PKGRequirementCPUMinimumCPUCoresCountKey:@(1),
			 PKGRequirementCPUArchitectureFamilyKey:@(PKGRequirementCPUFamilyAny),
			 PKGRequirementCPUPowerPCArchitectureTypeKey:@(PKGRequirementCPUGenerationAny),
			 PKGRequirementCPUIntelArchitectureTypeKey:@(PKGRequirementCPUGenerationAny),
			 PKGRequirementCPUMinimumFrequencyKey:@(CPU_MINIMUM_FREQUENCY)};
}

- (PKGRequirementType)requirementType
{
	return PKGRequirementTypeInstallation;
}

#pragma mark -

- (IBAction)switchMinimumCPUCoresCount:(id) sender
{
	NSInteger tTag=[[sender cell] tagForSegment:[sender selectedSegment]];
	
	self.settings[PKGRequirementCPUMinimumCPUCoresCountKey]=@(tTag);
}

- (IBAction)switchCPUArchitecture:(id) sender
{
	NSInteger tTag=[[sender cell] tagForSegment:[sender selectedSegment]];
	
	NSNumber * tNumber=self.settings[PKGRequirementCPUArchitectureFamilyKey];
	
	if (tNumber!=nil && [tNumber integerValue]!=tTag)
	{
		self.settings[PKGRequirementCPUArchitectureFamilyKey]=@(tTag);
			
			// PowerPC Type
			
		if (tTag==PKGRequirementCPUFamilyIntel)
		{
			[_PowerPCArchitectureSegmentedControl setEnabled:NO];
			
			self.settings[PKGRequirementCPUPowerPCArchitectureTypeKey]=@(PKGRequirementCPUGenerationAny);
			
			[_PowerPCArchitectureSegmentedControl selectSegmentWithTag:PKGRequirementCPUGenerationAny];
		}
		else
		{
			[_PowerPCArchitectureSegmentedControl setEnabled:YES];
			
			[_PowerPCArchitectureSegmentedControl selectSegmentWithTag:[self.settings[PKGRequirementCPUPowerPCArchitectureTypeKey] integerValue]];
		}
		
		// Intel
		
		if (tTag==PKGRequirementCPUFamilyPowerPC)
		{
			[_IntelArchitectureSegmentedControl setEnabled:NO];
			
			self.settings[PKGRequirementCPUIntelArchitectureTypeKey]=@(PKGRequirementCPUGenerationAny);
			
			[_IntelArchitectureSegmentedControl selectSegmentWithTag:PKGRequirementCPUGenerationAny];
		}
		else
		{
			[_IntelArchitectureSegmentedControl setEnabled:YES];
			
			[_IntelArchitectureSegmentedControl selectSegmentWithTag:[self.settings[PKGRequirementCPUIntelArchitectureTypeKey] integerValue]];
		}
	}
}

- (IBAction)switchPowerPCArchitecture:(id) sender
{
	NSInteger tTag=[[sender cell] tagForSegment:[sender selectedSegment]];
	
	self.settings[PKGRequirementCPUPowerPCArchitectureTypeKey]=@(tTag);
}

- (IBAction)switchIntelArchitecture:(id) sender
{
	NSInteger tTag=[[sender cell] tagForSegment:[sender selectedSegment]];
	
	self.settings[PKGRequirementCPUIntelArchitectureTypeKey]=@(tTag);
}

- (IBAction)switchMinimumCPUFrequency:(id) sender
{
	NSInteger tTag=[[sender selectedItem] tag];
	
	self.settings[PKGRequirementCPUMinimumFrequencyKey]=@(tTag);
}

@end
