/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationBackgroundSettings.h"

#import "PKGPackagesError.h"

#import "NSDictionary+WBExtensions.h"

#define PKGPRESENTATION_BACKGROUND_SETTINGS_1_2_3_OR_EARLIER_BACKWARDCOMPATIBILITY	1

NSString * const PKGPresentationBackgroundShowCustomImageKey=@"CUSTOM";

NSString * const PKGPresentationBackgroundSharedSettingsForAllAppearancesKey=@"SHARED_SETTINGS_FOR_ALL_APPAREANCES";	// Yes, there's a typo but too late to fix it

NSString * const PKGPresentationBackgroundAppearancesSettingsKey=@"APPAREANCES";

NSString * const PKGPresentationBackgroundImagePathKey=@"BACKGROUND_PATH";

NSString * const PKGPresentationBackgroundImageAlignmentKey=@"ALIGNMENT";

NSString * const PKGPresentationBackgroundImageScalingKey=@"SCALING";

NSString * const PKGPresentationBackgroundImageLayoutDirectionKey=@"LAYOUT_DIRECTION";


NSString * const PKGPresentationBackgroundImageAppearanceLightAquaNameKey=@"LIGHT_AQUA";

NSString * const PKGPresentationBackgroundImageAppearanceDarkAquaNameKey=@"DARK_AQUA";

@implementation PKGPresentationBackgroundAppearanceSettings

+ (NSArray *)allAppearancesNames
{
	static NSArray * sAllAppearancesNames=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sAllAppearancesNames=@[PKGPresentationBackgroundImageAppearanceLightAquaNameKey,
							   PKGPresentationBackgroundImageAppearanceDarkAquaNameKey];
	});
	
	return sAllAppearancesNames;
}

+ (NSString *)appearanceNameForAppearanceMode:(PKGPresentationAppearanceMode)inMode
{
	static NSDictionary * sAllAppearanceModesToNamesDictionary=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sAllAppearanceModesToNamesDictionary=@{@(PKGPresentationAppearanceModeLight):PKGPresentationBackgroundImageAppearanceLightAquaNameKey,
											   @(PKGPresentationAppearanceModeDark):PKGPresentationBackgroundImageAppearanceDarkAquaNameKey
											   };
	});
	
	return sAllAppearanceModesToNamesDictionary[@(inMode)];
}

+ (PKGPresentationAppearanceMode)appearanceModeForAppearanceName:(NSString *)inName
{
	if (inName==nil)
		return PKGPresentationAppearanceModeUnknown;
	
	static NSDictionary * sAllAppearanceNameKeysToModesDictionary=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sAllAppearanceNameKeysToModesDictionary=@{PKGPresentationBackgroundImageAppearanceLightAquaNameKey:@(PKGPresentationAppearanceModeLight),
												  PKGPresentationBackgroundImageAppearanceDarkAquaNameKey:@(PKGPresentationAppearanceModeDark)
											   };
	});
	
	NSNumber * tNumber=sAllAppearanceNameKeysToModesDictionary[inName];
	
	return (tNumber==nil) ? PKGPresentationAppearanceModeUnknown : [tNumber unsignedIntegerValue];
}


- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_showCustomImage=NO;
		
		_imagePath=nil;
		
		_imageAlignment=PKGImageAlignmentleft;
		_imageScaling=PKGImageScalingProportionnaly;
		_imageLayoutDirection=PKGImageLayoutDirectionNone;
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		NSNumber * tNumber=inRepresentation[PKGPresentationBackgroundShowCustomImageKey];
		
		if (tNumber==nil)
		{
			_showCustomImage=NO;
		}
		else
		{
			if ([tNumber isKindOfClass:NSNumber.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundShowCustomImageKey}];
				
				return nil;
			}
			
			_showCustomImage=[tNumber boolValue];
		}
		
		_imagePath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGPresentationBackgroundImagePathKey] error:&tError];	// can be nil
		
		if (_imagePath==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPresentationBackgroundImagePathKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		tNumber=inRepresentation[PKGPresentationBackgroundImageAlignmentKey];
		
		if (tNumber==nil)
		{
			_imageAlignment=PKGImageAlignmentleft;
		}
		else
		{
			if ([tNumber isKindOfClass:NSNumber.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImageAlignmentKey}];
				
				return nil;
			}
			
			_imageAlignment=[tNumber unsignedIntegerValue];
			
			if (_imageAlignment>PKGImageAlignmentRight)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImagePathKey}];
				
				return nil;
			}
		}
		
		tNumber=inRepresentation[PKGPresentationBackgroundImageScalingKey];
		
		if (tNumber==nil)
		{
			_imageScaling=PKGImageScalingProportionnaly;
		}
		else
		{
			if ([tNumber isKindOfClass:NSNumber.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImageScalingKey}];
				
				return nil;
			}
			
			_imageScaling=[tNumber unsignedIntegerValue];
			
			if (_imageScaling>PKGImageScalingNone)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImageScalingKey}];
				
				return nil;
			}
		}
		
		tNumber=inRepresentation[PKGPresentationBackgroundImageLayoutDirectionKey];
		
		if (tNumber==nil)
		{
			_imageLayoutDirection=PKGImageLayoutDirectionNone;
		}
		else
		{
			if ([tNumber isKindOfClass:NSNumber.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImageLayoutDirectionKey}];
				
				return nil;
			}
			
			_imageLayoutDirection=[tNumber unsignedIntegerValue];
			
			if (_imageLayoutDirection>PKGImageLayoutDirectionNatural)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImageLayoutDirectionKey}];
				
				return nil;
			}
		}
	}
	else
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	if (self.showCustomImage==NO)
		return tRepresentation;
	
	tRepresentation[PKGPresentationBackgroundShowCustomImageKey]=@(YES);
	
	NSMutableDictionary * tFilePathRepresentationDictionary=[self.imagePath representation];
	
	if (tFilePathRepresentationDictionary!=nil)
		tRepresentation[PKGPresentationBackgroundImagePathKey]=[self.imagePath representation];
	
	tRepresentation[PKGPresentationBackgroundImageAlignmentKey]=@(self.imageAlignment);
	
	tRepresentation[PKGPresentationBackgroundImageScalingKey]=@(self.imageScaling);
	
	tRepresentation[PKGPresentationBackgroundImageLayoutDirectionKey]=@(self.imageLayoutDirection);
	
	return tRepresentation;
}

#pragma mark -

- (NSUInteger)hash
{
	return [self.imagePath hash];
}

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"  Background Appearance Settings:\n"];
	[tDescription appendString:@"  -------------------------------\n\n"];
	
	[tDescription appendFormat:@"%@",[super description]];
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGPresentationBackgroundAppearanceSettings * nPresentationBackgroundAppearanceSettings=[[[self class] allocWithZone:inZone] init];
	
	if (nPresentationBackgroundAppearanceSettings!=nil)
	{
		nPresentationBackgroundAppearanceSettings.showCustomImage=self.showCustomImage;
		
		nPresentationBackgroundAppearanceSettings.imagePath=[self.imagePath copyWithZone:inZone];
		
		nPresentationBackgroundAppearanceSettings.imageAlignment=self.imageAlignment;
		
		nPresentationBackgroundAppearanceSettings.imageScaling=self.imageScaling;
		
		nPresentationBackgroundAppearanceSettings.imageLayoutDirection=self.imageLayoutDirection;
	}
	
	return nPresentationBackgroundAppearanceSettings;
}

@end

@interface PKGPresentationBackgroundSettings ()

@property (readwrite,nonatomic) NSDictionary * appearancesSettings;

@end

