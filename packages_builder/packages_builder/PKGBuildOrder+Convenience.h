
#import "PKGBuildOrder.h"

@interface PKGBuildOrder (Convenience)

- (NSString *)referenceProjectFolderPath;

- (NSString *)referenceFolderPath;

- (NSString *)scratchFolderPath;

- (NSDictionary *)userDefinedSettings;

- (id)userDefinedSettingsForKey:(NSString *)inKey;

@end
