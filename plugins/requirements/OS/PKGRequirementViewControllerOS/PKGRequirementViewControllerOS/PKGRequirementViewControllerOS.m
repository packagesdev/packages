/*
Copyright (c) 2008-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGRequirementViewControllerOS.h"

#import "PKGRequirement_OS+Constants.h"

@interface PKGRequirementViewControllerOS ()
{
	IBOutlet NSPopUpButton * _minimumVersionPopupButton;
	
	IBOutlet NSPopUpButton * _diskTypePopupButton;
	
	IBOutlet NSSegmentedControl * _distributionSegmentedControl;
	
	NSMutableDictionary * _settings;
}

- (IBAction)switchDiskType:(id) sender;

- (IBAction)switchMinimumVersion:(id) sender;

- (IBAction)switchDistribution:(id) sender;

@end

@implementation PKGRequirementViewControllerOS

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

- (void)refreshUI
{
	// Disk Type
	
	NSNumber * tNumber=_settings[PKGRequirementOSTargetDiskKey];
	
	NSInteger tTag;
	
	if (tNumber==nil)
		tTag=PKGRequirementOSTargetDestinationDisk;
	else
		tTag=[tNumber integerValue];
	
	[_diskTypePopupButton selectItemWithTag:tTag];
	
	// Minimum Version
	
	tNumber=_settings[PKGRequirementOSMinimumVersionKey];
	
	if (tNumber==nil)
		tTag=PKGRequirementOSMinimumVersionLeopard;
	else
		tTag=[tNumber integerValue];
	
	[_minimumVersionPopupButton selectItemWithTag:tTag];
	
	// Distribution Type
	
	if (tTag==PKGRequirementOSMinimumVersionNotInstalled)
	{
		_distributionSegmentedControl.enabled=NO;
		
		[_distributionSegmentedControl selectSegmentWithTag:PKGRequirementOSDistributionAny];
	}
	else
	{
		tNumber=_settings[PKGRequirementOSDistributionKey];
	
		if (tNumber==nil)
			tTag=PKGRequirementOSDistributionAny;
		else
			tTag=[tNumber intValue];
		
		[_distributionSegmentedControl selectSegmentWithTag:tTag];
	}
}

#pragma mark -

- (NSDictionary *)defaultSettings
{
	return @{PKGRequirementOSTargetDiskKey:@(PKGRequirementOSTargetDestinationDisk),
			 PKGRequirementOSMinimumVersionKey:@(PKGRequirementOSMinimumVersionLeopard),
			 PKGRequirementOSDistributionKey:@(PKGRequirementOSDistributionAny)};
}

- (PKGRequirementType)requirementType
{
	NSNumber * tNumber=_settings[PKGRequirementOSTargetDiskKey];
	
	if (tNumber!=nil)
	{
		NSInteger tDiskType=[tNumber integerValue];
		
		if (tDiskType==PKGRequirementOSTargetStartupDisk)
			return PKGRequirementTypeInstallation;
		
		if (tDiskType==PKGRequirementOSTargetDestinationDisk)
			return PKGRequirementTypeTarget;
	}
	
	return PKGRequirementTypeUndefined;
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{    
    if (inMenuItem.action==@selector(switchMinimumVersion:))
    {
		if (inMenuItem.tag==PKGRequirementOSMinimumVersionNotInstalled)
		{
			NSInteger tTag;
			
			NSNumber * tNumber=_settings[PKGRequirementOSTargetDiskKey];
			
			if (tNumber==nil)
				tTag=PKGRequirementOSTargetDestinationDisk;
			else
				tTag=[tNumber integerValue];
		
			return (tTag!=PKGRequirementOSTargetStartupDisk);
		}
	}
	
	return YES;
}

#pragma mark -

- (IBAction)switchDiskType:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementOSTargetDiskKey]=@(tTag);
	
	if (tTag==PKGRequirementOSTargetStartupDisk)
	{
		NSNumber * tNumber=_settings[PKGRequirementOSMinimumVersionKey];
		
		tTag=[tNumber integerValue];
		
		if (tTag==PKGRequirementOSMinimumVersionNotInstalled)
		{
			_settings[PKGRequirementOSMinimumVersionKey]=@(PKGRequirementOSMinimumVersionLeopard);
			
			[_minimumVersionPopupButton selectItemWithTag:PKGRequirementOSMinimumVersionLeopard];
		}
		
		_distributionSegmentedControl.enabled=YES;
	}
	
	[self noteCheckTypeChange];
}

- (IBAction)switchMinimumVersion:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementOSMinimumVersionKey]=@(tTag);
	
	if (tTag==PKGRequirementOSMinimumVersionNotInstalled)
	{
		_settings[PKGRequirementOSDistributionKey]=@(PKGRequirementOSDistributionAny);
		
		_distributionSegmentedControl.enabled=NO;
		
		[_distributionSegmentedControl selectSegmentWithTag:PKGRequirementOSDistributionAny];
	}
	else
	{
		_distributionSegmentedControl.enabled=YES;
	}
}

- (IBAction)switchDistribution:(NSSegmentedControl *)sender
{
	NSInteger tTag=[[sender cell] tagForSegment:sender.selectedSegment];
	
	_settings[PKGRequirementOSDistributionKey]=@(tTag);
}

@end
