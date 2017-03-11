/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSArray+UniqueName.h"

#import "NSArray+WBExtensions.h"

#define UNIQUENAME_ATTEMPTS_MAX		65535

@implementation NSArray (UniqueName)

- (NSString *)uniqueNameWithBaseName:(NSString *)inBaseName usingNameExtractor:(NSString * (^)(id bObject,NSUInteger bIndex))nameExtractor
{
	return [self uniqueNameWithBaseName:inBaseName options:NSCaseInsensitiveSearch usingNameExtractor:nameExtractor];
}

- (NSString *)uniqueNameWithBaseName:(NSString *)inBaseName options:(NSStringCompareOptions)inOptions usingNameExtractor:(NSString * (^)(id bObject,NSUInteger bIndex))nameExtractor
{
	return [self uniqueNameWithBaseName:inBaseName format: @"%@ %lu" options:inOptions usingNameExtractor:nameExtractor];
}

- (NSString *)uniqueNameWithBaseName:(NSString *)inBaseName format:(NSString *)inFormat options:(NSStringCompareOptions)inOptions usingNameExtractor:(NSString * (^)(id bObject,NSUInteger bIndex))nameExtractor
{
	if (inBaseName==nil || nameExtractor==nil)
		return nil;
	
	if (inFormat.length==0 ||
		[inFormat rangeOfString:@"%@"].location==NSNotFound ||
		[inFormat rangeOfString:@"%lu"].location==NSNotFound)
		return nil;
	
	NSArray * tNamesArray=[self WB_arrayByMappingObjectsUsingBlock:nameExtractor];
	
	if (tNamesArray==nil)
		return nil;
	
	NSString * tFileName=inBaseName;
	NSUInteger tIndex=1;
	
	do
	{
		if ([tNamesArray indexOfObjectPassingTest:^BOOL(NSString * bName, NSUInteger bIndex, BOOL * bOutStop){
		
			return ([bName compare:tFileName options:inOptions]==NSOrderedSame);
		
		}]==NSNotFound)
			return tFileName;
		
		tFileName=[NSString stringWithFormat:inFormat,inBaseName,(unsigned long)tIndex];
		
		tIndex++;
	}
	while (tIndex<UNIQUENAME_ATTEMPTS_MAX);
	
	NSLog(@"Unable to find a unique name using the basename %@",inBaseName);
	
	return nil;
}

@end
