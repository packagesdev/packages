
#import "PKGPackageProject.h"

@interface PKGPackageProject (Safe)

- (PKGPackagePayload *)payload_safe;

- (PKGPackageScriptsAndResources *)scriptsAndResources_safe;

@end
