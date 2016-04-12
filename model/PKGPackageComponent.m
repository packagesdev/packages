/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageComponent.h"

#import "PKGPackagesError.h"

NSString * const PKGPackageComponentUUIDKey=@"UUID";

NSString * const PKGPackageComponentTypeKey=@"TYPE";

NSString * const PKGPackageComponentReferencePathKey=@"PATH";

NSString * const PKGPackageComponentSettingsKey=@"PACKAGE_SETTINGS";

NSString * const PKGPackageComponentPayloadKey=@"PACKAGE_FILES";

NSString * const PKGPackageComponentScriptsAndResourcesKey=@"PACKAGE_SCRIPTS";


@interface PKGPackageComponent ()

	@property (readwrite) NSString * uuid;

	@property (readwrite) PKGPackageComponentType type;

	@property (readwrite) PKGFilePath * referencePath;

@end


@implementation PKGPackageComponent

@synthesize packageSettings=_packageSettings,payload=_payload,scriptsAndResources=_scriptsAndResources;

- (id) initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:[NSDictionary class]]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		_UUID=inRepresentation[PKGPackageComponentUUIDKey];
		
		_type=[inRepresentation[PKGPackageComponentTypeKey] unsignedIntegerValue];
		
		NSError * tError=nil;
		
		_importPath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGPackageComponentReferencePathKey] error:&tError];
		
		if (_referencePath==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPackageComponentReferencePathKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		_packageSettings=[[PKGPackageSettings alloc] initWithRepresentation:inRepresentation[PKGPackageComponentSettingsKey] error:&tError];
		
		if (_packageSettings==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGPackageComponentSettingsKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
				
			return nil;
		}
		
		_payload=[[PKGPackagePayload alloc] initWithRepresentation:inRepresentation[PKGPackageComponentPayloadKey] error:&tError];
		
		if (_payload==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPackageComponentPayloadKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		_scriptsAndResources=[[PKGPackageScriptsAndResources alloc] initWithRepresentation:inRepresentation[PKGPackageComponentScriptsAndResourcesKey] error:&tError];
		
		if (_scriptsAndResources==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPackageComponentScriptsAndResourcesKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
	}
	
	return self;
}

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGPackageComponentUUIDKey]=self.UUID;
	
	tRepresentation[PKGPackageComponentTypeKey]=@(self.type);
	
	if (self.importPath!=nil)
		tRepresentation[PKGPackageComponentReferencePathKey]=[self.importPath representation];
	
	tRepresentation[PKGPackageComponentSettingsKey]=[self.packageSettings representation];
	
	if (self.payload!=nil)
		tRepresentation[PKGPackageComponentPayloadKey]=[self.payload representation];
	
	if (self.scriptsAndResources!=nil)
		tRepresentation[PKGPackageComponentScriptsAndResourcesKey]=[self.scriptsAndResources representation];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"  UUID: %@\n",self.UUID];
	
	[tDescription appendString:@"  Type: "];
	
	switch(self.type)
	{
		case PKGPackageComponentTypeProject:
			[tDescription appendString:@"Project"];
			break;
			
		case PKGPackageComponentTypeImported:
			[tDescription appendFormat:@"Imported (%@)",[self.importPath description]];
			break;
			
		case PKGPackageComponentTypeReference:
			[tDescription appendString:@"Reference"];
			break;
	}
	
	[tDescription appendString:@"\n\n"];
	
	[tDescription appendString:[self.packageSettings description]];
	[tDescription appendString:@"\n"];
	
	if (self.payload!=nil)
	{
		[tDescription appendString:[self.payload description]];
		[tDescription appendString:@"\n"];
	}
	
	if (self.scriptsAndResources!=nil)
	{
		[tDescription appendString:[self.scriptsAndResources description]];
		[tDescription appendString:@"\n"];
	}
	
	return tDescription;
}

@end
