/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPathComponentPatternsRegister.h"

#import "RegexKitLite.h"

#include <fts.h>
#include <sys/stat.h>

@interface PKGPathComponentPatternsRegister ()
{
    NSMutableSet * _fileNamesSet;
    NSMutableSet * _fileNamesRegExSet;
    NSMutableSet * _folderNamesSet;
    NSMutableSet * _folderNamesRegExSet;
}

- (BOOL)removeDirectoryAtPath:(char * const) inPath error:(NSError **)outError;

@end

@implementation PKGPathComponentPatternsRegister

- (instancetype)initWithFilesFilters:(NSArray *)inFilesFilters
{
    self=[super init];
    
    if (self!=nil)
    {
        _fileNamesSet=[NSMutableSet set];
        _fileNamesRegExSet=[NSMutableSet set];
        _folderNamesSet=[NSMutableSet set];
        _folderNamesRegExSet=[NSMutableSet set];
        
        void (^dispatchFilePredicate)(PKGFilePredicate *)=^(PKGFilePredicate *bFilePredicate){
            
            if (bFilePredicate==nil)
                return;
            
            NSString * tPattern=bFilePredicate.pattern;
            
            if ([tPattern length]<2)
                return;
            
            NSMutableSet * tMutableSet;
			BOOL tIsRegularExpression=[bFilePredicate isRegularExpression];
			
            switch(bFilePredicate.fileType)
            {
                case PKGFileSystemTypeFile:
                    
                    tMutableSet=((tIsRegularExpression==NO) ? _fileNamesSet:_fileNamesRegExSet);
                    if ([tMutableSet containsObject:tPattern]==NO)
                        [tMutableSet addObject:tPattern];
                    break;
                    
                case PKGFileSystemTypeFolder:
                    
                    tMutableSet=((tIsRegularExpression==NO) ? _folderNamesSet:_folderNamesRegExSet);
                    if ([tMutableSet containsObject:tPattern]==NO)
                        [tMutableSet addObject:tPattern];
                    break;
                    
                case PKGFileSystemTypeFileorFolder:
                    
                    tMutableSet=((tIsRegularExpression==NO) ? _fileNamesSet:_fileNamesRegExSet);
                    if ([tMutableSet containsObject:tPattern]==NO)
                        [tMutableSet addObject:tPattern];
                    tMutableSet=((tIsRegularExpression==NO) ? _folderNamesSet:_folderNamesRegExSet);
                    if ([tMutableSet containsObject:tPattern]==NO)
                        [tMutableSet addObject:tPattern];
                    break;
            }
        };
        
        for(PKGFileFilter * tFileFilter in inFilesFilters)
        {
            if ([tFileFilter isKindOfClass:[PKGSeparatorFilter class]]==YES || [tFileFilter isEnabled]==NO)
                continue;
            
            if ([tFileFilter isKindOfClass:[PKGDefaultFileFilter class]]==YES)
            {
                for(PKGFilePredicate * tPredicate in ((PKGDefaultFileFilter *)tFileFilter).predicates)
                    dispatchFilePredicate(tPredicate);
            }
            else
            {
                dispatchFilePredicate(tFileFilter.predicate);
            }
        }
    }
    
    return self;
}

#pragma mark -

- (BOOL)patternMatchesFileName:(NSString *)inFileName
{
    if (inFileName==nil)
        return NO;
    
    for(NSString * tPattern in _fileNamesSet)
    {
        if ([inFileName caseInsensitiveCompare:tPattern]==NSOrderedSame)
            return YES;
    }
    
    NSError * tError;
    NSRange tRange=NSMakeRange(0,NSUIntegerMax);    // A VOIR (length of inFileName ?)
    
    for(NSString * tRegExPattern in _fileNamesRegExSet)
    {
        if ([inFileName isMatchedByRegex:tRegExPattern options:RKLNoOptions inRange:tRange error:&tError]==YES)
            return YES;
    }

    return NO;
}

