/*
Copyright (c) 2025, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGRequirementViewControllerOSRanges.h"

#import "PKGRequirement_OSRanges+Constants.h"

#import "WBVersionPicker.h"

#import "WBMacOSVersionsHistory.h"

typedef NS_ENUM(NSUInteger, PKGRequirementOSInstallationStatus)
{
	PKGRequirementOSInstallationStatusInstalled=0,
	PKGRequirementOSInstallationStatusNotInstalled
};


@interface PKGVersionTableCellView : NSTableCellView

@property (assign) IBOutlet WBVersionPicker * versionPicker;

@property (assign) IBOutlet NSTextField * versionOSNameLabel;

@end

@implementation PKGVersionTableCellView

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
	
	/*NSRect tBounds=self.bounds;
	NSRect tPopUpFrame=self.popUpButton.frame;
	
	tPopUpFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tPopUpFrame)*0.5);
	self.popUpButton.frame=tPopUpFrame;*/
}

@end

@interface PKGBeforeVersionTableCellView : PKGVersionTableCellView

@property (assign) IBOutlet NSButton *enabledCheckbox;

@end



@implementation PKGBeforeVersionTableCellView

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
	
	/*NSRect tBounds=self.bounds;
	 NSRect tPopUpFrame=self.popUpButton.frame;
	 
	 tPopUpFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tPopUpFrame)*0.5);
	 self.popUpButton.frame=tPopUpFrame;*/
}

@end



@interface PKGRequirementViewControllerOSRanges () <NSTableViewDataSource, NSTableViewDelegate, WBVersionPickerCellDelegate>
{
	IBOutlet NSTableView * _tableView;
	
	IBOutlet NSButton * _addButton;
	IBOutlet NSButton * _removeButton;
	
	// Data
	
	NSMutableArray <NSDictionary *> * _cachedOSRanges;
	
	NSMutableDictionary * _settings;
	
	
}

+ (NSString *)operatingSystemNameOfVersion:(WBVersion *)inVersion;

+ (WBMacOSVersionsHistory *)macOSVersionsHistory;

+ (WBVersion *)versionFromInteger:(NSInteger)inInteger;

+ (NSInteger)integerFromVersion:(WBVersion *)inVersion;

- (IBAction)addOSRange:(id)sender;
- (IBAction)delete:(id)sender;

@end

@implementation PKGRequirementViewControllerOSRanges

+ (NSString *)operatingSystemNameOfVersion:(WBVersion *)inVersion
{
	NSArray * tNames=nil;
	
	WBVersionComponents * tVersionComponents=[[self macOSVersionsHistory] components:WBMajorVersionUnit|WBMinorVersionUnit fromVersion:inVersion];
	
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
	
	_cachedOSRanges=[_settings[PKGRequirementOSRangesListKey] mutableCopy];
	
	if (_cachedOSRanges==nil)
		_cachedOSRanges=[NSMutableArray array];
	
	_settings[PKGRequirementOSRangesListKey]=_cachedOSRanges;
	
	[self refreshUI];
}

- (NSDictionary *)settings
{
	return [_settings copy];
}

- (void)refreshUI
{
	_addButton.enabled=YES;
	_removeButton.enabled=NO;
	
	[_tableView reloadData];
	
	[_tableView deselectAll:self];
}

#pragma mark -

- (NSDictionary *)defaultSettings
{
	return @{
		PKGRequirementOSRangesListKey:@[]
	};
}

- (PKGRequirementDomains)requirementDomains
{
	return PKGRequirementDomainDistribution;
}

- (PKGRequirementType)requirementType
{
	return PKGRequirementTypeTarget;
}

#pragma mark -

- (IBAction)addOSRange:(id)sender
{
	NSUInteger tRowIndex=_cachedOSRanges.count;
	
	NSMutableDictionary<NSString *, NSString *> * tOSRange = [@{PKGRequirementOSRangeMinimumVersionKey:@(100606)} mutableCopy];
	
	[_cachedOSRanges addObject:tOSRange];
	
	[_tableView deselectAll:self];
	
	[_tableView reloadData];
	
	[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tRowIndex] byExtendingSelection:NO];
	
	//[_tableView editColumn:0 row:tRowIndex withEvent:nil select:YES];
}

- (IBAction)delete:(id)sender
{
}

#pragma mark -

- (NSView *)previousKeyView
{
	return _tableView;
}

