/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WBVersionsHistory.h"

#import "WBVersion_Private.h"

@implementation WBVersionsHistory

+ (id)versionsHistory
{
	static WBVersionsHistory * sVersionsHistory=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sVersionsHistory=[WBVersionsHistory new];
	});
	
	return sVersionsHistory;
}

#pragma mark -

- (BOOL)validateVersion:(WBVersion *)inVersion
{
	if (inVersion==nil)
		return NO;
	
	NSRange tAllowedRange=[self maximumRangeOfUnit:WBMajorVersionUnit];
	
	if (inVersion.majorVersion<tAllowedRange.location || inVersion.majorVersion>=NSMaxRange(tAllowedRange))
		return NO;
	
	tAllowedRange=[self rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:inVersion];
	
	if (inVersion.minorVersion<tAllowedRange.location || inVersion.minorVersion>=NSMaxRange(tAllowedRange))
		return NO;
	
	tAllowedRange=[self rangeOfUnit:WBBugFixVersionUnit inUnit:WBMinorVersionUnit forVersion:inVersion];
	
	if (inVersion.bugFixVersion<tAllowedRange.location || inVersion.bugFixVersion>=NSMaxRange(tAllowedRange))
		return NO;
	
	return YES;
}

- (NSRange)minimumRangeOfUnit:(WBVersionUnit)inUnit
{
	switch (inUnit)
	{
		case WBMajorVersionUnit:
		case WBMinorVersionUnit:
		case WBBugFixVersionUnit:
			return NSMakeRange(0, NSIntegerMax);
	}
	
	return NSMakeRange(NSNotFound, 0);
}

- (NSRange)maximumRangeOfUnit:(WBVersionUnit)inUnit
{
	switch (inUnit)
	{
		case WBMajorVersionUnit:
		case WBMinorVersionUnit:
		case WBBugFixVersionUnit:
			return NSMakeRange(0, NSIntegerMax);
	}
	
	return NSMakeRange(NSNotFound, 0);
}

- (NSRange)rangeOfUnit:(WBVersionUnit)smaller inUnit:(WBVersionUnit)larger forVersion:(WBVersion *)inVersion
{
	if (inVersion==nil)
		return NSMakeRange(NSNotFound, 0);
	
	if (smaller>=larger)
		return NSMakeRange(NSNotFound, 0);
	
	switch (smaller)
	{
		case WBMajorVersionUnit:
		case WBMinorVersionUnit:
		case WBBugFixVersionUnit:
			
			return NSMakeRange(0, NSIntegerMax);
	}
	
	return NSMakeRange(NSNotFound, 0);
}

- (WBVersion *)versionFromComponents:(WBVersionComponents *)comps
{
	if (comps==nil)
		return nil;
	
	if (comps.majorVersion==WBUndefinedVersionComponent || comps.minorVersion==WBUndefinedVersionComponent || comps.bugFixVersion==WBUndefinedVersionComponent)
		return nil;
	
	WBVersion * tVersion=[[WBVersion alloc] init];
	
	tVersion.majorVersion=comps.majorVersion;
	tVersion.minorVersion=comps.minorVersion;
	tVersion.bugFixVersion=comps.bugFixVersion;
	
	return tVersion;
}


- (WBVersionComponents *)components:(NSUInteger)unitFlags fromVersion:(WBVersion *)inVersion
{
	if ([self validateVersion:inVersion]==NO)
		return nil;
	
	WBVersionComponents * tComponents=[WBVersionComponents new];
	
	if ((unitFlags&WBMajorVersionUnit)==WBMajorVersionUnit)
		tComponents.majorVersion=inVersion.majorVersion;
	
	if ((unitFlags&WBMinorVersionUnit)==WBMinorVersionUnit)
		tComponents.minorVersion=inVersion.minorVersion;
	
	if ((unitFlags&WBBugFixVersionUnit)==WBBugFixVersionUnit)
		tComponents.bugFixVersion=inVersion.bugFixVersion;
	
	return tComponents;
}

- (WBVersion *)versionByAddingComponents:(WBVersionComponents *)comps toVersion:(WBVersion *)inVersion
{
	if ([self validateVersion:inVersion]==NO)
		return nil;
	
	if (comps==nil)
		return inVersion;
	
	WBVersion * tNewVersion=[inVersion copy];
	
	if (comps.majorVersion!=WBUndefinedVersionComponent)
	{
		if (comps.majorVersion<0)
		{
			if ((-comps.majorVersion)>tNewVersion.majorVersion)
				tNewVersion.majorVersion=0;
		}
		else
		{
			tNewVersion.majorVersion+=comps.majorVersion;
		}
	}
	
	if (comps.minorVersion!=WBUndefinedVersionComponent)
	{
		if (comps.minorVersion<0)
		{
			if ((-comps.minorVersion)>tNewVersion.minorVersion)
				tNewVersion.minorVersion=0;
		}
		else
		{
			tNewVersion.minorVersion+=comps.minorVersion;
		}
	}
	
	if (comps.bugFixVersion!=WBUndefinedVersionComponent)
	{
		if (comps.bugFixVersion<0)
		{
			if ((-comps.bugFixVersion)>tNewVersion.bugFixVersion)
				tNewVersion.bugFixVersion=0;
		}
		else
		{
			tNewVersion.bugFixVersion+=comps.bugFixVersion;
		}
	}
	
	return tNewVersion;
}

@end

@implementation WBVersionComponents

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_majorVersion=WBUndefinedVersionComponent;
		_minorVersion=WBUndefinedVersionComponent;
		_bugFixVersion=WBUndefinedVersionComponent;
	}
	
	return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	WBVersionComponents * tCopy=[WBVersionComponents new];
	
	if (tCopy!=nil)
	{
		tCopy.majorVersion=self.majorVersion;
		tCopy.minorVersion=self.minorVersion;
		tCopy.bugFixVersion=self.bugFixVersion;
	}
	
	return tCopy;
}

@end
