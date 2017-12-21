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

@implementation WBVersionFormatter

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _versionsHistory=[WBVersionsHistory versionsHistory];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)inCoder
{
    self=[super initWithCoder:inCoder];
    
    if (self!=nil)
    {
        _versionsHistory=[WBVersionsHistory versionsHistory];
    }
    
    return self;
}

#pragma mark -

- (NSString *)stringForObjectValue:(id)inObject
{
    return [self stringFromVersion:inObject];
}

- (BOOL)getObjectValue:(out id *)outObject forString:(NSString *)inString errorDescription:(out NSString **)outDescription
{
    if (outObject==NULL)
    {
        if (outDescription!=NULL)
            ;
        
        return NO;
    }
    
    WBVersion * tVersion=[self versionFromString:inString];
    
    if (tVersion==nil)
    {
        if (outDescription!=NULL)
            ;
        
        return NO;
    }
    
    *outObject=tVersion;
    
    return YES;
}

#pragma mark -

- (NSString *)stringFromVersion:(WBVersion *)inVersion
{
	if (inVersion==nil || [inVersion isKindOfClass:WBVersion.class]==NO)
		return nil;
	
    WBVersionComponents * tComponents=[self.versionsHistory components:WBMajorVersionUnit|WBMinorVersionUnit|WBPatchVersionUnit fromVersion:inVersion];
    
	return [NSString stringWithFormat:@"%lu.%lu.%lu",(unsigned long)tComponents.majorVersion,(unsigned long)tComponents.minorVersion,(unsigned long)tComponents.patchVersion];
}

- (WBVersion *)versionFromString:(NSString *)inString
{
	if ([inString isKindOfClass:NSString.class]==NO || inString.length==0)
		return nil;
	
	static NSCharacterSet * sForbidddenCharacterSet=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sForbidddenCharacterSet=[[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
	});
	
	if ([inString rangeOfCharacterFromSet:sForbidddenCharacterSet].location!=NSNotFound)
		return nil;
	
	NSArray * tStringComponents=[inString componentsSeparatedByString:@"."];
	NSUInteger tCount=tStringComponents.count;
	
	if (tCount>3 || tCount==0)
		return nil;
	
    WBVersionComponents * tComponents=[WBVersionComponents new];
	
	NSUInteger tIndex=0;
	
	// Major
	
	NSString * tComponent=tStringComponents[tIndex];
	
	if (tComponent.length==0)
		return nil;
	
	tComponents.majorVersion=[tComponent integerValue];
	
	tIndex++;
	
	if (tIndex<tCount)
	{
        // Minor
	
        tComponent=tStringComponents[tIndex];
	
        if (tComponent.length==0)
            return nil;
	
        tComponents.minorVersion=[tComponent integerValue];
	
        tIndex++;
	
        if (tIndex<tCount)
		{
            // Patch
	
            tComponent=tStringComponents[tIndex];
	
            if (tComponent.length==0)
                return nil;
	
            tComponents.patchVersion=[tComponent integerValue];
        }
    }
    
	WBVersion * tVersion=[_versionsHistory versionFromComponents:tComponents];
    
    if ([_versionsHistory validateVersion:tVersion]==NO)
        return nil;
    
    return tVersion;
}

@end
