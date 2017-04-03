/*
 Copyright (c) 2014-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGInstallerApp.h"

NSString * const PKGInstallerAppVersionNumber6_1=@"6.1.0";	// OS X 10.10

NSString * const PKGInstallerAppPath=@"/System/Library/CoreServices/Installer.app";

@interface PKGInstallerApp ()
{
	NSBundle * _bundle;
	
	NSMutableDictionary * _pluginsRegistry;
}

- (NSComparisonResult)compareVersion:(NSString *)inShortVersionString;

@end

@implementation PKGInstallerApp

+ (PKGInstallerApp *)installerApp
{
	static dispatch_once_t onceToken;
	static PKGInstallerApp * sInstallerApp=nil;
	
	dispatch_once(&onceToken, ^{
		sInstallerApp=[PKGInstallerApp new];
	});
	
	return sInstallerApp;
}

- (instancetype)init
{
	NSBundle * tBundle=[NSBundle bundleWithPath:PKGInstallerAppPath];
	
	if (tBundle==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_bundle=tBundle;
		
		_pluginsRegistry=[NSMutableDictionary dictionary];
	}
	
	return self;
}

#pragma mark -

- (NSImage *)iconForPackageType:(PKGInstallerAppPackageType)inPackageType
{
	switch(inPackageType)
	{
		case PKGInstallerAppRawPackage:
			
			return [_bundle imageForResource:@"package"];
			
		case PKGInstallerAppDistributionBundle:
			
			return [_bundle imageForResource:@"metapackage"];
			
		case PKGInstallerAppDistrbutionFlat:
			
			return [_bundle imageForResource:@"package"];
	}
	
	return nil;
}

- (NSImage *)anteriorStepDot
{
	return [_bundle imageForResource:@"DotGray"];
}

- (NSImage *)currentStepDot
{
	return [_bundle imageForResource:@"DotBlue"];
}

- (NSImage *)posteriorStepDot
{
	return [_bundle imageForResource:@"DotGrayDisabled"];
}

#pragma mark -

- (NSComparisonResult)compareVersion:(NSString *)inShortVersionString
{
	if (inShortVersionString==nil)
		return NSOrderedDescending;
	
	static dispatch_once_t onceToken;
	static NSString * sShortVersionNumber=nil;

	dispatch_once(&onceToken, ^{
		sShortVersionNumber=[_bundle infoDictionary][@"CFBundleShortVersionString"];
	});
	
	return [sShortVersionNumber compare:inShortVersionString options:NSNumericSearch];
}

- (BOOL)isVersion6_1OrLater
{	
	return ([self compareVersion:PKGInstallerAppVersionNumber6_1]!=NSOrderedDescending);
}

#pragma mark -

- (PKGInstallerPlugin *)pluginWithSectionName:(NSString *)inSectionName
{
	if (inSectionName==nil)
		return nil;
	
	PKGInstallerPlugin * tInstallerPlugin=_pluginsRegistry[inSectionName];
	
	if (tInstallerPlugin!=nil)
		return tInstallerPlugin;
	
	NSURL * tPlugInsDirectoryURL=[_bundle builtInPlugInsURL];
	
	if (tPlugInsDirectoryURL==nil)
		return nil;
	
	NSURL * tPluginURL=[[tPlugInsDirectoryURL URLByAppendingPathComponent:inSectionName] URLByAppendingPathExtension:@"bundle"];
	
	tInstallerPlugin=[[PKGInstallerPlugin alloc] initWithBundleAtURL:tPluginURL];
	
	if (tInstallerPlugin!=nil)
		_pluginsRegistry[inSectionName]=tInstallerPlugin;
	
	return tInstallerPlugin;
}

@end
