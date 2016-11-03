/*
 Copyright (c) 2008-2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementConverterDiskSpace.h"

#import "PKGRequirement_DiskSpace+Constants.h"

#define DISKSPACE_CONVERSION_COUNT	4

static unsigned long long sDiskSpaceConversionTable[DISKSPACE_CONVERSION_COUNT]={
																			  1024ULL,		/* MB */
																		   1048576ULL,		/* GB */
																		1073741824ULL,		/* TB */
																	 1099511627776ULL,		/* PB */
																	};

@implementation PKGRequirementConverterDiskSpace

- (PKGRequirementType)requirementTypeWithParameters:(NSDictionary *) inParameters
{
	return PKGRequirementTypeTarget;
}

- (NSString *)invocationWithFormat:(NSString *) inFormat parameters:(NSDictionary *) inParameters index:(NSInteger) inIndex error:(out NSError **) outError
{
	NSNumber * tMinimumSizeUnitNumber=inParameters[PKGRequirementDiskSpaceMinimumSizeUnitKey];
	
	if (tMinimumSizeUnitNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementDiskSpaceMinimumSizeUnitKey}];

		return nil;
	}

	PKGRequirementDiskSpaceSizeUnit tUnit=[tMinimumSizeUnitNumber integerValue];
	
	if (tUnit<PKGRequirementDiskSpaceSizeUnitMB || tUnit>PKGRequirementDiskSpaceSizeUnitPB)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementDiskSpaceMinimumSizeUnitKey}];

		return nil;
	}
	
	NSNumber * tMinimumSizeValueNumber=inParameters[PKGRequirementDiskSpaceMinimumSizeValueKey];

	if (tMinimumSizeValueNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementDiskSpaceMinimumSizeValueKey}];

		return nil;
	}
	
	NSInteger tValue=[tMinimumSizeValueNumber integerValue];
	
	if (tValue<0)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementDiskSpaceMinimumSizeValueKey}];

		return nil;
	}
	
	unsigned long long tMinimumValueKB=tValue*sDiskSpaceConversionTable[tUnit]*1024;	// x 1024 because of a bug in Apple'sAPI.
		
	return [NSString stringWithFormat:inFormat,tMinimumValueKB];
}

@end