- (BOOL)patternMatchesFolderName:(NSString *)inFolderName
{
    if (inFolderName==nil)
        return NO;
    
     for(NSString * tPattern in _folderNamesSet)
     {
         if ([inFolderName caseInsensitiveCompare:tPattern]==NSOrderedSame)
             return YES;
     }
     
     NSError * tError;
     NSRange tRange=NSMakeRange(0,NSUIntegerMax);    // A VOIR (length of inFolderName ?)
     
     for(NSString * tRegExPattern in _folderNamesRegExSet)
     {
         if ([inFolderName isMatchedByRegex:tRegExPattern options:RKLNoOptions inRange:tRange error:&tError]==YES)
             return YES;
     }
     
     return NO;
}

#pragma mark -

- (BOOL)removeDirectoryAtPath:(char * const) inPath error:(NSError **)outError
{
	char * const tPath[2]={inPath,NULL};
	FTS * ftsp=fts_open(tPath, FTS_PHYSICAL, NULL);
	
	if (ftsp == NULL)
	{
		if (outError!=NULL)
		{
			NSError * tUnderlyingError=[NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];;
			NSString * tFilePath=[[NSFileManager defaultManager] stringWithFileSystemRepresentation:inPath length:strlen(inPath)];
			
			switch(errno)
			{
				case ENOENT:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSFilePathErrorKey:tFilePath ,
																												NSUnderlyingErrorKey:tUnderlyingError}];
					
					break;
					
				default:
					
					*outError=nil;
					
					break;
			}
		}
		
		return NO;
	}
	
	FTSENT * tFile;
	
	while ((tFile = fts_read(ftsp)) != NULL)
	{
		__uint32_t tFlags;
		
		switch (tFile->fts_info)
		{
			case FTS_DNR:
			case FTS_ERR:
			case FTS_NS:
				
				if (outError!=NULL)
					*outError=nil;
				
				fts_close(ftsp);
				
				return NO;
				
			case FTS_DP:
				
				tFlags=tFile->fts_statp->st_flags;
				
				if ((tFlags & (UF_APPEND|UF_IMMUTABLE)) &&
					!(tFlags & (SF_APPEND|SF_IMMUTABLE)))
				{
					chflags(tFile->fts_accpath,tFlags &= ~(UF_APPEND|UF_IMMUTABLE));
				}
				
				if (rmdir(tFile->fts_accpath)==-1)
				{
					if (outError!=NULL)
					{
						NSError * tUnderlyingError=[NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];;
						NSString * tFilePath=[[NSFileManager defaultManager] stringWithFileSystemRepresentation:tFile->fts_path length:strlen(tFile->fts_path)];
						
						switch(errno)
						{
							case ENOENT:
								
								*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSFilePathErrorKey:tFilePath ,
																																	 NSUnderlyingErrorKey:tUnderlyingError}];
								
								break;
								
							case EROFS:
								
								*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteVolumeReadOnlyError userInfo:@{NSFilePathErrorKey:tFilePath ,
																																	 NSUnderlyingErrorKey:tUnderlyingError}];
								
								break;
								
							default:
								
								*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSFilePathErrorKey:tFilePath ,
																															  NSUnderlyingErrorKey:tUnderlyingError}];
								
								break;
						}
					}
					
					return NO;
				}
				
				break;
				
			case FTS_SLNONE:
			case FTS_SL:
			case FTS_F:
				
				tFlags=tFile->fts_statp->st_flags;
				
				if ((tFlags & (UF_APPEND|UF_IMMUTABLE)) &&
					!(tFlags & (SF_APPEND|SF_IMMUTABLE)))
				{
					chflags(tFile->fts_accpath,tFlags &= ~(UF_APPEND|UF_IMMUTABLE));
				}
				
				if (unlink(tFile->fts_accpath)==-1)
				{
					if (outError!=NULL)
					{
						NSError * tUnderlyingError=[NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];;
						NSString * tFilePath=[[NSFileManager defaultManager] stringWithFileSystemRepresentation:tFile->fts_path length:strlen(tFile->fts_path)];
						
						switch(errno)
						{
							case EACCES:
								
								*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:@{NSFilePathErrorKey:tFilePath,
																																   NSUnderlyingErrorKey:tUnderlyingError}];
								
								break;
							
							case ENOENT:
								
								*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSFilePathErrorKey:tFilePath ,
																															NSUnderlyingErrorKey:tUnderlyingError}];
								
								break;
								
							case EROFS:
								
								*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteVolumeReadOnlyError userInfo:@{NSFilePathErrorKey:tFilePath ,
																																	 NSUnderlyingErrorKey:tUnderlyingError}];
								
								break;
								
							default:
								
								*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSFilePathErrorKey:tFilePath ,
																															  NSUnderlyingErrorKey:tUnderlyingError}];
								
								break;
						}
					}
					
					return NO;
				}
				
				break;
				
			default:
				break;
		}
	}
	
	fts_close(ftsp);
	
	return YES;
}

