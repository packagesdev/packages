/*
 Copyright (c) 2008-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLocatorConverterStandard.h"

#import "PKGLocator_Standard+Constants.h"

@implementation PKGLocatorConverterStandard

- (NSArray *)elementsWithSettings:(NSDictionary *)inSettings withUniqueSearchID:(NSString *)inUniqueUUID error:(out NSError **)outError
{
	if (outError!=NULL)
		*outError=nil;
	
	NSXMLElement * tSearchElement=(NSXMLElement *) [NSXMLNode elementWithName:@"search"];
	
	NSNumber * tNumber=inSettings[PKGLocatorStandardPreferDefaultPathKey];
	BOOL tPreferDefaultPath=NO;
	
	if (tNumber!=nil)
		tPreferDefaultPath=tNumber.boolValue;
	
	// type
	
	id tAttribute=[NSXMLNode attributeWithName:@"type" stringValue:@"component"];
		
	[tSearchElement addAttribute:tAttribute];
	
	// id
	
	NSString * tSubID=nil;
	
	if (tPreferDefaultPath==NO)
	{
		tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:inUniqueUUID];
	}
	else
	{
		tSubID=[inUniqueUUID stringByAppendingString:@".1"];
		
		tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:tSubID];
	}
	
	[tSearchElement addAttribute:tAttribute];
	
	
	NSString * tBundleIdentifier=inSettings[PKGLocatorStandardBundleIdentifierKey];

	if (tBundleIdentifier==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGLocatorStandardBundleIdentifierKey}];
		return nil;
	}
	
	tBundleIdentifier=[self.keysReplacer stringByReplacingKeysInString:tBundleIdentifier];

	if (tBundleIdentifier.length==0)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorInvalidParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGLocatorStandardBundleIdentifierKey}];

		return nil;
	}
	
	NSString * tDefaultPath=inSettings[PKGLocatorStandardDefaultPathKey];

	if (tDefaultPath==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGConverterErrorDomain
										  code:PKGConverterErrorMissingParameter
									  userInfo:@{PKGConverterErrorParameterKey:PKGLocatorStandardDefaultPathKey}];

		return nil;
	}
		
	NSXMLElement * tBundleElement=(NSXMLElement *) [NSXMLNode elementWithName:@"bundle"];
	
	// CFBundleIdentifier
	
	tAttribute=[NSXMLNode attributeWithName:@"CFBundleIdentifier" stringValue:tBundleIdentifier];
	
	[tBundleElement addAttribute:tAttribute];
	
	
	tDefaultPath=[tDefaultPath stringByStandardizingPath];
	
	if (tDefaultPath.length>0)
	{
		// path
	
		tAttribute=[NSXMLNode attributeWithName:@"path" stringValue:tDefaultPath];
		
		[tBundleElement addAttribute:tAttribute];
	}
	else
	{
		tPreferDefaultPath=NO;
	}
	
	[tSearchElement addChild:tBundleElement];
	
	
	if (tPreferDefaultPath==NO)
	{
		return [NSArray arrayWithObject:tSearchElement];
	}
	else
	{
		NSXMLElement * tSearchSortElement=(NSXMLElement *) [NSXMLNode elementWithName:@"search"];
		
		// type
		
		tAttribute=[NSXMLNode attributeWithName:@"type" stringValue:@"script"];
		
		[tSearchSortElement addAttribute:tAttribute];
		
		// id
		
		tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:inUniqueUUID];
		
		[tSearchSortElement addAttribute:tAttribute];
		
		// script
		
		tAttribute=[NSXMLNode attributeWithName:@"script" stringValue:@"searchDefaultPath()"];
		
		[tSearchSortElement addAttribute:tAttribute];
		
		NSXMLElement * tScriptElement=(NSXMLElement *) [NSXMLNode elementWithName:@"script"];
		
		// Add JavaScript code
		
		NSMutableString * tMutableSourceCode=[NSMutableString stringWithFormat:@"function searchDefaultPath()\n\
{\n\
\tvar tResults;\n\
\n\
\ttResults=my.search.results['%@'];\n\
\n\
\tif (typeof(tResults) == 'object')\n\
\t{\n\
\t\tvar tCount;\n\
\n\
\t\ttCount=tResults.length;\n\
\n\
\t\tif (tCount>0)\n\
\t\t{\n\
\t\t\tvar i;\n\
\n\
\t\t\tfor(i=0;i<tCount;i++)\n\
\t\t\t{\n\
\t\t\t\tif (tResults[i] == '%@')\n\
\t\t\t\t{\n\
\t\t\t\t\treturn tResults[i];\n\
\t\t\t\t}\n\
\t\t\t}\n\
\t\t}\n\
\t}\n\
\n\
\treturn tResults;\n\
}",tSubID,tDefaultPath];


		NSUInteger tLength=tMutableSourceCode.length;
		
		// Add tabs at the beginning of each line
			
		[tMutableSourceCode replaceOccurrencesOfString:@"\n" withString:@"\n\t\t" options:0 range:NSMakeRange(0,tLength)];
			
		[tMutableSourceCode insertString:@"\n\n\t\t" atIndex:0];
	
		[tMutableSourceCode appendString:@"\n\n        "];
	
		NSXMLNode * tNode=[NSXMLNode textWithStringValue:tMutableSourceCode];
		
		[tScriptElement addChild:tNode];
	
		[tSearchSortElement addChild:tScriptElement];

		return [NSArray arrayWithObjects:tSearchElement,tSearchSortElement,nil];
	}
}

@end
