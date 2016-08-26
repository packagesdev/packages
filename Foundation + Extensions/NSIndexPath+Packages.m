/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSIndexPath+Packages.h"

@implementation NSIndexPath (Packages)

- (instancetype)PKG_initWithStringRepresentation:(NSString *)inStringRepresentation
{
	if (inStringRepresentation==nil)
		return nil;
	
	NSArray * tIndexComponents=[inStringRepresentation componentsSeparatedByString:@":"];
	
	NSUInteger tLength=[tIndexComponents count];
	
	if (tLength==0)
		return [self init];
	
	NSUInteger * tIndexes=(NSUInteger *)malloc(tLength*sizeof(NSUInteger));
	NSUInteger tPosition=0;
	
	for(NSString * tIndexString in tIndexComponents)
	{
		if ([tIndexString length]==0)
			break;
		
		tIndexes[tPosition]=[tIndexString integerValue];
		tPosition++;
	}
	
	self=[self initWithIndexes:tIndexes length:tPosition];
	
	free(tIndexes);
	
	return self;
}

#pragma mark -

- (NSString *)PKG_stringRepresentation
{
	NSUInteger tLength=self.length;
	
	NSMutableString * tMutableString=[NSMutableString string];
	
	if (tLength>0)
	{
		for(NSUInteger tPosition=0;tPosition<tLength;tPosition++)
		{
			NSUInteger tIndex=[self indexAtPosition:tPosition];
			
			[tMutableString appendFormat:@"%llu:",(unsigned long long)tIndex];
		}
		
		[tMutableString deleteCharactersInRange:NSMakeRange([tMutableString length]-1, 1)];
	}
	
	return [tMutableString copy];
}

- (NSUInteger)PKG_lastIndex
{
	if (self.length<1)
		return NSNotFound;
	
	return [self indexAtPosition:self.length-1];
}

@end
