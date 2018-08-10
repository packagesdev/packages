
#import "PKGProjectBuilder.h"

@interface PKGProjectBuilder (Documents)

- (NSString *)distributionResources;

- (BOOL)setPosixPermissionsOfDocumentAtPath:(NSString *)inPath;

- (NSString *)suitableFileNameForProposedFileName:(NSString *)inName inDirectory:(NSString *)inDirectory;

@end
