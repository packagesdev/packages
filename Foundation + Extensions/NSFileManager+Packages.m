
#import "NSFileManager+Packages.h"

#include <fts.h>
#include <sys/stat.h>

@implementation NSFileManager (Packages)

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
		
		if (chmod(tFile->fts_accpath, inPosixPermisions) == -1)
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
