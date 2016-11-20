/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGProjectSettings.h"

#import "PKGPackagesError.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGProjectSettingsNameKey=@"NAME";

NSString * const PKGProjectSettingsBuildPathKey=@"BUILD_PATH";

NSString * const PKGProjectSettingsReferenceFolderPathKey=@"REFERENCE_FOLDER_PATH";

NSString * const PKGProjectSettingsCertificateKey=@"CERTIFICATE";

NSString * const PKGProjectSettingsCertificateNameKey=@"NAME";

NSString * const PKGProjectSettingsCertificateKeyChainPathKey=@"PATH";

NSString * const PKGProjectSettingsFilesFiltersKey=@"EXCLUDED_FILES";

NSString * const PKGProjectSettingsFilterPayloadOnlyKey=@"PAYLOAD_ONLY";


NSString * const PKGProjectSettingsDefaultKeyChainPath=@"~/Library/Keychains/login.keychain";


@implementation PKGProjectSettings

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		// Name
		
		NSString * tString=inRepresentation[PKGProjectSettingsNameKey];		// can be nil
		
		PKGClassCheckStringValueForKey(tString,PKGProjectSettingsNameKey);
		
		_name=[tString copy];
		
		__block NSError * tError=nil;
		
		// Build Path
		
		_buildPath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGProjectSettingsBuildPathKey] error:&tError];
		
		if (_buildPath==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGProjectSettingsBuildPathKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		// Reference Folder
		
		tString=inRepresentation[PKGProjectSettingsReferenceFolderPathKey];
		
		PKGClassCheckStringValueForKey(tString,PKGProjectSettingsReferenceFolderPathKey);	// can be nil -> project folder
		
		_referenceFolderPath=[tString copy];
		
		// Certificate
		
		NSDictionary * tCertificateRepresentation=inRepresentation[PKGProjectSettingsCertificateKey];
		
		if (tCertificateRepresentation!=nil)
		{
			if ([tCertificateRepresentation isKindOfClass:NSDictionary.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGProjectSettingsCertificateKey}];
				
				return nil;
			}
			
			tString=tCertificateRepresentation[PKGProjectSettingsCertificateNameKey];
			
			PKGClassCheckStringValueForKey(tString,PKGProjectSettingsCertificateNameKey);
			
			_certificateName=[tString copy];
			
			
			tString=tCertificateRepresentation[PKGProjectSettingsCertificateKeyChainPathKey];
			
			PKGClassCheckStringValueForKey(tString,PKGProjectSettingsCertificateKeyChainPathKey);
			
			_certificateKeychainPath=[tString copy];
		}
		
		// Files Filters
		
		NSArray * tArray=inRepresentation[PKGProjectSettingsFilesFiltersKey];
		
		PKGFullCheckArrayValueForKey(tArray,PKGProjectSettingsFilesFiltersKey);
		
		_filesFilters=[[tArray WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bFileFilterRepresentation,__attribute__((unused))NSUInteger bIndex){
			return [PKGFileFilterFactory filterWithRepresentation:bFileFilterRepresentation error:&tError];
		}] mutableCopy];
		
		if (_filesFilters==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGProjectSettingsFilesFiltersKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		_filterPayloadOnly=[inRepresentation[PKGProjectSettingsFilterPayloadOnlyKey] boolValue];
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	if (self.name!=nil)
		tRepresentation[PKGProjectSettingsNameKey]=self.name;
	
	tRepresentation[PKGProjectSettingsBuildPathKey]=[self.buildPath representation];
	
	if (self.referenceFolderPath!=nil)
		tRepresentation[PKGProjectSettingsReferenceFolderPathKey]=self.referenceFolderPath;
	
	NSMutableDictionary * tCertificateRepresentation=[NSMutableDictionary dictionary];
	
	if (self.certificateName!=nil)
		tCertificateRepresentation[PKGProjectSettingsCertificateNameKey]=self.certificateName;
	
	if (self.certificateKeychainPath!=nil)
		tCertificateRepresentation[PKGProjectSettingsCertificateKeyChainPathKey]=self.certificateKeychainPath;
		
	if ([tCertificateRepresentation count]>0)
		tRepresentation[PKGProjectSettingsCertificateKey]=tCertificateRepresentation;
	
	
	tRepresentation[PKGProjectSettingsFilesFiltersKey]=[self.filesFilters WB_arrayByMappingObjectsUsingBlock:^id(id<PKGObjectProtocol,PKGFileFilterProtocol>bFilter,__attribute__((unused))NSUInteger bIndex){
		return [bFilter representation];
	}];
	
	tRepresentation[PKGProjectSettingsFilterPayloadOnlyKey]=@(self.filterPayloadOnly);
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"Project Settings:\n"];
	[tDescription appendString:@"----------------\n\n"];
	
	[tDescription appendFormat:@"  Name: %@\n",self.name];
	[tDescription appendFormat:@"  Build Path: %@\n",[self.buildPath description]];
	[tDescription appendFormat:@"  Reference Folder Path: %@\n\n",self.referenceFolderPath];
	
	if (self.certificateName!=nil)
	{
		[tDescription appendFormat:@"  Certificate Identifier: %@\n",self.certificateName];
	
		[tDescription appendFormat:@"  Certificate KeyChain Path: %@\n\n",(self.certificateKeychainPath!=nil)? self.certificateKeychainPath : PKGProjectSettingsDefaultKeyChainPath];
	}
	
	[tDescription appendFormat:@"  Exclusions(%lu):\n\n",(unsigned long) [self.filesFilters count]];
	
	for(PKGFileFilter * tFileFilter in self.filesFilters)
	{
		[tDescription appendString:[tFileFilter description]];
		
		[tDescription appendString:@"\n"];
	}
	
	[tDescription appendFormat:@"  Exclude files in payload only: %@\n",(self.filterPayloadOnly==YES)? @"Yes": @"No"];
	
	return tDescription;
}

#pragma mark -

- (BOOL)shouldFilterFileNamed:(NSString *)inFileName ofType:(PKGFileSystemType)inType
{
	if (inFileName==nil)
		return NO;
	
	for(PKGFileFilter * tFileFilter in self.filesFilters)
	{
		if ([tFileFilter matchesFileNamed:inFileName ofType:inType]==YES)
			return YES;
	}
	
	return NO;
}

@end
