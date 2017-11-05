/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageComponent.h"

#import "PKGPackagesError.h"

#import "NSObject+Conformance.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGPackageComponentUUIDKey=@"UUID";

NSString * const PKGPackageComponentTypeKey=@"TYPE";

NSString * const PKGPackageComponentImportPathKey=@"PATH";


NSString * const PKGPackageComponentMustCloseApplicationsKey=@"MUST-CLOSE-APPLICATIONS";

NSString * const PKGPackageComponentMustCloseApplicationItemsKey=@"MUST-CLOSE-APPLICATION-ITEMS";


NSString * const PKGPackageComponentSettingsKey=@"PACKAGE_SETTINGS";

NSString * const PKGPackageComponentPayloadKey=@"PACKAGE_FILES";

NSString * const PKGPackageComponentScriptsAndResourcesKey=@"PACKAGE_SCRIPTS";


@interface PKGPackageComponent ()

	@property (readwrite) NSString * UUID;

	@property (readwrite) PKGPackageComponentType type;

	@property (readwrite) PKGFilePath * importPath;


	@property (readwrite) NSMutableArray * mustCloseApplicationItems;

@end


@implementation PKGPackageComponent

@synthesize packageSettings=_packageSettings,payload=_payload,scriptsAndResources=_scriptsAndResources;

+ (PKGPackageComponent *)projectComponent
{
	PKGPackageComponent * nProjectComponent=[PKGPackageComponent new];
	
	if (nProjectComponent!=nil)
	{
		nProjectComponent.UUID=[[NSUUID UUID] UUIDString];
		nProjectComponent.type=PKGPackageComponentTypeProject;
		nProjectComponent.importPath=nil;
		
		nProjectComponent.mustCloseApplications=NO;
		nProjectComponent.mustCloseApplicationItems=[NSMutableArray array];
		
		nProjectComponent.packageSettings=[PKGPackageSettings new];
	}
	
	return nProjectComponent;
}

+ (PKGPackageComponent *)referenceComponent
{
	PKGPackageComponent * nReferenceComponent=[PKGPackageComponent new];
	
	if (nReferenceComponent!=nil)
	{
		nReferenceComponent.UUID=[[NSUUID UUID] UUIDString];
		nReferenceComponent.type=PKGPackageComponentTypeReference;
		nReferenceComponent.importPath=nil;
		
		nReferenceComponent.mustCloseApplications=NO;
		nReferenceComponent.mustCloseApplicationItems=[NSMutableArray array];
		
		nReferenceComponent.packageSettings=[PKGPackageSettings new];
	}
	
	return nReferenceComponent;
}

+ (PKGPackageComponent *)importedComponentWithFilePath:(PKGFilePath *)inFilePath
{
	if (inFilePath==nil)
		return nil;
	
	PKGPackageComponent * nImportedComponent=[PKGPackageComponent new];
	
	if (nImportedComponent!=nil)
	{
		nImportedComponent.UUID=[[NSUUID UUID] UUIDString];
		nImportedComponent.type=PKGPackageComponentTypeImported;
		nImportedComponent.importPath=inFilePath;
		
		nImportedComponent.mustCloseApplications=NO;
		nImportedComponent.mustCloseApplicationItems=[NSMutableArray array];
		
		nImportedComponent.packageSettings=[PKGPackageSettings new];
	}
	
	return nImportedComponent;
}

