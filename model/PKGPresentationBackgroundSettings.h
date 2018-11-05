/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationStepSettings.h"

#import "PKGFilePath.h"

typedef NS_ENUM(NSUInteger, PKGImageAlignment)
{
	PKGImageAlignmentCenter=0,
	PKGImageAlignmentTop,
	PKGImageAlignmentTopLeft,
	PKGImageAlignmentTopRight,
	PKGImageAlignmentleft,
	PKGImageAlignmentBottom,
	PKGImageAlignmentBottomLeft,
	PKGImageAlignmentBottomRight,
	PKGImageAlignmentRight
};

typedef NS_ENUM(NSUInteger, PKGImageScaling)
{
	PKGImageScalingProportionnaly=0,
	PKGImageScalingToFit,
	PKGImageScalingNone
};

typedef NS_ENUM(NSUInteger, PKGImageLayoutDirection)
{
	PKGImageLayoutDirectionNone=0,
	PKGImageLayoutDirectionNatural=1
};

typedef NS_ENUM(NSUInteger, PKGPresentationAppearanceMode)
{
	PKGPresentationAppearanceModeUnknown=-1,
	PKGPresentationAppearanceModeLight=0,
	PKGPresentationAppearanceModeDark=1,
	
	PKGPresentationAppearanceModeShared=PKGPresentationAppearanceModeLight
};

@interface PKGPresentationBackgroundAppearanceSettings : NSObject <PKGObjectProtocol,NSCopying>

	@property BOOL showCustomImage;

	@property PKGFilePath * imagePath;	// can be nil

	@property PKGImageAlignment imageAlignment;

	@property PKGImageScaling imageScaling;

	@property PKGImageLayoutDirection imageLayoutDirection;

+ (NSArray *)allAppearancesNames;

+ (NSString *)appearanceNameForAppearanceMode:(PKGPresentationAppearanceMode)inMode;

+ (PKGPresentationAppearanceMode)appearanceModeForAppearanceName:(NSString *)inApperanceName;

@end


@interface PKGPresentationBackgroundSettings : PKGPresentationStepSettings

	@property BOOL sharedSettingsForAllAppearances;

	@property (readonly,nonatomic) NSDictionary * appearancesSettings;

- (PKGPresentationBackgroundAppearanceSettings *)appearanceSettingsForAppearanceMode:(PKGPresentationAppearanceMode)inAppearanceMode;


@end