- (BOOL)filterContentsAtPath:(NSString *)inPath error:(NSError **)outError
{
	if (inPath==nil)
		return NO;
	
	char * tPath[2]={(char *) [inPath fileSystemRepresentation],NULL};
	FTS * ftsp=fts_open(tPath, FTS_PHYSICAL, NULL);
	
	if (ftsp == NULL)
	{
		if (outError!=NULL)
		{
			NSError * tUnderlyingError=[NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];;
			NSString * tFilePath=[[NSFileManager defaultManager] stringWithFileSystemRepresentation:tPath[0] length:strlen(tPath[0])];
			
			switch(errno)
			{
				case ENOENT:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSFilePathErrorKey:tFilePath ,
																												NSUnderlyingErrorKey:tUnderlyingError}];
					
					break;
					
				default:
					
					*outError=nil;
					
					break;
			}
		}
		
		return NO;
	}
	
	FTSENT * tFile;
	
	while ((tFile = fts_read(ftsp)) != NULL)
	{
		switch (tFile->fts_info)
		{
			case FTS_DNR:
			case FTS_ERR:
			case FTS_NS:
				
				fts_close(ftsp);
				
				return NO;
				
			case FTS_DP:
				
				// Folder
				
				if ([self patternMatchesFolderName:[NSString stringWithUTF8String:tFile->fts_name]]==YES)
				{
					NSError * tError;
					
					if ([self removeDirectoryAtPath:tFile->fts_path error:&tError]==NO)
					{
						if (outError!=NULL)
							*outError=tError;
						
						fts_close(ftsp);
						
						return NO;
					}
				}
				
				break;
				
			case FTS_F:
				
				// File
				
				if ([self patternMatchesFileName:[NSString stringWithUTF8String:tFile->fts_name]]==YES)
				{
					if (unlink(tFile->fts_path)==-1)
					{
						if (errno==EPERM)
						{
							chown(tFile->fts_path,0,0);
							if (unlink(tFile->fts_path)==0)
								break;
						}
						
						if (outError!=NULL)
						{
							NSError * tUnderlyingError=[NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];;
							NSString * tFilePath=[[NSFileManager defaultManager] stringWithFileSystemRepresentation:tFile->fts_accpath length:strlen(tFile->fts_path)];
							
							switch(errno)
							{
								case EACCES:
									
									*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:@{NSFilePathErrorKey:tFilePath,
																																	   NSUnderlyingErrorKey:tUnderlyingError}];
									
									break;
									
								case ENOENT:
									
									*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSFilePathErrorKey:tFilePath ,
																																NSUnderlyingErrorKey:tUnderlyingError}];
									
									break;
									
								case EROFS:
									
									*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteVolumeReadOnlyError userInfo:@{NSFilePathErrorKey:tFilePath ,
																																		 NSUnderlyingErrorKey:tUnderlyingError}];
									
									break;
									
								default:
									
									*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSFilePathErrorKey:tFilePath ,
																																  NSUnderlyingErrorKey:tUnderlyingError}];
									
									break;
							}
						}
					}
				}
				
				break;
				
			default:
				
				break;
		}
	}
	
	fts_close(ftsp);
	
	return YES;
}

@end
