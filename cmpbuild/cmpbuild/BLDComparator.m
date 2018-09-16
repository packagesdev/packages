/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BLDComparator.h"

#import "PKGArchive.h"

#import "NSString+Random.h"

@interface BLDComparator ()
{
	NSFileManager * _fileManager;
}

- (BOOL)isXarAtPath:(NSString *)inPath;

- (BOOL)compareContentsOfDirectoryAtPath:(NSString *)inPath withContentsOfDirectoryAtPath:(NSString *)inOtherPath withinArchive:(BOOL)inWithinArchive;

- (BOOL)compareContentsOfXarArchiveAtPath:(NSString *)inPath withContentsOfXarArchiveAtPath:(NSString *)inOtherPath;

@end

@implementation BLDComparator

+ (void)usage
{
	(void)fprintf(stderr, "Usage: %s directory --expected expected_directory\n",__CMPBUILD_NAME__);
}

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_fileManager=[NSFileManager defaultManager];
	}
	
	return self;
}

#pragma mark -

- (BOOL)isXarAtPath:(NSString *)inPath
{
	if (inPath==nil)
		return NO;
	
	const char * tCFilePath=[inPath fileSystemRepresentation];
	
	if (tCFilePath==NULL)
		return NO;
	
	// Check the Magic Cookie
	
	int fd=open(tCFilePath,O_RDONLY);
	
	if (fd==0)
		return NO;
	
	char tMagicCookie[4];
	
	size_t tReadSize=read(fd,tMagicCookie,4*sizeof(char));
	
	close(fd);
	
	if (tReadSize!=4)
		return NO;
	
	if (tMagicCookie[0]=='x' &&
		tMagicCookie[1]=='a' &&
		tMagicCookie[2]=='r' &&
		tMagicCookie[3]=='!')
	{
		return YES;
	}
	
	return NO;
}

#pragma mark -

- (BOOL)compareContentsOfXarArchiveAtPath:(NSString *)inPath withContentsOfXarArchiveAtPath:(NSString *)inOtherPath
{
	if (inPath==nil || inOtherPath==nil)
		return NO;
	
	PKGArchive * tArchive=[PKGArchive archiveAtPath:inPath];
	NSString * tExtractionFolderPath=[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString randomFolderName]];
	
	if ([_fileManager createDirectoryAtPath:tExtractionFolderPath withIntermediateDirectories:NO attributes:nil error:NULL]==NO)
	{
		(void)fprintf(stderr, "%s: Can not create directory at \"%s\"\n",__CMPBUILD_NAME__,[tExtractionFolderPath UTF8String]);
		
		return NO;
	}
	
	if ([tArchive extractToPath:tExtractionFolderPath error:NULL]==NO)
	{
		(void)fprintf(stderr, "%s: Extraction failed for archive \"%s\"\n",__CMPBUILD_NAME__,[inPath UTF8String]);
		
		[_fileManager removeItemAtPath:tExtractionFolderPath error:NULL];
		
		return NO;
	}
	
	PKGArchive * tOtherArchive=[PKGArchive archiveAtPath:inOtherPath];
	NSString * tOtherExtractionFolderPath=[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString randomFolderName]];
	
	if ([_fileManager createDirectoryAtPath:tOtherExtractionFolderPath withIntermediateDirectories:NO attributes:nil error:NULL]==NO)
	{
		(void)fprintf(stderr, "%s: Can not create directory at \"%s\"\n",__CMPBUILD_NAME__,[tOtherExtractionFolderPath UTF8String]);
		
		[_fileManager removeItemAtPath:tExtractionFolderPath error:NULL];
		
		return NO;
	}
	
	if ([tOtherArchive extractToPath:tOtherExtractionFolderPath error:NULL]==NO)
	{
		(void)fprintf(stderr, "%s: Extraction failed for archive \"%s\"\n",__CMPBUILD_NAME__,[inOtherPath UTF8String]);
		
		[_fileManager removeItemAtPath:tExtractionFolderPath error:NULL];
		[_fileManager removeItemAtPath:tOtherExtractionFolderPath error:NULL];
		
		return NO;
	}
	
	BOOL tResult=[self compareContentsOfDirectoryAtPath:tExtractionFolderPath withContentsOfDirectoryAtPath:tOtherExtractionFolderPath withinArchive:YES];
	
	[_fileManager removeItemAtPath:tExtractionFolderPath error:NULL];
	[_fileManager removeItemAtPath:tOtherExtractionFolderPath error:NULL];
	
	return tResult;
}

