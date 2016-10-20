/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSFileManager+Packages.h"

#include <fts.h>
#include <sys/stat.h>
#include <sys/xattr.h>

NSString * const PKGPackagesFileManagerErrorDomain=@"fr.whitebox.packages.filemanager";

NSString * const PKGFileFinderInfoKey=@XATTR_FINDERINFO_NAME;
NSString * const PKGFileResourceForkKey=@XATTR_RESOURCEFORK_NAME;

@interface NSFileManager (PackagesInternal)

+ (id)PKG_objectFromData:(NSData *)inData extendedAttributeName:(NSString *)inAttributeName;

+ (NSData *)PKG_dataFromObject:(id)inObject extendedAttributeName:(NSString *)inAttributeName;

@end

@implementation NSFileManager (PackagesInternal)

+ (id)PKG_objectFromData:(NSData *)inData extendedAttributeName:(NSString *)inAttributeName
{
	// A COMPLETER
	
	return inData;
}

+ (NSData *)PKG_dataFromObject:(id)inObject extendedAttributeName:(NSString *)inAttributeName
{
	if ([inAttributeName isEqualToString:PKGFileFinderInfoKey]==YES)
	{
		if ([inObject isKindOfClass:[NSData class]]==NO)
			return nil;
	}
	else if ([inAttributeName isEqualToString:PKGFileResourceForkKey]==YES)
	{
		if ([inObject isKindOfClass:[NSData class]]==NO)
			return nil;
	}
	
	// A COMPLETER
	
	return inObject;
}

- (NSDictionary *)PKG_extendedAttributesOfItemAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError
{
	if (inPath==nil)
		return nil;
	
	const char * tCPath=[inPath fileSystemRepresentation];
	
	if (tCPath==NULL)
	{
		// A COMPLETER
		
		return nil;
	}
	
	int tFileDescriptor=open(tCPath,O_RDONLY|O_NOFOLLOW);
	
	if (tFileDescriptor==-1)
	{
		if (errno==ELOOP)	// Symbolic link
			return [NSDictionary dictionary];
		
		if (outError!=NULL)
		{
			switch(errno)
			{
				case EACCES:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoPermissionError userInfo:nil];
					return nil;
					
				case ENOENT:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:nil];
					return nil;
				
				default:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
					return nil;
			}
		}
		
		return nil;
	}
	
	ssize_t tBufferSize=flistxattr(tFileDescriptor,NULL,0,0);
	
	if (tBufferSize==-1)
	{
		if (errno==ENOTSUP)
			return [NSDictionary dictionary];
		
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
		
		close(tFileDescriptor);
		
		return nil;
	}
	
	if (tBufferSize==0)
		return [NSDictionary dictionary];
	
	char * tBuffer=(char *)malloc(tBufferSize*sizeof(char));
	
	if (tBuffer==NULL)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesFileManagerErrorDomain code:PKGFileManagerMemoryCanNotBeAllocated userInfo:nil];

		close(tFileDescriptor);
		
		return nil;
	}
	
	ssize_t tReadBufferSize=flistxattr(tFileDescriptor, tBuffer, tBufferSize, 0);
	
	if (tReadBufferSize==-1)
	{
		if (errno==ENOTSUP)
		{
			free(tBuffer);
			close(tFileDescriptor);
			return [NSDictionary dictionary];
		}
		
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
		
		free(tBuffer);
		
		close(tFileDescriptor);
		
		return nil;
	}
	
	char * tBufferEnd=tBuffer+tReadBufferSize;
	
	NSMutableDictionary * tExtendedAttributes=[NSMutableDictionary dictionary];
	
	for(char * tAttributeNamePtr=tBuffer;tAttributeNamePtr<tBufferEnd;tAttributeNamePtr+=strlen(tAttributeNamePtr)+1)
	{
		NSString * tAttributeName=[NSString stringWithUTF8String:tAttributeNamePtr];
		
		if (tAttributeName==nil)
		{
			// A COMPLETER
			
			tExtendedAttributes=nil;
			goto extended_attributes_bail;
		}
		
		ssize_t tAttributeBufferSize=fgetxattr(tFileDescriptor,tAttributeNamePtr, NULL, 0, 0, 0);
		
		if (tAttributeBufferSize==-1)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
			
			tExtendedAttributes=nil;
			goto extended_attributes_bail;
		}
		
		void * tAttributeBuffer=malloc(tAttributeBufferSize*sizeof(uint8_t));
			
		if (tAttributeBuffer==NULL)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesFileManagerErrorDomain code:PKGFileManagerMemoryCanNotBeAllocated userInfo:nil];
			
			tExtendedAttributes=nil;
			goto extended_attributes_bail;
		}
		
		ssize_t tReadAttributeBufferSize=fgetxattr(tFileDescriptor,tAttributeNamePtr, tAttributeBuffer,tAttributeBufferSize, 0, 0);
		
		if (tReadAttributeBufferSize==-1)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
			
			free(tAttributeBuffer);
			tExtendedAttributes=nil;
			goto extended_attributes_bail;
		}
		
		NSData * tData=[NSData dataWithBytesNoCopy:tAttributeBuffer length:tReadAttributeBufferSize];
		
		if (tData==nil)
		{
			// A COMPLETER
			
			free(tAttributeBuffer);
			tExtendedAttributes=nil;
			goto extended_attributes_bail;
		}
		
		id tObject=[NSFileManager PKG_objectFromData:tData extendedAttributeName:tAttributeName];
		
		if (tObject==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesFileManagerErrorDomain code:PKGFileManagerObjectConversionError userInfo:nil];
			
			tExtendedAttributes=nil;
			goto extended_attributes_bail;
		}
		
		tExtendedAttributes[tAttributeName]=tObject;
	}
	
