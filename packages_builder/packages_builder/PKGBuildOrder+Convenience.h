
#import "PKGBuildOrder.h"

@interface PKGBuildOrder (Convenience)

- (NSString *)referenceProjectFolderPath;

- (NSString *)referenceFolderPath;

- (NSString *)scratchFolderPath;

- (BOOL)embedTimestamp;

- (NSDictionary *)userDefinedSettings;

- (id)externalSettingsForKey:(NSString *)inKey;

@end
