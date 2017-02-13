/*
Copyright (c) 2007-2010, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPatternFormatter.h"

@implementation PKGPatternFormatter

- (BOOL) getObjectValue:(id *) outObject forString:(NSString *) inString errorDescription:(NSString **)error
{
	*outObject=inString;
	
	return YES;
}

- (NSString *) stringForObjectValue:(id) inObject
{
	if (![inObject isKindOfClass:NSString.class])
		return @"";
	
	return inObject;
}

- (NSString *) editingStringForObjectValue:(id) inObject
{
	if (![inObject isKindOfClass:NSString.class])
		return @"";
	
	return inObject;
}

- (NSAttributedString *) attributedStringForObjectValue:(id) inObject withDefaultAttributes:(NSDictionary *) inAttributes
{
	NSAttributedString * tAttributedString=nil;

	if (inObject!=nil)
	{
		if (![inObject isKindOfClass:NSString.class])
			return nil;
		
		if ([inObject length]>0)
			tAttributedString=[[NSAttributedString alloc] initWithString:inObject attributes:inAttributes];
	}
	
	if (tAttributedString==nil)
	{
		NSColor * tColor=[inAttributes objectForKey:NSForegroundColorAttributeName];
		
		if ([tColor isEqualTo:[NSColor alternateSelectedControlTextColor]]==NO)
			tColor=[NSColor colorWithDeviceWhite:0.75f alpha:1.0f];

		tAttributedString=[[NSAttributedString alloc] initWithString:NSLocalizedString(@"No Pattern Set",@"")
														  attributes:@{NSForegroundColorAttributeName:tColor,
																	   NSObliquenessAttributeName:@(0.35),
																	   NSFontAttributeName:inAttributes[NSFontAttributeName]}];
	}
	
	return tAttributedString;
}

@end