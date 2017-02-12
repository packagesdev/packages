/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLocator.h"

#import "PKGPackagesError.h"

NSString * const PKGLocatorEnabledKey=@"STATE";

NSString * const PKGLocatorNameKey=@"NAME";

NSString * const PKGLocatorIdentifierKey=@"IDENTIFIER";

NSString * const PKGLocatorSettingsRepresentationKey=@"DICTIONARY";

@implementation PKGLocator

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_enabled=YES;
		
		_name=@"";
		
		_identifier=@"";
		
		_settingsRepresentation=nil;
	}
	
	return self;
}

- (id) initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
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
		_enabled=[inRepresentation[PKGLocatorEnabledKey] boolValue];
		
		NSString * tString=inRepresentation[PKGLocatorNameKey];
		
		PKGClassCheckStringValueForKey(tString,PKGLocatorNameKey);
		
		_name=[tString copy];
		
		if (_name==nil)
			_name=@"";
		
		
		tString=inRepresentation[PKGLocatorIdentifierKey];
		
		PKGFullCheckStringValueForKey(tString,PKGLocatorIdentifierKey);
		
		_identifier=[tString copy];
		
		
		_settingsRepresentation=inRepresentation[PKGLocatorSettingsRepresentationKey];
	}
	
	return self;
}

#pragma mark -

- (id)copyWithZone:(NSZone *)inZone
{
	PKGLocator * nLocator=[[[self class] allocWithZone:inZone] init];
	
	if (nLocator!=nil)
	{
		nLocator.enabled=self.enabled;
		nLocator.name=[self.name copy];
		nLocator.identifier=[self.identifier copy];
		nLocator.settingsRepresentation=[self.settingsRepresentation copy];	// A AMELIORER
	}
	
	return nLocator;
}

#pragma mark -

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGLocatorEnabledKey]=@(self.enabled);
	
	tRepresentation[PKGLocatorNameKey]=self.name;
	
	tRepresentation[PKGLocatorIdentifierKey]=self.identifier;
	
	tRepresentation[PKGLocatorSettingsRepresentationKey]=self.settingsRepresentation;
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"Enabled: %@\n",(self.enabled==YES)? @"Yes" : @"No"];
	
	[tDescription appendFormat:@"Name: %@\n",self.name];
	
	[tDescription appendFormat:@"Identifier: %@\n",self.identifier];
	
	[tDescription appendFormat:@"Settings Dictionary: %@\n",[self.settingsRepresentation description]];
	
	return tDescription;
}

@end
