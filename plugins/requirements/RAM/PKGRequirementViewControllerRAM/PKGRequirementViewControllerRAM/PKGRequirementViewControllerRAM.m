/*
 Copyright (c) 2008-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementViewControllerRAM.h"

#import "PKGRequirement_RAM+Constants.h"

@interface PKGRequirementViewControllerRAM ()
{
	IBOutlet NSPopUpButton * _minimumRAMPopUpButton;
	
	NSMutableDictionary * _settings;
}

- (IBAction)switchMinimumRAM:(id) sender;

@end

@implementation PKGRequirementViewControllerRAM

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
	// Mimimum Size Index
	
	NSInteger tTag=PKGRequirementRAMMinimumSize512MBIndex;
	
	NSNumber * tNumber=_settings[PKGRequirementRAMMinimumSizeIndexKey];
	
	if (tNumber!=nil)
		tTag=tNumber.integerValue;
	
	if ([_minimumRAMPopUpButton selectItemWithTag:tTag]==NO)
	{
		[_minimumRAMPopUpButton selectItemWithTag:PKGRequirementRAMMinimumSize512MBIndex];
	}
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

- (IBAction)switchMinimumRAM:(NSPopUpButton *) sender
{
	NSInteger tTag=sender.selectedTag;
	
	_settings[PKGRequirementRAMMinimumSizeIndexKey]=@(tTag);
}

@end
