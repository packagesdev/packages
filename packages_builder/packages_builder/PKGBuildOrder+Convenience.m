
#import "PKGBuildOrder+Convenience.h"

@implementation PKGBuildOrder (Convenience)

- (NSString *)referenceProjectFolderPath
{
	return self.externalSettings[PKGBuildOrderExternalSettingsReferenceProjectFolderKey];
}

- (NSString *)referenceFolderPath
{
	return self.externalSettings[PKGBuildOrderExternalSettingsReferenceFolderKey];
}

- (NSString *)scratchFolderPath
{
	return self.externalSettings[PKGBuildOrderExternalSettingsScratchFolderKey];
}

- (BOOL)embedTimestamp
{
	NSNumber * tNumber=self.externalSettings[PKGBuildOrderExternalSettingsEmbedTimestamp];
	
	return ([tNumber isKindOfClass:[NSNumber class]]==YES) ? tNumber.boolValue : YES;
}

- (NSDictionary *)userDefinedSettings
{
	return self.externalSettings[PKGBuildOrderExternalSettingsUserDefinedSettingsKey];
}

- (id)externalSettingsForKey:(NSString *)inKey
{
	if (inKey==nil)
		return nil;
	
	return self.externalSettings[inKey];
}

@end
