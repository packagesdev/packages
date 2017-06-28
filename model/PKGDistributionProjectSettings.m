/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectSettings.h"

#import "PKGPackagesError.h"

#import "NSDictionary+MutableDeepCopy.h"

NSString * const PKGDistributionProjectBuildFormatKey=@"BUILD_FORMAT";

NSString * const PKGDistributionProjectTreatMissingPresentationDocumentsAsWarningsKey=@"TREAT_MISSING_PRESENTATION_DOCUMENTS_AS_WARNING";

NSString * const PKGDistributionProjectAdvancedOptionsKey=@"ADVANCED_OPTIONS";

@interface PKGDistributionProjectSettings ()

	@property (readwrite) NSMutableDictionary * advancedOptions;

@end

@implementation PKGDistributionProjectSettings

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_buildFormat=PKGProjectBuildFormatFlat;
		
		_treatMissingPresentationDocumentsAsWarnings=NO;
		
		_advancedOptions=[NSMutableDictionary dictionary];
	}
	
	return self;
}

- (instancetype)initWithProjectSettings:(PKGProjectSettings *)inProjectSettings
{
	self=[super initWithProjectSettings:inProjectSettings];
	
	if (self!=nil)
	{
		if ([inProjectSettings isKindOfClass:PKGDistributionProjectSettings.class]==NO)
		{
			_treatMissingPresentationDocumentsAsWarnings=NO;
			_advancedOptions=[NSMutableDictionary dictionary];
		}
		else
		{
			PKGDistributionProjectSettings * tDistributionProjectSettings=(PKGDistributionProjectSettings *)inProjectSettings;
			
			_treatMissingPresentationDocumentsAsWarnings=tDistributionProjectSettings.treatMissingPresentationDocumentsAsWarnings;
			_advancedOptions=[tDistributionProjectSettings.advancedOptions mutableDeepCopy];
		}
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
	
	// Build Format
		
	_buildFormat=[inRepresentation[PKGDistributionProjectBuildFormatKey] unsignedIntegerValue];
	
	if (_buildFormat>PKGProjectBuildFormatBundle)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGRepresentationInvalidValueError
									  userInfo:@{PKGKeyPathErrorKey:PKGDistributionProjectBuildFormatKey}];
		
		return nil;
	}
	
	_treatMissingPresentationDocumentsAsWarnings=[inRepresentation[PKGDistributionProjectTreatMissingPresentationDocumentsAsWarningsKey] boolValue];
	
	// Advanced Options
	
	NSDictionary * tDictionary=inRepresentation[PKGDistributionProjectAdvancedOptionsKey];
	
	if (tDictionary==nil)
	{
		_advancedOptions=[NSMutableDictionary dictionary];
	}
	else
	{
		if ([tDictionary isKindOfClass:NSDictionary.class]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGDistributionProjectAdvancedOptionsKey}];
			
			return nil;
		}
		
		_advancedOptions=[tDictionary mutableCopy];
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[super representation];
	
	tRepresentation[PKGDistributionProjectBuildFormatKey]=@(self.buildFormat);
	
	tRepresentation[PKGDistributionProjectTreatMissingPresentationDocumentsAsWarningsKey]=@(self.treatMissingPresentationDocumentsAsWarnings);
	
	// Advanced Options
	
	if (self.advancedOptions.count>0)
		tRepresentation[PKGDistributionProjectAdvancedOptionsKey]=[self.advancedOptions copy];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString stringWithString:[super description]];
	
	[tDescription appendFormat:@"  Build Format: %@\n",(self.buildFormat==PKGProjectBuildFormatFlat) ? @"Flat" : @"Bundle"];
	
	return tDescription;
}

@end
