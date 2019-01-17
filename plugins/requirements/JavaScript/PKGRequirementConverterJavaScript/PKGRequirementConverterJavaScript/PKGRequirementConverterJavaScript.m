#import "PKGRequirementConverterJavaScript.h"

#import "PKGRequirement_JavaScript+Constants.h"
											
@implementation PKGRequirementConverterJavaScript

- (PKGRequirementType)requirementTypeWithParameters:(NSDictionary *) inParameters
{
	return PKGRequirementTypeUndefined;
}

- (NSDictionary *)sharedFunctionsImplementation
{
	NSString * tSharedSourceCode=self.project.sharedProjectData[PKGRequirementJavaScriptSharedSourceCodeKey];
	
	if (tSharedSourceCode!=nil)
	{
		static NSString * sJavaScript_UUID=nil;
		
		if (sJavaScript_UUID==nil)
		{
			sJavaScript_UUID=[[NSUUID UUID] UUIDString];
			
			if (sJavaScript_UUID==nil)
				return nil;
			
			id tObject=tSharedSourceCode;
			
			NSUInteger tLength=[tSharedSourceCode length];
				
			// Add a tab at the beginning of each line
			
			if (tLength>0)
			{
				NSMutableString * tMutableSourceCode=[tSharedSourceCode mutableCopy];
				
				[tMutableSourceCode insertString:@"\t" atIndex:0];
			
				[tMutableSourceCode replaceOccurrencesOfString:@"\n" withString:@"\n\t" options:0 range:NSMakeRange(0,tLength)];
				
				tObject=tMutableSourceCode;
			}
			
			if (tObject!=nil)
				return @{sJavaScript_UUID:tObject};
		}
	}
	
	return nil;
}

- (NSString *)invocationWithFormat:(NSString *) inFormat parameters:(NSDictionary *) inParameters index:(NSInteger) inIndex error:(NSError **) outError
{
	PKGJavaScriptReturnValue tReturnValue=PKGJavaScriptReturnTrue;
	
	NSNumber * tNumber=inParameters[PKGRequirementJavaScriptReturnValueKey];
	
	if (tNumber!=nil)
		tReturnValue=[tNumber integerValue];
	
	NSString * tFunctionName=inParameters[PKGRequirementJavaScriptFunctionKey];
		
	if (tFunctionName==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementJavaScriptFunctionKey}];

		return nil;
	}
	
	if ([tFunctionName length]==0)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementJavaScriptFunctionKey}];

		return nil;
	}
	
	BOOL nonEmptyParameterFound=NO;
	
	NSMutableArray * tMutableArray=[inParameters[PKGRequirementJavaScriptParametersKey] mutableCopy];
	
	for(NSUInteger tIndex=[tMutableArray count];tIndex>0;tIndex--)
	{
		NSMutableString * tMutableString=[tMutableArray[(tIndex-1)] mutableCopy];
		
		CFStringTrimWhitespace((CFMutableStringRef) tMutableString);
		
		if ([tMutableString length]==0)
		{
			if (nonEmptyParameterFound==YES)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGConverterErrorDomain
												  code:PKGConverterErrorInvalidParameter
											  userInfo:@{PKGConverterErrorParameterKey:PKGRequirementJavaScriptParametersKey}];

				return nil;
			}
		}
		else
		{
			nonEmptyParameterFound=YES;
		}
		
		if ([tMutableString length]==0)
			[tMutableArray removeObjectAtIndex:(tIndex-1)];
		else
			[tMutableArray replaceObjectAtIndex:(tIndex-1) withObject:tMutableString];
	}
	
	NSString * tStringParameters=@"";
	
	if ([tMutableArray count]>0)
		tStringParameters=[tMutableArray componentsJoinedByString:@","];
	
	return [NSString stringWithFormat:@"(%@(%@)==%@)",tFunctionName,tStringParameters,(tReturnValue==PKGJavaScriptReturnTrue) ? @"true" : @"false"];
}

@end
