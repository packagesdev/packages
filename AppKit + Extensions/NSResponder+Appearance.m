/*
 Copyright (c) 2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSResponder+Appearance.h"

NSString * const WB_NSAppearanceNameAqua=@"NSAppearanceNameAqua";

NSString * const WB_NSAppearanceNameDarkAqua=@"NSAppearanceNameDarkAqua";

@implementation NSResponder (Appearance_WB)

+ (WB_AppearanceMode)WB_appearanceModeForAppearanceName:(NSString *)inAppearanceName
{
	if ([inAppearanceName isEqualToString:WB_NSAppearanceNameDarkAqua]==YES)
		return WB_AppearanceDarkAqua;
	
	return WB_AppearanceAqua;
}

+ (NSString *)WB_appearanceNameForAppearanceMode:(WB_AppearanceMode)inAppearanceMode
{
	switch(inAppearanceMode)
	{
		case WB_AppearanceAqua:
			
			return WB_NSAppearanceNameAqua;
			
		case WB_AppearanceDarkAqua:
			
			return WB_NSAppearanceNameDarkAqua;
	}
	
	return WB_NSAppearanceNameAqua;
}

#pragma mark -

- (NSString *)WB_effectiveAppearanceName
{
	if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
		return WB_NSAppearanceNameAqua;
	
	if ([self conformsToProtocol:@protocol(NSAppearanceCustomization)]==NO)
		return WB_NSAppearanceNameAqua;
	
	id tAppearance=[self performSelector:@selector(effectiveAppearance) withObject:nil];
	
	return (NSString *)[tAppearance performSelector:@selector(bestMatchFromAppearancesWithNames:) withObject:@[WB_NSAppearanceNameAqua,WB_NSAppearanceNameDarkAqua]];
}

- (BOOL)WB_isEffectiveAppearanceDarkAqua
{
	if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
		return NO;
	
	if ([self conformsToProtocol:@protocol(NSAppearanceCustomization)]==NO)
		return NO;
	
	id tAppearance=[self performSelector:@selector(effectiveAppearance) withObject:nil];
	
	NSString * tBestMatch=(NSString *)[tAppearance performSelector:@selector(bestMatchFromAppearancesWithNames:) withObject:@[WB_NSAppearanceNameAqua,WB_NSAppearanceNameDarkAqua]];
	
	return [tBestMatch isEqualToString:WB_NSAppearanceNameDarkAqua];
}

@end