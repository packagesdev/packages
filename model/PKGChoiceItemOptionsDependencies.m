/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGChoiceItemOptionsDependencies.h"

#import "PKGPackagesError.h"

NSString * const PKGChoiceItemOptionsEnabledStateDependencyTypeKey=@"ENABLED_MODE";

NSString * const PKGChoiceItemOptionsEnabledDependenciesTreeKey=@"ENABLED_DEPENDENCY";

NSString * const PKGChoiceItemOptionsSelectedDependenciesTreeKey=@"SELECTED_DEPENDENCY";


@implementation PKGChoiceItemOptionsDependencies

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_enabledStateDependencyType=PKGEnabledStateDependencyTypeAlways;
		
		_enabledStateDependenciesTree=nil;
		_selectedStateDependenciesTree=nil;
	}
	
	return self;
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
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
		_enabledStateDependencyType=[inRepresentation[PKGChoiceItemOptionsEnabledStateDependencyTypeKey] unsignedIntegerValue];
		
		if (_enabledStateDependencyType>PKGEnabledStateDependencyTypeDependent)
		{
			if (outError!=NULL)
			{
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGChoiceItemOptionsEnabledStateDependencyTypeKey}];
			}
			
			return nil;
		}
		
		NSError * tError=nil;
		
		_enabledStateDependenciesTree=[[PKGChoiceDependencyTree alloc] initWithRepresentation:inRepresentation[PKGChoiceItemOptionsEnabledDependenciesTreeKey] error:&tError];
		
		if (_enabledStateDependenciesTree==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)	// can be nil
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGChoiceItemOptionsEnabledDependenciesTreeKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValueError
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		_selectedStateDependenciesTree=[[PKGChoiceDependencyTree alloc] initWithRepresentation:inRepresentation[PKGChoiceItemOptionsSelectedDependenciesTreeKey] error:&tError];
		
		if (_selectedStateDependenciesTree==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)	// can be nil
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGChoiceItemOptionsSelectedDependenciesTreeKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValueError
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
	
	tRepresentation[PKGChoiceItemOptionsEnabledStateDependencyTypeKey]=@(self.enabledStateDependencyType);
	
	if (self.enabledStateDependenciesTree!=nil)
		tRepresentation[PKGChoiceItemOptionsEnabledDependenciesTreeKey]=[self.enabledStateDependenciesTree representation];
	
	if (self.selectedStateDependenciesTree!=nil)
		tRepresentation[PKGChoiceItemOptionsSelectedDependenciesTreeKey]=[self.selectedStateDependenciesTree representation];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	// A COMPLETER
	
	return tDescription;
}

@end