extended_attributes_bail:
	
	free(tBuffer);

	close(tFileDescriptor);
	
	return [tExtendedAttributes copy];
}

- (BOOL)PKG_setExtendedAttributes:(NSDictionary *)inExtendedAttributes ofItemAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError
{
	if ([inExtendedAttributes count]==0)
		return YES;
	
	if (inPath==nil)
		return NO;
	
	const char * tCPath=[inPath fileSystemRepresentation];
	
	if (tCPath==NULL)
	{
		// A COMPLETER
		
		return nil;
	}
	
	int tFileDescriptor=open(tCPath,O_RDONLY|O_NOFOLLOW);
	
	if (tFileDescriptor==-1)
	{
		int tError=errno;
		
		if (tError==ELOOP)	// Symbolic link
			return [NSDictionary dictionary];
		
		if (outError!=NULL)
		{
			switch(tError)
			{
				case EACCES:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
					return NO;
					
				default:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
					return NO;
			}
		}
		
		return nil;
	}
	
	__block BOOL tSucceeded=YES;
	
	[inExtendedAttributes enumerateKeysAndObjectsUsingBlock:^(NSString * bAttributeName,id bAttributeObject,BOOL * bOutStop){
	
		NSData * tData=[NSFileManager PKG_dataFromObject:bAttributeObject extendedAttributeName:bAttributeName];
		
		if (tData==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesFileManagerErrorDomain code:PKGFileManagerObjectConversionError userInfo:nil];
			
			tSucceeded=NO;
			*bOutStop=YES;
			
			return;
		}
		
		if (fsetxattr(tFileDescriptor, [bAttributeName UTF8String], [tData bytes], [tData length],0,0)==-1)
		{
			if (outError!=NULL)
			{
				switch(errno)
				{
					case EACCES:
						
						*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
						break;
						
					case EROFS:
						
						*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteVolumeReadOnlyError userInfo:nil];
						break;
						
					case ENOSPC:
						
						*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteOutOfSpaceError userInfo:nil];
						break;
						
					default:
						
						*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
						break;
				}
			}
			
			tSucceeded=NO;
			*bOutStop=YES;
			
			return;
		}
	}];
	
	close(tFileDescriptor);
	
	return tSucceeded;
}

- (BOOL)PKG_copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath options:(PKG_NSFileManagerCopyOptions)inOptions error:(NSError *__autoreleasing *)outError
{
	if ((inOptions & PKG_NSDeleteExisting)==PKG_NSDeleteExisting)
	{
		NSError * tError=nil;
		
		if ([self removeItemAtPath:dstPath error:&tError]==NO)
		{
			if (tError==nil)
				return NO;
			
			if ([tError.domain isEqualToString:NSCocoaErrorDomain]==NO)
				return NO;
			
			switch(tError.code)
			{
				case NSFileNoSuchFileError:
					
					break;
					
				default:
					
					NSLog(@"%d",(int)tError.code);
					
					if (outError!=NULL)
						*outError=tError;
					
					return NO;
			}
		}
	}
	
	return [self copyItemAtPath:srcPath toPath:dstPath error:outError];
}

- (BOOL)PKG_isEmptyDirectoryAtPath:(NSString *)inPath
{
	if (inPath==nil)
		return NO;
	const char * tCPath=[inPath fileSystemRepresentation];
	char * const tPath[2]={(char * const)tCPath,NULL};
	
	FTS * ftsp = fts_open(tPath, FTS_PHYSICAL|FTS_NOSTAT, NULL);
	
	if (ftsp == NULL)
		return YES;
	
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
				
			case FTS_DOT:
				
				break;
				
			case FTS_DP:
			case FTS_D:
				
				if (!strcmp(tCPath,tFile->fts_path))
					break;
				
			case FTS_DC:
			case FTS_F:
			case FTS_SL:
			case FTS_SLNONE:
				
				fts_close(ftsp);
				
				return NO;
				
			default:
				break;
		}
	}
	
	fts_close(ftsp);
	
	return YES;
}

