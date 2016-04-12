#import <Foundation/Foundation.h>

#import "PKGPackages.h"

typedef void (*usage_callback)(void);

@interface PUUtilities : NSObject


+ (PUUtilities *) sharedUtilities;

- (void) setHelpRequired:(BOOL) inBool;

// --------------------------------------------------------


// Package setters

- (BOOL) setPackageName:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageIdentifier:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageVersion:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackagePost_Installation_Behavior:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageLocation_Type:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageLocation_Path:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageRequire_Admin_Password:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageRelocatable:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageOverwrite_Directory_Permission:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageFollow_Symbolic_Links:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageUse_Hfs_Compression:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;


- (BOOL) setPackagePre_Installation_Script:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackagePost_Installation_Script:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) setPackageValue:(NSMutableArray *) inArguments;

// Project setters

- (BOOL) setProjectName:(NSMutableArray *) inArguments;

- (BOOL) setProjectBuild_Format:(NSMutableArray *) inArguments;

- (BOOL) setProjectBuild_Folder:(NSMutableArray *) inArguments;

- (BOOL) setProjectValue:(NSMutableArray *) inArguments;


- (BOOL) setValue:(NSMutableArray *) inArguments forFileAtPath:(NSString *) inPath;


// --------------------------------------------------------

// Package getters

- (BOOL) getPackageName:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageVersion:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageIdentifier:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackagePost_Installation_Behavior:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageLocation_Type:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageLocation_Path:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageRequire_Admin_Password:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageRelocatable:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageOverwrite_Directory_Permission:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageFollow_Symbolic_Links:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageUse_Hfs_Compression:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;


- (BOOL) getPackagePre_Installation_Script:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackagePost_Installation_Script:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType;

- (BOOL) getPackageValue:(NSMutableArray *) inArguments;

// Project getters

- (BOOL) getProjectName:(NSMutableArray *) inArguments;

- (BOOL) getProjectBuild_Format:(NSMutableArray *) inArguments;

- (BOOL) getProjectBuild_Folder:(NSMutableArray *) inArguments;

- (BOOL) getProjectValue:(NSMutableArray *) inArguments;


- (BOOL) getValue:(NSMutableArray *) inArguments forFileAtPath:(NSString *) inPath;

@end
