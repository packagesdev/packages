/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WBMacOSVersionsHistory.h"

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

@implementation WBMacOSVersionsHistory

+ (id)versionsHistory
{
	return [WBMacOSVersionsHistory new];
}

#pragma mark -

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

#pragma mark -

+ (WBVersion *)systemVersion
{
	return nil;
}

#pragma mark -

- (NSRange)minimumRangeOfUnit:(WBVersionUnit)inUnit
{
	switch(inUnit)
	{
		case WBMajorVersionUnit:
			
			return NSMakeRange(WBMacOSXMajorVersion, 1);
			
		case WBMinorVersionUnit:
			
			return NSMakeRange(0, 13);
			
		case WBBugFixVersionUnit:
			
			return NSMakeRange(0, 5);
	}
	
	return NSMakeRange(NSNotFound, 0);
}

- (NSRange)maximumRangeOfUnit:(WBVersionUnit)inUnit
{
	switch(inUnit)
	{
		case WBMajorVersionUnit:
			
			return NSMakeRange(WBMacOSXMajorVersion, 1);
			
		case WBMinorVersionUnit:
			
			return NSMakeRange(0, NSUIntegerMax);
			
		case WBBugFixVersionUnit:
			
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
			return NSMakeRange(WBMacOSXMajorVersion, 1);
		
		case WBMinorVersionUnit:
		
			return NSMakeRange(0, NSUIntegerMax);
		
		case WBBugFixVersionUnit:
		
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
					
					return NSMakeRange(0, 6);
					
				case WBMacOSHighSierraMinorVersion:
					
					return NSMakeRange(0, NSUIntegerMax);
			}
			
			return NSMakeRange(0, NSUIntegerMax);
	}
	
	return NSMakeRange(NSNotFound, 0);
}

- (WBVersion *)versionFromComponents:(WBVersionComponents *)comps
{
	if (comps==nil)
		return nil;
	
	if (comps.majorVersion<0 || comps.minorVersion<0 || comps.bugFixVersion<0)
		return nil;
	
	if (comps.minorVersion==WBUndefinedVersionComponent || comps.bugFixVersion==WBUndefinedVersionComponent)
		return nil;
	
	WBVersion * tVersion=[[WBVersion alloc] init];
	
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
		
		tAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tVersion];
		
		tVersion.bugFixVersion=tAllowedRange.location;
		
		WBVersionComponents * tNewComponents=[WBVersionComponents new];
		tNewComponents.minorVersion=comps.minorVersion-tVersion.minorVersion;
		
		tVersion=[self versionByAddingComponents:tNewComponents toVersion:tVersion];
	}
	else if (comps.minorVersion<tAllowedRange.location)
		tVersion.minorVersion=tAllowedRange.location;
	else 
		tVersion.minorVersion=comps.minorVersion;
	
	// BugFix
	
	tAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tVersion];
	
	if (comps.bugFixVersion>=NSMaxRange(tAllowedRange))
	{
		tVersion.bugFixVersion=NSMaxRange(tAllowedRange)-1;
		
		WBVersionComponents * tNewComponents=[WBVersionComponents new];
		tNewComponents.bugFixVersion=comps.bugFixVersion-tVersion.bugFixVersion;
		
		return [self versionByAddingComponents:tNewComponents toVersion:tVersion];
	}
	
	if (comps.bugFixVersion<tAllowedRange.location)
		tVersion.bugFixVersion=tAllowedRange.location;
	else 
		tVersion.bugFixVersion=comps.bugFixVersion;
	
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
			
			NSRange tBugFixAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
			
			if (tNewVersion.bugFixVersion>=NSMaxRange(tBugFixAllowedRange))
				tNewVersion.bugFixVersion=NSMaxRange(tBugFixAllowedRange)-1;
			else if (tNewVersion.bugFixVersion<tBugFixAllowedRange.location)
				tNewVersion.bugFixVersion=tBugFixAllowedRange.location;
		}
	}

	// Minor Version
	
	if (tComponents.minorVersion!=WBUndefinedVersionComponent && tComponents.minorVersion!=0)
	{
		NSRange tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
		
		if (tComponents.minorVersion>0)
		{
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
					break;
				}
			}
			
			tNewVersion.minorVersion+=tComponents.minorVersion;
		}
		else
		{
			NSUInteger tDelta=(-tComponents.minorVersion);
			
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
					break;
				}
			}
			
			tNewVersion.minorVersion-=tDelta;
		}
	
		NSRange tBugFixAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
			
		if (tNewVersion.bugFixVersion>=NSMaxRange(tBugFixAllowedRange))
			tNewVersion.bugFixVersion=NSMaxRange(tBugFixAllowedRange)-1;
		else if (tNewVersion.bugFixVersion<tBugFixAllowedRange.location)
			tNewVersion.bugFixVersion=tBugFixAllowedRange.location;
	}
	
	// BugFix version
	
	if (tComponents.bugFixVersion!=WBUndefinedVersionComponent && tComponents.bugFixVersion!=0)
	{
		NSRange tBugFixAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
		
		if (comps.bugFixVersion>0)
		{
			while ((tNewVersion.bugFixVersion+tComponents.bugFixVersion)>=NSMaxRange(tBugFixAllowedRange))
			{
				NSRange tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
				
				tComponents.bugFixVersion-=(NSMaxRange(tBugFixAllowedRange)-tNewVersion.bugFixVersion);
				
				if ((tNewVersion.minorVersion+1)<NSMaxRange(tMinorAllowedRange))
				{
					tNewVersion.minorVersion++;
					
					tBugFixAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
					
					tNewVersion.bugFixVersion=tBugFixAllowedRange.location;
				}
				else
				{
					if ((tNewVersion.majorVersion+1)<NSMaxRange(tMajorAllowedRange))
					{
						tNewVersion.majorVersion++;
						
						tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.minorVersion=tMinorAllowedRange.location;
						
						tBugFixAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.bugFixVersion=tBugFixAllowedRange.location;
					}
					else
					{
						tNewVersion.minorVersion=NSMaxRange(tMinorAllowedRange)-1;
						
						tBugFixAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.bugFixVersion=NSMaxRange(tBugFixAllowedRange)-1;
						
						break;
					}
				}
			}
			
			tNewVersion.bugFixVersion+=tComponents.bugFixVersion;
		}
		else
		{
			NSUInteger tDelta=(-tComponents.bugFixVersion);
			
			while (tDelta>(tNewVersion.bugFixVersion-tBugFixAllowedRange.location))
			{
				NSRange tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
				
				tDelta-=(tNewVersion.bugFixVersion-tBugFixAllowedRange.location+1);
				
				if (tNewVersion.minorVersion>=(tMinorAllowedRange.location+1))
				{
					tNewVersion.minorVersion--;
					
					tBugFixAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
					
					tNewVersion.bugFixVersion=NSMaxRange(tBugFixAllowedRange)-1;
				}
				else
				{
					if (tNewVersion.majorVersion>=(tMajorAllowedRange.location+1))
					{
						tNewVersion.majorVersion--;
						
						tMinorAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.minorVersion=NSMaxRange(tMinorAllowedRange)-1;
						
						tBugFixAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.bugFixVersion=NSMaxRange(tBugFixAllowedRange)-1;
					}
					else
					{
						tNewVersion.minorVersion=tMinorAllowedRange.location;
						
						tBugFixAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:tNewVersion];
						
						tNewVersion.bugFixVersion=tBugFixAllowedRange.location;
						
						break;
					}
				}
			}
			
			tNewVersion.bugFixVersion-=tDelta;
		}
	}
	
	return tNewVersion;
}

@end
