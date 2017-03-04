/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageSettings.h"

#import "PKGPackagesError.h"

NSString * const PKGPackageSettingsNameKey=@"NAME";

NSString * const PKGPackageSettingsIdentifierKey=@"IDENTIFIER";

NSString * const PKGPackageSettingsVersionKey=@"VERSION";

NSString * const PKGPackageSettingsConclusionActionKey=@"CONCLUSION_ACTION";

NSString * const PKGPackageSettingsLocationTypeKey=@"LOCATION";

NSString * const PKGPackageSettingsLocationPathKey=@"REFERENCE_PATH";

NSString * const PKGPackageSettingsAuthenticationModeKey=@"AUTHENTICATION";

NSString * const PKGPackageSettingsRelocatableKey=@"RELOCATABLE";

NSString * const PKGPackageSettingsOverwriteDirectoryPermissionsKey=@"OVERWRITE_PERMISSIONS";

NSString * const PKGPackageSettingsFollowSymbolicLinksKey=@"FOLLOW_SYMBOLIC_LINKS";

NSString * const PKGPackageSettingsUseHFSPlusCompressionKey=@"USE_HFS+_COMPRESSION";

NSString * const PKGPackageSettingsPayloadSizeKey=@"PAYLOAD_SIZE";


@interface PKGPackageSettings ()

	@property (readwrite) NSInteger payloadSize;

@end


@implementation PKGPackageSettings

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_name=@"";
		_identifier=@"";
		_version=@"1.0";
		
		_conclusionAction=PKGPackageConclusionActionNone;
		
		_locationType=PKGPackageLocationEmbedded;
		_locationURL=@"";
		
		_authenticationMode=PKGPackageAuthenticationRoot;
		_relocatable=NO;
		_overwriteDirectoryPermissions=NO;
		_followSymbolicLinks=NO;
		_useHFSPlusCompression=NO;
		
		_payloadSize=-1;
	}
	
	return self;
}

