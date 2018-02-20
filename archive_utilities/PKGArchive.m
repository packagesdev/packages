/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* For ixar_extract_to_bufferz */

/*
 * Copyright (c) 2005 Rob Braun
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Rob Braun nor the names of his contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * 03-Apr-2005
 * DRI: Rob Braun <bbraun@opendarwin.org>
 */
/*
 * Portions Copyright 2006, Apple Computer, Inc.
 * Christopher Ryan <ryanc@apple.com>
 */


#import "PKGArchive.h"

#include "xar.h"
#include "arcmod.h"

#include <fts.h>

NSString * const PKGArchiveErrorDomain=@"fr.whitebox.archive.xar";

NSString * const PKGArchiveErrorFilePath=@"Path";


int32_t ixar_extract_tobuffersz(xar_t x, xar_file_t f, char **buffer, size_t *size)
{
	const char *sizestring = NULL;
	
	if(0 != xar_prop_get(f,"data/size",&sizestring))
		return -1;
	
	*size = (size_t)strtoull(sizestring, (char **)NULL, 10);
	
	*buffer = malloc(*size);
	
	if(!(*buffer))
		return -1;
	
	return xar_arcmod_extract(x,f,NULL,*buffer,*size);
}


@interface PKGArchive ()

	@property (copy,readwrite) NSString * path;

@end


static int32_t PKGArchiveSignatureCallback(xar_signature_t inSignature, void *context, uint8_t * inData, uint32_t inLength, uint8_t **signed_data, uint32_t *signed_len)
{
	PKGArchive * tArchive=(__bridge PKGArchive *) context;
	
	NSData * tSignedData=[tArchive.delegate archive:tArchive signatureForData:[NSData dataWithBytes:inData length:inLength]];
	
	if (tSignedData==nil)
		return -1;
	
	*signed_len=(uint32_t) [tSignedData length];
	
	*signed_data = (uint8_t *) malloc(*signed_len);
	
	memcpy(*signed_data,[tSignedData bytes], *signed_len);
	
	return 0;
}


@implementation PKGArchive

+ (instancetype)archiveAtPath:(NSString *)inPath
{
	return [[PKGArchive alloc] initWithPath:inPath];
}

+ (instancetype)archiveAtURL:(NSURL *)inURL
{
	return [[PKGArchive alloc] initWithURL:inURL];
}

- (instancetype)initWithPath:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_path=inPath;
	}
	
	return self;
}

- (instancetype)initWithURL:(NSURL *)inURL
{
	if (inURL==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		// A COMPLETER
	}
	
	return self;
}

#pragma mark -

- (BOOL)isFlatPackage
{
	if (self.path==nil)
		return NO;
	
	const char * tCFilePath=[self.path fileSystemRepresentation];
		
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
		// Check that it's a pure package xar archive
		
		BOOL isFlatPackage=NO;
		
		xar_t tArchive=xar_open(tCFilePath,READ);
		
		if (tArchive==NULL)
			return NO;
		
		xar_iter_t tIterator=xar_iter_new();
		
		if (tIterator!=NULL)
		{
			for(xar_file_t tFile=xar_file_first(tArchive,tIterator);tFile!=NULL;tFile=xar_file_next(tIterator))
			{
				const char * tValue=NULL;
				
				xar_prop_get(tFile,"name",&tValue);
				
				if (!strcmp(tValue,"Distribution"))		// It's a Distribution Script, not a FLAT package
				{
					xar_iter_free(tIterator);
					xar_close(tArchive);
					
					return NO;
				}
				
				if (!strcmp(tValue,"PackageInfo"))
				{
					// Check whether it's a file
					
					xar_prop_get(tFile,"type",&tValue);
					
					if (!strcmp(tValue,"file"))
						isFlatPackage=YES;
				}
			}
			
			xar_iter_free(tIterator);
		}
		
		xar_close(tArchive);
		
		return isFlatPackage;
	}
	
	return NO;
}

#pragma mark -

