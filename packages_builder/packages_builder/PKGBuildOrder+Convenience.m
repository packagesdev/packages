
#import "PKGBuildOrder+Convenience.h"

@implementation PKGBuildOrder (Convenience)

- (NSString *)referenceFolderPath
{
	return [self.externalSettings objectForKey:PKGBuildOrderExternalSettingsReferenceFolderKey];
}

- (NSString *)scratchFolderPath
{
	return [self.externalSettings objectForKey:PKGBuildOrderExternalSettingsScratchFolderKey];
}

- (NSDictionary *)userDefinedSettings
{
	return [self.externalSettings objectForKey:PKGBuildOrderExternalSettingsUserDefinedSettingsKey];
}

- (id)userDefinedSettingsForKey:(NSString *)inKey
{
	return nil;
}

@end
