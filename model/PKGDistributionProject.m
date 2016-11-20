/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProject.h"

#import "PKGPackagesError.h"
#import "NSArray+WBExtensions.h"

NSString * const PKGDistributionProjectProjectSettingsKey=@"PROJECT_SETTINGS";

NSString * const PKGDistributionProjectPresentationSettingsKey=@"PROJECT_PRESENTATION";

NSString * const PKGDistributionProjectRequirementsAndResourcesKey=@"PROJECT_REQUIREMENTS";

NSString * const PKGDistributionProjectPackagesComponentsKey=@"PACKAGES";

NSString * const PKGDistributionProjectSharedProjectDataKey=@"SHARED_GLOBAL_DATA";


@interface PKGDistributionProject ()

	@property (readwrite) NSMutableArray * packageComponents;

@end

@implementation PKGDistributionProject

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	__block NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		NSDictionary * tProjectDictionary=inRepresentation[PKGProjectKey];
		
		if (tProjectDictionary==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGProjectKey}];
			
			return nil;
		}
		
		self.settings=[[PKGDistributionProjectSettings alloc] initWithRepresentation:tProjectDictionary[PKGDistributionProjectProjectSettingsKey] error:&tError];
		
		if (self.settings==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGDistributionProjectProjectSettingsKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
			
		_presentationSettings=[[PKGDistributionProjectPresentationSettings alloc] initWithRepresentation:tProjectDictionary[PKGDistributionProjectPresentationSettingsKey] error:&tError];
		
		if (_presentationSettings==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGDistributionProjectPresentationSettingsKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
			
		_requirementsAndResources=[[PKGDistributionProjectRequirementsAndResources alloc] initWithRepresentation:tProjectDictionary[PKGDistributionProjectRequirementsAndResourcesKey] error:&tError];
		
		if (_requirementsAndResources==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGDistributionProjectRequirementsAndResourcesKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
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
		
		if (inRepresentation[PKGDistributionProjectPackagesComponentsKey]==nil)
		{
			_packageComponents=[NSMutableArray array];
		}
		else
		{
			if ([inRepresentation[PKGDistributionProjectPackagesComponentsKey] isKindOfClass:NSArray.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGDistributionProjectPackagesComponentsKey}];
				
				return nil;
			}
			
			_packageComponents=[[inRepresentation[PKGDistributionProjectPackagesComponentsKey] WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bPackageComponentRepresentation,__attribute__((unused))NSUInteger bIndex){
				return [[PKGPackageComponent alloc] initWithRepresentation:bPackageComponentRepresentation error:&tError];
			}] mutableCopy];
			
			if (_packageComponents==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValue;
					
					NSString * tPathError=PKGDistributionProjectPackagesComponentsKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		if (inRepresentation[PKGDistributionProjectSharedProjectDataKey]==nil)
		{
			_sharedProjectData=[NSMutableDictionary dictionary];
		}
		else
		{
			if ([inRepresentation[PKGDistributionProjectSharedProjectDataKey] isKindOfClass:NSDictionary.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGDistributionProjectSharedProjectDataKey}];
				
				return nil;
			}
			
			_sharedProjectData=[inRepresentation[PKGDistributionProjectSharedProjectDataKey] mutableCopy];
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
	
	if (tRepresentation!=nil)
	{
		tRepresentation[PKGProjectKey][PKGDistributionProjectProjectSettingsKey]=[self.settings representation];
		
		if (self.presentationSettings!=nil)
			tRepresentation[PKGProjectKey][PKGDistributionProjectPresentationSettingsKey]=[self.presentationSettings representation];
		
		if (self.requirementsAndResources!=nil)
			tRepresentation[PKGProjectKey][PKGDistributionProjectRequirementsAndResourcesKey]=[self.requirementsAndResources representation];
		
		if (self.comments!=nil)
			tRepresentation[PKGProjectKey][PKGProjectCommentsKey]=[self.comments representation];
		
		tRepresentation[PKGDistributionProjectPackagesComponentsKey]=[self.packageComponents WB_arrayByMappingObjectsUsingBlock:^id(PKGPackageComponent * bPackageComponent,__attribute__((unused))NSUInteger bIndex){
			return [bPackageComponent representation];
		}];
		
		if ([self.sharedProjectData count]>0)
			tRepresentation[PKGDistributionProjectSharedProjectDataKey]=[self.sharedProjectData copy];
	}
	
	return tRepresentation;
}

#pragma mark -

- (PKGProjectType)type
{
	return PKGProjectTypeDistribution;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString stringWithString:[super description]];
	
	[tDescription appendString:@"\n"];
	
	[tDescription appendString:[self.settings description]];
	[tDescription appendString:@"\n"];
	
	[tDescription appendString:[self.presentationSettings description]];
	[tDescription appendString:@"\n"];
	
	if (self.requirementsAndResources!=nil)
	{
		[tDescription appendString:[self.requirementsAndResources description]];
		[tDescription appendString:@"\n"];
	}
	
	if (self.comments!=nil)
	{
		[tDescription appendString:[self.comments description]];
		[tDescription appendString:@"\n"];
	}
	
	[tDescription appendString:@"Package Components:\n"];
	[tDescription appendString:@"-------------------\n\n"];
	
	for(PKGPackageComponent * tPackageComponent in self.packageComponents)
	{
		[tDescription appendString:[tPackageComponent description]];
		
		[tDescription appendString:@"\n"];
	}
	
	return tDescription;
}

#pragma mark -

- (BOOL)isFlat
{
	PKGDistributionProjectSettings * tDistributionProjectSettings=(PKGDistributionProjectSettings *)self.settings;
	
	if (tDistributionProjectSettings==nil)
		return NO;
	
	return (tDistributionProjectSettings.buildFormat==PKGProjectBuildFormatFlat);
}

- (PKGPackageComponent *)packageComponentWithUUID:(NSString *)inUUID
{
	if (inUUID==nil)
		return nil;
	
	for(PKGPackageComponent * tPackageComponent in self.packageComponents)
	{
		if ([tPackageComponent.UUID isEqualToString:inUUID]==YES)
			return tPackageComponent;
	}
	
	return nil;
}

- (PKGPackageComponent *)packageComponentWithIdentifier:(NSString *)inIdentifier
{
	if (inIdentifier==nil)
		return nil;
	
	for(PKGPackageComponent * tPackageComponent in self.packageComponents)
	{
		PKGPackageSettings * tPackageSettings=tPackageComponent.packageSettings;
		
		if ([tPackageSettings.identifier isEqualToString:inIdentifier]==YES)
			return tPackageComponent;
	}
	
	return nil;
}

@end
