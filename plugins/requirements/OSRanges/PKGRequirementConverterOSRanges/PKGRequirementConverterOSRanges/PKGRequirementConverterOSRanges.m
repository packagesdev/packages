/*
Copyright (c) 2025, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGRequirementConverterOSRanges.h"

#import "PKGRequirement_OSRanges+Constants.h"


@implementation PKGRequirementConverterOSRanges

+ (NSString *)versionStringFromIntegerVersion:(NSInteger)integerVersion
{
	if ((integerVersion%100)==0)
		return [NSString stringWithFormat:@"'%d.%d'",(int)integerVersion/10000,(int)((integerVersion/100)%100)];
	else
		return [NSString stringWithFormat:@"'%d.%d.%d'",(int)integerVersion/10000,(int)((integerVersion/100)%100),(int)(integerVersion%100)];
}

- (PKGRequirementDomains)requirementDomains
{
	return PKGRequirementDomainDistribution;
}

- (PKGRequirementOutputFormat)requirementOutputFormat
{
	return PKGRequirementOutputFormatXML;
}

- (NSXMLElement *)requirementElementWithParameters:(NSDictionary *)inParameters
{
	NSArray<NSDictionary <NSString *, NSString *> *> * tOSRangeRequirements=inParameters[PKGRequirementOSRangesListKey];
	NSMutableArray<NSXMLElement *> * tOSVersionElements=[NSMutableArray array];
	
	for(NSDictionary <NSString *, NSString *> * tOSRangeRequirement in tOSRangeRequirements)
	{
		NSXMLElement * tElement=(NSXMLElement *) [NSXMLNode elementWithName:@"os-version"];
		
		// Minimum version (Required)
		NSString * tMinimumOSVersion=[self.class versionStringFromIntegerVersion:[tOSRangeRequirement[PKGRequirementOSRangesMinimumVersionKey] integerValue]];
		
		[tElement addAttribute:[NSXMLNode attributeWithName:@"min" stringValue:tMinimumOSVersion]];
		
		// Maximum version (Optional)
		NSString * tMaximumOSVersion=[self.class versionStringFromIntegerVersion:[tOSRangeRequirement[PKGRequirementOSRangesMaximumVersionKey] integerValue]];
		
		if (tMaximumOSVersion!=nil)
			[tElement addAttribute:[NSXMLNode attributeWithName:@"before" stringValue:tMaximumOSVersion]];
		
		[tOSVersionElements addObject:tElement];
	}
	
	if (tOSVersionElements.count==0)
	{
		NSXMLElement * tFallBackElement=(NSXMLElement *) [NSXMLNode elementWithName:@"os-version"];
		id tAttribute=[NSXMLNode attributeWithName:@"min" stringValue:@"10.6.6"];
		
		[tFallBackElement addAttribute:tAttribute];
		
		[tOSVersionElements addObject:tFallBackElement];
	}
	
	NSXMLElement * tAllowedOSVersionsElement=[NSXMLNode elementWithName:@"allowed-os-versions"];
	
	for(NSXMLElement * tElement in tOSVersionElements)
		
		[tAllowedOSVersionsElement addChild:tElement];
	
	return tAllowedOSVersionsElement;
}

@end