- (int)preflightContentsAtPath:(NSString *) inPath
{
	char * tPath[2]={(char *) [inPath fileSystemRepresentation],NULL};
	
	FTS * ftsp=fts_open(tPath, FTS_PHYSICAL, 0);
	
	if (ftsp == NULL)
		return errno;
	
	FTSENT * tFile;
	
	while ((tFile = fts_read(ftsp)) != NULL)
	{
		mode_t tMode;
		
		switch (tFile->fts_info)
		{
			case FTS_D:
				tMode=S_IRWXU+S_IRGRP+S_IXGRP+S_IROTH+S_IXOTH;	// 0755
				
				break;
			case FTS_DP:
			case FTS_SL:
			case FTS_SLNONE:
				continue;
			case FTS_DNR:
			case FTS_ERR:
			case FTS_NS:
				fts_close(ftsp);
				
				return errno;
			default:				// At least 0644
				
				if ((tFile->fts_statp->st_mode & 0700) < (S_IRUSR+S_IWUSR))
				{
					tMode=S_IRUSR+S_IWUSR;
				}
				else
				{
					tMode=(tFile->fts_statp->st_mode & 0700);
				}
				
				if ((tFile->fts_statp->st_mode & 0070) < S_IRGRP)
				{
					tMode+=S_IRGRP;
				}
				else
				{
					tMode+=(tFile->fts_statp->st_mode & 0070);
				}
				
				if ((tFile->fts_statp->st_mode & 0007) < S_IROTH)
				{
					tMode+=S_IROTH;
				}
				else
				{
					tMode+=(tFile->fts_statp->st_mode & 0007);
				}
				
				break;
		}
		
		// Set Permissions
		
		if (tMode != tFile->fts_statp->st_mode)
		{
			if (chmod(tFile->fts_accpath, tMode) == -1)
				return errno;
		}
	}
	
	fts_close(ftsp);
	
	return 0;
}

#pragma mark -

- (BOOL)extractFile:(NSString *)inContentsPath intoData:(out NSData **)outData error:(NSError **)outError
{
	if (inContentsPath==nil || outData==NULL)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorInvalidParameter
									  userInfo:nil];
		
		return NO;
	}
	
	if (self.path==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorFilePathNotSet
									  userInfo:nil];
		
		return NO;
	}
	
	xar_t tArchive=xar_open([self.path fileSystemRepresentation],READ);
	
	if (tArchive==NULL)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:([[NSFileManager defaultManager] fileExistsAtPath:self.path]==NO) ? PKGArchiveErrorFileNotFound:PKGArchiveErrorFileNotReadable
									  userInfo:nil];
		
		return NO;
	}
	
	xar_iter_t tIterator=xar_iter_new();
	
	if (tIterator==NULL)
	{
		xar_close(tArchive);
		
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorMemoryAllocationFailed
									  userInfo:nil];
		
		return NO;
	}
	
	*outData=nil;
	
	for(xar_file_t tFile=xar_file_first(tArchive,tIterator);tFile!=NULL;tFile=xar_file_next(tIterator))
	{
		const char * tValue=NULL;
		
		xar_prop_get(tFile,"name",&tValue);
		
		if (!strcmp(tValue,[inContentsPath UTF8String]))
		{
			char * tBuffer;
			size_t tSize;
			
			// Check it's a file
			
			xar_prop_get(tFile,"type",&tValue);
			
			if (!strcmp(tValue,"file"))
			{
				if (ixar_extract_tobuffersz(tArchive,tFile,&tBuffer,&tSize)==0)
				{
					*outData=[NSData dataWithBytesNoCopy:tBuffer length:tSize];
				}
				else
				{
					xar_iter_free(tIterator);
					xar_close(tArchive);
					
					if (outError!=NULL)
						*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
													  code:PKGArchiveErrorFileCanNotBeExtracted
												  userInfo:@{PKGArchiveErrorFilePath:inContentsPath}];
					
					return NO;
				}
			}
			
			break;
		}
	}
	
	xar_iter_free(tIterator);
	xar_close(tArchive);
	
	if ((*outData)==nil)
	{
		if (outError!=NULL)
			;// A COMPLETER
		
		return NO;
	}
	
	return YES;
}

- (BOOL)extractToPath:(NSString *) inFolderPath error:(NSError **)outError
{
	if (self.path==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorFilePathNotSet
									  userInfo:nil];
		
		return NO;
	}
	
	if (inFolderPath==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorInvalidParameter
									  userInfo:nil];
		
		return NO;
	}
		
	xar_t tArchive=xar_open([self.path fileSystemRepresentation],READ);
	
	if (tArchive==NULL)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:([[NSFileManager defaultManager] fileExistsAtPath:self.path]==NO) ? PKGArchiveErrorFileNotFound:PKGArchiveErrorFileNotReadable
									  userInfo:nil];
		
		return NO;
	}
	
	xar_iter_t tIterator=xar_iter_new();
	
	if (tIterator==NULL)
	{
		xar_close(tArchive);
		
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorMemoryAllocationFailed
									  userInfo:nil];
		
		return NO;
	}
	
	for (xar_file_t tFile=xar_file_first(tArchive,tIterator);tFile!=NULL;tFile=xar_file_next(tIterator))
	{
		NSString * tFileRelativePath= [NSString stringWithUTF8String:xar_get_path(tFile)];
		
		int32_t tError=xar_extract_tofile(tArchive,tFile,[[inFolderPath stringByAppendingPathComponent:tFileRelativePath] fileSystemRepresentation]);
		
		if (tError!=0)
		{
			xar_iter_free(tIterator);
			xar_close(tArchive);
			
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
											  code:PKGArchiveErrorFileCanNotBeExtracted
										  userInfo:@{PKGArchiveErrorFilePath:tFileRelativePath}];
			
			return NO;
		}
	}
	
	xar_iter_free(tIterator);
	xar_close(tArchive);
	
	return YES;
}

