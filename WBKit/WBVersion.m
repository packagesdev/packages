/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WBVersion.h"

#import "WBVersionFormatter.h"

@interface WBVersion ()

	@property NSUInteger majorVersion;
	@property NSUInteger minorVersion;
	@property NSUInteger patchVersion;

@end

@implementation WBVersion

- (WBVersion *)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_majorVersion=1;
		_minorVersion=0;
		_patchVersion=0;
	}
	
	return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	WBVersion * tCopy=[WBVersion new];
	
	if (tCopy!=nil)
	{
		tCopy.majorVersion=self.majorVersion;
		tCopy.minorVersion=self.minorVersion;
		tCopy.patchVersion=self.patchVersion;
	}
	
	return tCopy;
}

@end

@implementation WBVersion (WBExtendedVersion)

- (WBVersion *)earlierVersion:(WBVersion *)otherVersion
{
	if (otherVersion==nil)
		return self;
	
	if (self.majorVersion>otherVersion.majorVersion)
		return otherVersion;
	
	if (self.majorVersion<otherVersion.majorVersion)
		return self;
	
	if (self.minorVersion>otherVersion.minorVersion)
		return otherVersion;
	
	if (self.minorVersion<otherVersion.minorVersion)
		return self;
	
	if (self.patchVersion>otherVersion.patchVersion)
		return otherVersion;
	
	if (self.patchVersion<otherVersion.patchVersion)
		return self;
	
	return self;
}

- (WBVersion *)laterVersion:(WBVersion *)otherVersion
{
	if (otherVersion==nil)
		return self;
	
	if (self.majorVersion>otherVersion.majorVersion)
		return self;
	
	if (self.majorVersion<otherVersion.majorVersion)
		return otherVersion;
	
	if (self.minorVersion>otherVersion.minorVersion)
		return self;
	
	if (self.minorVersion<otherVersion.minorVersion)
		return otherVersion;
	
	if (self.patchVersion>otherVersion.patchVersion)
		return self;
	
	if (self.patchVersion<otherVersion.patchVersion)
		return otherVersion;
	
	return self;
}

- (NSComparisonResult)compare:(WBVersion *)other
{
	if (other==nil)
		return NSOrderedDescending;
	
	if (self.majorVersion>other.majorVersion)
		return NSOrderedDescending;
	
	if (self.majorVersion<other.majorVersion)
		return NSOrderedAscending;
	
	if (self.minorVersion>other.minorVersion)
		return NSOrderedDescending;
	
	if (self.minorVersion<other.minorVersion)
		return NSOrderedAscending;
		
	if (self.patchVersion>other.patchVersion)
		return NSOrderedDescending;
	
	if (self.patchVersion<other.patchVersion)
		return NSOrderedAscending;
	
	return NSOrderedSame;
}

- (BOOL)isEqualToVersion:(WBVersion *)otherVersion
{
	if (otherVersion==nil)
		return NO;
	
	return (self.majorVersion==otherVersion.majorVersion &&
			self.minorVersion==otherVersion.minorVersion &&
			self.patchVersion==otherVersion.patchVersion);
}

@end

@implementation WBVersion (WBVersionCreation)

+ (id)bundleVersionForBundle:(NSBundle *)inBundle
{
	if (inBundle==nil)
		return nil;
	
	NSString * tBundleVersion=[inBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	
	if (tBundleVersion==nil || [tBundleVersion isKindOfClass:[NSString class]]==NO)
		return nil;
	
	WBVersionFormatter * tVersionFormatter=[WBVersionFormatter new];
	
	WBVersion * tVersion=[tVersionFormatter versionFromString:tBundleVersion];
	
	return tVersion;
}

+ (id)mainBundleVersion
{	
	return [WBVersion bundleVersionForBundle:[NSBundle mainBundle]];
}

@end


