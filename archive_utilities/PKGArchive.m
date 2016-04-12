
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
{
	NSString * _path;
}

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
	
	xar_t tArchive=xar_open([[NSFileManager defaultManager] fileSystemRepresentationWithPath:_path],READ);
	
	if (tArchive==NULL)
	{
		
		return NO;
	}
	
	xar_iter_t tIterator=xar_iter_new();
	
	if (tIterator==NULL)
	{
		
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

@end