- (instancetype)initWithProjectPackageObject:(id<PKGPackageObjectProtocol>)inPackageObject
{
	if (inPackageObject==nil)
		return nil;
	
	if ([((NSObject *)inPackageObject) WB_doesReallyConformToProtocol:@protocol(PKGPackageObjectProtocol)]==NO)
		return nil;
	
	if ([((NSObject *)inPackageObject) isKindOfClass:PKGPackageComponent.class]==YES && ((PKGPackageComponent *)inPackageObject).type!=PKGPackageComponentTypeProject)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_UUID=[[NSUUID UUID] UUIDString];
		_type=PKGPackageComponentTypeProject;
		_importPath=nil;
		
		_mustCloseApplications=NO;
		_mustCloseApplicationItems=[NSMutableArray array];
		
		_packageSettings=[inPackageObject.packageSettings copy];
		_payload=[inPackageObject.payload copy];
		_scriptsAndResources=[inPackageObject.scriptsAndResources copy];
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
		NSError * tError=nil;
		
		NSString * tString=inRepresentation[PKGPackageComponentUUIDKey];
		
		PKGFullCheckStringValueForKey(tString,PKGPackageComponentUUIDKey);
		
		_UUID=[tString copy];
		
		
		_type=[inRepresentation[PKGPackageComponentTypeKey] unsignedIntegerValue];
		
		if (_type>PKGPackageComponentTypeReference)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGPackageComponentTypeKey}];
			
			return nil;
		}
		
		
		if (inRepresentation[PKGPackageComponentImportPathKey]!=nil)
		{
			_importPath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGPackageComponentImportPathKey] error:&tError];
			
			if (_importPath==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValueError;
					
					NSString * tPathError=PKGPackageComponentImportPathKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		NSNumber * tNumber=inRepresentation[PKGPackageComponentMustCloseApplicationsKey];
		
		if (tNumber==nil)
		{
			_mustCloseApplications=NO;
		}
		else
		{
			PKGClassCheckNumberValueForKey(tNumber,PKGPackageComponentMustCloseApplicationsKey);
			
			_mustCloseApplications=[tNumber boolValue];
		}
		
		NSArray * tArray=inRepresentation[PKGPackageComponentMustCloseApplicationItemsKey];
		
		if (tArray==nil)
		{
			_mustCloseApplicationItems=[NSMutableArray array];
		}
		else
		{
			__block NSError * tMappingError=nil;
			
			PKGFullCheckArrayValueForKey(tArray,PKGPackageComponentMustCloseApplicationItemsKey);
			
			_mustCloseApplicationItems=[[tArray WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bMustCloseApplicationItemRepresentation,__attribute__((unused))NSUInteger bIndex){
				
				return [[PKGMustCloseApplicationItem alloc] initWithRepresentation:bMustCloseApplicationItemRepresentation error:&tMappingError];
				
			}] mutableCopy];
			
			if (_mustCloseApplicationItems==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tMappingError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValueError;
					
					NSString * tPathError=PKGPackageComponentMustCloseApplicationItemsKey;
					
					if (tMappingError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tMappingError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		
		_packageSettings=[[PKGPackageSettings alloc] initWithRepresentation:inRepresentation[PKGPackageComponentSettingsKey] error:&tError];
		
		if (_packageSettings==nil)	// A VOIR (cas d'un import)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValueError;
				
				NSString * tPathError=PKGPackageComponentSettingsKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
				
			return nil;
		}
		
		// can be nil
		
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
		
		// can be nil
		
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

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGPackageComponentUUIDKey]=self.UUID;
	
	tRepresentation[PKGPackageComponentTypeKey]=@(self.type);
	
	if (self.importPath!=nil)
		tRepresentation[PKGPackageComponentImportPathKey]=[self.importPath representation];
	
	
	tRepresentation[PKGPackageComponentMustCloseApplicationsKey]=@(self.mustCloseApplications);
	
	if (self.mustCloseApplicationItems!=nil)
	{
		tRepresentation[PKGPackageComponentMustCloseApplicationItemsKey]=[self.mustCloseApplicationItems WB_arrayByMappingObjectsUsingBlock:^id(PKGMustCloseApplicationItem * bMustCloseApplicationItem,__attribute__((unused))NSUInteger bIndex){
		
			return [bMustCloseApplicationItem representation];
		
		}];
	}
	
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
	
	[tDescription appendFormat:@"                              UUID: %@\n",self.UUID];
	
	[tDescription appendString:@"                              Type: "];

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
	
	[tDescription appendFormat:@"           Must close Applications: %@",(self.mustCloseApplications==YES) ? @"Yes" : @"No"];
	
	[tDescription appendFormat:@"  Must close ApplicationItems(%lu):\n\n",(unsigned long)self.mustCloseApplicationItems.count];
	
	for(PKGMustCloseApplicationItem * tMustCloseApplicationItem in self.mustCloseApplicationItems)
	{
		[tDescription appendString:[tMustCloseApplicationItem description]];
		
		[tDescription appendString:@"\n"];
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

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGPackageComponent * nPackageComponent=[[[self class] allocWithZone:inZone] init];
	
	if (nPackageComponent!=nil)
	{
		nPackageComponent.UUID=[[NSUUID UUID] UUIDString];
		
		nPackageComponent.type=self.type;
		
		nPackageComponent.importPath=[self.importPath copyWithZone:inZone];
		
		nPackageComponent.packageSettings=[self.packageSettings copyWithZone:inZone];
		
		nPackageComponent.payload=[self.payload copyWithZone:inZone];
		
		nPackageComponent.scriptsAndResources=[self.scriptsAndResources copyWithZone:inZone];
	}
	
	return nPackageComponent;
}

@end
