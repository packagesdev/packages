
#import "PKGPresentationInstallationTypeStepSettings+UI.h"

@implementation PKGPresentationInstallationTypeStepSettings (UI)

+ (NSArray *)allHierarchiesNames
{
	static NSArray * sHierarchyNames=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sHierarchyNames=@[
						  PKGPresentationInstallationTypeInstallerHierarchyKey,
						  PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey,
						  PKGPresentationInstallationTypeInvisibleHierarchyKey
						  ];
	});
	
	return sHierarchyNames;
}

+ (NSString *)hierarchyNameForType:(PKGInstallationHierarchyType)inType
{
	switch(inType)
	{
		case PKGInstallationHierarchyInstaller:
			
			return PKGPresentationInstallationTypeInstallerHierarchyKey;
			
		case PKGInstallationHierarchySoftwareUpdate:
			
			return PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey;
			
		case PKGInstallationHierarchyInvisible:
			
			return PKGPresentationInstallationTypeInvisibleHierarchyKey;
	}
	
	return nil;
}

+ (PKGInstallationHierarchyType)hierarchyTypeForName:(NSString *)inName
{
	if (inName==nil)
		return PKGInstallationHierarchyInstaller;
	
	static NSDictionary * sHierarchyTypesForNames=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sHierarchyTypesForNames=@{
								  PKGPresentationInstallationTypeInstallerHierarchyKey:@(PKGInstallationHierarchyInstaller),
								  PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey:@(PKGInstallationHierarchySoftwareUpdate),
								  PKGPresentationInstallationTypeInvisibleHierarchyKey:@(PKGInstallationHierarchyInvisible)
								  };
	});
	
	return [sHierarchyTypesForNames[inName] integerValue];
}

@end
