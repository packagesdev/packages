/*
 Copyright (c) 2008-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementConverterRAM.h"

#import "PKGRequirement_RAM+Constants.h"

#define RAM_CONVERSION_COUNT	18

static unsigned long long sRAMConversionTable[RAM_CONVERSION_COUNT]={
																		536870912ULL,		/* 512 MB */
	
																	   1073741824ULL,		/* 1 GB */
																	   1610612736ULL,		/* 1.5 GB */
																	   2147483648ULL,		/* 2 GB */
																	   3221225472ULL,		/* 3 GB */
																	   4294967296ULL,		/* 4 GB */
																	   8589934592ULL,		/* 8 GB */
																	  17179869184ULL,		/* 16 GB */
																	  34359738368ULL,		/* 32 GB */
																	  68719476736ULL,		/* 64 GB */
																	  51539607552ULL,		/* 48 GB */
																	 103079215104ULL,		/* 96 GB */
																	 137438953472ULL,		/* 128 GB */
																	 206158430208ULL,		/* 192 GB */
																	 274877906944ULL,		/* 256 GB */
																	 412316860416ULL,		/* 384 GB */
																	 824633720832ULL,		/* 768 GB */
																	
																	1649267441664ULL,		/* 1.5 TB */
																	};
											
											
											
@implementation PKGRequirementConverterRAM

- (PKGRequirementType)requirementTypeWithParameters:(NSDictionary *)inParameters
{
	return PKGRequirementTypeInstallation;
}

- (NSString *)invocationWithFormat:(NSString *) inFormat parameters:(NSDictionary *) inParameters index:(NSInteger)inIndex error:(out NSError **) outError
{
	NSNumber * tNumber=inParameters[PKGRequirementRAMMinimumSizeIndexKey];
	
	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementRAMMinimumSizeIndexKey}];

		return nil;
	}
	
	NSInteger tIndex=tNumber.integerValue;
	
	if (tIndex<0 || tIndex>=RAM_CONVERSION_COUNT)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementRAMMinimumSizeIndexKey}];

		return nil;
	}
	
	return [NSString stringWithFormat:inFormat,sRAMConversionTable[tIndex]];
}

@end