@implementation PKGPresentationBackgroundSettings

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_sharedSettingsForAllAppearances=YES;
		
		NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
		
		for(NSString * tAppearanceNameKey in [PKGPresentationBackgroundAppearanceSettings allAppearancesNames])
		{
			tMutableDictionary[tAppearanceNameKey]=[PKGPresentationBackgroundAppearanceSettings new];
		}
		
		_appearancesSettings=[tMutableDictionary copy];
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		NSNumber * tNumber=inRepresentation[PKGPresentationBackgroundSharedSettingsForAllAppearancesKey];
		
		if (tNumber==nil)
		{
			_sharedSettingsForAllAppearances=YES;
		}
		else
		{
			if ([tNumber isKindOfClass:NSNumber.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundSharedSettingsForAllAppearancesKey}];
				
				return nil;
			}
			
			_sharedSettingsForAllAppearances=[tNumber boolValue];
		}
		
		NSDictionary * tAppearancesSettingsDictionary=inRepresentation[PKGPresentationBackgroundAppearancesSettingsKey];
		
		if (tAppearancesSettingsDictionary==nil)
		{
			NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
			
			PKGPresentationBackgroundAppearanceSettings * tAppearanceSettings=[[PKGPresentationBackgroundAppearanceSettings alloc] initWithRepresentation:inRepresentation error:&tError];
			
			if (tAppearanceSettings==nil)
			{
				if (outError!=NULL)
					*outError=[tError copy];
				
				return nil;
			}
			
			for(NSString * tAppearanceNameKey in [PKGPresentationBackgroundAppearanceSettings allAppearancesNames])
			{
				tMutableDictionary[tAppearanceNameKey]=[tAppearanceSettings copy];
			}
			
			_appearancesSettings=[tMutableDictionary copy];
		}
		else
		{
			if ([tAppearancesSettingsDictionary isKindOfClass:NSDictionary.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundAppearancesSettingsKey}];
				
				return nil;
			}
			
			__block NSError * bError=nil;
			
			NSMutableDictionary * tMutableDictionary=[[tAppearancesSettingsDictionary WB_dictionaryByMappingObjectsLenientlyUsingBlock:^PKGPresentationBackgroundAppearanceSettings *(NSString * bAppearanceNameKey, NSDictionary * bRepresentation) {
				
				if ([bAppearanceNameKey isKindOfClass:NSString.class]==NO)
				{
					bError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											   code:PKGRepresentationInvalidTypeOfValueError
										   userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundAppearancesSettingsKey}];
					
					return nil;
				}
				
				if ([PKGPresentationBackgroundAppearanceSettings appearanceModeForAppearanceName:bAppearanceNameKey]==PKGPresentationAppearanceModeUnknown)
					return nil;
				
				return [[PKGPresentationBackgroundAppearanceSettings alloc] initWithRepresentation:bRepresentation error:&bError];
			}] mutableCopy];
			
			if (tMutableDictionary==nil)
			{
				if (outError!=NULL)
					*outError=[bError copy];
				
				return nil;
			}
			
			for(NSString * tAppearanceNameKey in [PKGPresentationBackgroundAppearanceSettings allAppearancesNames])
			{
				if (tMutableDictionary[tAppearanceNameKey]==nil)
					tMutableDictionary[tAppearanceNameKey]=[PKGPresentationBackgroundAppearanceSettings new];
			}
			
			_appearancesSettings=[tMutableDictionary copy];
		}
	}
	else
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[super representation];
	
	tRepresentation[PKGPresentationBackgroundSharedSettingsForAllAppearancesKey]=@(_sharedSettingsForAllAppearances);

#if (PKGPRESENTATION_BACKGROUND_SETTINGS_1_2_3_OR_EARLIER_BACKWARDCOMPATIBILITY == 1)

	NSMutableDictionary * tLightAquaAppearanceSettingsRepresentation=[[self appearanceSettingsForAppearanceMode:PKGPresentationAppearanceModeLight] representation];
	
	if (tLightAquaAppearanceSettingsRepresentation==nil)
	{
		// A COMPLETER
		
		// Oh Oh
		
		return nil;
	}
	
	[tRepresentation addEntriesFromDictionary:tLightAquaAppearanceSettingsRepresentation];
	
#endif
	
	NSDictionary * tAppearanceSettingsDictionary=[self.appearancesSettings WB_dictionaryByMappingObjectsUsingBlock:^NSMutableDictionary *(NSString * bAppearanceNameKey, PKGPresentationBackgroundAppearanceSettings * bAppearanceSettings) {
		return [bAppearanceSettings representation];
	}];
	
	if (tAppearanceSettingsDictionary!=nil)
		tRepresentation[PKGPresentationBackgroundAppearancesSettingsKey]=tAppearanceSettingsDictionary;
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"  Background Settings:\n"];
	[tDescription appendString:@"  -------------------\n\n"];
	
	[tDescription appendFormat:@"%@",[super description]];
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGPresentationBackgroundSettings * nPresentationBackgroundSettings=[super copyWithZone:inZone];
	
	if (nPresentationBackgroundSettings!=nil)
	{
		nPresentationBackgroundSettings.sharedSettingsForAllAppearances=self.sharedSettingsForAllAppearances;
		
		nPresentationBackgroundSettings.appearancesSettings=[self->_appearancesSettings WB_dictionaryByMappingObjectsUsingBlock:^PKGPresentationBackgroundAppearanceSettings *(NSString * bAppearanceKey, PKGPresentationBackgroundAppearanceSettings * bBackgroundAppearanceSettings) {
			
			return [bBackgroundAppearanceSettings copy];
		}];
	}
	
	return nPresentationBackgroundSettings;
}

#pragma mark -

- (PKGPresentationBackgroundAppearanceSettings *)appearanceSettingsForAppearanceMode:(PKGPresentationAppearanceMode)inAppearanceMode
{
	return self.appearancesSettings[[PKGPresentationBackgroundAppearanceSettings appearanceNameForAppearanceMode:inAppearanceMode]];
}

@end