- (BOOL)compareContentsOfDirectoryAtPath:(NSString *)inPath withContentsOfDirectoryAtPath:(NSString *)inOtherPath withinArchive:(BOOL)inWithinArchive
{
	NSArray * tDirectoryContents=[_fileManager contentsOfDirectoryAtPath:inPath error:NULL];
	
	if (tDirectoryContents==nil)
	{
		(void)fprintf(stderr, "%s: Can not retrieve contents of directory \"%s\"\n",__CMPBUILD_NAME__,[[inPath substringFromIndex:[self.buildDirectoryPath length]] UTF8String]);
		return NO;
	}
	
	NSArray * tOtherDirectoryContents=[_fileManager contentsOfDirectoryAtPath:inOtherPath error:NULL];
	
	if (tOtherDirectoryContents==nil)
	{
		(void)fprintf(stderr, "%s: Can not retrieve contents of directory \"%s\"\n",__CMPBUILD_NAME__,[[inOtherPath substringFromIndex:[self.expectedBuildDirectoryPath length]] UTF8String]);
		return NO;
	}
	
	NSSet * (^filteredContentsSet)(NSArray *)=^NSSet *(NSArray * bArray){
		
		if(bArray==nil)
			return nil;
		
		NSMutableSet * tMutableSet=[NSMutableSet setWithArray:bArray];
		
		[tMutableSet removeObject:@".DS_Store"];
		
		return [tMutableSet copy];
		
	};
	
	NSSet * tContentsSet=filteredContentsSet(tDirectoryContents);
	NSSet * tOtherContentsSet=filteredContentsSet(tDirectoryContents);
	
	if ([tContentsSet isEqualToSet:tOtherContentsSet]==NO)
	{
		NSUInteger tCount=[tContentsSet count];
		NSUInteger tOtherCount=[tOtherContentsSet count];
		
		if (tCount>tOtherCount)
		{
			NSMutableSet * tExtraSet=[tContentsSet mutableCopy];
			
			[tExtraSet minusSet:tOtherContentsSet];
			
			for(NSString * tLastPathComponent in tExtraSet)
			{
				(void)fprintf(stderr, "%s: Extra file \"%s\"\n",__CMPBUILD_NAME__,[tLastPathComponent UTF8String]);
			}
			
			return NO;
		}
		
		if (tCount<tOtherCount)
		{
			NSMutableSet * tMissingSet=[tOtherContentsSet mutableCopy];
			
			[tMissingSet minusSet:tContentsSet];
			
			for(NSString * tLastPathComponent in tMissingSet)
			{
				(void)fprintf(stderr, "%s: Missing file \"%s\"\n",__CMPBUILD_NAME__,[tLastPathComponent UTF8String]);
			}
			
			return NO;
		}
		
		for(NSString * tLastPathComponent in tOtherContentsSet)
		{
			if ([tContentsSet containsObject:tLastPathComponent]==NO)
			{
				(void)fprintf(stderr, "%s: Missing file \"%s\"\n",__CMPBUILD_NAME__,[tLastPathComponent UTF8String]);
			}
		}
		
		return NO;
	}
	
	for(NSString * tLastPathComponent in tContentsSet)
	{
		NSString * tFilePath=[inPath stringByAppendingPathComponent:tLastPathComponent];
		NSDictionary *tAttributes=[_fileManager attributesOfItemAtPath:tFilePath error:NULL];
		
		if (tAttributes==nil)
		{
			(void)fprintf(stderr, "%s: Can not retrieve attributes of \"%s\"\n",__CMPBUILD_NAME__,[[tFilePath substringFromIndex:[self.buildDirectoryPath length]] UTF8String]);
			return NO;
		}
		
		NSString * tOtherFilePath=[inOtherPath stringByAppendingPathComponent:tLastPathComponent];
		NSDictionary *tOtherAttributes=[_fileManager attributesOfItemAtPath:tOtherFilePath error:NULL];
		
		if (tOtherAttributes==nil)
		{
			(void)fprintf(stderr, "%s: Can not retrieve attributes of \"%s\"\n",__CMPBUILD_NAME__,[[tOtherFilePath substringFromIndex:[self.expectedBuildDirectoryPath length]] UTF8String]);
			return NO;
		}
		
		if ([tAttributes[NSFileType] isEqualToString:tOtherAttributes[NSFileType]]==NO)
		{
			if ([tOtherAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]==YES)
			{
				(void)fprintf(stderr, "%s: \"%s\" was expected to be a directory\n",__CMPBUILD_NAME__,[[tFilePath substringFromIndex:[self.buildDirectoryPath length]] UTF8String]);
			}
			else if ([tOtherAttributes[NSFileType] isEqualToString:NSFileTypeRegular]==YES)
			{
				(void)fprintf(stderr, "%s: \"%s\" was expected to be a regular file\n",__CMPBUILD_NAME__,[[tFilePath substringFromIndex:[self.buildDirectoryPath length]] UTF8String]);
			}
			else
			{
				(void)fprintf(stderr, "%s: \"%s\" type does not match expected type: %s\n",__CMPBUILD_NAME__,[[tFilePath substringFromIndex:[self.buildDirectoryPath length]] UTF8String],[tOtherAttributes[NSFileType] UTF8String]);
			}
			
			return NO;
		}
		
		if ([tAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]==YES)
		{
			if ([self compareContentsOfDirectoryAtPath:tFilePath withContentsOfDirectoryAtPath:tOtherFilePath withinArchive:inWithinArchive]==NO)
				return NO;
		}
		else
		{
			if ([self isXarAtPath:tOtherFilePath]==YES && inWithinArchive==NO)
			{
				if ([self isXarAtPath:tFilePath]==NO)
				{
					(void)fprintf(stderr, "%s: \"%s\" was expected to be a xar archive\n",__CMPBUILD_NAME__,[[tFilePath substringFromIndex:[self.buildDirectoryPath length]] UTF8String]);
					
					return NO;
				}
				
				if ([self compareContentsOfXarArchiveAtPath:tFilePath withContentsOfXarArchiveAtPath:tOtherFilePath]==NO)
					return NO;
			}
			else
			{
				if (inWithinArchive==YES)
				{
					// Check for special files
					
					if ([tLastPathComponent isEqualToString:@"Bom"]==YES)
					{
						// A COMPLETER
						
						return YES;
					}
					else
					if ([tLastPathComponent isEqualToString:@"PackageInfo"]==YES)
					{
						// A COMPLETER
					}
					else if ([tLastPathComponent isEqualToString:@"distribution"]==YES)
					{
						// A COMPLETER
					}
					
					
					
					// A COMPLETER
				}
				
				if ([_fileManager contentsEqualAtPath:tFilePath andPath:tOtherFilePath]==NO)
				{
					(void)fprintf(stderr, "%s: \"%s\" contents does not match the expected one\n",__CMPBUILD_NAME__,[[tFilePath substringFromIndex:[self.buildDirectoryPath length]] UTF8String]);
					
					return NO;
				}
			}
		}
	}
	
	return YES;
}

