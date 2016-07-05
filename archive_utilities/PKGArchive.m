
#import "PKGArchive.h"

#include "xar.h"
#include "arcmod.h"


int32_t ixar_extract_tobuffersz(xar_t x, xar_file_t f, char **buffer, size_t *size)
{
	const char *sizestring = NULL;
	
	if(0 != xar_prop_get(f,"data/size",&sizestring))
	{
		return -1;
	}
	
	*size = (size_t)strtoull(sizestring, (char **)NULL, 10);
	
	*buffer = malloc(*size);
	
	if(!(*buffer))
	{
		return -1;
	}
	
	return xar_arcmod_extract(x,f,NULL,*buffer,*size);
}

@interface PKGArchive ()

	@property (copy,readwrite) NSString * path;

@end

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
	
	const char * tCFilePath=[[NSFileManager defaultManager] fileSystemRepresentationWithPath:self.path];
		
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

- (BOOL)extractFile:(NSString *)inContentsPath intoData:(out NSData **)outData error:(NSError **)outError
{
	if (inContentsPath==nil)
	{
		// A COMPLETER
		
		return NO;
	}
	
	if (outData==NULL)
	{
		// A COMPLETER
		
		return NO;
	}
	
	xar_t tArchive=xar_open([_path fileSystemRepresentation],READ);
	
	if (tArchive==NULL)
	{
		if (outError!=NULL)
			;// A COMPLETER
		
		return NO;
	}
	
	xar_iter_t tIterator=xar_iter_new();
	
	if (tIterator==NULL)
	{
		xar_close(tArchive);
		
		if (outError!=NULL)
			;// A COMPLETER
		
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
			}
			
			break;
		}
	}
	
	xar_iter_free(tIterator);
	xar_close(tArchive);
	
	return ((*outData)!=nil);
}

- (BOOL)extractToPath:(NSString *) inFolderPath error:(NSError **)outError
{
	if(inFolderPath==nil)
		return NO;
	
	xar_t tArchive=xar_open([_path fileSystemRepresentation],READ);
	
	if (tArchive==NULL)
	{
		if (outError!=NULL)
			;// A COMPLETER
		
		return NO;
	}
	
	
	xar_iter_t tIterator=xar_iter_new();
	
	if (tIterator==NULL)
	{
		xar_close(tArchive);
		
		if (outError!=NULL)
			;// A COMPLETER
		
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
				;// A COMPLETER
			
			return NO;
			
			/*tMetadata=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:IC_BUILDER_FAILURE_REASON_FILE_CANNOT_BE_CREATED],IC_BUILDER_FAILURE_REASON,
					   [inFolderPath stringByAppendingPathComponent:tFileRelativePath],IC_BUILDER_INFORMATION_FILE_PATH,
					   nil];*/
		}
	}
	
	xar_iter_free(tIterator);
	xar_close(tArchive);
	
	return YES;
}

- (BOOL)createArchiveWithContentsAtPath:(NSString *)inContentsPath error:(NSError **)outError
{
	// A COMPLETER
	
	return NO;
}

@end
