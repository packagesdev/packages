/*
 Copyright (c) 2017-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WBMacOSVersionsHistory.h"

#ifndef MAC_OS_X_VERSION_10_10
#define MAC_OS_X_VERSION_10_10      101000
#endif

#ifndef NSFoundationVersionNumber10_10
#define NSFoundationVersionNumber10_10 1151.16
#endif

#if (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_10)
#include <CoreServices/CoreServices.h>
#endif

#import "WBVersion_Private.h"

#define WBMacOSXMajorVersion				10		// No support for MacOS Classic (which is a good thing considering some minor versions are skipped with this OS)

#define WBMacOSCheetahMinorVersion			0
#define WBMacOSPumaMinorVersion				1
#define WBMacOSJaguarMinorVersion			2
#define WBMacOSPantherMinorVersion			3
#define WBMacOSTigerMinorVersion			4
#define WBMacOSLeopardMinorVersion			5
#define WBMacOSSnowLeopardMinorVersion		6
#define WBMacOSLionMinorVersion				7
#define WBMacOSMountainLionMinorVersion		8
#define WBMacOSMavericksMinorVersion		9
#define WBMacOSYosemiteMinorVersion			10
#define WBMacOSElCapitanMinorVersion		11
#define WBMacOSSierraMinorVersion			12
#define WBMacOSHighSierraMinorVersion		13
#define WBMacOSMojaveMinorVersion			14
#define WBMacOSCatalinaMinorVersion			15


#define WBMacOSBigSurMajorVersion           11
#define WBMacOSMontereyMajorVersion         12
#define WBMacOSVenturaMajorVersion          13
#define WBMacOSSonomaMajorVersion           14
#define WBMacOSSequoiaMajorVersion           15

#define WBMacOSReasonableMaxUnitValue          100

@implementation WBVersion (MacOSVersion)

+ (WBVersion *)macOSCheetahVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSCheetahMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSPumaVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSPumaMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSJaguarVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSJaguarMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSPantherVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSPantherMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSTigerVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSTigerMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSLeopardVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSLeopardMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSSnowLeopardVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSSnowLeopardMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSLionVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSLionMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSMountainLionVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSMountainLionMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSMavericksVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSMavericksMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSYosemiteVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSYosemiteMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSElCapitanVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSElCapitanMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSSierraVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSSierraMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSHighSierraVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSHighSierraMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSMojaveVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSMojaveMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSCatalinaVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSXMajorVersion;
    tNewVersion.minorVersion=WBMacOSCatalinaMinorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSBigSurVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSBigSurMajorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSMontereyVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSMontereyMajorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSVenturaVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSVenturaMajorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSSonomaVersion
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSSonomaMajorVersion;
    
    return tNewVersion;
}

+ (WBVersion *)macOSSequoiaVersion;
{
    WBVersion * tNewVersion=[WBVersion new];
    
    tNewVersion.majorVersion=WBMacOSSequoiaMajorVersion;
    
    return tNewVersion;
}

#pragma mark -

+ (WBVersion *)systemVersion
{
    static dispatch_once_t onceToken;
    static WBVersion * sSystemVersion=nil;
    dispatch_once(&onceToken, ^{
        
        sSystemVersion=[WBVersion new];
        
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_10)
        NSOperatingSystemVersion tOperatingSystemVersion=[NSProcessInfo processInfo].operatingSystemVersion;
        
        sSystemVersion.majorVersion=tOperatingSystemVersion.majorVersion;
        sSystemVersion.minorVersion=tOperatingSystemVersion.minorVersion;
        sSystemVersion.patchVersion=tOperatingSystemVersion.patchVersion;
#else
        
    #if __MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10
        
        if (NSFoundationVersionNumber>=NSFoundationVersionNumber10_10)
        {
            NSOperatingSystemVersion tOperatingSystemVersion=[NSProcessInfo processInfo].operatingSystemVersion;
            
            sSystemVersion.majorVersion=tOperatingSystemVersion.majorVersion;
            sSystemVersion.minorVersion=tOperatingSystemVersion.minorVersion;
            sSystemVersion.patchVersion=tOperatingSystemVersion.patchVersion;
        }
        else
        
    #endif
        {
            SInt32 tMajorVersion,tMinorVersion,tBugFixVersion;
            
            Gestalt(gestaltSystemVersionMajor,&tMajorVersion);
            Gestalt(gestaltSystemVersionMinor,&tMinorVersion);
            Gestalt(gestaltSystemVersionBugFix,&tBugFixVersion);
            
            sSystemVersion.majorVersion=tMajorVersion;
            sSystemVersion.minorVersion=tMinorVersion;
            sSystemVersion.patchVersion=tBugFixVersion;
        }
#endif
    });
    
    return sSystemVersion;
}

@end

@implementation WBMacOSVersionsHistory

+ (id)versionsHistory
{
	return [WBMacOSVersionsHistory new];
}

#pragma mark -

- (NSRange)minimumRangeOfUnit:(WBVersionUnit)inUnit
{
	switch(inUnit)
	{
		case WBMajorVersionUnit:
			
			return NSMakeRange(WBMacOSXMajorVersion, 2);
			
		case WBMinorVersionUnit:
			
			return NSMakeRange(0, 16);
			
		case WBPatchVersionUnit:
			
			return NSMakeRange(0, 10);
	}
	
	return NSMakeRange(NSNotFound, 0);
}

- (NSRange)maximumRangeOfUnit:(WBVersionUnit)inUnit
{
	switch(inUnit)
	{
		case WBMajorVersionUnit:
			
			return NSMakeRange(WBMacOSXMajorVersion, 10);
			
		case WBMinorVersionUnit:
			
			return NSMakeRange(0, NSUIntegerMax);
			
		case WBPatchVersionUnit:
			
			return NSMakeRange(0, NSUIntegerMax);
	}
	
	return NSMakeRange(NSNotFound, 0);
}

- (NSRange)rangeOfUnit:(WBVersionUnit)smaller inUnit:(WBVersionUnit)larger forVersion:(WBVersion *)inVersion
{
	if (inVersion==nil)
		return NSMakeRange(NSNotFound, 0);
	
	if (smaller<=larger)
		return NSMakeRange(NSNotFound, 0);
	
	switch (smaller)
	{
		case WBMajorVersionUnit:
			return NSMakeRange(WBMacOSXMajorVersion, 10);
		
		case WBMinorVersionUnit:
		
            switch(inVersion.majorVersion)
            {
                case WBMacOSXMajorVersion:
                    
                    return NSMakeRange(0, 16);
                    
                case WBMacOSBigSurMajorVersion:
                    
                    return NSMakeRange(0, 8);
                    
                case WBMacOSMontereyMajorVersion:
                case WBMacOSVenturaMajorVersion:
                default:
                    
                    break;
            }
            
            return NSMakeRange(0, WBMacOSReasonableMaxUnitValue);
            
		case WBPatchVersionUnit:
		
            if (inVersion.majorVersion==WBMacOSXMajorVersion)
            {
                switch(inVersion.minorVersion)
                {
                    case WBMacOSCheetahMinorVersion:
                        
                        return NSMakeRange(0, 5);
                        
                    case WBMacOSPumaMinorVersion:
                        
                        return NSMakeRange(0, 6);
                        
                    case WBMacOSJaguarMinorVersion:
                        
                        return NSMakeRange(0, 9);
                        
                    case WBMacOSPantherMinorVersion:
                        
                        return NSMakeRange(0, 10);
                        
                    case WBMacOSTigerMinorVersion:
                        
                        return NSMakeRange(0, 12);
                        
                    case WBMacOSLeopardMinorVersion:
                        
                        return NSMakeRange(0, 9);
                        
                    case WBMacOSSnowLeopardMinorVersion:
                        
                        return NSMakeRange(0, 9);
                        
                    case WBMacOSLionMinorVersion:
                        
                        return NSMakeRange(0, 6);
                        
                    case WBMacOSMountainLionMinorVersion:
                        
                        return NSMakeRange(0, 6);
                        
                    case WBMacOSMavericksMinorVersion:
                        
                        return NSMakeRange(0, 6);
                        
                    case WBMacOSYosemiteMinorVersion:
                        
                        return NSMakeRange(0, 6);
                        
                    case WBMacOSElCapitanMinorVersion:
                        
                        return NSMakeRange(0, 7);
                        
                    case WBMacOSSierraMinorVersion:
                        
                        return NSMakeRange(0, 7);
                        
                    case WBMacOSHighSierraMinorVersion:
                        
                        return NSMakeRange(0, 6);
                        
                    case WBMacOSMojaveMinorVersion:
                        
                        return NSMakeRange(0, 7);
                        
                    case WBMacOSCatalinaMinorVersion:
                        
                        return NSMakeRange(0, 8);
                }
                
                return NSMakeRange(0, WBMacOSReasonableMaxUnitValue);
            }
			
            if (inVersion.majorVersion==WBMacOSBigSurMajorVersion)
            {
                switch(inVersion.minorVersion)
                {
                    case 0:
                        
                        return NSMakeRange(0, 2);
                        
                    case 1:
                        
                        return NSMakeRange(0, 1);
                        
                    case 2:
                        
                        return NSMakeRange(0, 4);
                        
                    case 3:
                        
                        return NSMakeRange(0, 2);
                        
                    case 4:
                        
                        return NSMakeRange(0, 1);
                        
                    case 5:
                        
                        return NSMakeRange(0, 3);
                        
                    case 6:
                        
                        return NSMakeRange(0, 9);
                        
                    case 7:
                        
                        return NSMakeRange(0, 10);
                }
                
                return NSMakeRange(0, WBMacOSReasonableMaxUnitValue);
            }
            
            if (inVersion.majorVersion==WBMacOSMontereyMajorVersion)
            {
                switch(inVersion.minorVersion)
                {
                    case 0:
                        
                        return NSMakeRange(0, 2);
                        
                    case 1:
                        
                        return NSMakeRange(0, 1);
                        
                    case 2:
                        
                        return NSMakeRange(0, 2);
                        
                    case 3:
                        
                        return NSMakeRange(0, 2);
                        
                    case 4:
                        
                        return NSMakeRange(0, 1);
                        
                    case 5:
                        
                        return NSMakeRange(0, 2);
                        
                    case 6:
                        
                        return NSMakeRange(0, 10);
                        
                    /*case 7:
                        
                        return NSMakeRange(0, 7);*/
                }
                        
                return NSMakeRange(0, WBMacOSReasonableMaxUnitValue);
			}
            
            if (inVersion.majorVersion==WBMacOSVenturaMajorVersion)
            {
                switch(inVersion.minorVersion)
                {
                    case 0:
                        
                        return NSMakeRange(0, 2);
                        
                    case 1:
                        
                        return NSMakeRange(0, 1);
                        
                    case 2:
                        
                        return NSMakeRange(0, 2);
                        
                    case 3:
                        
                        return NSMakeRange(0, 2);
                        
                    case 4:
                        
                        return NSMakeRange(0, 2);
                        
                    case 5:
                        
                        return NSMakeRange(0, 3);
                        
                    case 6:
                        
                        return NSMakeRange(0, 10);
                        
                    /*case 7:
                        
                        return NSMakeRange(0, 5);*/
                }
                
                return NSMakeRange(0, WBMacOSReasonableMaxUnitValue);
            }
            
            if (inVersion.majorVersion==WBMacOSSonomaMajorVersion)
            {
                switch(inVersion.minorVersion)
                {
                    case 0:
                        
                        return NSMakeRange(0, 1);
                        
                    case 1:
                        
                        return NSMakeRange(0, 3);
                        
                    case 2:
                        
                        return NSMakeRange(0, 2);
                        
                    case 3:
                        
                        return NSMakeRange(0, 2);
                        
                    case 4:
                        
                        return NSMakeRange(0, 2);
                        
                    case 5:
                        
                        return NSMakeRange(0, 1);
                        
                    case 6:
                        
                        return NSMakeRange(0, 2);
                        
                    /*case 7:
                        
                        return NSMakeRange(0, 5);*/
                }
                
                return NSMakeRange(0, WBMacOSReasonableMaxUnitValue);
            }
			
            if (inVersion.majorVersion==WBMacOSSequoiaMajorVersion)
            {
                return NSMakeRange(0, WBMacOSReasonableMaxUnitValue);
            }
            
			return NSMakeRange(0, WBMacOSReasonableMaxUnitValue);
	}
	
	return NSMakeRange(NSNotFound, 0);
}

