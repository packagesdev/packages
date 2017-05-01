
#import "PKGInstallationHierarchy.h"

@interface PKGInstallationHierarchy (Edition)

- (void)removeAllReferencesToPackageComponentUUIDs:(NSArray *)inPackageComponentsUUIDs;

- (void)insertBackPackageComponentUUIDs:(NSArray *)inPackageComponentsUUIDs asChildrenOfNode:(PKGChoiceTreeNode *)inTreeNode index:(NSUInteger)inIndex;

@end
