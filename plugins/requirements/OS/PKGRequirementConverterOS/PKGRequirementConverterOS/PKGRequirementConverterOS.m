/*
Copyright (c) 2008-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGRequirementConverterOS.h"

#import "PKGRequirement_OS+Constants.h"


@implementation PKGRequirementConverterOS

- (PKGRequirementType)requirementTypeWithParameters:(NSDictionary *) inParameters
{
	if (inParameters!=nil)
	{
		NSNumber * tNumber=inParameters[PKGRequirementOSTargetDiskKey];
		
		if (tNumber!=nil)
		{
			NSInteger tDiskType=tNumber.integerValue;
			
			if (tDiskType==PKGRequirementOSTargetStartupDisk)
				return PKGRequirementTypeInstallation;
			
			if (tDiskType==PKGRequirementOSTargetDestinationDisk)
				return PKGRequirementTypeTarget;
		}
	}
	
	return PKGRequirementTypeUndefined;
}

- (NSString *)invocationWithFormat:(NSString *) inFormat parameters:(NSDictionary *) inParameters index:(NSInteger) inIndex error:(NSError **) outError
{
	NSNumber * tNumber=inParameters[PKGRequirementOSMinimumVersionKey];
	
	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementOSMinimumVersionKey}];

		return nil;
	}
	
	NSInteger tMinimumVersion=tNumber.integerValue;
	
	if (tMinimumVersion<0)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementOSMinimumVersionKey}];

		return nil;
	}
	
	NSInteger tMaximumVersion=PKGRequirementOSMaximumVersionNotDefined;
	
	tNumber=inParameters[PKGRequirementOSMaximumVersionKey];
	
	if (tNumber!=nil)
	{
		tMaximumVersion=tNumber.integerValue;
		
		if (tMinimumVersion<0)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGConverterErrorDomain
											  code:PKGConverterErrorInvalidParameter
										  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementOSMaximumVersionKey}];
			
			return nil;
		}
	}
	
	NSString * tDiskTypeString=@"IC_DISK_TYPE_DESTINATION";
	
	if (tMinimumVersion==PKGRequirementOSMinimumVersionNotInstalled)
		return [NSString stringWithFormat:inFormat,tDiskTypeString,@"false",@"''",@"IC_OS_DISTRIBUTION_TYPE_ANY"];

	tNumber=inParameters[PKGRequirementOSTargetDiskKey];
	
	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementOSTargetDiskKey}];
		return nil;
	}
	
	NSInteger tDiskType=tNumber.integerValue;
	
	if (tDiskType<PKGRequirementOSTargetDestinationDisk || tDiskType>PKGRequirementOSTargetStartupDisk)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementOSTargetDiskKey}];

		return nil;
	}
	
	if (tDiskType==PKGRequirementOSTargetStartupDisk)
		tDiskTypeString=@"IC_DISK_TYPE_STARTUP_DISK";
	
	/* Create Minimum Version String */
	
	NSString * tMinimumVersionString;
	
	if ((tMinimumVersion%100)==0)
		tMinimumVersionString=[NSString stringWithFormat:@"'%d.%d'",(int)tMinimumVersion/10000,(int)((tMinimumVersion/100)%100)];
	else
		tMinimumVersionString=[NSString stringWithFormat:@"'%d.%d.%d'",(int)tMinimumVersion/10000,(int)((tMinimumVersion/100)%100),(int)(tMinimumVersion%100)];
	
	/* Create Maximum Version String */
	
	NSString * tMaximumVersionString;
	
	if (tMaximumVersion==PKGRequirementOSMaximumVersionNotDefined)
	{
		tMaximumVersionString=@"undefined";
	}
	else
	{
		if ((tMaximumVersion%100)==0)
			tMaximumVersionString=[NSString stringWithFormat:@"'%d.%d'",(int)tMaximumVersion/10000,(int)((tMaximumVersion/100)%100)];
		else
			tMaximumVersionString=[NSString stringWithFormat:@"'%d.%d.%d'",(int)tMaximumVersion/10000,(int)((tMaximumVersion/100)%100),(int)(tMaximumVersion%100)];
	}
	
	
	tNumber=inParameters[PKGRequirementOSDistributionKey];

	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementOSDistributionKey}];
		return nil;
	}
	
	NSUInteger tDistributionType=tNumber.integerValue;

	NSString * tDistributionTypeString=nil;
	
	switch(tDistributionType)
	{
		case PKGRequirementOSDistributionAny:
			
			tDistributionTypeString=@"IC_OS_DISTRIBUTION_TYPE_ANY";
			break;
			
		case PKGRequirementOSDistributionClient:
			
			tDistributionTypeString=@"IC_OS_DISTRIBUTION_TYPE_CLIENT";
			break;
			
		case PKGRequirementOSDistributionServer:
			
			tDistributionTypeString=@"IC_OS_DISTRIBUTION_TYPE_SERVER";
			break;
			
		default:
			
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGConverterErrorDomain
											  code:PKGConverterErrorInvalidParameter
										  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementOSDistributionKey}];
			
			return nil;
	}
	
	return [NSString stringWithFormat:inFormat,tDiskTypeString,@"true",tMinimumVersionString,tMaximumVersionString,tDistributionTypeString];
}

@end
