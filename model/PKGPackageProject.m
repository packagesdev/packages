/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageProject.h"

#import "PKGPackagesError.h"

extern NSString * const PKGProjectKey;
extern NSString * const PKGProjectCommentsKey;

NSString * const PKGPackageProjectSettingsKey=@"PROJECT_SETTINGS";
NSString * const PKGPackageProjectPackageSettingsKey=@"PACKAGE_SETTINGS";
NSString * const PKGPackageProjectPackagePayloadsKey=@"PACKAGE_FILES";
NSString * const PKGPackageProjectPackageScriptsAndResources=@"PACKAGE_SCRIPTS";

@interface PKGPackageProject ()

@end

@implementation PKGPackageProject

@synthesize packageSettings=_packageSettings,payload=_payload,scriptsAndResources=_scriptsAndResources;

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
		self.settings=[[PKGPackageProjectSettings alloc] init];
		
		_packageSettings=[[PKGPackageSettings alloc] init];
		
		_payload=[[PKGPackagePayload alloc] init];
		
		_scriptsAndResources=[[PKGPackageScriptsAndResources alloc] init];
		
		self.comments=[[PKGProjectComments alloc] init];
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		NSDictionary * tProjectDictionary=inRepresentation[PKGProjectKey];
		
		self.settings=[[PKGPackageProjectSettings alloc] initWithRepresentation:tProjectDictionary[PKGPackageProjectSettingsKey] error:&tError];
		
		if (self.settings==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGPackageProjectSettingsKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		_packageSettings=[[PKGPackageSettings alloc] initWithRepresentation:tProjectDictionary[PKGPackageProjectPackageSettingsKey] error:&tError];
		
		if (_packageSettings==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGPackageProjectPackageSettingsKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		// Can be nil
		
		_payload=[[PKGPackagePayload alloc] initWithRepresentation:tProjectDictionary[PKGPackageProjectPackagePayloadsKey] error:&tError];
		
		if (_payload==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPackageProjectPackagePayloadsKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		// Can be nil
		
		_scriptsAndResources=[[PKGPackageScriptsAndResources alloc] initWithRepresentation:tProjectDictionary[PKGPackageProjectPackageScriptsAndResources] error:&tError];
		
		if (_scriptsAndResources==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPackageProjectPackageScriptsAndResources;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		// Can be nil
		
		self.comments=[[PKGProjectComments alloc] initWithRepresentation:tProjectDictionary[PKGProjectCommentsKey] error:&tError];
		
		if (self.comments==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGProjectCommentsKey;
					
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
	else
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tMutableDictionary=[super representation];
	
	if (tMutableDictionary!=nil)
	{
		tMutableDictionary[PKGProjectKey][PKGPackageProjectSettingsKey]=[self.settings representation];
		
		tMutableDictionary[PKGProjectKey][PKGPackageProjectPackageSettingsKey]=[self.packageSettings representation];
		
		if (self.payload!=nil)
			tMutableDictionary[PKGProjectKey][PKGPackageProjectPackagePayloadsKey]=[self.payload representation];
		
		if (self.scriptsAndResources!=nil)
			tMutableDictionary[PKGProjectKey][PKGPackageProjectPackageScriptsAndResources]=[self.scriptsAndResources representation];
		
		if (self.comments!=nil)
			tMutableDictionary[PKGProjectKey][PKGProjectCommentsKey]=[self.comments representation];
	}
	
	return tMutableDictionary;
}

#pragma mark -

- (PKGProjectType)type
{
	return PKGProjectTypePackage;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString stringWithString:[super description]];
	
	[tDescription appendString:@"\n"];
	
	[tDescription appendString:[self.settings description]];
	[tDescription appendString:@"\n"];
	
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
	
	if (self.comments!=nil)
	{
		[tDescription appendString:[self.comments description]];
		[tDescription appendString:@"\n"];
	}
	
	return tDescription;
}

@end