- (BOOL)createArchiveWithContentsAtPath:(NSString *)inContentsPath error:(NSError **)outError
{
	if (self.path==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorFilePathNotSet
									  userInfo:nil];
		
		return NO;
	}
	
	if (inContentsPath==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorInvalidParameter
									  userInfo:nil];
		
		return NO;
	}
	
	// Check that there is a directory at the provided path
	
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	BOOL tisDirectory;
	
	if ([tFileManager fileExistsAtPath:inContentsPath isDirectory:&tisDirectory]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorSourceNotFound
									  userInfo:nil];
		
		return NO;
	}
	
	if (tisDirectory==NO)
	{
		if (outError!=NULL)
			;// A COMPLETER
		
		return NO;
	}
	
	// Check whether the file already exists
	
	if ([tFileManager fileExistsAtPath:self.path]==YES)
	{
		NSError * tError;
		
		if ([tFileManager removeItemAtPath:self.path error:&tError]==NO)
		{
			if (outError!=NULL)
				*outError=tError;
			
			return NO;
		}
	}
	
	xar_t tArchive=xar_open([self.path fileSystemRepresentation],WRITE);
	
	if (tArchive==NULL)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
										  code:PKGArchiveErrorFileCanNotBeCreated
									  userInfo:nil];
		
		return NO;
	}
	
	if ([tFileManager changeCurrentDirectoryPath:inContentsPath]==NO)
	{
		if (outError!=NULL)
			;// A COMPLETER
		
		xar_close(tArchive);
		
		return NO;
	}
	
	if (self.delegate!=nil && [self.delegate archiveShouldSign:self]==YES)
	{
		int32_t tSignatureSize=[self.delegate signatureSizeForArchive:self];
		
		if (tSignatureSize==0)
		{
			if (outError!=NULL)
				/**outError=[NSError errorWithDomain:PKGArchiveErrorDomain
											  code:PKGArchiveErrorMemoryAllocationFailed
										  userInfo:nil]*/;
			
			xar_close(tArchive);
			
			return NO;
		}
		
		xar_signature_t tSignature=xar_signature_new(tArchive,"RSA", tSignatureSize,PKGArchiveSignatureCallback,(__bridge void *)self);
		
		if (tSignature==NULL)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
											  code:PKGArchiveErrorMemoryAllocationFailed
										  userInfo:nil];
			
			xar_close(tArchive);
			
			return NO;
		}
		
		NSArray * tCertificatesDataArray=[self.delegate certificatesDataForArchive:self];
		
		if (tCertificatesDataArray==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGArchiveErrorDomain
											  code:PKGArchiveErrorCertificatesCanNotBeRetrieved
										  userInfo:nil];
			
			xar_close(tArchive);
			
			return NO;
		}
		
		for(NSData * tCertificateData in tCertificatesDataArray)
			xar_signature_add_x509certificate(tSignature,tCertificateData.bytes,(uint32_t)tCertificateData.length);
	}

	NSDirectoryEnumerator * tDirectoryEnumerator=[tFileManager enumeratorAtPath:inContentsPath];
	
	NSString * tItemPath;
	
	while (tItemPath=[tDirectoryEnumerator nextObject])
	{
		NSString * tLastPathComponent=tItemPath.lastPathComponent;
		
		if (tLastPathComponent==nil)
			tLastPathComponent=tItemPath;
		
		if ([tLastPathComponent hasPrefix:@"."]==NO)
		{
			if (([tLastPathComponent isEqualToString:@"Payload"]==YES || [tLastPathComponent isEqualToString:@"Scripts"]==YES) &&
				[tItemPath rangeOfString:@"Resources/"].location==NSNotFound)
			{
				xar_opt_set(tArchive,XAR_OPT_COMPRESSION,XAR_OPT_VAL_NONE);
			}
			else
			{
				xar_opt_set(tArchive,XAR_OPT_COMPRESSION,XAR_OPT_VAL_GZIP);
			}
			
			if (xar_add(tArchive,[[tItemPath precomposedStringWithCanonicalMapping] UTF8String])==NULL)		// canonical mapping + UTF8String to provide the xar API with a UTF-8 string that does not require a base64 encoding.
			{
				if (outError!=NULL)
					;// A COMPLETER
				
				xar_close(tArchive);
				
				return NO;
			}
		}
	}
	
	// Close file
	
	if (xar_close(tArchive)!=0)
	{
		if (outError!=NULL)
			;// A COMPLETER
		
		return NO;
	}
	
	return YES;
}

@end
