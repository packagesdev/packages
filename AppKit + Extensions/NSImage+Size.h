
#import <Cocoa/Cocoa.h>

@interface NSImage (WB_Size)

+ (NSSize)WB_sizeOfImageAtPath:(NSString *)inPath;

+ (NSSize)WB_sizeOfImageAtURL:(NSURL *)inURL;

@end
