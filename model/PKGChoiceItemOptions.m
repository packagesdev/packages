/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGChoiceItemOptions.h"

#import "PKGPackagesError.h"

NSString * const PKGChoiceItemOptionStateKey=@"STATE";

NSString * const PKGChoiceItemOptionStateDependenciesKey=@"DEPENDENCY";

NSString * const PKGChoiceItemOptionHiddenKey=@"HIDDEN";

NSString * const PKGChoiceItemOptionHideChildrenKey=@"HIDE_CHILDREN";


@implementation PKGChoiceItemOptions

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
		_state=[inRepresentation[PKGChoiceItemOptionStateKey] unsignedIntegerValue];
		
		if (_state==PKGDependentChoiceState || _state==PKGDependentChoiceGroupState)
		{
			NSError * tError=nil;
			
			_stateDependencies=[[PKGChoiceItemOptionsDependencies alloc] initWithRepresentation:inRepresentation[PKGChoiceItemOptionStateDependenciesKey] error:&tError];
		
			if (_stateDependencies==nil)
			{
				if (*outError!=nil)
					*outError=tError;
				
				return nil;
			}
		}
		
		_hidden=[inRepresentation[PKGChoiceItemOptionHiddenKey] boolValue];
		
		_hideChildren=[inRepresentation[PKGChoiceItemOptionHideChildrenKey] boolValue];
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGChoiceItemOptionStateKey]=@(self.state);
	
	if (self.state==PKGDependentChoiceState || self.state==PKGDependentChoiceGroupState)
		tRepresentation[PKGChoiceItemOptionStateDependenciesKey]=[self.stateDependencies representation];
	
	tRepresentation[PKGChoiceItemOptionHiddenKey]=@(self.hidden);
	
	if (self.hideChildren==YES)
		tRepresentation[PKGChoiceItemOptionHideChildrenKey]=@(self.hideChildren);
	
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