- (void)setNextKeyView:(NSView *) inView
{
	_tableView.nextKeyView=inView;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView==_tableView)
		return _cachedOSRanges.count;
	
	return 0;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=_tableView || inTableColumn==nil)
		return nil;
	
	if (inRow>=_cachedOSRanges.count)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	
	if ([tTableColumnIdentifier isEqualToString:@"version.minimum"]==YES)
	{
		PKGVersionTableCellView * tVersionMinimumView=(PKGVersionTableCellView *)[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		WBVersionPicker * tVersionPicker=tVersionMinimumView.versionPicker;
		
		NSDictionary<NSString *, NSString *> *osRangeDictionary=_cachedOSRanges[inRow];
		
		tVersionPicker.drawsBackground = YES;
		tVersionPicker.versionsHistory=[self.class macOSVersionsHistory];
		tVersionPicker.minVersion=[WBVersion macOSSnowLeopardVersion];
		
		//[tVersionPicker sizeToFit];
		
		tVersionPicker.delegate=self;
		
		tVersionMinimumView.versionPicker.versionValue=[PKGRequirementViewControllerOSRanges versionFromInteger:[osRangeDictionary[PKGRequirementOSRangeMinimumVersionKey] integerValue]];
		
		tVersionMinimumView.versionOSNameLabel.stringValue = [PKGRequirementViewControllerOSRanges operatingSystemNameOfVersion:tVersionMinimumView.versionPicker.versionValue];
		
		return tVersionMinimumView;
	}
	else if ([tTableColumnIdentifier isEqualToString:@"version.before"]==YES)
	{
		PKGBeforeVersionTableCellView *tVersionBeforeView=(PKGBeforeVersionTableCellView *)[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		WBVersionPicker * tVersionPicker=tVersionBeforeView.versionPicker;
		
		NSDictionary<NSString *, NSString *> *osRangeDictionary=_cachedOSRanges[inRow];
		
		tVersionPicker.drawsBackground = YES;
		tVersionPicker.versionsHistory=[self.class macOSVersionsHistory];
		tVersionPicker.minVersion=[PKGRequirementViewControllerOSRanges versionFromInteger:[osRangeDictionary[PKGRequirementOSRangeMinimumVersionKey] integerValue]];
		
		//[tVersionPicker sizeToFit];
		
		tVersionPicker.delegate=self;
		
		NSString *beforeVersionString = osRangeDictionary[PKGRequirementOSRangeBeforeVersionKey];
		
		if (beforeVersionString==nil)
		{
			tVersionBeforeView.enabledCheckbox.state = NSOffState;
			
			tVersionPicker.enabled = NO;
			
			tVersionBeforeView.versionPicker.versionValue=[PKGRequirementViewControllerOSRanges versionFromInteger:[beforeVersionString integerValue]];
			
			tVersionBeforeView.versionOSNameLabel.stringValue = @"-";
		}
		else
		{
			tVersionBeforeView.enabledCheckbox.state = NSOnState;
			
			tVersionPicker.enabled = YES;
			
			tVersionBeforeView.versionPicker.versionValue=[PKGRequirementViewControllerOSRanges versionFromInteger:[beforeVersionString integerValue]];
			
			tVersionBeforeView.versionOSNameLabel.stringValue = [PKGRequirementViewControllerOSRanges operatingSystemNameOfVersion:tVersionBeforeView.versionPicker.versionValue];
		}
		
		return tVersionBeforeView;
	}
	
	return nil;
}

- (IBAction)setMinimumVersion:(WBVersionPicker *)sender
{
	NSInteger tRow=[_tableView rowForView:sender];
	
	if (tRow==-1)
		return;
	
	WBVersion * tVersion=[sender versionValue];
	
	NSInteger tMinInteger=[PKGRequirementViewControllerOSRanges integerFromVersion:tVersion];
	
	NSMutableDictionary *range=[_cachedOSRanges[tRow] mutableCopy];
	
	range[PKGRequirementOSRangeMinimumVersionKey]=@(tMinInteger);
	
	_cachedOSRanges[tRow]=range;
	
	[_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tRow] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
	
	/*_minimumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOSRanges operatingSystemNameOfVersion:tVersion];
	
	_maximumVersionPicker.minVersion=tVersion;
	
	NSInteger tMaxInteger=[_settings[PKGRequirementOSMaximumVersionKey] integerValue];
	NSInteger tEffectiveMaxInteger=(tMaxInteger==PKGRequirementOSMaximumVersionNotDefined) ? PKGRequirementOSMinimumVersionLeopard : tMaxInteger;
	
	if (tEffectiveMaxInteger<=tMinInteger)
	{
		if (tMaxInteger!=PKGRequirementOSMaximumVersionNotDefined)
			_settings[PKGRequirementOSMaximumVersionKey]=@(tMinInteger);
		
		_maximumVersionPicker.versionValue=tVersion;
		
		_maximumVersionOSNameLabel.stringValue=[PKGRequirementViewControllerOSRanges operatingSystemNameOfVersion:tVersion];
	}*/
}

- (IBAction)switchBeforeVersionStatus:(NSButton *)sender
{
	NSInteger tRow=[_tableView rowForView:sender];
	
	if (tRow==-1)
		return;
	
	NSDictionary<NSString *, NSString *> *osRangeDictionary=_cachedOSRanges[tRow];
	
	if (sender.state == NSOnState)
	{
		_cachedOSRanges[tRow] = @{
								  PKGRequirementOSRangeMinimumVersionKey: osRangeDictionary[PKGRequirementOSRangeMinimumVersionKey],
								  PKGRequirementOSRangeBeforeVersionKey: osRangeDictionary[PKGRequirementOSRangeMinimumVersionKey]
								  };
	}
	else
	{
		_cachedOSRanges[tRow] = @{
								  PKGRequirementOSRangeMinimumVersionKey: osRangeDictionary[PKGRequirementOSRangeMinimumVersionKey]
								  };
	}
	
	[_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tRow] columnIndexes:[NSIndexSet indexSetWithIndex:1]];
}

- (IBAction)setBeforeVersion:(WBVersionPicker *)sender
{
	NSInteger tRow=[_tableView rowForView:sender];
	
	if (tRow==-1)
		return;
	
	WBVersion * tVersion=[sender versionValue];
	
	NSInteger tMaxInteger=[PKGRequirementViewControllerOSRanges integerFromVersion:tVersion];
	
	NSMutableDictionary *range=[_cachedOSRanges[tRow] mutableCopy];
	
	range[PKGRequirementOSRangeBeforeVersionKey]=@(tMaxInteger);
	
	_cachedOSRanges[tRow]=range;
	
	[_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:tRow] columnIndexes:[NSIndexSet indexSetWithIndex:1]];
}

#pragma mark -

- (BOOL)versionPickerCell:(WBVersionPickerCell *)inVersionPickerCell shouldSelectElementType:(WBVersionPickerCellElementType)inElementType
{	
	return YES;
}

@end
