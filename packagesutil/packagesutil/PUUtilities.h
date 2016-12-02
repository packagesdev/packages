/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
