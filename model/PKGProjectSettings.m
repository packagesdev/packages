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

NSString * const PKGProjectSettingsUserDefinedSettingsKey=@"USER_DEFINED_SETTINGS";

NSString * const PKGProjectSettingsDefaultKeyChainPath=@"~/Library/Keychains/login.keychain";


NSString * const PKGProjectSettingsUserSettingsDidChangeNotification=@"PKGProjectSettingsUserSettingsDidChangeNotification";

@interface PKGProjectSettings ()

	@property (readwrite) NSMutableArray * filesFilters;

    @property (readwrite) NSMutableDictionary<NSString *,NSString *> * userDefinedSettings;

@end

@implementation PKGProjectSettings

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_buildPath=[PKGFilePath filePathWithString:@"build" type:PKGFilePathTypeRelativeToProject];
		
		
		_filesFilters=[NSMutableArray array];
		
		_filterPayloadOnly=NO;
        
        _userDefinedSettings=[NSMutableDictionary dictionary];
	}
	
	return self;
}

- (instancetype)initWithProjectSettings:(PKGProjectSettings *)inProjectSettings
{
	self=[super init];
	
	if (self!=nil)
	{
		_name=[inProjectSettings.name copy];
		_buildPath=[inProjectSettings.buildPath copy];
		_referenceFolderPath=[inProjectSettings.referenceFolderPath copy];
		
		
		_certificateName=[inProjectSettings.certificateName copy];
		_certificateKeychainPath=[inProjectSettings.certificateKeychainPath copy];
		
		_filesFilters=[inProjectSettings.filesFilters WB_arrayByMappingObjectsUsingBlock:^id(PKGFileFilter * bFileFilter, NSUInteger bIndex) {
			
			return [bFileFilter copy];
		}];
		
		_filterPayloadOnly=inProjectSettings.filterPayloadOnly;
        
        _userDefinedSettings=[inProjectSettings.userDefinedSettings mutableCopy];
	}
	
	return self;
}

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
					tCode=PKGRepresentationInvalidValueError;
				
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
		
		if (tArray==nil)
		{
			_filesFilters=[NSMutableArray array];
		}
		else
		{
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
						tCode=PKGRepresentationInvalidValueError;
					
					NSString * tPathError=PKGProjectSettingsFilesFiltersKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		NSNumber * tNumber=inRepresentation[PKGProjectSettingsFilterPayloadOnlyKey];
		
		//PKGFullCheckNumberValueForKey(tNumber,PKGProjectSettingsFilterPayloadOnlyKey);	// A VOIR
		
		_filterPayloadOnly=[tNumber boolValue];
        
        // User Defined Settings
        
        NSDictionary * tDictionary=inRepresentation[PKGProjectSettingsUserDefinedSettingsKey];
        
        if (tDictionary!=nil)
        {
            if ([tDictionary isKindOfClass:[NSDictionary class]]==NO)
            {
                if (outError!=NULL)
                    *outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
                                                  code:PKGRepresentationInvalidTypeOfValueError
                                              userInfo:@{PKGKeyPathErrorKey:PKGProjectSettingsUserDefinedSettingsKey}];
                
                return nil;
            }
            
            _userDefinedSettings=[tDictionary mutableCopy];
            
            [_userDefinedSettings enumerateKeysAndObjectsUsingBlock:^(NSString * bKey, NSString * bObject, BOOL * bOutStop) {
                
               if ([bKey isKindOfClass:[NSString class]]==NO ||
                   [bObject isKindOfClass:[NSString class]]==NO)
               {
                   self->_userDefinedSettings=nil;
                   *bOutStop=YES;
                   return;
               }
                
            }];
            
            if (_userDefinedSettings==nil)
            {
                if (outError!=NULL)
                {
                    NSInteger tCode=tError.code;
                    
                    if (tCode==PKGRepresentationNilRepresentationError)
                        tCode=PKGRepresentationInvalidValueError;
                    
                    NSString * tPathError=PKGProjectSettingsUserDefinedSettingsKey;
                    
                    if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
                        tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
                    
                    *outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
                                                  code:tCode
                                              userInfo:@{PKGKeyPathErrorKey:tPathError}];
                }
                
                return nil;
            }
        }
        else
        {
            _userDefinedSettings=[NSMutableDictionary dictionary];
        }
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
		
	if (tCertificateRepresentation.count>0)
		tRepresentation[PKGProjectSettingsCertificateKey]=tCertificateRepresentation;
	
	
	tRepresentation[PKGProjectSettingsFilesFiltersKey]=[self.filesFilters WB_arrayByMappingObjectsUsingBlock:^id(id<PKGObjectProtocol,PKGFileFilterProtocol>bFilter,__attribute__((unused))NSUInteger bIndex){
		return [bFilter representation];
	}];
	
	tRepresentation[PKGProjectSettingsFilterPayloadOnlyKey]=@(self.filterPayloadOnly);
    
    if (self.userDefinedSettings.count>0)
        tRepresentation[PKGProjectSettingsUserDefinedSettingsKey]=[self.userDefinedSettings copy];
	
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
	
	[tDescription appendFormat:@"  Exclusions(%lu):\n\n",(unsigned long) self.filesFilters.count];
	
	for(PKGFileFilter * tFileFilter in self.filesFilters)
	{
		[tDescription appendString:[tFileFilter description]];
		
		[tDescription appendString:@"\n"];
	}
	
	[tDescription appendFormat:@"  Exclude files in payload only: %@\n",(self.filterPayloadOnly==YES)? @"Yes": @"No"];
	
    // A COMPLETER (User Defined Settings)
    
    
    
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGProjectSettings * nProjectSettings=[[[self class] allocWithZone:inZone] init];
	
	if (nProjectSettings!=nil)
	{
		nProjectSettings.name=[self.name copyWithZone:inZone];
		nProjectSettings.buildPath=[self.buildPath copyWithZone:inZone];
		nProjectSettings.referenceFolderPath=[self.referenceFolderPath copyWithZone:inZone];
		
		
		nProjectSettings.certificateName=[self.certificateName copyWithZone:inZone];
		nProjectSettings.certificateKeychainPath=[self.certificateKeychainPath copyWithZone:inZone];
		
		nProjectSettings.filesFilters=[self.filesFilters WB_arrayByMappingObjectsUsingBlock:^id(PKGFileFilter * bFileFilter, NSUInteger bIndex) {
			
			return [bFileFilter copyWithZone:inZone];
		}];
		
		nProjectSettings.filterPayloadOnly=self.filterPayloadOnly;
        
        nProjectSettings.userDefinedSettings=[self.userDefinedSettings copyWithZone:inZone];
	}
	
	return nProjectSettings;
}

#pragma mark -

- (NSArray *)optimizedFilesFilters
{
	NSMutableArray * tMutableOptimizedFiltersArray=[self.filesFilters WB_filteredArrayUsingBlock:^BOOL(PKGFileFilter * bFilter, NSUInteger bIndex) {
	
		if ([bFilter isKindOfClass:PKGSeparatorFilter.class]==YES)
			return NO;
		
		if (bFilter.isEnabled==NO)
			return NO;
		
		return YES;
	}];
	
	return [tMutableOptimizedFiltersArray copy];
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
