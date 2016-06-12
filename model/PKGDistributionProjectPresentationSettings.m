/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectPresentationSettings.h"

#import "PKGPackagesError.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGPresentationInstallationStepsKey=@"INSTALLATION_STEPS";

NSString * const PKGPresentationTitleKey=@"TITLE";

NSString * const PKGPresentationBackgroundKey=@"BACKGROUND";

NSString * const PKGPresentationIntroductionKey=@"INTRODUCTION";

NSString * const PKGPresentationReadMeKey=@"README";

NSString * const PKGPresentationLicenseKey=@"LICENSE";

NSString * const PKGPresentationInstallationTypeKey=@"INSTALLATION TYPE";

NSString * const PKGPresentationSummaryKey=@"SUMMARY";

@interface PKGDistributionProjectPresentationSettings()

	@property (readwrite)NSMutableArray * sections;

@end

@implementation PKGDistributionProjectPresentationSettings

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
		__block NSError * tError=nil;
		
		// Steps List
		
		if (inRepresentation[PKGPresentationInstallationStepsKey]!=nil)
		{
			if ([inRepresentation[PKGPresentationInstallationStepsKey] isKindOfClass:[NSArray class]]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationInstallationStepsKey}];
				
				return nil;
			}
			
			_sections=[[inRepresentation[PKGPresentationInstallationStepsKey] WBmapObjectsUsingBlock:^id(NSDictionary * bSectionRepresentation, NSUInteger bIndex){
				return [[PKGPresentationSection alloc] initWithRepresentation:bSectionRepresentation error:&tError];
			}] mutableCopy];
			
			if (_sections==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValue;
					
					NSString * tPathError=PKGPresentationInstallationStepsKey;
					
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
			// Build the defaults
			
			// A COMPLETER
		}
		
		// Title
		
		_titleSettings=[[PKGPresentationTitleSettings alloc] initWithRepresentation:inRepresentation[PKGPresentationTitleKey] error:&tError];
		
		if (_titleSettings==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPresentationTitleKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		// Background Picture
		
		_backgroundSettings=[[PKGPresentationBackgroundSettings alloc] initWithRepresentation:inRepresentation[PKGPresentationBackgroundKey] error:&tError];
		
		if (_backgroundSettings==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPresentationBackgroundKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		// Welcome
		
		_welcomeSettings=[[PKGPresentationWelcomeStepSettings alloc] initWithRepresentation:inRepresentation[PKGPresentationIntroductionKey] error:&tError];
		
		if (_welcomeSettings==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPresentationIntroductionKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		// Read Me
		
		_readMeSettings=[[PKGPresentationReadMeStepSettings alloc] initWithRepresentation:inRepresentation[PKGPresentationReadMeKey] error:&tError];
		
		if (_readMeSettings==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPresentationReadMeKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		// License
		
		_licenseSettings=[[PKGPresentationLicenseStepSettings alloc] initWithRepresentation:inRepresentation[PKGPresentationLicenseKey] error:&tError];
		
		if (_licenseSettings==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPresentationLicenseKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		// Installation Type
		
		_installationTypeSettings=[[PKGPresentationInstallationTypeStepSettings alloc] initWithRepresentation:inRepresentation[PKGPresentationInstallationTypeKey] error:&tError];
		
		if (_installationTypeSettings==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPresentationInstallationTypeKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		// Summary
		
		_summarySettings=[[PKGPresentationSummaryStepSettings alloc] initWithRepresentation:inRepresentation[PKGPresentationSummaryKey] error:&tError];
		
		if (_summarySettings==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPresentationSummaryKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
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
	
	if (self.sections!=nil)
	{
		tRepresentation[PKGPresentationInstallationStepsKey]=[self.sections WBmapObjectsUsingBlock:^id(PKGPresentationSection * bSection, NSUInteger bIndex){
			return [bSection representation];
		}];
	}
	
	tRepresentation[PKGPresentationTitleKey]=[self.titleSettings representation];
	
	NSMutableDictionary * tSettingsDictionary=[self.backgroundSettings representation];
	
	if (tSettingsDictionary!=nil)
		tRepresentation[PKGPresentationBackgroundKey]=tSettingsDictionary;
	
	if (self.welcomeSettings!=nil)
		tRepresentation[PKGPresentationIntroductionKey]=[self.welcomeSettings representation];
	
	if (self.readMeSettings!=nil)
		tRepresentation[PKGPresentationReadMeKey]=[self.readMeSettings representation];
	
	if (self.licenseSettings!=nil)
		tRepresentation[PKGPresentationLicenseKey]=[self.licenseSettings representation];
	
	if (self.installationTypeSettings!=nil)
		tRepresentation[PKGPresentationInstallationTypeKey]=[self.installationTypeSettings representation];
	
	if (self.summarySettings!=nil)
		tRepresentation[PKGPresentationSummaryKey]=[self.summarySettings representation];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"Presentation Settings:\n"];
	[tDescription appendString:@"---------------------\n\n"];
	
	if ([self.sections count]>0)
	{
		[tDescription appendString:@"  Sections Order:\n"];
		
		for(PKGPresentationSection * tSection in self.sections)
			[tDescription appendFormat:@"%@",[tSection description]];
		
		[tDescription appendString:@"\n"];
	}
	
	[tDescription appendFormat:@"%@",[self.titleSettings description]];
	[tDescription appendString:@"\n"];
	
	if (self.backgroundSettings!=nil)
	{
		[tDescription appendFormat:@"%@",[self.backgroundSettings description]];
		[tDescription appendString:@"\n"];
	}
	
	if (self.welcomeSettings!=nil)
	{
		[tDescription appendFormat:@"%@",[self.welcomeSettings description]];
		[tDescription appendString:@"\n"];
	}
	
	if (self.readMeSettings!=nil)
	{
		[tDescription appendFormat:@"%@",[self.readMeSettings description]];
		[tDescription appendString:@"\n"];
	}
	
	if (self.licenseSettings!=nil)
	{
		[tDescription appendFormat:@"%@",[self.licenseSettings description]];
		[tDescription appendString:@"\n"];
	}
	
	if (self.installationTypeSettings!=nil)
	{
		[tDescription appendFormat:@"%@",[self.installationTypeSettings description]];
		[tDescription appendString:@"\n"];
	}
	
	if (self.summarySettings!=nil)
	{
		[tDescription appendFormat:@"%@",[self.summarySettings description]];
		[tDescription appendString:@"\n"];
	}
	
	return tDescription;
}

@end