- (WBVersion *)versionFromComponents:(WBVersionComponents *)comps
{
	if (comps==nil)
		return nil;
	
	if (comps.majorVersion<0 || comps.minorVersion<0 || comps.patchVersion<0)
		return nil;
	
	if (comps.minorVersion==WBUndefinedVersionComponent || comps.patchVersion==WBUndefinedVersionComponent)
		return nil;
	
	WBVersion * tVersion=[WBVersion new];
	
	// Major
	
	NSRange tAllowedRange=[self maximumRangeOfUnit:WBMajorVersionUnit];
	
	if (comps.majorVersion==WBUndefinedVersionComponent)
	{
		tVersion.majorVersion=tAllowedRange.location;
	}
	else
	{
		if (comps.majorVersion<tAllowedRange.location || comps.majorVersion>=NSMaxRange(tAllowedRange))
			return nil;
		
		tVersion.majorVersion=comps.majorVersion;
	}
	
	// Minor
	
	tAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tVersion];
	
	if (comps.minorVersion>=NSMaxRange(tAllowedRange))
	{
		tVersion.minorVersion=NSMaxRange(tAllowedRange)-1;
		
		tAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tVersion];
		
		tVersion.patchVersion=tAllowedRange.location;
		
		WBVersionComponents * tNewComponents=[WBVersionComponents new];
		tNewComponents.minorVersion=comps.minorVersion-tVersion.minorVersion;
		
		tVersion=[self versionByAddingComponents:tNewComponents toVersion:tVersion];
	}
	else if (comps.minorVersion<tAllowedRange.location)
		tVersion.minorVersion=tAllowedRange.location;
	else 
		tVersion.minorVersion=comps.minorVersion;
	
	// Patch
	
	tAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tVersion];
	
	if (comps.patchVersion>=NSMaxRange(tAllowedRange))
	{
		tVersion.patchVersion=NSMaxRange(tAllowedRange)-1;
		
		WBVersionComponents * tNewComponents=[WBVersionComponents new];
		tNewComponents.patchVersion=comps.patchVersion-tVersion.patchVersion;
		
		return [self versionByAddingComponents:tNewComponents toVersion:tVersion];
	}
	
	if (comps.patchVersion<tAllowedRange.location)
		tVersion.patchVersion=tAllowedRange.location;
	else 
		tVersion.patchVersion=comps.patchVersion;
	
	return tVersion;
}

