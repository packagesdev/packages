/*
 Copyright (c) 2008-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementConverterFiles.h"

#import "PKGRequirement_Files+Constants.h"


@implementation PKGRequirementConverterFiles

- (PKGRequirementType)requirementTypeWithParameters:(NSDictionary *) inParameters
{
	if (inParameters!=nil)
	{
		NSNumber * tNumber=inParameters[PKGRequirementFilesTargetDiskKey];
		
		if (tNumber!=nil)
		{
			NSInteger tDiskType=[tNumber integerValue];
			
			if (tDiskType==PKGRequirementFilesTargetStartupDisk)
				return PKGRequirementTypeInstallation;
			
			if (tDiskType==PKGRequirementFilesTargetDestinationDisk)
				return PKGRequirementTypeTarget;
		}
	}
	
	return PKGRequirementTypeUndefined;
}

- (NSString *)variablesWithIndex:(NSInteger) inIndex tabulationDepth:(NSString *) inTabulationDepth parameters:(NSDictionary *) inParameters error:(out NSError **) outError;
{
	NSArray * tArray=inParameters[PKGRequirementFilesListKey];
	
	if (tArray==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementFilesListKey}];

		return nil;
	}
	
	NSUInteger tCount=tArray.count;
		
	if (tCount==0)
		return @"";
	
	__block NSMutableString * tMutableString=[NSMutableString stringWithFormat:@"%@var tFilesToCheck%d=new Array(",inTabulationDepth,(int)inIndex];
	
	if (tMutableString!=nil)
	{
		[tArray enumerateObjectsUsingBlock:^(NSString * bPath,NSUInteger bIndex,BOOL * bOutStop){
		
            bPath=[self.keysReplacer stringByReplacingKeysInString:bPath];
            
            // Escape the string (" > < &")
			
			NSString * tEscapedPath=CFBridgingRelease(CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault,(CFStringRef) bPath,NULL));
			
			if (tEscapedPath!=nil)
			{
				[tMutableString appendFormat:@"\'%@\'",tEscapedPath];
			}
			else
			{
				// A COMPLETER
			}
			
			if (bIndex!=(tCount-1))
				[tMutableString appendFormat:@",\n%@                             ",inTabulationDepth];
		}];
		
		[tMutableString appendString:@");\n\n"];
	}
	
	return tMutableString;
}

- (NSString *)invocationWithFormat:(NSString *) inFormat parameters:(NSDictionary *) inParameters index:(NSInteger) inIndex error:(out NSError **) outError
{
	NSNumber * tNumber=inParameters[PKGRequirementFilesTargetDiskKey];
	
	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementFilesTargetDiskKey}];

		return nil;
	}

	NSInteger tDiskType=[tNumber integerValue];
	
	if (tDiskType<PKGRequirementFilesTargetDestinationDisk || tDiskType>PKGRequirementFilesTargetStartupDisk)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementFilesTargetDiskKey}];
		
		return nil;
	}
	
	NSString * tDiskTypeString=@"IC_DISK_TYPE_DESTINATION";
	
	if (tDiskType==PKGRequirementFilesTargetStartupDisk)
		tDiskTypeString=@"IC_DISK_TYPE_STARTUP_DISK";
	
	tNumber=inParameters[PKGRequirementFilesSelectorKey];
	
	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementFilesSelectorKey}];

		return nil;
	}
	
	NSInteger tSelector=[tNumber integerValue];
	
	if (tSelector<PKGRequirementFilesSelectorAny || tSelector>PKGRequirementFilesSelectorAll)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementFilesSelectorKey}];

		return nil;
	}
	
	NSString * tSelectorString=@"IC_SELECTOR_ANY";
	
	if (tSelector==PKGRequirementFilesSelectorAll)
		tSelectorString=@"IC_SELECTOR_ALL";
	
	tNumber=inParameters[PKGRequirementFilesConditionKey];

	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementFilesConditionKey}];

		return nil;
	}
	
	NSInteger tCondition=[tNumber integerValue];
	
	if (tCondition<PKGRequirementFilesConditionExist || tCondition>PKGRequirementFilesConditionDoesNotExist)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementFilesConditionKey}];

		return nil;
	}
	
	NSString * tConditionString=@"IC_CONDITION_EXIST";
	
	if (tCondition==PKGRequirementFilesConditionDoesNotExist)
		tConditionString=@"IC_CONDITION_DOES_NOT_EXIST";
	
	return [NSString stringWithFormat:inFormat,tSelectorString,tConditionString,tDiskTypeString,[NSString stringWithFormat:@"tFilesToCheck%d",(int)inIndex]];
}

@end
