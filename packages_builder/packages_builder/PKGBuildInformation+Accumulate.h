//
//  PKGBuildInformation+Accumulate.h
//  packages_builder
//
//  Created by stephane on 02/08/2021.
//

#import "PKGBuildInformation.h"

@interface PKGBuildInformation (Accumulate)

- (void)accumulateHostArchitecturesInFileHierarchyAtPath:(NSString *)inFileHierarchyPath;

- (BOOL)accumulateBundleVersionsAndHostArchitecturesInFileHierarchyAtPath:(NSString *)inFileHierarchyPath forPackageUUID:(NSString *)inPackageUUID;

@end
