/*
Copyright (c) 2004-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "NSString+Packages.h"

@implementation NSString (Packages)

- (NSString *)PKG_stringByDeletingPathPkgExtension
{
	NSString * tPathExtension=[self pathExtension];
	
	if ([tPathExtension caseInsensitiveCompare:@"pkg"]==NSOrderedSame)
		return [self stringByDeletingPathExtension];
	
	return [self copy];
}

- (NSString *)PKG_stringByRelativizingToPath:(NSString *)inReferencePath
{
	if ([inReferencePath length]==0)
		return [self copy];
	
	if ([self length]==0)
		return @"";
	
	if ([inReferencePath isEqualToString:@"/"]==YES)
		return [self copy];
	
	if ([self characterAtIndex:0]!='/' || [inReferencePath characterAtIndex:0]!='/')
		return [self copy];
	
	NSArray * tComponents=[self componentsSeparatedByString:@"/"];
	NSArray * tReferencePathComponents=[inReferencePath componentsSeparatedByString:@"/"];
	
	if (tComponents==nil || tReferencePathComponents==nil)
		return [self copy];
	
	NSUInteger tCount=[tComponents count];
	NSUInteger tReferenceCount=[tReferencePathComponents count];
	
	NSUInteger i;
	
	for(i=1;i<tCount && i<tReferenceCount;i++)
	{
		if ([tComponents[i] isEqualToString:tReferencePathComponents[i]]==NO)
			break;
	}
	
	NSString * tRelativePath=nil;
	
	if (i<tReferenceCount)
	{
		NSUInteger savedI=i;
		
		for(;i<tReferenceCount;i++)
		{
			if (tRelativePath==nil)
				tRelativePath=@"..";
			else
				tRelativePath=[tRelativePath stringByAppendingPathComponent:@".."];
		}
		
		i=savedI;
	}
	else if (tCount==tReferenceCount)
	{
		tRelativePath=@".";
		
	}
	
	for(;i<tCount;i++)
	{
		if (tRelativePath==nil)
			tRelativePath=[NSString stringWithString:tComponents[i]];
		else
			tRelativePath=[tRelativePath stringByAppendingPathComponent:tComponents[i]];
	}
    
    return tRelativePath;
}

- (NSString *)PKG_stringByAbsolutingWithPath:(NSString *)inReferencePath
{
	if ([inReferencePath length]==0)
		return [self copy];
	
	if ([self length]==0)
		return @"";
	
	if ([self characterAtIndex:0]=='/' || [inReferencePath characterAtIndex:0]!='/')
		return [self copy];
		
	if ([self isEqualToString:@"."]==YES)
		return [inReferencePath copy];
	
	NSString * tAbsolutePath=[inReferencePath copy];
	
	NSArray * tComponents=[self componentsSeparatedByString:@"/"];
	
	if (tComponents!=nil)
	{
		NSUInteger tCount=[tComponents count];
		
		for(NSUInteger i=0;i<tCount;i++)
		{
			NSString * tComponent=tComponents[i];
			
			if ([tComponent isEqualToString:@".."]==YES)
			{
				if ([tAbsolutePath isEqualToString:@"/"]==YES)
					return nil;
				
				tAbsolutePath=[tAbsolutePath stringByDeletingLastPathComponent];
			}
			else if ([tComponent isEqualToString:@"."]==YES)
			{
				continue;
			}
			else
			{
				for(;i<tCount;i++)
					tAbsolutePath=[tAbsolutePath stringByAppendingPathComponent:tComponents[i]];
				
				break;
			}
		}
	}
    
    return tAbsolutePath;
}

@end
