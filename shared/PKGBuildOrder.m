/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildOrder.h"

NSString * const PKGBuildOrderUUIDKey=@"UUID";
NSString * const PKGBuildOrderProjectPathKey=@"ProjectPath";
NSString * const PKGBuildOrderBuildOptionsKey=@"BuildOptions";
NSString * const PKGBuildOrderExternalSettingsKey=@"ExternalSettings";

NSString * const PKGBuildOrderExternalSettingsReferenceProjectFolderKey=@"ReferenceProjectFolder";
NSString * const PKGBuildOrderExternalSettingsReferenceFolderKey=@"ReferenceFolder";
NSString * const PKGBuildOrderExternalSettingsScratchFolderKey=@"ScratchFolder";
NSString * const PKGBuildOrderExternalSettingsBuildFolderKey=@"BuildFolder";
NSString * const PKGBuildOrderExternalSettingsSigningIdentityKey=@"SigningIdentity";
NSString * const PKGBuildOrderExternalSettingsKeychainKey=@"Keychain";
NSString * const PKGBuildOrderExternalSettingsPackageVersionKey=@"PackageVersion";		// Only supported for Raw Package projects
NSString * const PKGBuildOrderExternalSettingsUserDefinedSettingsKey=@"UserDefinedSettings";

@interface PKGBuildOrder ()

	@property (readwrite,copy) NSString * UUID;

@end


@implementation PKGBuildOrder

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_UUID=[[[NSUUID UUID] UUIDString] copy];
	}
	
	return self;
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation
{
	if (inRepresentation==nil || [inRepresentation isKindOfClass:NSDictionary.class]==NO)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_UUID=[inRepresentation[PKGBuildOrderUUIDKey] copy];
		
		if (_UUID==nil)
			return nil;
		
		_projectPath=[inRepresentation[PKGBuildOrderProjectPathKey] copy];
		
		if (_projectPath==nil)
			return nil;
		
		_buildOptions=[inRepresentation[PKGBuildOrderBuildOptionsKey] unsignedIntegerValue];
		
		_externalSettings=inRepresentation[PKGBuildOrderExternalSettingsKey];
		
		if (_externalSettings!=nil && [_externalSettings isKindOfClass:NSDictionary.class]==NO)
			return nil;
	}
	
	return self;
}

#pragma mark -

- (NSUInteger)hash
{
	return self.projectPath.hash;
}

- (id)copy
{
	PKGBuildOrder * nBuildOrder=[PKGBuildOrder new];
	
	nBuildOrder.UUID=[self.UUID copy];
	nBuildOrder.projectPath=[self.projectPath copy];
	nBuildOrder.buildOptions=self.buildOptions;
	nBuildOrder.externalSettings=[self.externalSettings copy];
	
	return nBuildOrder;
}

#pragma mark -

- (NSDictionary *)representation
{
	if (self.externalSettings==nil)
		return @{PKGBuildOrderUUIDKey:self.UUID,
				 PKGBuildOrderProjectPathKey:self.projectPath,
				 PKGBuildOrderBuildOptionsKey:@(self.buildOptions)};
	
	return @{PKGBuildOrderUUIDKey:self.UUID,
			 PKGBuildOrderProjectPathKey:self.projectPath,
			 PKGBuildOrderBuildOptionsKey:@(self.buildOptions),
			 PKGBuildOrderExternalSettingsKey:self.externalSettings};
}

@end
