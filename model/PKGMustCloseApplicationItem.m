/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGMustCloseApplicationItem.h"

NSString * const PKGMustCloseApplicationItemEnabledKey=@"STATE";

NSString * const PKGMustCloseApplicationItemApplicationIDKey=@"APPLICATION_ID";

@implementation PKGMustCloseApplicationItem

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_enabled=YES;
		
		_applicationID=@"";
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
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		_enabled=[inRepresentation[PKGMustCloseApplicationItemEnabledKey] boolValue];
		
		NSString * tString=inRepresentation[PKGMustCloseApplicationItemApplicationIDKey];
		
		PKGFullCheckStringValueForKey(tString,PKGMustCloseApplicationItemApplicationIDKey);
		
		_applicationID=[tString copy];
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGMustCloseApplicationItemEnabledKey]=@(self.isEnabled);
	
	tRepresentation[PKGMustCloseApplicationItemApplicationIDKey]=self.applicationID;
	
	return tRepresentation;
}

#pragma mark -

- (BOOL)isEqual:(PKGMustCloseApplicationItem *)inOtherMustCloseApplicationItem
{
	if ([inOtherMustCloseApplicationItem isKindOfClass:PKGMustCloseApplicationItem.class]==NO)
		return NO;
	
	return ([self.applicationID isEqualToString:inOtherMustCloseApplicationItem.applicationID]==YES && self.isEnabled==inOtherMustCloseApplicationItem.isEnabled);
}

 - (NSUInteger)hash
{
	return (self.isEnabled<<16 + self.applicationID.length);
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"    Enabled: %@\n",(self.enabled==YES)? @"Yes" : @"No"];
	
	[tDescription appendFormat:@"    Application ID: %@\n",self.applicationID];
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGMustCloseApplicationItem * nMustCloseApplicationItem=[[[self class] allocWithZone:inZone] init];
	
	if (nMustCloseApplicationItem!=nil)
	{
		nMustCloseApplicationItem.enabled=self.isEnabled;
		nMustCloseApplicationItem.applicationID=[self.applicationID copyWithZone:inZone];
	}
	
	return nMustCloseApplicationItem;
}

@end