- (instancetype)initWithXMLData:(NSData *)inData
{
	if (inData==nil)
	{
		
		return nil;
	}
	
	NSError * tError;
	NSXMLDocument * tXMLDocument=[[NSXMLDocument alloc] initWithData:inData options:0 error:&tError];
	
	if (tXMLDocument==nil)
	{
		
		return nil;
	}
	
	NSArray * tNodes=[tXMLDocument nodesForXPath:@"pkg-info" error:&tError];
	
	if ([tNodes count]==0)
	{
		
		return nil;
	}

	NSXMLElement * tElement=(NSXMLElement *) [tNodes objectAtIndex:0];
	
	if (tElement==nil)
	{
		
		return nil;
	}
	
	NSArray * tAttributes=[tElement attributes];
		
	if (tAttributes==nil)
	{
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		// Default Values
		
		_name=nil;
		_identifier=@"";
		_version=@"";
		
		_conclusionAction=PKGPackageConclusionActionNone;
		
		_locationType=PKGPackageLocationEmbedded;
		_locationURL=@"";
		
		_authenticationMode=PKGPackageAuthenticationNone;
		_relocatable=NO;
		_overwriteDirectoryPermissions=NO;
		_followSymbolicLinks=NO;
		_useHFSPlusCompression=NO;
		
		_payloadSize=0;
		
		for(NSXMLNode * tAttributeNode in tAttributes)
		{
			NSString * tAttributeName=[tAttributeNode name];
			NSString * tStringValue=[tAttributeNode stringValue];
			
			if ([tAttributeName isEqualToString:@"identifier"]==YES)
			{
				_identifier=tStringValue;
			}
			else if ([tAttributeName isEqualToString:@"relocatable"]==YES)
			{
				tStringValue=[tStringValue lowercaseString];
				
				_relocatable=([tStringValue isEqualToString:@"yes"] || [tStringValue isEqualToString:@"true"]);
			}
			else if ([tAttributeName isEqualToString:@"overwrite-permissions"]==YES)
			{
				tStringValue=[tStringValue lowercaseString];
				
				_overwriteDirectoryPermissions=([tStringValue isEqualToString:@"yes"] || [tStringValue isEqualToString:@"true"]);
			}
			else if ([tAttributeName isEqualToString:@"followSymLinks"]==YES)
			{
				tStringValue=[tStringValue lowercaseString];
				
				_followSymbolicLinks=([tStringValue isEqualToString:@"yes"] || [tStringValue isEqualToString:@"true"]);
			}
			else if ([tAttributeName isEqualToString:@"useHFSPlusCompression"]==YES)
			{
				tStringValue=[tStringValue lowercaseString];
				
				_useHFSPlusCompression=([tStringValue isEqualToString:@"yes"] || [tStringValue isEqualToString:@"true"]);
			}
			else if ([tAttributeName isEqualToString:@"auth"]==YES)
			{
				tStringValue=[tStringValue lowercaseString];
				
				if ([tStringValue isEqualToString:@"root"]==YES)
					_authenticationMode=PKGPackageAuthenticationRoot;
			}
			else if ([tAttributeName isEqualToString:@"postinstall-action"]==YES)
			{
				tStringValue=[tStringValue lowercaseString];
				
				if ([tStringValue isEqualToString:@"restart"]==YES)
				{
					_conclusionAction=PKGPackageConclusionActionRequireRestart;
				}
				else if ([tStringValue isEqualToString:@"shutdown"]==YES)
				{
					_conclusionAction=PKGPackageConclusionActionRequireShutdown;
				}
				else if ([tStringValue isEqualToString:@"logout"]==YES)
				{
					_conclusionAction=PKGPackageConclusionActionRequireLogout;
				}
			}
			else if ([tAttributeName isEqualToString:@"version"]==YES)
			{
				_version=tStringValue;
			}
		}
		
		_payloadSize=-1;
		
		tNodes=[tXMLDocument nodesForXPath:@"pkg-info/payload" error:&tError];
		
		if ([tNodes count]>0)
		{
			tElement=(NSXMLElement *) tNodes[0];
			
			if (tElement!=nil)
			{
				tAttributes=[tElement attributes];
				
				for (NSXMLNode * tAttributeNode in tAttributes)
				{
					if ([tAttributeNode.name isEqualToString:@"installKBytes"]==YES)
					{
						_payloadSize=tAttributeNode.stringValue.integerValue;
						break;
					}
				}
			}
		}
	}
	
	return self;
}

