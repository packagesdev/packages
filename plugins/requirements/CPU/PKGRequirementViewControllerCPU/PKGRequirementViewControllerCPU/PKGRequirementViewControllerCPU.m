#import "PKGRequirementViewControllerCPU.h"

#import "PKGRequirement_CPU+Constants.h"

@interface PKGRequirementViewControllerCPU ()
{
	IBOutlet NSSegmentedControl * _minimumCPUCoresCountSegmentedControl;
	
	IBOutlet NSSegmentedControl * _CPUArchitectureSegmentedControl;
	
	IBOutlet NSSegmentedControl * _PowerPCArchitectureSegmentedControl;
	
	IBOutlet NSSegmentedControl * _IntelArchitectureSegmentedControl;
	
	IBOutlet NSPopUpButton * _minimumCPUFrequencyPopupButton;
	
	NSMutableDictionary * _settings;
}

- (IBAction)switchMinimumCPUCoresCount:(id) sender;

- (IBAction)switchCPUArchitecture:(id) sender;

- (IBAction)switchPowerPCArchitecture:(id) sender;

- (IBAction)switchIntelArchitecture:(id) sender;

- (IBAction)switchMinimumCPUFrequency:(id) sender;

@end

@implementation PKGRequirementViewControllerCPU

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
}

#pragma mark -

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
	// Minimum Number of CPU Cores
	
	NSNumber * tNumber=_settings[PKGRequirementCPUMinimumCPUCoresCountKey];
	NSInteger tTag;
	NSInteger tSubTag;
	
	if (tNumber==nil)
		tTag=1;
	else
		tTag=[tNumber integerValue];
	
	[_minimumCPUCoresCountSegmentedControl selectSegmentWithTag:tTag];
	
	// CPU Family
	
	tNumber=_settings[PKGRequirementCPUArchitectureFamilyKey];
	
	tTag=(tNumber==nil) ? 1 : [tNumber integerValue];
	
	[_CPUArchitectureSegmentedControl selectSegmentWithTag:tTag];
	
	// PowerPC
	
	if (tTag==PKGRequirementCPUFamilyIntel)
	{
		_PowerPCArchitectureSegmentedControl.enabled=NO;
		
		[_PowerPCArchitectureSegmentedControl selectSegmentWithTag:PKGRequirementCPUGenerationAny];
	}
	else
	{
		tNumber=_settings[PKGRequirementCPUPowerPCArchitectureTypeKey];
		
		tSubTag=(tNumber==nil) ? PKGRequirementCPUGenerationAny : [tNumber integerValue];
	
		[_PowerPCArchitectureSegmentedControl selectSegmentWithTag:tSubTag];
	}
	
	// Intel
	
	if (tTag==PKGRequirementCPUFamilyPowerPC)
	{
		_IntelArchitectureSegmentedControl.enabled=NO;
		
		[_IntelArchitectureSegmentedControl selectSegmentWithTag:PKGRequirementCPUGenerationAny];
	}
	else
	{
		tNumber=_settings[PKGRequirementCPUIntelArchitectureTypeKey];
		
		tSubTag=(tNumber==nil) ? PKGRequirementCPUGenerationAny : [tNumber integerValue];
	
		[_IntelArchitectureSegmentedControl selectSegmentWithTag:tSubTag];
	}
	
	// Minimum CPU Frequency
	
	tNumber=_settings[PKGRequirementCPUMinimumFrequencyKey];
	
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

- (IBAction)switchMinimumCPUCoresCount:(NSSegmentedControl *) sender
{
	NSInteger tTag=[[sender cell] tagForSegment:sender.selectedSegment];
	
	_settings[PKGRequirementCPUMinimumCPUCoresCountKey]=@(tTag);
}

- (IBAction)switchCPUArchitecture:(NSSegmentedControl *) sender
{
	NSInteger tTag=[[sender cell] tagForSegment:sender.selectedSegment];
	
	NSNumber * tNumber=_settings[PKGRequirementCPUArchitectureFamilyKey];
	
	if (tNumber!=nil && [tNumber integerValue]!=tTag)
	{
		_settings[PKGRequirementCPUArchitectureFamilyKey]=@(tTag);
			
			// PowerPC Type
			
		if (tTag==PKGRequirementCPUFamilyIntel)
		{
			_PowerPCArchitectureSegmentedControl.enabled=NO;
			
			_settings[PKGRequirementCPUPowerPCArchitectureTypeKey]=@(PKGRequirementCPUGenerationAny);
			
			[_PowerPCArchitectureSegmentedControl selectSegmentWithTag:PKGRequirementCPUGenerationAny];
		}
		else
		{
			_PowerPCArchitectureSegmentedControl.enabled=YES;
			
			[_PowerPCArchitectureSegmentedControl selectSegmentWithTag:[_settings[PKGRequirementCPUPowerPCArchitectureTypeKey] integerValue]];
		}
		
		// Intel
		
		if (tTag==PKGRequirementCPUFamilyPowerPC)
		{
			_IntelArchitectureSegmentedControl.enabled=NO;
			
			_settings[PKGRequirementCPUIntelArchitectureTypeKey]=@(PKGRequirementCPUGenerationAny);
			
			[_IntelArchitectureSegmentedControl selectSegmentWithTag:PKGRequirementCPUGenerationAny];
		}
		else
		{
			_IntelArchitectureSegmentedControl.enabled=YES;
			
			[_IntelArchitectureSegmentedControl selectSegmentWithTag:[_settings[PKGRequirementCPUIntelArchitectureTypeKey] integerValue]];
		}
	}
}

- (IBAction)switchPowerPCArchitecture:(NSSegmentedControl *) sender
{
	NSInteger tTag=[[sender cell] tagForSegment:sender.selectedSegment];
	
	_settings[PKGRequirementCPUPowerPCArchitectureTypeKey]=@(tTag);
}

- (IBAction)switchIntelArchitecture:(NSSegmentedControl *) sender
{
	NSInteger tTag=[[sender cell] tagForSegment:sender.selectedSegment];
	
	_settings[PKGRequirementCPUIntelArchitectureTypeKey]=@(tTag);
}

- (IBAction)switchMinimumCPUFrequency:(NSPopUpButton *) sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementCPUMinimumFrequencyKey]=@(tTag);
}

@end
