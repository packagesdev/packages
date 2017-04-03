/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationLocalizableStepSettings.h"

#import "PKGPackagesError.h"

#import "NSArray+WBExtensions.h"

#import "NSMutableDictionary+PKGLocalizedValues.h"


NSString * const PKGPresentationLocalizationsKey=@"LOCALIZATIONS";

@implementation PKGPresentationLocalizableStepSettings

+ (Class)valueClass
{
	return NSObject.class;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		NSArray * tArray=inRepresentation[PKGPresentationLocalizationsKey];
		
		PKGFullCheckArrayValueForKey(tArray,PKGPresentationLocalizationsKey);
		
		_localizations=[NSMutableDictionary PKG_dictionaryWithRepresentations:tArray ofLocalizationsOfValueOfClass:[[self class] valueClass] error:&tError];
		
		if (_localizations==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGPresentationLocalizationsKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
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
	
	tRepresentation[PKGPresentationLocalizationsKey]=[self.localizations PKG_representationsOfLocalizations];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[self.localizations enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguageKey,id bValue,__attribute__((unused))BOOL * bOutStop){
		
		[tDescription appendFormat:@"  %@: ",bLanguageKey];
		
		if ([bValue conformsToProtocol:@protocol(PKGObjectProtocol)]==YES)
			[tDescription appendFormat:@"%@",[bValue description]];
		else
			[tDescription appendFormat:@"%@",bValue];
	
	
		[tDescription appendString:@"\n"];
	}];
	
	return tDescription;
}

#pragma mark -

- (BOOL)isCustomized
{
	return (self.localizations.count>0);
}

@end
