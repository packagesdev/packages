/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationInstallationTypeStepSettings.h"

#import "PKGPackagesError.h"

NSString * const PKGPresentationInstallationTypeModeKey=@"MODE";

NSString * const PKGPresentationInstallationTypeInstallerHierarchyKey=@"INSTALLER";

NSString * const PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey=@"SOFTWAREUPDATE";

NSString * const PKGPresentationInstallationTypeInvisibleHierarchyKey=@"INVISIBLE";

NSString * const PKGPresentationInstallationTypeHierarchiesKey=@"HIERARCHIES";

@interface PKGPresentationInstallationTypeStepSettings ()
{
	NSDictionary * _cachedHierarchiesRepresentation;
}

	@property (nonatomic,readwrite) NSMutableDictionary * hierarchies;

@end

@implementation PKGPresentationInstallationTypeStepSettings

- (instancetype)initWithPackagesComponents:(NSArray *)inPackagesComponents
{
	if (inPackagesComponents==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_mode=PKGPresentationInstallationTypeStandardOrCustomInstall;
		
		_hierarchies=[NSMutableDictionary dictionary];
		
		PKGInstallationHierarchy * tInstallationHierarchy=[[PKGInstallationHierarchy alloc] initWithPackagesComponents:inPackagesComponents];
		
		if (tInstallationHierarchy==nil)
			return nil;
		
		_hierarchies[PKGPresentationInstallationTypeInstallerHierarchyKey]=tInstallationHierarchy;
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		if (inRepresentation[PKGPresentationInstallationTypeModeKey]!=nil)
		{
			_mode=[inRepresentation[PKGPresentationInstallationTypeModeKey] unsignedIntegerValue];
			
			if (_mode>PKGPresentationInstallationTypeCustomInstallOnly)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidValue userInfo:nil];

				return nil;
			}
		}
		else
		{
			_mode=PKGPresentationInstallationTypeStandardOrCustomInstall;
		}
		
		_cachedHierarchiesRepresentation=inRepresentation[PKGPresentationInstallationTypeHierarchiesKey];
		
		if (_cachedHierarchiesRepresentation==nil)
			_cachedHierarchiesRepresentation=[NSMutableDictionary dictionary];
		
		for(NSString * tHierarchyKey in _cachedHierarchiesRepresentation)
		{
			if ([tHierarchyKey isEqualToString:PKGPresentationInstallationTypeInstallerHierarchyKey]==NO &&
				[tHierarchyKey isEqualToString:PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey]==NO &
				[tHierarchyKey isEqualToString:PKGPresentationInstallationTypeInvisibleHierarchyKey]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValue
											  userInfo:@{PKGKeyPathErrorKey:[PKGPresentationInstallationTypeHierarchiesKey stringByAppendingPathComponent:tHierarchyKey]}];
				
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
	NSMutableDictionary * tRepresentation=[super representation];
	
	tRepresentation[PKGPresentationInstallationTypeModeKey]=@(self.mode);
	
	if (_cachedHierarchiesRepresentation!=nil)
	{
		tRepresentation[PKGPresentationInstallationTypeHierarchiesKey]=_cachedHierarchiesRepresentation;
	}
	else
	{
		NSMutableDictionary * tHierarchiesRepresentation=[NSMutableDictionary dictionary];
		
		[_hierarchies enumerateKeysAndObjectsUsingBlock:^(NSString * bHierarchyIdentifier,PKGInstallationHierarchy * bHierarchy,BOOL * bOutStop){
		
			NSDictionary * tHierarchyRepresentation=[bHierarchy representation];
			
			if (tHierarchyRepresentation!=nil)
				tHierarchiesRepresentation[bHierarchyIdentifier]=tHierarchyRepresentation;
		}];
		
		tRepresentation[PKGPresentationInstallationTypeHierarchiesKey]=tHierarchiesRepresentation;
	}
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"  Installation Type Settings:\n"];
	[tDescription appendString:@"  --------------------------\n\n"];
	
	switch(self.mode)
	{
		case PKGPresentationInstallationTypeStandardOrCustomInstall:
			
			[tDescription appendString:@"  Type: Standard or Custom\n"];
			break;
			
		case PKGPresentationInstallationTypeStandardInstallOnly:
			
			[tDescription appendString:@"  Type: Standard\n"];
			break;
			
		case PKGPresentationInstallationTypeCustomInstallOnly:
			
			[tDescription appendString:@"  Type: Custom\n"];
			break;
	}
	
	[tDescription appendString:@"\n"];
	
	[self.hierarchies enumerateKeysAndObjectsUsingBlock:^(NSString * bHierarchyIdentifier,PKGInstallationHierarchy * bHierarchy,BOOL * bOutStop){
	
		[tDescription appendFormat:@"  \"%@\" Choices Hierarchy:\n\n",bHierarchyIdentifier];
		
		[tDescription appendFormat:@"%@\n\n",[bHierarchy description]];
	
	}];
	
	return tDescription;
}

#pragma mark -

- (NSMutableDictionary *)hierarchies
{
	if (_cachedHierarchiesRepresentation!=nil)
	{
		_hierarchies=[NSMutableDictionary dictionary];
		
		__block NSError * tError=nil;
		
		[_cachedHierarchiesRepresentation enumerateKeysAndObjectsUsingBlock:^(NSString * bHierarchyIdentifier,NSDictionary * bHierarchyRepresentation,BOOL * bOutStop){
			
			PKGInstallationHierarchy * tHierarchy=[[PKGInstallationHierarchy alloc] initWithRepresentation:bHierarchyRepresentation error:&tError];
			
			if (tHierarchy==nil)
			{
				*bOutStop=YES;
				return;
			}
			
			_hierarchies[bHierarchyIdentifier]=tHierarchy;
		}];
		
		_cachedHierarchiesRepresentation=nil;
	}
	
	return _hierarchies;
}

- (PKGInstallationHierarchy *)installerHierarchy
{
	return self.hierarchies[PKGPresentationInstallationTypeInstallerHierarchyKey];
}

#pragma mark -

- (NSSet *)allPackagesUUIDs
{
	NSMutableSet * tMutableSet=[NSMutableSet set];
	
	[self.hierarchies enumerateKeysAndObjectsUsingBlock:^(NSString * bHierarchyIdentifier,PKGInstallationHierarchy * bHierarchy,BOOL * bOutStop){
	
		NSSet * tSet=[bHierarchy allPackagesUUIDs];
		
		if(tSet!=nil)
			[tMutableSet unionSet:tSet];
	}];
	
	return [tMutableSet copy];
}

@end