- (id) initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
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
		NSString * tString=inRepresentation[PKGPackageSettingsNameKey];
		
		PKGClassCheckStringValueForKey(tString,PKGPackageSettingsNameKey);
		
		_name=[tString copy];
		if (_name==nil)
			_name=@"";
		
		_locationType=[inRepresentation[PKGPackageSettingsLocationTypeKey] unsignedIntegerValue];
		
		if (_locationType>PKGPackageLocationRemovableMedia)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGPackageSettingsLocationTypeKey}];
			
			return nil;
		}
		
		if (_locationType!=PKGPackageLocationEmbedded)
		{
			tString=inRepresentation[PKGPackageSettingsLocationPathKey];
			
			PKGClassCheckStringValueForKey(tString,PKGPackageSettingsLocationPathKey);
			
			_locationURL=[tString copy];
		}
		
		if (_locationURL==nil)
			_locationURL=@"";
			
		
		// Only available to project and referenced packages
		
		tString=inRepresentation[PKGPackageSettingsIdentifierKey];
		
		PKGClassCheckStringValueForKey(tString,PKGPackageSettingsIdentifierKey);
		
		_identifier=[tString copy];
		if (_identifier==nil)
			_identifier=@"";
		
		
		tString=inRepresentation[PKGPackageSettingsVersionKey];
		
		PKGClassCheckStringValueForKey(tString,PKGPackageSettingsVersionKey);
		
		_version=[tString copy];
		if (_version==nil)
			_version=@"";
		
		_conclusionAction=[inRepresentation[PKGPackageSettingsConclusionActionKey] unsignedIntegerValue];
		
		if (_conclusionAction>PKGPackageConclusionActionRequireLogout)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGPackageSettingsConclusionActionKey}];
			
			return nil;
		}
		
		if (_conclusionAction==PKGPackageConclusionActionRecommendRestart)		// Recommend restart is not supported by Installer.app in recent versions
			_conclusionAction=PKGPackageConclusionActionRequireRestart;
		
		_authenticationMode=[inRepresentation[PKGPackageSettingsAuthenticationModeKey] unsignedIntegerValue];
		
		if (_authenticationMode>PKGPackageAuthenticationRoot)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGPackageSettingsAuthenticationModeKey}];
			
			return nil;
		}
		
		_relocatable=[inRepresentation[PKGPackageSettingsRelocatableKey] boolValue];
		_overwriteDirectoryPermissions=[inRepresentation[PKGPackageSettingsOverwriteDirectoryPermissionsKey] boolValue];
		_followSymbolicLinks=[inRepresentation[PKGPackageSettingsFollowSymbolicLinksKey] boolValue];
		_useHFSPlusCompression=[inRepresentation[PKGPackageSettingsUseHFSPlusCompressionKey] boolValue];
		
		_payloadSize=-1;
		
		if (inRepresentation[PKGPackageSettingsPayloadSizeKey]!=nil)
			_payloadSize=[inRepresentation[PKGPackageSettingsPayloadSizeKey] integerValue];
	}
	
	return self;
}

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	if (self.name!=nil)
		tMutableDictionary[PKGPackageSettingsNameKey]=self.name;
	
	tMutableDictionary[PKGPackageSettingsLocationTypeKey]=@(self.locationType);
	
	NSString * tLocationPath=self.locationPath;
	if (tLocationPath!=nil)
		tMutableDictionary[PKGPackageSettingsLocationPathKey]=tLocationPath;
	
	// Only available to project and referenced packages
	
	if (self.identifier!=nil)
	{
		tMutableDictionary[PKGPackageSettingsIdentifierKey]=self.identifier;
		tMutableDictionary[PKGPackageSettingsVersionKey]=self.version;
		
		tMutableDictionary[PKGPackageSettingsConclusionActionKey]=@(self.conclusionAction);
		
		tMutableDictionary[PKGPackageSettingsAuthenticationModeKey]=@(self.authenticationMode);
		tMutableDictionary[PKGPackageSettingsRelocatableKey]=@(self.relocatable);
		tMutableDictionary[PKGPackageSettingsOverwriteDirectoryPermissionsKey]=@(self.overwriteDirectoryPermissions);
		tMutableDictionary[PKGPackageSettingsFollowSymbolicLinksKey]=@(self.followSymbolicLinks);
		tMutableDictionary[PKGPackageSettingsUseHFSPlusCompressionKey]=@(self.useHFSPlusCompression);
		
		tMutableDictionary[PKGPackageSettingsPayloadSizeKey]=@(self.payloadSize);
	}
	
	return tMutableDictionary;
}

#pragma mark -

- (NSString *)locationScheme
{
	switch(self.locationType)
	{
		case PKGPackageLocationEmbedded:
			
			return @"file:";
			
		case PKGPackageLocationCustomPath:
			
			return @"file:";
			
		case PKGPackageLocationHTTPURL:
			
			return @"http://";
			
		case PKGPackageLocationRemovableMedia:
		
			return @"x-disc://";
	}
	
	return nil;
}

- (NSString *)locationPath
{
	if (self.locationURL==nil)
		return nil;
	
	NSString * tLocationPath=[self.locationURL copy];
	
	switch(self.locationType)
	{
		case PKGPackageLocationEmbedded:
			
			return nil;
			
		case PKGPackageLocationCustomPath:
			
			if ([tLocationPath hasPrefix:@"file:"]==YES)
				tLocationPath=[tLocationPath substringFromIndex:5];
			
			break;
			
		case PKGPackageLocationHTTPURL:
		case PKGPackageLocationRemovableMedia:
		{
			NSString * tURLPrefix=[self locationScheme];
			
			if ([tLocationPath hasPrefix:tURLPrefix]==YES)
				tLocationPath=[tLocationPath substringFromIndex:[tURLPrefix length]];
			
			if ([tLocationPath hasPrefix:@"/"]==YES)
				tLocationPath=[tLocationPath substringFromIndex:1];
			
			break;
		}
	}
	
	if ([tLocationPath length]==0)
		return nil;
	
	return tLocationPath;
}

