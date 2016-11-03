/*
 Copyright (c) 2008-2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLocatorConverterJavaScript.h"

#import "PKGLocator_JavaScript+Constants.h"

@implementation PKGLocatorConverterJavaScript

- (NSArray *)elementsWithSettings:(NSDictionary *) inSettings withUniqueSearchID:(NSString *) inUniqueUUID error:(out NSError **) outError
{
	if (outError!=NULL)
		*outError=nil;
	
	NSXMLElement * tSearchElement=(NSXMLElement *) [NSXMLNode elementWithName:@"search"];

	// type
	
	id tAttribute=[NSXMLNode attributeWithName:@"type" stringValue:@"script"];
	
	[tSearchElement addAttribute:tAttribute];
	
	// id
	
	tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:inUniqueUUID];
	
	[tSearchElement addAttribute:tAttribute];
	
	// script
	
	NSString * tFunctionName=[inSettings objectForKey:PKGLocatorJavaScriptFunctionKey];

	if (tFunctionName==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGLocatorJavaScriptFunctionKey}];

		return nil;
	}
	
	if ([tFunctionName length]==0)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGLocatorJavaScriptFunctionKey}];

		return nil;
	}
	
	NSMutableArray * tMutableArray=[[inSettings objectForKey:PKGLocatorJavaScriptParametersKey] mutableCopy];
	
	BOOL nonEmptyParameterFound=NO;
	
	for(NSUInteger tIndex=[tMutableArray count];tIndex>0;tIndex--)
	{
		NSMutableString * tMutableString=[[tMutableArray objectAtIndex:(tIndex-1)] mutableCopy];
		
		CFStringTrimWhitespace((CFMutableStringRef) tMutableString);
		
		if ([tMutableString length]==0)
		{
			if (nonEmptyParameterFound==YES)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGConverterErrorDomain
												  code:PKGConverterErrorInvalidParameter
											  userInfo:@{PKGConverterErrorParameterKey:PKGLocatorJavaScriptParametersKey}];

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
	
	
	tAttribute=[NSXMLNode attributeWithName:@"script" stringValue:[NSString stringWithFormat:@"%@(%@)",tFunctionName,tStringParameters]];
	
	[tSearchElement addAttribute:tAttribute];
	
	NSXMLElement * tScriptElement=(NSXMLElement *) [NSXMLNode elementWithName:@"script"];
	
	// Add JavaScript code
		
	NSMutableString * tMutableSourceCode=[[inSettings objectForKey:PKGLocatorJavaScriptSourceCodeKey] mutableCopy];
	NSUInteger tLength=[tMutableSourceCode length];
	
	// Add tabs at the beginning of each line
		
	if (tLength==0)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGLocatorJavaScriptSourceCodeKey}];

		return nil;
	}
	
	[tMutableSourceCode replaceOccurrencesOfString:@"\n" withString:@"\n\t\t" options:0 range:NSMakeRange(0,tLength)];
	
	[tMutableSourceCode insertString:@"\n\n\t\t" atIndex:0];

	[tMutableSourceCode appendString:@"\n\n        "];

	NSXMLNode * tNode=[NSXMLNode textWithStringValue:tMutableSourceCode];
	
	[tScriptElement addChild:tNode];

	[tSearchElement addChild:tScriptElement];

	return @[tSearchElement];
}

@end
