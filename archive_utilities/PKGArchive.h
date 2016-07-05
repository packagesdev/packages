
#import <Foundation/Foundation.h>

@interface PKGArchive : NSObject

	@property (copy,readonly) NSString * path;


+ (instancetype)archiveAtPath:(NSString *)inPath;

+ (instancetype)archiveAtURL:(NSURL *)inURL;

- (instancetype)initWithPath:(NSString *)inPath;

- (instancetype)initWithURL:(NSURL *)inURL;


- (BOOL)isFlatPackage;


- (BOOL)extractToPath:(NSString *) inFolderPath error:(NSError **)outError;

- (BOOL)extractFile:(NSString *)inContentsPath intoData:(out NSData **)outData error:(NSError **)outError;

- (BOOL)createArchiveWithContentsAtPath:(NSString *)inContentsPath error:(NSError **)outError;

@end