#pragma mark -

- (NSString *) description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"  Package Settings:\n"];
	[tDescription appendString:@"  ----------------\n\n"];
	
	[tDescription appendFormat:@"  Name: %@\n",self.name];
	[tDescription appendFormat:@"  Identifier: %@\n",self.identifier];
	[tDescription appendFormat:@"  Version: %@\n\n",self.version];
	
	[tDescription appendString:@"  Conclusion Action: "];
	
	switch(self.conclusionAction)
	{
		case PKGPackageConclusionActionNone:
			
			[tDescription appendString:@"None"];
			break;
			
		case PKGPackageConclusionActionRecommendRestart:
			
			[tDescription appendString:@"Recommend Restart"];
			break;
			
		case PKGPackageConclusionActionRequireRestart:
			
			[tDescription appendString:@"Require Restart"];
			break;
			
		case PKGPackageConclusionActionRequireShutdown:
			
			[tDescription appendString:@"Require Shutdown"];
			break;
			
		case PKGPackageConclusionActionRequireLogout:
			
			[tDescription appendString:@"Require Logout"];
			break;
	}
	
	[tDescription appendString:@"\n\n"];
	
	[tDescription appendString:@"  Location: "];
	
	switch(self.locationType)
	{
		case PKGPackageLocationEmbedded:
			
			[tDescription appendString:@"Embedded"];
			break;
			
		case PKGPackageLocationCustomPath:
			
			[tDescription appendString:@"Custom Path"];
			break;
			
		case PKGPackageLocationHTTPURL:
			
			[tDescription appendString:@"HTTP URL"];
			break;
			
		case PKGPackageLocationRemovableMedia:
			
			[tDescription appendString:@"Removable Media"];
			break;
	}
	
	[tDescription appendString:@"\n"];
	
	if (self.locationType!=PKGPackageLocationEmbedded)
		[tDescription appendFormat:@"  Location Path: %@\n",self.locationURL];
	
	[tDescription appendString:@"\n"];
	
	
	[tDescription appendFormat:@"  Authentication Mode: %@\n",(self.authenticationMode==PKGPackageAuthenticationRoot) ? @"root" : @"none"];
	[tDescription appendFormat:@"  Relocatable: %@\n",(self.relocatable==YES) ? @"Yes" : @"No"];
	[tDescription appendFormat:@"  Overwrite Directory Permissions: %@\n",(self.overwriteDirectoryPermissions==YES) ? @"Yes" : @"No"];
	[tDescription appendFormat:@"  Follow Symbolic Links: %@\n",(self.followSymbolicLinks==YES) ? @"Yes" : @"No"];
	[tDescription appendFormat:@"  Use HFS+ Compression: %@\n",(self.useHFSPlusCompression==YES) ? @"Yes" : @"No"];
	
	[tDescription appendString:@"\n"];
	
	[tDescription appendFormat:@"  Payload Size: %lu\n",(unsigned long)self.payloadSize];
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGPackageSettings * nPackageSettings=[[[self class] allocWithZone:inZone] init];
	
	if (nPackageSettings!=nil)
	{
		nPackageSettings.name=[self.name copyWithZone:inZone];
		
		nPackageSettings.identifier=[self.identifier copyWithZone:inZone];
		
		nPackageSettings.version=[self.version copyWithZone:inZone];
		
		
		nPackageSettings.conclusionAction=self.conclusionAction;
		
		
		nPackageSettings.locationType=self.locationType;
		
		nPackageSettings.locationURL=[self.locationURL copyWithZone:inZone];
		
		
		nPackageSettings.authenticationMode=self.authenticationMode;
		
		
		nPackageSettings.relocatable=self.relocatable;
		
		nPackageSettings.overwriteDirectoryPermissions=self.overwriteDirectoryPermissions;
		
		nPackageSettings.followSymbolicLinks=self.followSymbolicLinks;
		
		nPackageSettings.useHFSPlusCompression=self.useHFSPlusCompression;
	}
	
	return nPackageSettings;
}

@end