- (BOOL)PKG_setPosixPermissions:(mode_t)inPosixPermisions ofItemAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError
{
	if (inPath==nil)
		return NO;
	
	NSError * tError=nil;
	
	NSDictionary * tAttributes=[self attributesOfItemAtPath:inPath error:NULL];
	
	if ([tAttributes.fileType isEqualToString:NSFileTypeSymbolicLink]==YES)
		return YES;
	
	if ([self setAttributes:@{NSFilePosixPermissions:@(inPosixPermisions)} ofItemAtPath:inPath error:&tError]==YES)
		return YES;
	
	if (tError==nil || [tError.domain isEqualToString:NSCocoaErrorDomain]==NO)
	{
		if (outError!=NULL)
			*outError=tError;
		
		return NO;
	}
		
	if ([tAttributes[NSFileImmutable] boolValue]==NO)
		return NO;
	
	if ([self setAttributes:@{NSFileImmutable:@(NO)} ofItemAtPath:inPath error:NULL]==NO)
		return NO;
	
	BOOL tFinalResult=[self setAttributes:@{NSFilePosixPermissions:@(inPosixPermisions)} ofItemAtPath:inPath error:&tError];
	
	if (tFinalResult==NO)
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	[self setAttributes:@{NSFileImmutable:@(NO)} ofItemAtPath:inPath error:NULL];
	
	return tFinalResult;
}

- (BOOL)PKG_setPosixPermissions:(mode_t)inPosixPermisions ofItemAndDescendantsAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError
{
	if (inPath==nil)
		return NO;
	
	const char * tCPath=[inPath fileSystemRepresentation];
	char * const tPath[2]={(char * const)tCPath,NULL};
	
	FTS * ftsp = fts_open(tPath, FTS_PHYSICAL|FTS_NOSTAT, NULL);
	
	if (ftsp == NULL)
	{
		if (outError!=NULL)
		{
			switch(errno)
			{
				case EACCES:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoPermissionError userInfo:nil];
					break;
					
				case ENOENT:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:nil];
					break;
					
				default:
					
					*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
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
			case FTS_D:
			case FTS_SL:
			case FTS_SLNONE:
				continue;
			case FTS_DNR:
			case FTS_ERR:
			case FTS_NS:
				fts_close(ftsp);
				
				if (outError!=NULL)
				{
					// A COMPLETER
				}
				
				return NO;
			default:
				break;
		}
		
		if (chmod(tFile->fts_accpath, inPosixPermisions) == -1)
		{
			if (outError!=NULL)
			{
				switch(errno)
				{
					case EPERM:
						
						*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
						break;
						
					case ENOENT:
						
						*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteInvalidFileNameError userInfo:nil];
						break;
						
					default:
						
						*outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
						break;
				}
			}
			
			fts_close(ftsp);
			
			return NO;
		}
	}
	
	fts_close(ftsp);
	
	if (errno)
	{
		if (outError!=NULL)
		{
			// A COMPLETER
		}
		
		return NO;
	}
	
	return YES;
}

- (BOOL)PKG_setOwnerAccountID:(uid_t)inOwnerAccountID groupAccountID:(gid_t)inGroupAccountID ofItemAndDescendantsAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError
{
	if (inPath==nil)
		return NO;
	
	const char * tCPath=[inPath fileSystemRepresentation];
	char * const tPath[2]={(char * const)tCPath,NULL};
	
	FTS * ftsp = fts_open(tPath, FTS_PHYSICAL, NULL);
	
	if (ftsp == NULL)
	{
		if (outError!=NULL)
		{
			// A COMPLETER
		}
		
		return NO;
	}
	
	FTSENT * tFile;
	while ((tFile = fts_read(ftsp)) != NULL)
	{
		switch (tFile->fts_info)
		{
			case FTS_D:
			case FTS_SL:
			case FTS_SLNONE:
				continue;
			case FTS_DNR:
			case FTS_ERR:
			case FTS_NS:
				fts_close(ftsp);
				
				if (outError!=NULL)
				{
					// A COMPLETER
				}
				
				return NO;
			default:
				break;
		}
		
		if (inOwnerAccountID == tFile->fts_statp->st_uid && inGroupAccountID == tFile->fts_statp->st_gid)
			continue;
		
		if (chown(tFile->fts_accpath, inOwnerAccountID, inGroupAccountID) == -1)
		{
			fts_close(ftsp);
			
			if (outError!=NULL)
			{
				// A COMPLETER
			}
			
			return NO;
		}
	}
	
	fts_close(ftsp);
	
	if (errno)
	{
		if (outError!=NULL)
		{
			// A COMPLETER
		}
		
		return NO;
	}
	
	return YES;
}

@end
