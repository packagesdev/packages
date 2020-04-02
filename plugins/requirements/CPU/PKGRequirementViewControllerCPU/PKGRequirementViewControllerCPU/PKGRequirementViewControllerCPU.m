/*
 Copyright (c) 2008-2020, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementViewControllerCPU.h"

#import "PKGRequirement_CPU+Constants.h"

@interface PKGRequirementViewControllerCPU ()
{
	IBOutlet NSPopUpButton * _minimumCPUCoresCountPopupButton;
	
	IBOutlet NSSegmentedControl * _CPUArchitectureSegmentedControl;
	
	IBOutlet NSSegmentedControl * _PowerPCArchitectureSegmentedControl;
	
	IBOutlet NSSegmentedControl * _IntelArchitectureSegmentedControl;
	
	IBOutlet NSPopUpButton * _minimumCPUFrequencyPopupButton;
	
	NSMutableDictionary * _settings;
}

- (IBAction)switchMinimumCPUCoresCount:(id)sender;

- (IBAction)switchCPUArchitecture:(id)sender;

- (IBAction)switchPowerPCArchitecture:(id)sender;

- (IBAction)switchIntelArchitecture:(id)sender;

- (IBAction)switchMinimumCPUFrequency:(id)sender;

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
	
	[_minimumCPUCoresCountPopupButton selectItemWithTag:tTag];
	
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

- (IBAction)switchMinimumCPUCoresCount:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementCPUMinimumCPUCoresCountKey]=@(tTag);
}

- (IBAction)switchCPUArchitecture:(NSSegmentedControl *)sender
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

- (IBAction)switchPowerPCArchitecture:(NSSegmentedControl *)sender
{
	NSInteger tTag=[[sender cell] tagForSegment:sender.selectedSegment];
	
	_settings[PKGRequirementCPUPowerPCArchitectureTypeKey]=@(tTag);
}

- (IBAction)switchIntelArchitecture:(NSSegmentedControl *)sender
{
	NSInteger tTag=[[sender cell] tagForSegment:sender.selectedSegment];
	
	_settings[PKGRequirementCPUIntelArchitectureTypeKey]=@(tTag);
}

- (IBAction)switchMinimumCPUFrequency:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementCPUMinimumFrequencyKey]=@(tTag);
}

@end