- (BOOL)compare
{
	if (self.buildDirectoryPath==nil)
	{
		(void)fprintf(stderr, "%s: build directory path is not set\n",__CMPBUILD_NAME__);
		return NO;
	}
	
	if (self.expectedBuildDirectoryPath==nil)
	{
		(void)fprintf(stderr, "%s: expected build directory path is not set\n",__CMPBUILD_NAME__);
		return NO;
	}
	
	BOOL tIsDirectory;
	BOOL tIsOtherDirectory;
	
	if ([_fileManager fileExistsAtPath:self.buildDirectoryPath isDirectory:&tIsDirectory]==NO)
	{
		(void)fprintf(stderr, "%s: Directory not found at path \"%s\"\n",__CMPBUILD_NAME__,[self.buildDirectoryPath UTF8String]);
		return NO;
	}
	
	if (tIsDirectory==NO)
	{
		(void)fprintf(stderr, "%s: \"%s\" is not a directory\n",__CMPBUILD_NAME__,[self.buildDirectoryPath UTF8String]);
		return NO;
	}
	
	if ([_fileManager fileExistsAtPath:self.expectedBuildDirectoryPath isDirectory:&tIsOtherDirectory]==NO)
	{
		(void)fprintf(stderr, "%s: Directory not found at path \"%s\"\n",__CMPBUILD_NAME__,[self.expectedBuildDirectoryPath UTF8String]);
		return NO;
	}
	
	if (tIsOtherDirectory==NO)
	{
		(void)fprintf(stderr, "%s: \"%s\" is not a directory\n",__CMPBUILD_NAME__,[self.expectedBuildDirectoryPath UTF8String]);
		return NO;
	}
	
	return [self compareContentsOfDirectoryAtPath:self.buildDirectoryPath withContentsOfDirectoryAtPath:self.expectedBuildDirectoryPath withinArchive:NO];
}

@end
