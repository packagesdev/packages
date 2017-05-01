
#import "PKGPresentationInstallationTypeStepSettings+Edition.h"

#import "PKGInstallationHierarchy+Edition.h"

@implementation PKGPresentationInstallationTypeStepSettings (Edition)

- (void)removeAllReferencesToPackageComponentUUIDs:(NSArray *)inPackageComponentsUUIDs
{
	[self.hierarchies enumerateKeysAndObjectsUsingBlock:^(id bKey, PKGInstallationHierarchy * bInstallationHierarchy, BOOL * bOutStop) {
		
		[bInstallationHierarchy removeAllReferencesToPackageComponentUUIDs:inPackageComponentsUUIDs];
		
	}];
}

@end
