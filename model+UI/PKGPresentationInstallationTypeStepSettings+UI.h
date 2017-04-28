
#import "PKGPresentationInstallationTypeStepSettings.h"

#import "PKGInstallationHierarchy+UI.h"

@interface PKGPresentationInstallationTypeStepSettings (UI)

+ (NSArray *)allHierarchiesNames;

+ (NSString *)hierarchyNameForType:(PKGInstallationHierarchyType)inType;

+ (PKGInstallationHierarchyType)hierarchyTypeForName:(NSString *)inName;

@end
