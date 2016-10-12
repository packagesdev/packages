
#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, PKG_NSFileManagerCopyOptions) {
	PKG_NSDeleteExisting = 1
};

@interface NSFileManager (Packages)

- (BOOL)PKG_copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath options:(PKG_NSFileManagerCopyOptions)inOptions error:(NSError *__autoreleasing *)outError;

- (BOOL)PKG_isEmptyDirectoryAtPath:(NSString *)inPath;

- (BOOL)PKG_setPosixPermissions:(mode_t)inPosixPermisions ofItemAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError;

- (BOOL)PKG_setPosixPermissions:(mode_t)inPosixPermisions ofItemAndDescendantsAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError;

- (BOOL)PKG_setOwnerAccountID:(uid_t)inOwnerAccountID groupAccountID:(gid_t)inGroupAccountID ofItemAndDescendantsAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError;

@end
