/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementFailureMessage.h"

#import "PKGPackagesError.h"

NSString * const PKGRequirementFailureMessageValueKey=@"VALUE";

NSString * const PKGRequirementFailureMessageSecondaryValueKey=@"SECONDARY_VALUE";

@implementation PKGRequirementFailureMessage

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_messageTitle=@"";
		
		_messageDescription=nil;
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
		NSString * tString=inRepresentation[PKGRequirementFailureMessageValueKey];
		
		PKGFullCheckStringValueForKey(tString,PKGRequirementFailureMessageValueKey);
		
		_messageTitle=[tString copy];
		
		tString=inRepresentation[PKGRequirementFailureMessageSecondaryValueKey];
		
		if (tString!=nil)
		{
			if ([tString isKindOfClass:NSString.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGRequirementFailureMessageSecondaryValueKey}];
				
				return nil;
			}
			
			_messageDescription=[tString copy];
		}
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGRequirementFailureMessageValueKey]=self.messageTitle;
	
	if (self.messageDescription!=nil)
		tRepresentation[PKGRequirementFailureMessageSecondaryValueKey]=self.messageDescription;
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"Title: %@\n",self.messageTitle];
	
	if (self.messageDescription!=nil)
		[tDescription appendFormat:@"Description: %@\n",self.messageDescription];
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGRequirementFailureMessage * nRequirementFailureMessage=[[[self class] allocWithZone:inZone] init];
	
	if (nRequirementFailureMessage!=nil)
	{
		nRequirementFailureMessage.messageTitle=[self.messageTitle copyWithZone:inZone];
		
		nRequirementFailureMessage.messageDescription=[self.messageDescription copyWithZone:inZone];
	}
	
	return nRequirementFailureMessage;
}

@end
