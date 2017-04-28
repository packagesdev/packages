
#import <AppKit/AppKit.h>

#import "PKGInstallationHierarchy.h"

extern NSString * const PKGInstallationHierarchyCurrentHierarchyDidChangeNotification;
extern NSString * const PKGInstallationHierarchyNameKey;

extern NSString * const PKGInstallationHierarchyRemovedPackagesListDidChangeNotification;
extern NSString * const PKGInstallationHierarchyRemovedPackagesUUIDsKey;

#define PKGInstallationHierarchyTypesCount	3

typedef NS_ENUM(NSInteger, PKGInstallationHierarchyType)
{
	PKGInstallationHierarchyInstaller,
	PKGInstallationHierarchySoftwareUpdate,
	PKGInstallationHierarchyInvisible
};

@interface PKGInstallationHierarchy (UI)

+ (NSImage *)iconForHierarchyType:(PKGInstallationHierarchyType)inType;

@end
