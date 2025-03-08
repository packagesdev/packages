/*
Copyright (c) 2008-2023, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGRequirementViewControllerOS.h"

#import "PKGRequirement_OS+Constants.h"

#import "WBVersionPicker.h"

#import "WBMacOSVersionsHistory.h"

typedef NS_ENUM(NSUInteger, PKGRequirementOSInstallationStatus)
{
	PKGRequirementOSInstallationStatusInstalled=0,
	PKGRequirementOSInstallationStatusNotInstalled
};

@interface PKGRequirementViewControllerOS () <WBVersionPickerCellDelegate>
{
	IBOutlet NSPopUpButton * _diskTypePopupButton;
	
	IBOutlet NSPopUpButton * _installationStatusPopupButton;
	
	IBOutlet NSPopUpButton * _distributionPopupButton;
	
	
	IBOutlet WBVersionPicker * _minimumVersionPicker;
	
	IBOutlet NSTextField * _minimumVersionOSNameLabel;
	
	IBOutlet NSButton * _maximumVersionCheckBox;
	
	IBOutlet WBVersionPicker * _maximumVersionPicker;
	
	IBOutlet NSTextField * _maximumVersionOSNameLabel;
	
	
	NSMutableDictionary * _settings;
	
	
}

+ (NSString *)operatingSystemNameOfVersion:(WBVersion *)inVersion;

+ (WBMacOSVersionsHistory *)macOSVersionsHistory;

+ (WBVersion *)versionFromInteger:(NSInteger)inInteger;

+ (NSInteger)integerFromVersion:(WBVersion *)inVersion;

- (IBAction)switchDiskType:(id)sender;

- (IBAction)switchInstallationStatus:(id)sender;

- (IBAction)switchDistribution:(id)sender;

- (IBAction)setMinimumVersion:(id)sender;

- (IBAction)switchMaximumVersionStatus:(id)sender;

- (IBAction)setMaximumVersion:(id)sender;

@end

@implementation PKGRequirementViewControllerOS

+ (NSString *)operatingSystemNameOfVersion:(WBVersion *)inVersion
{
	NSArray * tNames=nil;
	
	WBVersionComponents * tVersionComponents=[[PKGRequirementViewControllerOS macOSVersionsHistory] components:WBMajorVersionUnit|WBMinorVersionUnit fromVersion:inVersion];
	
	if (tVersionComponents.majorVersion==10)
	{
		static NSArray * sKnownMacOS10Names=nil;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			sKnownMacOS10Names=@[
                                @"Cheetah",
                                @"Puma",
                                @"Jaguar",
                                @"Panther",
                                @"Tiger",
                                @"Leopard",
                                @"Snow Leopard",
                                @"Lion",
                                @"Mountain Lion",
                                @"Mavericks",
                                @"Yosemite",
                                @"El Capitan",
                                @"Sierra",
                                @"High Sierra",
                                @"Mojave",
                                @"Catalina"];
		});
        
		tNames=sKnownMacOS10Names;
	}
	else if (tVersionComponents.majorVersion==11)
	{
		return @"Big Sur";
	}
    else if (tVersionComponents.majorVersion==12)
    {
        return @"Monterey";
    }
    else if (tVersionComponents.majorVersion==13)
    {
        return @"Ventura";
    }
    else if (tVersionComponents.majorVersion==14)
    {
        return @"Sonoma";
    }
    else if (tVersionComponents.majorVersion==15)
    {
        return @"Sequoia";
    }
	
	NSInteger tMinorComponent=tVersionComponents.minorVersion;
	
	if (tMinorComponent<0 || tMinorComponent>=tNames.count)
		return @"-";
	
	return tNames[tMinorComponent];
}

+ (WBMacOSVersionsHistory *)macOSVersionsHistory
{
	static WBMacOSVersionsHistory * sMacOSVersionsHistory=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sMacOSVersionsHistory=[WBMacOSVersionsHistory versionsHistory];
	});
	
	return sMacOSVersionsHistory;
}

+ (WBVersion *)versionFromInteger:(NSInteger)inInteger
{
	WBVersionComponents * tVersionComponents=[WBVersionComponents new];
	
	NSInteger tInteger=inInteger;
	
	tVersionComponents.patchVersion=tInteger%100;
	
	tInteger/=100;
	
	tVersionComponents.minorVersion=tInteger%100;
	
	tInteger/=100;
	
	tVersionComponents.majorVersion=tInteger%100;
	
	return [[self macOSVersionsHistory] versionFromComponents:tVersionComponents];
}

+ (NSInteger)integerFromVersion:(WBVersion *)inVersion
{
	if (inVersion==nil)
		return 0;
	
	WBVersionComponents * tVersionComponents=[[self macOSVersionsHistory] components:WBMajorVersionUnit|WBMinorVersionUnit|WBPatchVersionUnit fromVersion:inVersion];
	
	if (tVersionComponents==nil)
		return 0;
	
	return (tVersionComponents.majorVersion*10000+tVersionComponents.minorVersion*100+tVersionComponents.patchVersion);
}

#pragma mark -

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_minimumVersionPicker.versionsHistory=[PKGRequirementViewControllerOS macOSVersionsHistory];
	_minimumVersionPicker.minVersion=[WBVersion macOSLeopardVersion];
	
	[_minimumVersionPicker sizeToFit];
	
	_minimumVersionPicker.delegate=self;
	
	_maximumVersionPicker.versionsHistory=[PKGRequirementViewControllerOS macOSVersionsHistory];
	_maximumVersionPicker.minVersion=[WBVersion macOSLeopardVersion];
	
	[_maximumVersionPicker sizeToFit];
	
	_maximumVersionPicker.delegate=self;
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
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

- (void)refreshUI
{
	// Disk Type
	
	NSNumber * tNumber=_settings[PKGRequirementOSTargetDiskKey];
	
	NSInteger tDiskTypeTag;
	
	if (tNumber==nil)
		tDiskTypeTag=PKGRequirementOSTargetDestinationDisk;
	else
		tDiskTypeTag=[tNumber integerValue];
	
	[_diskTypePopupButton selectItemWithTag:tDiskTypeTag];
	
	// Installation Status & Minimum Version & Maximum Version
	
	NSInteger tInstallationStatusTag=PKGRequirementOSInstallationStatusInstalled;
	
	NSInteger tMinimumOSVersion=PKGRequirementOSMinimumVersionLeopard;
	NSInteger tMaximumOSVersion=PKGRequirementOSMaximumVersionNotDefined;
	
	tNumber=_settings[PKGRequirementOSMinimumVersionKey];
	
	if (tNumber!=nil)
		tMinimumOSVersion=[tNumber integerValue];
	
	if (tMinimumOSVersion==PKGRequirementOSMinimumVersionNotInstalled)
	{
		if (tDiskTypeTag==PKGRequirementOSTargetStartupDisk)
		{
			// This does not make sense
			
			tMinimumOSVersion=PKGRequirementOSMinimumVersionLeopard;
			tMaximumOSVersion=PKGRequirementOSMaximumVersionNotDefined;
			
			_minimumVersionPicker.enabled=YES;
			_minimumVersionOSNameLabel.textColor=[NSColor colorWithDeviceWhite:0.25 alpha:1.0];
			_maximumVersionCheckBox.enabled=YES;
		}
		else
		{
			tMinimumOSVersion=PKGRequirementOSMinimumVersionLeopard;
			tMaximumOSVersion=PKGRequirementOSMaximumVersionNotDefined;
			tInstallationStatusTag=PKGRequirementOSInstallationStatusNotInstalled;
			
			_minimumVersionPicker.enabled=NO;
			_minimumVersionOSNameLabel.textColor=[NSColor secondaryLabelColor];
			_maximumVersionCheckBox.enabled=NO;
		}
	}
	else
	{
		if (tMinimumOSVersion<PKGRequirementOSMinimumVersionLeopard)
			tMinimumOSVersion=PKGRequirementOSMinimumVersionLeopard;
		
		_minimumVersionPicker.enabled=YES;
		_minimumVersionOSNameLabel.textColor=[NSColor labelColor];
		_maximumVersionCheckBox.enabled=YES;
	}
	
	[_installationStatusPopupButton selectItemWithTag:tInstallationStatusTag];
	
	
	_minimumVersionPicker.versionValue=[PKGRequirementViewControllerOS versionFromInteger:tMinimumOSVersion];
	
	_minimumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:_minimumVersionPicker.versionValue];
	
	tNumber=_settings[PKGRequirementOSMaximumVersionKey];
	
	if (tNumber!=nil)
		tMaximumOSVersion=[tNumber integerValue];
	
	_maximumVersionCheckBox.state=(tMaximumOSVersion==PKGRequirementOSMaximumVersionNotDefined) ? NSOffState : NSOnState;
	_maximumVersionPicker.enabled=(tMaximumOSVersion!=PKGRequirementOSMaximumVersionNotDefined);
	
	if (tMaximumOSVersion==PKGRequirementOSMaximumVersionNotDefined)
	{
		tMaximumOSVersion=tMinimumOSVersion;
	
		_maximumVersionOSNameLabel.textColor=[NSColor secondaryLabelColor];
	}
	else
	{
		_maximumVersionOSNameLabel.textColor=[NSColor labelColor];
	}
	
	_maximumVersionPicker.versionValue=[PKGRequirementViewControllerOS versionFromInteger:tMaximumOSVersion];
	
	_maximumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:_maximumVersionPicker.versionValue];
	
	// Distribution Type
	
	if (tInstallationStatusTag==PKGRequirementOSInstallationStatusNotInstalled)
	{
		_distributionPopupButton.enabled=NO;
		[_distributionPopupButton selectItemWithTag:PKGRequirementOSDistributionAny];
	}
	else
	{
		NSInteger tTag=PKGRequirementOSDistributionAny;
		
		tNumber=_settings[PKGRequirementOSDistributionKey];
		
		if (tNumber!=nil)
			tTag=[tNumber integerValue];
		
		[_distributionPopupButton selectItemWithTag:tTag];
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

- (IBAction)switchDiskType:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementOSTargetDiskKey]=@(tTag);
	
	if (tTag==PKGRequirementOSTargetStartupDisk)
	{
		[_installationStatusPopupButton selectItemWithTag:PKGRequirementOSInstallationStatusInstalled];
		
		NSNumber * tNumber=_settings[PKGRequirementOSMinimumVersionKey];
		
		tTag=[tNumber integerValue];
		
		if (tTag==PKGRequirementOSMinimumVersionNotInstalled)
		{
			_settings[PKGRequirementOSMinimumVersionKey]=@(PKGRequirementOSMinimumVersionLeopard);
			
			
			_minimumVersionPicker.versionValue=[PKGRequirementViewControllerOS versionFromInteger:PKGRequirementOSMinimumVersionLeopard];
			_minimumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:_minimumVersionPicker.versionValue];
			_minimumVersionOSNameLabel.textColor=[NSColor labelColor];
			
			[_settings removeObjectForKey:PKGRequirementOSMaximumVersionKey];
			
			_maximumVersionCheckBox.state=NSOffState;
			_maximumVersionPicker.enabled=NO;
			
			_maximumVersionPicker.versionValue=[PKGRequirementViewControllerOS versionFromInteger:PKGRequirementOSMinimumVersionLeopard];
			_maximumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:_maximumVersionPicker.versionValue];
		}
		
		_maximumVersionCheckBox.enabled=YES;
		
		_minimumVersionPicker.enabled=YES;
		
		_distributionPopupButton.enabled=YES;
	}
	
	[self noteCheckTypeChange];
}

- (IBAction)switchInstallationStatus:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	if (tTag==PKGRequirementOSInstallationStatusNotInstalled)
	{
		_settings[PKGRequirementOSDistributionKey]=@(PKGRequirementOSDistributionAny);
		
		_distributionPopupButton.enabled=NO;
		[_distributionPopupButton selectItemWithTag:PKGRequirementOSDistributionAny];
		
		_settings[PKGRequirementOSMinimumVersionKey]=@(PKGRequirementOSMinimumVersionNotInstalled);
		
		_minimumVersionPicker.enabled=NO;
		_minimumVersionPicker.versionValue=[PKGRequirementViewControllerOS versionFromInteger:PKGRequirementOSMinimumVersionLeopard];
		_minimumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:_minimumVersionPicker.versionValue];
		_minimumVersionOSNameLabel.textColor=[NSColor secondaryLabelColor];
		
		[_settings removeObjectForKey:PKGRequirementOSMaximumVersionKey];
		
		_maximumVersionCheckBox.enabled=NO;
		_maximumVersionCheckBox.state=NSOffState;
		
		_maximumVersionPicker.enabled=NO;
		_maximumVersionPicker.minVersion=_minimumVersionPicker.versionValue;
		_maximumVersionPicker.versionValue=[PKGRequirementViewControllerOS versionFromInteger:PKGRequirementOSMinimumVersionLeopard];
		_maximumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:_maximumVersionPicker.versionValue];
		_maximumVersionOSNameLabel.textColor=[NSColor secondaryLabelColor];
	}
	else
	{
		_distributionPopupButton.enabled=YES;
		
		_settings[PKGRequirementOSMinimumVersionKey]=@(PKGRequirementOSMinimumVersionLeopard);
		
		_minimumVersionPicker.enabled=YES;
		_minimumVersionOSNameLabel.textColor=[NSColor labelColor];
		
		_maximumVersionCheckBox.enabled=YES;
	}
}

- (IBAction)switchDistribution:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	_settings[PKGRequirementOSDistributionKey]=@(tTag);
}

- (IBAction)setMinimumVersion:(WBVersionPicker *)sender
{
	WBVersion * tVersion=[sender versionValue];
	
	NSInteger tMinInteger=[PKGRequirementViewControllerOS integerFromVersion:tVersion];
	
	_settings[PKGRequirementOSMinimumVersionKey]=@(tMinInteger);
	
	_minimumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:tVersion];
	
	_maximumVersionPicker.minVersion=tVersion;
	
	NSInteger tMaxInteger=[_settings[PKGRequirementOSMaximumVersionKey] integerValue];
	NSInteger tEffectiveMaxInteger=(tMaxInteger==PKGRequirementOSMaximumVersionNotDefined) ? PKGRequirementOSMinimumVersionLeopard : tMaxInteger;
	
	if (tEffectiveMaxInteger<=tMinInteger)
	{
		if (tMaxInteger!=PKGRequirementOSMaximumVersionNotDefined)
			_settings[PKGRequirementOSMaximumVersionKey]=@(tMinInteger);
		
		_maximumVersionPicker.versionValue=tVersion;
		
		_maximumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:tVersion];
	}
}

- (IBAction)switchMaximumVersionStatus:(NSButton *)sender
{
	NSInteger tState=sender.state;
	
	if (tState==NSOffState)
	{
		NSNumber * tNumber=_settings[PKGRequirementOSMaximumVersionKey];
		
		if (tNumber==nil || [tNumber integerValue]==PKGRequirementOSMaximumVersionNotDefined)
			return;
		
		[_settings removeObjectForKey:PKGRequirementOSMaximumVersionKey];
		
		_maximumVersionPicker.enabled=NO;
		_maximumVersionOSNameLabel.textColor=[NSColor secondaryLabelColor];
	}
	else
	{
		_maximumVersionPicker.enabled=YES;
		_maximumVersionOSNameLabel.textColor=[NSColor labelColor];
		
		_settings[PKGRequirementOSMaximumVersionKey]=[_settings[PKGRequirementOSMinimumVersionKey] copy];
	}
	
	_maximumVersionPicker.minVersion=_minimumVersionPicker.versionValue;
	_maximumVersionPicker.versionValue=_minimumVersionPicker.versionValue;
	_maximumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:_maximumVersionPicker.versionValue];
}

- (IBAction)setMaximumVersion:(WBVersionPicker *)sender
{
	WBVersion * tVersion=[sender versionValue];
	
	NSInteger tMaxInteger=[PKGRequirementViewControllerOS integerFromVersion:tVersion];
	
	_settings[PKGRequirementOSMaximumVersionKey]=@(tMaxInteger);
	
	_maximumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOS operatingSystemNameOfVersion:tVersion];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchInstallationStatus:))
	{
		if (inMenuItem.tag==PKGRequirementOSInstallationStatusNotInstalled)
			return ([_settings[PKGRequirementOSTargetDiskKey] integerValue]!=PKGRequirementOSTargetStartupDisk);
	}
	
	return YES;
}

#pragma mark -

- (BOOL)versionPickerCell:(WBVersionPickerCell *)inVersionPickerCell shouldSelectElementType:(WBVersionPickerCellElementType)inElementType
{	
	return YES;
	
	//return (inElementType!=WBVersionPickerCellElementMajorVersion);
}

@end