- (WBVersion *)versionByAddingComponents:(WBVersionComponents *)comps toVersion:(WBVersion *)inVersion
{
	if ([self validateVersion:inVersion]==NO)
	{
		NSLog(@"Invalid or unsupported macOS Version");
		return nil;
	}
	
	if (comps==nil)
		return inVersion;
	
	WBVersionComponents * tComponents=[comps copy];
	WBVersion * tNewVersion=[inVersion copy];
	
	// Major Version
	
	NSRange tMajorAllowedRange=[self maximumRangeOfUnit:WBMajorVersionUnit];
	
	if (tComponents.majorVersion!=WBUndefinedVersionComponent && tComponents.majorVersion!=0)
	{
		if (tComponents.majorVersion>0)
		{
			tNewVersion.majorVersion+=tComponents.majorVersion;
			
			if (tNewVersion.majorVersion>=NSMaxRange(tMajorAllowedRange))
				tNewVersion.majorVersion=NSMaxRange(tMajorAllowedRange)-1;
		}
		else
		{
			NSUInteger tDelta=(-tComponents.majorVersion);
			
			if ((tDelta+tMajorAllowedRange.location)>tNewVersion.majorVersion)
			{
				tNewVersion.majorVersion=tMajorAllowedRange.location;
			}
			else
			{
				tNewVersion.majorVersion-=tDelta;
			}
		}
		
		if (tNewVersion.majorVersion!=inVersion.majorVersion)
		{
			NSRange tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
			
			if (tNewVersion.minorVersion>=NSMaxRange(tMinorAllowedRange))
				tNewVersion.minorVersion=NSMaxRange(tMinorAllowedRange)-1;
			else if (tNewVersion.minorVersion<tMinorAllowedRange.location)
				tNewVersion.minorVersion=tMinorAllowedRange.location;
			
			NSRange tPatchAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
			
			if (tNewVersion.patchVersion>=NSMaxRange(tPatchAllowedRange))
				tNewVersion.patchVersion=NSMaxRange(tPatchAllowedRange)-1;
			else if (tNewVersion.patchVersion<tPatchAllowedRange.location)
				tNewVersion.patchVersion=tPatchAllowedRange.location;
		}
	}

	// Minor Version
	
	if (tComponents.minorVersion!=WBUndefinedVersionComponent && tComponents.minorVersion!=0)
	{
		NSRange tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
		
		if (tComponents.minorVersion>0)
		{
			BOOL tDone=NO;
            
            while ((tNewVersion.minorVersion+tComponents.minorVersion)>=NSMaxRange(tMinorAllowedRange))
			{
				if ((tNewVersion.majorVersion+1)<NSMaxRange(tMajorAllowedRange))
				{
					tNewVersion.majorVersion++;
					
					tComponents.minorVersion-=(NSMaxRange(tMinorAllowedRange)-tNewVersion.minorVersion);
					
					tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
					
					tNewVersion.minorVersion=tMinorAllowedRange.location;
				}
				else
				{
					tNewVersion.minorVersion=NSMaxRange(tMinorAllowedRange)-1;
                    
                    tDone=YES;
                    
					break;
				}
			}
			
			if (tDone==NO)
                tNewVersion.minorVersion+=tComponents.minorVersion;
		}
		else
		{
			NSUInteger tDelta=(-tComponents.minorVersion);
			
			BOOL tDone=NO;
			
			while (tDelta>(tNewVersion.minorVersion-tMinorAllowedRange.location))
			{
				if (tNewVersion.majorVersion>=(tMajorAllowedRange.location+1))
				{
					tNewVersion.majorVersion--;
					
					tDelta-=(tNewVersion.minorVersion-tMinorAllowedRange.location+1);
					
					tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
					
					tNewVersion.minorVersion=NSMaxRange(tMinorAllowedRange)-1;
				}
				else
				{
					tNewVersion.minorVersion=tMinorAllowedRange.location;
					
					tDone=YES;
					
					break;
				}
			}
			
			if (tDone==NO)
				tNewVersion.minorVersion-=tDelta;
		}
	
		NSRange tPatchAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
			
		if (tNewVersion.patchVersion>=NSMaxRange(tPatchAllowedRange))
			tNewVersion.patchVersion=NSMaxRange(tPatchAllowedRange)-1;
		else if (tNewVersion.patchVersion<tPatchAllowedRange.location)
			tNewVersion.patchVersion=tPatchAllowedRange.location;
	}
	
	// Patch version
	
	if (tComponents.patchVersion!=WBUndefinedVersionComponent && tComponents.patchVersion!=0)
	{
		NSRange tPatchAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
		
		if (comps.patchVersion>0)
		{
			while ((tNewVersion.patchVersion+tComponents.patchVersion)>=NSMaxRange(tPatchAllowedRange))
			{
				NSRange tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
				
				tComponents.patchVersion-=(NSMaxRange(tPatchAllowedRange)-tNewVersion.patchVersion);
				
				if ((tNewVersion.minorVersion+1)<NSMaxRange(tMinorAllowedRange))
				{
					tNewVersion.minorVersion++;
					
					tPatchAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
					
					tNewVersion.patchVersion=tPatchAllowedRange.location;
				}
				else
				{
					if ((tNewVersion.majorVersion+1)<NSMaxRange(tMajorAllowedRange))
					{
						tNewVersion.majorVersion++;
						
						tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.minorVersion=tMinorAllowedRange.location;
						
						tPatchAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.patchVersion=tPatchAllowedRange.location;
					}
					else
					{
						tNewVersion.minorVersion=NSMaxRange(tMinorAllowedRange)-1;
						
						tPatchAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.patchVersion=NSMaxRange(tPatchAllowedRange)-1;
						
						break;
					}
				}
			}
			
			tNewVersion.patchVersion+=tComponents.patchVersion;
		}
		else
		{
			NSUInteger tDelta=(-tComponents.patchVersion);
			
			BOOL tDone=NO;
			
			while (tDelta>(tNewVersion.patchVersion-tPatchAllowedRange.location))
			{
				NSRange tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
				
				tDelta-=(tNewVersion.patchVersion-tPatchAllowedRange.location+1);
				
				if (tNewVersion.minorVersion>=(tMinorAllowedRange.location+1))
				{
					tNewVersion.minorVersion--;
					
					tPatchAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
					
					tNewVersion.patchVersion=NSMaxRange(tPatchAllowedRange)-1;
				}
				else
				{
					if (tNewVersion.majorVersion>=(tMajorAllowedRange.location+1))
					{
						tNewVersion.majorVersion--;
						
						tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.minorVersion=NSMaxRange(tMinorAllowedRange)-1;
						
						tPatchAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.patchVersion=NSMaxRange(tPatchAllowedRange)-1;
					}
					else
					{
						tNewVersion.minorVersion=tMinorAllowedRange.location;
						
						tPatchAllowedRange=[self rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.patchVersion=tPatchAllowedRange.location;
						
						tDone=YES;
						
						break;
					}
				}
			}
			
			if (tDone==NO)
				tNewVersion.patchVersion-=tDelta;
		}
	}
	
	return tNewVersion;
}

@end
