
#import <Foundation/Foundation.h>

@interface PKGArchive : NSObject

+ (instancetype)archiveAtPath:(NSString *)inPath;

+ (instancetype)archiveAtURL:(NSURL *)inURL;

- (instancetype)initWithPath:(NSString *)inPath;

- (instancetype)initWithURL:(NSURL *)inURL;

- (BOOL)extractFile:(NSString *)inContentsPath intoData:(out NSData **)outData error:(NSError **)outError;

@end
