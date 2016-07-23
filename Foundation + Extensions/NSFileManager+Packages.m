
#import "NSFileManager+Packages.h"

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

@end
