/*
Copyright (c) 2008-2021, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGRequirementConverterScript.h"

#import "PKGRequirement_Script+Constants.h"

@implementation PKGRequirementConverterScript

- (NSDictionary *)requiredOptionsValuesWithParameters:(NSDictionary *) inParameters
{
	return @{@"installer-script.options:allow-external-scripts":@(YES)};
}

- (NSArray *)requiredAdditionalResourcesWithParameters:(NSDictionary *) inParameters
{
	NSNumber * tEmbedScript=inParameters[PKGRequirementScriptEmbeddedKey];
		
	if (tEmbedScript!=nil && [tEmbedScript boolValue]==YES)
	{
		NSDictionary * tDictionary=inParameters[PKGRequirementScriptPathKey];
		
		PKGFilePath * tFilePath=[[PKGFilePath alloc] initWithRepresentation:tDictionary error:NULL];
		
		if (tFilePath==nil)
		{
			// A COMPLETER
			
			return nil;
		}
		
		PKGAdditionalResource * tAdditionalResource=[[PKGAdditionalResource alloc] initWithFilePath:tFilePath mode:0775];
		
		return @[tAdditionalResource];
	}
	
	return nil;
}

- (PKGRequirementType)requirementTypeWithParameters:(NSDictionary *) inParameters
{
	return PKGRequirementTypeUndefined;
}

- (NSString *)variablesWithIndex:(NSInteger) inIndex tabulationDepth:(NSString *) inTabulationDepth parameters:(NSDictionary *) inParameters error:(out NSError **) outError
{
	NSArray * tArray=inParameters[PKGRequirementScriptArgumentsListKey];
	
	if (tArray==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementScriptArgumentsListKey}];

		return nil;
	}
	
	NSMutableString * tMutableString=[NSMutableString stringWithFormat:@"%@var tScriptArguments%d=new Array(",inTabulationDepth,(int)inIndex];
	
	if (tMutableString!=nil)
	{
		int tIndex=0;
		
		for(NSDictionary * tArgumentDictionary in tArray)
		{
			NSNumber * tNumber=tArgumentDictionary[PKGRequirementScriptArgumentEnabledKey];
			
			if ([tNumber boolValue]==YES)
			{
				NSString * tArgumentValue=tArgumentDictionary[PKGRequirementScriptArgumentValueKey];
				
                tArgumentValue=[self.keysReplacer stringByReplacingKeysInString:tArgumentValue];
                
				if (tArgumentValue.length>0)
				{
					/* Escape the string (" > < &") */
				
					tArgumentValue=(__bridge_transfer NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault,(__bridge CFStringRef) tArgumentValue,NULL);
					
					if (tArgumentValue!=nil)
					{
						if (tIndex!=0)
							[tMutableString appendFormat:@",\n%@                             ",inTabulationDepth];
						
						[tMutableString appendFormat:@"\'%@\'",tArgumentValue];
						
						tIndex++;
					}
					else
					{
						/* A COMPLETER */
					}
				}
			}
		}
		
		[tMutableString appendString:@");\n\n"];
		
		return tMutableString;
	}
	
	return nil;
}

- (NSString *)invocationWithFormat:(NSString *) inFormat parameters:(NSDictionary *) inParameters index:(NSInteger) inIndex error:(out NSError **) outError
{
	NSDictionary * tRepresentation=inParameters[PKGRequirementScriptPathKey];
	
	if (tRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementScriptPathKey}];
		
		return nil;
	}
	
	PKGFilePath * tFilePath=[[PKGFilePath alloc] initWithRepresentation:tRepresentation error:NULL];
	
	NSString * tPath=tFilePath.string;
	
	if (tPath==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementScriptPathKey}];

		return nil;
	}

	NSNumber * tEmbedScript=inParameters[PKGRequirementScriptEmbeddedKey];
	
	if (tEmbedScript==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementScriptEmbeddedKey}];
		
		return nil;
	}
	
	if ([tEmbedScript boolValue]==YES)
		tPath=[tPath lastPathComponent];
	
	NSNumber * tComparatorNumber=inParameters[PKGRequirementScriptReturnValueComparatorKey];
	
	if (tComparatorNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementScriptReturnValueComparatorKey}];

		return nil;
	}

	PKGRequirementComparator tComparator=[tComparatorNumber integerValue];
	NSString * tComparatorString=nil;
	
	if (tComparator==PKGRequirementComparatorIsLess)
	{
		tComparatorString=@"IC_COMPARATOR_IS_LESS";
	}
	else if (tComparator==PKGRequirementComparatorIsEqual)
	{
		tComparatorString=@"IC_COMPARATOR_IS_EQUAL";
	}
	else if (tComparator==PKGRequirementComparatorisGreater)
	{
		tComparatorString=@"IC_COMPARATOR_IS_GREATER";
	}
	else if (tComparator==PKGRequirementComparatorIsNotEqual)
	{
		tComparatorString=@"IC_COMPARATOR_IS_NOT_EQUAL";
	}
	else
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementScriptReturnValueComparatorKey}];
		
		return nil;
	}
	
	NSNumber * tReturnValueNumber=inParameters[PKGRequirementScriptReturnValueKey];
		
	if (tReturnValueNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementScriptReturnValueKey}];
		
		return nil;
	}
	
	return [NSString stringWithFormat:inFormat,tPath,[NSString stringWithFormat:@"tScriptArguments%d",(int)inIndex],tComparatorString,[tReturnValueNumber integerValue]];
}

@end
