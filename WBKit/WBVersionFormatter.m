/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WBVersionFormatter.h"

#import "WBVersion_Private.h"

@implementation WBVersionFormatter

- (NSString *)stringFromVersion:(WBVersion *)inVersion
{
	if (inVersion==nil)
		return nil;
	
	return [NSString stringWithFormat:@"%lu.%lu.%lu",(unsigned long)inVersion.majorVersion,(unsigned long)inVersion.minorVersion,(unsigned long)inVersion.bugFixVersion];
}

- (WBVersion *)versionFromString:(NSString *)inString
{
	if (inString.length==0)
		return nil;
	
	static NSCharacterSet * sForbidddenCharacterSet=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sForbidddenCharacterSet=[[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
	});
	
	if ([inString rangeOfCharacterFromSet:sForbidddenCharacterSet].location!=NSNotFound)
		return nil;
	
	NSArray * tComponents=[inString componentsSeparatedByString:@"."];
	NSUInteger tCount=tComponents.count;
	
	if (tCount>3 || tCount==0)
		return nil;
	
	WBVersion * tVersion=[WBVersion new];
	
	NSUInteger tIndex=0;
	
	// Major
	
	NSString * tComponent=tComponents[tIndex];
	
	if (tComponent.length==0)
		return nil;
	
	tVersion.majorVersion=[tComponent integerValue];
	
	tIndex++;
	
	if (tIndex>=tCount)
		return tVersion;
	
	// Minor
	
	tComponent=tComponents[tIndex];
	
	if (tComponent.length==0)
		return nil;
	
	tVersion.minorVersion=[tComponent integerValue];
	
	tIndex++;
	
	if (tIndex>=tCount)
		return tVersion;
	
	// BugFix
	
	tComponent=tComponents[tIndex];
	
	if (tComponent.length==0)
		return nil;
	
	tVersion.bugFixVersion=[tComponent integerValue];
	
	return tVersion;
}

@end