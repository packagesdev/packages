/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectRequirementsAndResources.h"

#import "PKGPackagesError.h"

#import "NSArray+WBMapping.h"

NSString * const PKGDistributionProjectRequirementsRootVolumeOnlyKey=@"ROOT_VOLUME_ONLY";

NSString * const PKGDistributionProjectRequirementsListKey=@"LIST";

NSString * const PKGDistributionProjectResourcesListKey=@"RESOURCES";

@interface PKGDistributionProjectRequirementsAndResources ()

@end

@implementation PKGDistributionProjectRequirementsAndResources

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_rootVolumeOnlyRequirement=NO;
		
		_requirements=[NSMutableArray array];
		
		_resourcesForest=[[PKGResourcesForest alloc] init];
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
	
	if ([inRepresentation isKindOfClass:[NSDictionary class]]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		_rootVolumeOnlyRequirement=[inRepresentation[PKGDistributionProjectRequirementsRootVolumeOnlyKey] boolValue];
		
		if (inRepresentation[PKGDistributionProjectRequirementsListKey]==nil)
		{
			_requirements=[NSMutableArray array];
		}
		else
		{
			if ([inRepresentation[PKGDistributionProjectRequirementsListKey] isKindOfClass:[NSArray class]]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
				
				return nil;
			}
			
			__block NSError * tError=nil;
			
			_requirements=[[inRepresentation[PKGDistributionProjectRequirementsListKey] WBmapObjectsUsingBlock:^id(NSDictionary * bRequirementRepresentation,NSUInteger bIndex){
			
				return [[PKGRequirement alloc] initWithRepresentation:bRequirementRepresentation error:&tError];
			}] mutableCopy];
			
			if (_requirements==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValue;
					
					NSString * tPathError=PKGDistributionProjectRequirementsListKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		NSError * tError=nil;
		
		_resourcesForest=[[PKGResourcesForest alloc] initWithArrayRepresentation:inRepresentation[PKGDistributionProjectResourcesListKey] error:&tError];
		
		if (_resourcesForest==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGDistributionProjectResourcesListKey;
				
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

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGDistributionProjectRequirementsRootVolumeOnlyKey]=@(self.rootVolumeOnlyRequirement);
	
	tRepresentation[PKGDistributionProjectRequirementsListKey]=[self.requirements WBmapObjectsUsingBlock:^id(PKGRequirement * bRequirement,NSUInteger bIndex){
	
		return [bRequirement representation];
	}];
	
	tRepresentation[PKGDistributionProjectResourcesListKey]=[self.resourcesForest arrayRepresentation];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"Requirements and Resources:\n"];
	[tDescription appendString:@"--------------------------\n\n"];
	
	[tDescription appendFormat:@"  Install on startup volume only: %@\n",(self.rootVolumeOnlyRequirement==YES) ? @"Yes" : @"No"];
	
	[tDescription appendFormat:@"  Requirements (%lu):\n",(unsigned long)[self.requirements count]];
	
	for(PKGRequirement * tRequirement in self.requirements)
		[tDescription appendString:[tRequirement description]];
	
	[tDescription appendString:@"\n"];
	
	return tDescription;
}

@end
