/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirement.h"

#import "PKGPackagesError.h"

#import "NSMutableDictionary+PKGLocalizedValues.h"

NSString * const PKGRequirementEnabledKey=@"STATE";

NSString * const PKGRequirementNameKey=@"NAME";

NSString * const PKGRequirementIdentifierKey=@"IDENTIFIER";

NSString * const PKGRequirementTypeKey=@"IC_REQUIREMENT_CHECK_TYPE";

NSString * const PKGRequirementSettingsRepresentationKey=@"DICTIONARY";

NSString * const PKGRequirementOnFailureBehaviorKey=@"BEHAVIOR";

NSString * const PKGRequirementFailureMessagesKey=@"MESSAGE";


@interface PKGRequirement ()

	@property (readwrite)NSMutableDictionary * messages;

@end


@implementation PKGRequirement

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_enabled=YES;
		
		_name=@"";
		
		_identifier=@"";
		
		_type=PKGRequirementTypeUndefined;
		
		_behavior=PKGRequirementOnFailureBehaviorInstallationStop;
		
		_settingsRepresentation=[NSDictionary dictionary];
		
		_messages=[NSMutableDictionary dictionary];
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
		_enabled=[inRepresentation[PKGRequirementEnabledKey] boolValue];
		
		NSString * tString=inRepresentation[PKGRequirementNameKey];
		
		PKGClassCheckStringValueForKey(tString,PKGRequirementNameKey);
		
		_name=[tString copy];
		
		if (_name==nil)
			_name=@"";
		
		tString=inRepresentation[PKGRequirementIdentifierKey];
		
		PKGFullCheckStringValueForKey(tString,PKGRequirementIdentifierKey);
		
		_identifier=[tString copy];
		
		
		if (inRepresentation[PKGRequirementTypeKey]==nil)
		{
			_type=PKGRequirementTypeUndefined;
		}
		else
		{
			_type=[inRepresentation[PKGRequirementTypeKey] unsignedIntegerValue];
		
			if (_type>PKGRequirementTypeTarget)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValue
											  userInfo:@{PKGKeyPathErrorKey:PKGRequirementTypeKey}];
				
				return nil;
			}
		}
		
		_settingsRepresentation=inRepresentation[PKGRequirementSettingsRepresentationKey];
		
		if (_settingsRepresentation==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGRequirementSettingsRepresentationKey}];
				
			// A COMPLETER
			
			return nil;
		}
		
		_behavior=[inRepresentation[PKGRequirementOnFailureBehaviorKey] unsignedIntegerValue];
		
		if (_behavior>PKGRequirementOnFailureBehaviorInstallationStop)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGRequirementOnFailureBehaviorKey}];
			
			return nil;
		}
		
		NSArray * tArray=inRepresentation[PKGRequirementFailureMessagesKey];
		
		if (tArray==nil)
		{
			_messages=[NSMutableDictionary dictionary];
		}
		else
		{
			if ([tArray isKindOfClass:[NSArray class]]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
				
				return nil;
			}
			
			NSError * tError=nil;
			
			_messages=[NSMutableDictionary PKG_dictionaryWithRepresentations:tArray ofLocalizationsOfValueOfClass:[NSString class] error:&tError];
			
			if (_messages==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValue;
					
					NSString * tPathError=PKGRequirementFailureMessagesKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
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
	
	tRepresentation[PKGRequirementEnabledKey]=@(self.enabled);
	
	tRepresentation[PKGRequirementNameKey]=self.name;
	
	tRepresentation[PKGRequirementIdentifierKey]=self.identifier;
	
	tRepresentation[PKGRequirementTypeKey]=@(self.type);
	
	tRepresentation[PKGRequirementSettingsRepresentationKey]=self.settingsRepresentation;
	
	tRepresentation[PKGRequirementOnFailureBehaviorKey]=@(self.behavior);
	
	tRepresentation[PKGRequirementFailureMessagesKey]=[self.messages PKG_representationsOfLocalizations];
	
	return tRepresentation;
}

#pragma mark -

- (NSComparisonResult)compareBehavior:(PKGRequirement *)inOtherRequirement
{
	PKGRequirementOnFailureBehavior tOtherBehavior=inOtherRequirement.behavior;
	
	if (self.behavior<tOtherBehavior)
		return NSOrderedDescending;
	
	if (self.behavior>tOtherBehavior)
		return NSOrderedAscending;
	
	return NSOrderedSame;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	// A COMPLETER
	
	return tDescription;
}

@end
