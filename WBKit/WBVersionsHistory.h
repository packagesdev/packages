/*
 Copyright (c) 2017-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "WBVersion.h"

@class WBVersionComponents;

typedef NS_ENUM(NSUInteger,WBVersionUnit)
{
	WBMajorVersionUnit=(1UL << 1),
	WBMinorVersionUnit=(1UL << 2),
	WBPatchVersionUnit=(1UL << 3),
};

@interface WBVersionsHistory : NSObject <NSCopying>

+ (id)versionsHistory;

- (BOOL)validateVersion:(WBVersion *)inVersion;

- (NSRange)minimumRangeOfUnit:(WBVersionUnit)inUnit;
- (NSRange)maximumRangeOfUnit:(WBVersionUnit)inUnit;

- (NSRange)rangeOfUnit:(WBVersionUnit)smaller inUnit:(WBVersionUnit)larger forVersion:(WBVersion *)inVersion;

- (WBVersion *)versionFromComponents:(WBVersionComponents *)comps;
- (WBVersionComponents *)components:(NSUInteger)unitFlags fromVersion:(WBVersion *)inVersion;

- (WBVersion *)versionByAddingComponents:(WBVersionComponents *)comps toVersion:(WBVersion *)inVersion;

// Calculations

- (WBVersion *)previousMajorVersionOfVersion:(WBVersion *)inVersion;
- (WBVersion *)nextMajorVersionOfVersion:(WBVersion *)inVersion;

- (WBVersion *)previousMinorVersionOfVersion:(WBVersion *)inVersion;
- (WBVersion *)nextMinorVersionOfVersion:(WBVersion *)inVersion;

- (WBVersion *)previousPatchVersionOfVersion:(WBVersion *)inVersion;
- (WBVersion *)nextPatchVersionOfVersion:(WBVersion *)inVersion;

@end


enum
{
	WBUndefinedVersionComponent = NSIntegerMax
};

@interface WBVersionComponents : NSObject <NSCopying>

	@property NSInteger majorVersion;
	@property NSInteger minorVersion;
	@property NSInteger patchVersion;

@end

