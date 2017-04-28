
#import "PKGInstallationHierarchy+UI.h"

#import "PKGInstallerApp.h"

NSString * const PKGInstallationHierarchyCurrentHierarchyDidChangeNotification=@"PKGInstallationHierarchyCurrentHierarchyDidChangeNotification";
NSString * const PKGInstallationHierarchyNameKey=@"HierarchyName";

NSString * const PKGInstallationHierarchyRemovedPackagesListDidChangeNotification=@"PKGInstallationHierarchyRemovedPackagesListDidChangeNotification";
NSString * const PKGInstallationHierarchyRemovedPackagesUUIDsKey=@"RemovedPackagesUUIDsKey";

@implementation PKGInstallationHierarchy (UI)

+ (NSImage *)iconForHierarchyType:(PKGInstallationHierarchyType)inType
{
	switch(inType)
	{
		case PKGInstallationHierarchyInstaller:
			
			return [[NSWorkspace sharedWorkspace] iconForFile:[PKGInstallerApp installerApp].bundlePath];
			
		case PKGInstallationHierarchySoftwareUpdate:
			
			return nil;
			
		case PKGInstallationHierarchyInvisible:
			
			return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kUnknownFSObjectIcon)];
	}
	
	return nil;
}

@end
