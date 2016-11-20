/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageScriptsAndResources.h"

#import "PKGPackagesError.h"

NSString * const PKGPackageScriptsAndResourcesPreInstallationScriptKey=@"PREINSTALL_PATH";

NSString * const PKGPackageScriptsAndResourcesPostInstallationScriptKey=@"POSTINSTALL_PATH";

NSString * const PKGPackageScriptsAndResourcesResourcesHierarchyKey=@"RESOURCES";

@interface PKGPackageScriptsAndResources ()

@end

@implementation PKGPackageScriptsAndResources

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_preInstallationScriptPath=[[PKGFilePath alloc] init];
		
		_postInstallationScriptPath=[[PKGFilePath alloc] init];
		
		_resourcesForest=[[PKGResourcesForest alloc] init];
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
		NSError * tError=nil;
		
		_preInstallationScriptPath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGPackageScriptsAndResourcesPreInstallationScriptKey] error:&tError];
		
		if (_preInstallationScriptPath==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPackageScriptsAndResourcesPreInstallationScriptKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValue
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		_postInstallationScriptPath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGPackageScriptsAndResourcesPostInstallationScriptKey] error:&tError];
		
		if (_postInstallationScriptPath==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPackageScriptsAndResourcesPostInstallationScriptKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValue
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		_resourcesForest=[[PKGResourcesForest alloc] initWithArrayRepresentation:inRepresentation[PKGPackageScriptsAndResourcesResourcesHierarchyKey] error:&tError];
		
		if (_resourcesForest==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGPackageScriptsAndResourcesResourcesHierarchyKey;
				
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
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	if (self.preInstallationScriptPath!=nil)
		tRepresentation[PKGPackageScriptsAndResourcesPreInstallationScriptKey]=[self.preInstallationScriptPath representation];
	
	if (self.postInstallationScriptPath!=nil)
		tRepresentation[PKGPackageScriptsAndResourcesPostInstallationScriptKey]=[self.postInstallationScriptPath representation];
	
	tRepresentation[PKGPackageScriptsAndResourcesResourcesHierarchyKey]=[self.resourcesForest arrayRepresentation];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *) description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"  Scripts and Resources:\n"];
	[tDescription appendString:@"  ---------------------\n\n"];
	
	[tDescription appendFormat:@"  Pre-installation Script Path: %@",[self.preInstallationScriptPath description]];
	
	[tDescription appendFormat:@"  Post-installation Script Path: %@",[self.postInstallationScriptPath description]];
	
	[tDescription appendString:@"  Additional Resources:\n\n"];
	
	[tDescription appendFormat:@"%@",[self.resourcesForest description]];
	
	return tDescription;
}

@end
