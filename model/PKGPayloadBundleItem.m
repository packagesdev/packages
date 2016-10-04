/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadBundleItem.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGPayloadBundleItemAllowDowngradeKey=@"BUNDLE_CAN_DOWNGRADE";

NSString * const PKGPayloadBundleItemPreInstallationScriptKey=@"BUNDLE_PREINSTALL_PATH";

NSString * const PKGPayloadBundleItemPostInstallationScriptKey=@"BUNDLE_POSTINSTALL_PATH";

NSString * const PKGPayloadBundleItemLocatorsKey=@"LOCATORS";

@interface PKGPayloadBundleItem ()

	@property (readwrite) NSMutableArray * locators;

@end


@implementation PKGPayloadBundleItem

+ (BOOL)isRepresentationOfBundleItem:(NSDictionary *)inRepresentation
{
	if (inRepresentation[PKGPayloadBundleItemAllowDowngradeKey]!=nil ||
		inRepresentation[PKGPayloadBundleItemPreInstallationScriptKey]!=nil ||
		inRepresentation[PKGPayloadBundleItemPostInstallationScriptKey]!=nil ||
		inRepresentation[PKGPayloadBundleItemLocatorsKey]!=nil)
		return YES;
	
	// A COMPLETER (it's probably more complex)
	
	return NO;
}

- (id) initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	__block NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self==nil)
	{
		if (outError!=NULL)
			*outError=tError;
		
		return nil;
	}
	
	_allowDowngrade=[inRepresentation[PKGPayloadBundleItemAllowDowngradeKey] boolValue];
	
	_preInstallationScriptPath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGPayloadBundleItemPreInstallationScriptKey] error:&tError];
	
	if (_preInstallationScriptPath==nil)
	{
		if (tError.code!=PKGRepresentationNilRepresentationError)
		{
			if (outError!=NULL)
			{
				NSString * tPathError=PKGPayloadBundleItemPreInstallationScriptKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tError.code
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
	}
	
	_postInstallationScriptPath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGPayloadBundleItemPostInstallationScriptKey] error:&tError];
	
	if (_postInstallationScriptPath==nil)
	{
		if (tError.code!=PKGRepresentationNilRepresentationError)
		{
			if (outError!=NULL)
			{
				NSString * tPathError=PKGPayloadBundleItemPostInstallationScriptKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tError.code
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
	}
	
	if (inRepresentation[PKGPayloadBundleItemLocatorsKey]==nil)
	{
		_locators=[NSMutableArray array];
	}
	else
	{
		if ([inRepresentation[PKGPayloadBundleItemLocatorsKey] isKindOfClass:[NSArray class]]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGPayloadBundleItemLocatorsKey}];
			
			return nil;
		}
		
		_locators=[[inRepresentation[PKGPayloadBundleItemLocatorsKey] WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bLocatorRepresentation,__attribute__((unused))NSUInteger bIndex){
		
			return [[PKGLocator alloc] initWithRepresentation:bLocatorRepresentation error:&tError];

		}] mutableCopy];
		
		if (_locators==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGPayloadBundleItemLocatorsKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
	}
	
	return self;
}

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tRepresentation=[super representation];
	
	tRepresentation[PKGPayloadBundleItemAllowDowngradeKey]=@(self.allowDowngrade);
	
	NSMutableDictionary * tPathRepresentation=[self.preInstallationScriptPath representation];
	
	if (tPathRepresentation!=nil)
		tRepresentation[PKGPayloadBundleItemPreInstallationScriptKey]=tPathRepresentation;
	
	tPathRepresentation=[self.postInstallationScriptPath representation];
	
	if (tPathRepresentation!=nil)
		tRepresentation[PKGPayloadBundleItemPostInstallationScriptKey]=tPathRepresentation;
	
	NSMutableArray * tLocatorsRepresentation=[self.locators WB_arrayByMappingObjectsUsingBlock:^id(PKGLocator * bLocator,__attribute__((unused))NSUInteger bIndex){
		
		return [bLocator representation];
	}];
	
	if ([tLocatorsRepresentation count]>0)
		tRepresentation[PKGPayloadBundleItemLocatorsKey]=tLocatorsRepresentation;
	
	return tRepresentation;
}

@end
