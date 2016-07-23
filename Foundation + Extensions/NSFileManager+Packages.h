
#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, PKG_NSFileManagerCopyOptions) {
	PKG_NSDeleteExisting = 1
};

@interface NSFileManager (Packages)

- (BOOL)PKG_copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath options:(PKG_NSFileManagerCopyOptions)inOptions error:(NSError *__autoreleasing *)error;

@end
