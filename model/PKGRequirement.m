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

#import "NSCollection+DeepCopy.h"

#import "NSDictionary+WBExtensions.h"

NSString * const PKGRequirementEnabledKey=@"STATE";

NSString * const PKGRequirementNameKey=@"NAME";

NSString * const PKGRequirementIdentifierKey=@"IDENTIFIER";

NSString * const PKGRequirementTypeKey=@"IC_REQUIREMENT_CHECK_TYPE";

NSString * const PKGRequirementSettingsRepresentationKey=@"DICTIONARY";

NSString * const PKGRequirementOnFailureBehaviorKey=@"BEHAVIOR";

NSString * const PKGRequirementFailureMessagesKey=@"MESSAGE";

NSString * const PKGRequirementFailureMessageLanguageKey=@"LANGUAGE";


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
		
		_failureBehavior=PKGRequirementOnFailureBehaviorInstallationStop;
		
		_settingsRepresentation=nil;
		
		_messages=[NSMutableDictionary dictionary];
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
		_enabled=[inRepresentation[PKGRequirementEnabledKey] boolValue];
		
		NSString * tString=inRepresentation[PKGRequirementNameKey];
		
		PKGClassCheckStringValueForKey(tString,PKGRequirementNameKey);
		
		_name=[tString copy];
		
		if (_name==nil)
			_name=@"";
		
		tString=inRepresentation[PKGRequirementIdentifierKey];
		
		PKGFullCheckStringValueForKey(tString,PKGRequirementIdentifierKey);
		
		// Fix backward & forward compatibility snafu introduced in version 1.2
		
		if ([tString isEqualToString:@"fr.whitebox.Packages.requirement.script"]==YES)
			tString=@"fr.whitebox.Packages.requirement.scripts";
		
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
												  code:PKGRepresentationInvalidValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGRequirementTypeKey}];
				
				return nil;
			}
		}
		
		NSDictionary * tDictionary=inRepresentation[PKGRequirementSettingsRepresentationKey];
		
		PKGFullCheckDictionaryValueForKey(tDictionary,PKGRequirementSettingsRepresentationKey);
		
		_settingsRepresentation=tDictionary;
		
		
		
		_failureBehavior=[inRepresentation[PKGRequirementOnFailureBehaviorKey] unsignedIntegerValue];
		
		if (_failureBehavior>PKGRequirementOnFailureBehaviorInstallationStop)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGRequirementOnFailureBehaviorKey}];
			
			return nil;
		}
		
		__block NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
		
		NSArray * tArray=inRepresentation[PKGRequirementFailureMessagesKey];
		
		if (tArray!=nil)
		{
			if ([tArray isKindOfClass:NSArray.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGRequirementFailureMessagesKey}];
				
				return nil;
			}
			
			__block NSError * tError=nil;
			
			[tArray enumerateObjectsUsingBlock:^(NSDictionary * bLocalizationDictionary,__attribute__((unused))NSUInteger bIndex,BOOL * bOutStop){
			
				NSString * tLanguageName=bLocalizationDictionary[PKGRequirementFailureMessageLanguageKey];
				
				if (tLanguageName==nil)
				{
					tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											   code:PKGRepresentationInvalidValueError
										   userInfo:@{PKGKeyPathErrorKey:PKGRequirementFailureMessageLanguageKey}];
					
					tMutableDictionary=nil;
					*bOutStop=YES;
					
					return;
				}
				
				if ([tLanguageName isKindOfClass:NSString.class]==NO)
				{
					tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											   code:PKGRepresentationInvalidTypeOfValueError
										   userInfo:@{PKGKeyPathErrorKey:PKGRequirementFailureMessageLanguageKey}];
					
					tMutableDictionary=nil;
					*bOutStop=YES;
					
					return;
				}
				
				if ([tLanguageName length]==0)		// Language can not be empty
				{
					tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											   code:PKGRepresentationInvalidValueError
										   userInfo:@{PKGKeyPathErrorKey:PKGRequirementFailureMessageLanguageKey}];
					
					tMutableDictionary=nil;
					*bOutStop=YES;
					
					return;
				}
				
				PKGRequirementFailureMessage * tFailureMessage=[[PKGRequirementFailureMessage alloc] initWithRepresentation:bLocalizationDictionary error:&tError];
				
				if (tFailureMessage==nil)
				{
					tMutableDictionary=nil;
					*bOutStop=YES;
					
					return;
				}
				
				tMutableDictionary[tLanguageName]=tFailureMessage;
			}];
			
			if (tMutableDictionary==nil)
			{
				if (outError!=NULL)
					*outError=tError;
				
				return nil;
			}
		}
		
		_messages=tMutableDictionary;
	}
	
	return self;
}

#pragma mark -

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGRequirementEnabledKey]=@(self.enabled);
	
	tRepresentation[PKGRequirementNameKey]=self.name;
	
	tRepresentation[PKGRequirementIdentifierKey]=self.identifier;
	
	tRepresentation[PKGRequirementTypeKey]=@(self.type);
	
	if (self.settingsRepresentation!=nil)
		tRepresentation[PKGRequirementSettingsRepresentationKey]=self.settingsRepresentation;
	
	tRepresentation[PKGRequirementOnFailureBehaviorKey]=@(self.failureBehavior);
	
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[self.messages enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguage,PKGRequirementFailureMessage * bMessage,__attribute__((unused))BOOL * bOutStop){
	
		NSMutableDictionary * tLocalizationDictionary=[bMessage representation];
		
		tLocalizationDictionary[PKGRequirementFailureMessageLanguageKey]=bLanguage;
		
		[tMutableArray addObject:tLocalizationDictionary];
		
	}];
	
	tRepresentation[PKGRequirementFailureMessagesKey]=[tMutableArray copy];
	
	return tRepresentation;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGRequirement * nRequirement=[[[self class] allocWithZone:inZone] init];
	
	if (nRequirement!=nil)
	{
		nRequirement.enabled=self.enabled;
		nRequirement.name=[self.name copyWithZone:inZone];
		nRequirement.identifier=[self.identifier copyWithZone:inZone];
		nRequirement.type=self.type;
		nRequirement.failureBehavior=self.failureBehavior;
		nRequirement.messages=[self.messages WB_dictionaryByMappingObjectsUsingBlock:^id(id bKey, id<NSCopying> bObject) {
			return [bObject copyWithZone:inZone];
		}];
		
		nRequirement.settingsRepresentation=[self.settingsRepresentation deepCopy];
	}
	
	return nRequirement;
}

#pragma mark -

- (BOOL)isEqualToRequirement:(PKGRequirement *)inRequirement
{
	if (inRequirement==nil)
		return NO;
	
	if (inRequirement.settingsRepresentation==nil && self.settingsRepresentation!=nil)
		return NO;
	
	return (self.enabled==inRequirement.enabled &&
			[self.name isEqualToString:inRequirement.name]==YES &&
			[self.identifier isEqualToString:inRequirement.identifier]==YES &&
			self.type==inRequirement.type &&
			self.failureBehavior==inRequirement.failureBehavior &&
			[self.messages isEqualToDictionary:inRequirement.messages]==YES &&
			[self.settingsRepresentation isEqualToDictionary:inRequirement.settingsRepresentation]==YES);
}

- (NSComparisonResult)compareFailureBehavior:(PKGRequirement *)inOtherRequirement
{
	PKGRequirementOnFailureBehavior tOtherBehavior=inOtherRequirement.failureBehavior;
	
	if (self.failureBehavior<tOtherBehavior)
		return NSOrderedDescending;
	
	if (self.failureBehavior>tOtherBehavior)
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
