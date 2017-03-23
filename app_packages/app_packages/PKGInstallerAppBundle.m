/*
 Copyright (c) 2014-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGInstallerAppBundle.h"

NSString * const PKGInstallerAppVersionNumber6_1=@"6.1.0";

NSString * const PKGInstallerAppPath=@"/System/Library/CoreServices/Installer.app";

@interface PKGInstallerAppBundle ()

- (NSComparisonResult)compareVersion:(NSString *)inShortVersionString;

@end

@implementation PKGInstallerAppBundle

+ (PKGInstallerAppBundle *)installerAppBundle
{
	static dispatch_once_t onceToken;
	static PKGInstallerAppBundle * sInstallerAppBundle=nil;
	
	dispatch_once(&onceToken, ^{
		sInstallerAppBundle=[[PKGInstallerAppBundle alloc] initWithPath:PKGInstallerAppPath];
	});
	
	return sInstallerAppBundle;
}

#pragma mark -

- (NSComparisonResult)compareVersion:(NSString *)inShortVersionString
{
	if (inShortVersionString==nil)
		return NSOrderedDescending;
	
	static dispatch_once_t onceToken;
	static NSString * sShortVersionNumber=nil;

	dispatch_once(&onceToken, ^{
		sShortVersionNumber=[self infoDictionary][@"CFBundleShortVersionString"];
	});
	
	return [sShortVersionNumber compare:inShortVersionString options:NSNumericSearch];
}

- (BOOL)isVersion6_1OrLater
{	
	return [self compareVersion:PKGInstallerAppVersionNumber6_1];
}

@end
