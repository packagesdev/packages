
#import "NSFileManager+Packages.h"

#include <fts.h>

@implementation NSFileManager (Packages)

- (BOOL)PKG_copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath options:(PKG_NSFileManagerCopyOptions)inOptions error:(NSError *__autoreleasing *)error
{
	if ((inOptions & PKG_NSDeleteExisting)==PKG_NSDeleteExisting)
	{
		if ([self removeItemAtPath:dstPath error:error]==NO)
			return NO;
	}
	
	return [self copyItemAtPath:srcPath toPath:dstPath error:error];
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

@end
