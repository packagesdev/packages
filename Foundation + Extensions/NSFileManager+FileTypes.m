/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "NSFileManager+FileTypes.h"

@implementation NSFileManager (WB_FileTypes)

- (BOOL)WB_fileAtPath:(NSString *)inPath matchesTypes:(NSArray *)inFileTypes traverseLink:(BOOL)yorn
{
	if (inPath==nil || inFileTypes==nil)
		return NO;
	
	NSError * tError=nil;
	NSDictionary * tAttributes=[self attributesOfItemAtPath:(yorn==YES) ? [inPath stringByResolvingSymlinksInPath] : inPath error:&tError];
	
	if (tAttributes==nil)
	{
		if (tError!=nil)
		{
			NSLog(@"Error (%ld) retrieving attributes for file \"%@\": %@",(long)tError.code,inPath,tError.localizedDescription);
		}
		
		return NO;
	}

	NSNumber * tFileType=tAttributes[NSFileHFSTypeCode];
	NSString * tPathExtension=inPath.pathExtension;
	
	for(id tObject in inFileTypes)
	{
		if ([tObject isKindOfClass:NSString.class]==YES && tPathExtension!=nil)
		{
			if ([tPathExtension caseInsensitiveCompare:tObject]==NSOrderedSame)
				return YES;
		}
		else if ([tObject isKindOfClass:NSNumber.class]==YES && tFileType!=nil)
		{
			if ([tFileType isEqualToNumber:tObject]==YES)
				return YES;
		}
	}

	return NO;
}

- (BOOL)WB_fileAtPath:(NSString *)inPath matchesTypes:(NSArray *)inFileTypes
{
	return [self WB_fileAtPath:inPath matchesTypes:inFileTypes traverseLink:YES];
}


@end
