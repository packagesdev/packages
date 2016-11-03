/*
 Copyright (c) 2008-2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementConverterCPU.h"

#import "PKGRequirement_CPU+Constants.h"
											
@implementation PKGRequirementConverterCPU

- (PKGRequirementType)requirementTypeWithParameters:(NSDictionary *) inParameters
{
	return PKGRequirementTypeInstallation;
}

- (NSString *)invocationWithFormat:(NSString *) inFormat parameters:(NSDictionary *) inParameters index:(NSInteger) inIndex error:(out NSError **) outError
{
	NSNumber * tNumber=inParameters[PKGRequirementCPUMinimumCPUCoresCountKey];
	
	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementCPUMinimumCPUCoresCountKey}];

		return nil;
	}
	
	NSInteger tMinimumCoresCount=[tNumber integerValue];
	
	if (tMinimumCoresCount<0)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementCPUMinimumCPUCoresCountKey}];

		return nil;
	}
	
	tNumber=inParameters[PKGRequirementCPUArchitectureFamilyKey];

	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementCPUArchitectureFamilyKey}];

		return nil;
	}
	
	PKGRequirementCPUFamilyType tFamily=[tNumber integerValue];
		
	if (tFamily<PKGRequirementCPUFamilyAny || tFamily>PKGRequirementCPUFamilyIntel)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementCPUArchitectureFamilyKey}];

		return nil;
	}
	
	NSString * tFamilyString;
		
	if (tFamily==PKGRequirementCPUFamilyPowerPC)
	{
		tFamilyString=@"IC_CPU_ARCHITECTURE_POWERPC";
	}
	else if (tFamily==PKGRequirementCPUFamilyIntel)
	{
		tFamilyString=@"IC_CPU_ARCHITECTURE_INTEL";
	}
	else
	{
		tFamilyString=@"IC_CPU_ARCHITECTURE_ANY";
	}
	
	NSString * tPowerPCTypeString=@"IC_CPU_ARCHITECTURE_TYPE_ANY";
	
	if (tFamily==PKGRequirementCPUFamilyPowerPC || tFamily==PKGRequirementCPUFamilyAny)
	{
		tNumber=inParameters[PKGRequirementCPUPowerPCArchitectureTypeKey];

		if (tNumber==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGConverterErrorDomain
											  code:PKGConverterErrorMissingParameter
										  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementCPUPowerPCArchitectureTypeKey}];

			return nil;
		}
		
		PKGRequirementCPUGenerationType tPowerPCGeneration=[tNumber integerValue];
			
		if (tPowerPCGeneration==PKGRequirementCPUGeneration32bit)
		{
			tPowerPCTypeString=@"IC_CPU_ARCHITECTURE_TYPE_32";
		}
		else if (tPowerPCGeneration==PKGRequirementCPUGeneration64bit)
		{
			tPowerPCTypeString=@"IC_CPU_ARCHITECTURE_TYPE_64";
		}
	}
	
	NSString * tIntelTypeString=@"IC_CPU_ARCHITECTURE_TYPE_ANY";
	
	if (tFamily==PKGRequirementCPUFamilyIntel || tFamily==PKGRequirementCPUFamilyAny)
	{
		tNumber=inParameters[PKGRequirementCPUIntelArchitectureTypeKey];

		if (tNumber==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGConverterErrorDomain
											  code:PKGConverterErrorMissingParameter
										  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementCPUIntelArchitectureTypeKey}];

			return nil;
		}
		
		PKGRequirementCPUGenerationType tIntelGeneration=[tNumber integerValue];
		
		if (tIntelGeneration==PKGRequirementCPUGeneration32bit)
		{
			tIntelTypeString=@"IC_CPU_ARCHITECTURE_TYPE_32";
		}
		else if (tIntelGeneration==PKGRequirementCPUGeneration64bit)
		{
			tIntelTypeString=@"IC_CPU_ARCHITECTURE_TYPE_64";
		}
	}
	
	tNumber=inParameters[PKGRequirementCPUMinimumFrequencyKey];
	
	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementCPUMinimumFrequencyKey}];

		return nil;
	}
	
	unsigned long long tMinimumFrequency=[tNumber unsignedLongLongValue];
		
	return [NSString stringWithFormat:inFormat,tMinimumCoresCount,tFamilyString,tPowerPCTypeString,tIntelTypeString,tMinimumFrequency];
}

@end
