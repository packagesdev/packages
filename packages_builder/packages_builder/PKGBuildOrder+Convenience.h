
#import "PKGBuildOrder.h"

@interface PKGBuildOrder (Convenience)

- (NSString *)referenceFolderPath;

- (NSString *)scratchFolderPath;

- (NSDictionary *)userDefinedSettings;

- (id)userDefinedSettingsForKey:(NSString *)inKey;

@end
