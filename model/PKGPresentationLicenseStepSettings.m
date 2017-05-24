/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationLicenseStepSettings.h"

#import "PKGPackagesError.h"

#import "PKGFilePath.h"

NSString * const PKGPresentationLicenseTypeKey=@"MODE";

NSString * const PKGPresentationLicenseTemplateNameKey=@"TEMPLATE";

NSString * const PKGPresentationLicenseTemplateKeywordsKey=@"KEYWORDS";

@interface PKGPresentationLicenseStepSettings ()

	@property (readwrite) NSMutableDictionary * templateValues;

@end

@implementation PKGPresentationLicenseStepSettings

+ (Class)valueClass
{
	return PKGFilePath.class;
}

- (BOOL)isValueSet:(PKGFilePath *)inValue
{
	return inValue.isSet;
}

#pragma mark -

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_licenseType=PKGLicenseTypeCustom;
		
		_templateValues=[NSMutableDictionary dictionary];
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self==nil)
	{
		if (outError!=NULL)
			*outError=tError;
		
		return nil;
	}
	
	_licenseType=[inRepresentation[PKGPresentationLicenseTypeKey] unsignedIntegerValue];
	
	if (_licenseType>PKGLicenseTypeTemplate)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGRepresentationInvalidValue
									  userInfo:@{PKGKeyPathErrorKey:PKGPresentationLicenseTypeKey}];
		
		return nil;
	}
	
	_templateValues=[NSMutableDictionary dictionary];
	
	if (_licenseType==PKGLicenseTypeTemplate)
	{
		NSString * tString=inRepresentation[PKGPresentationLicenseTemplateNameKey];
		
		PKGFullCheckStringValueForKey(tString,PKGPresentationLicenseTemplateNameKey);
		
		_templateName=[tString copy];
		

		if (inRepresentation[PKGPresentationLicenseTemplateKeywordsKey]!=nil)
		{
			if ([inRepresentation[PKGPresentationLicenseTemplateKeywordsKey] isKindOfClass:NSDictionary.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationLicenseTemplateKeywordsKey}];
				
				return nil;
			}
			
			_templateValues=[inRepresentation[PKGPresentationLicenseTemplateKeywordsKey] mutableCopy];
		}
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[super representation];
	
	tRepresentation[PKGPresentationLicenseTypeKey]=@(self.licenseType);
	
	if (self.licenseType==PKGLicenseTypeTemplate)
	{
		tRepresentation[PKGPresentationLicenseTemplateNameKey]=self.templateName;
		
		if (self.templateValues.count>0)
			tRepresentation[PKGPresentationLicenseTemplateKeywordsKey]=self.templateValues;
	}
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"  License Settings:\n"];
	[tDescription appendString:@"  ----------------\n\n"];
	
	if (self.licenseType==PKGLicenseTypeCustom)
	{
		[tDescription appendFormat:@"%@",[super description]];
	}
	else
	{
		[tDescription appendFormat:@"  Template: %@\n",self.templateName];
		
	}
	
	return tDescription;
}

#pragma mark -

- (BOOL)isCustomized
{
	if (self.licenseType==PKGLicenseTypeTemplate)
		return YES;
	
	if (self.licenseType==PKGLicenseTypeCustom)
	{
		for(NSString * tLanguageKey in self.localizations)
		{
			PKGFilePath * tFilePath=self.localizations[tLanguageKey];
		
			if (tFilePath.isSet==YES)
				return YES;
		}
	}
	
	return NO;
}

@end
