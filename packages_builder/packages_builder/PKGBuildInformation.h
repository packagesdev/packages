/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "PKGPackageSettings.h"

extern NSString * const PKGBuildDefaultLanguageKey;

//#define __SUPPORT_CUSTOM_LOCATION__	1

@interface PKGBuildJavaScriptInformation : NSObject

	@property (nonatomic,readonly) NSArray * constants;

	@property (nonatomic,readonly) NSArray * functions;


- (NSSet *)unknownConstantsNameInSet:(NSSet *)inConstantsNames;

- (void)addConstantsNamed:(NSSet *)inConstantsNames declaration:(NSString *)inDeclaration;

- (BOOL)containsFunctionNamed:(NSString *)inFunctionName;

- (void)addFunctionName:(NSString *)inFunctionName implementation:(NSString *)inImplementation;

@end

@interface PKGBuildBundleScripts: NSObject

	@property (copy) NSString * preInstallScriptPath;
	
	@property (copy) NSString * postInstallScriptPath;

	@property (nonatomic,readonly) BOOL hasScripts;

@end


@interface PKGBuildPackageAttributes : NSObject

	@property (copy) NSString * name;

	@property (copy) NSString * identifier;

	@property (copy) NSString * version;


	@property PKGPackageConclusionAction conclusionAction;


	@property PKGPackageLocationType locationType;

	@property PKGPackageAuthentication authenticationMode;

#ifdef __SUPPORT_CUSTOM_LOCATION__

	@property (copy) NSString * customLocation;

#endif

	@property NSArray * mustBeClosedApplicationIDs;


	@property NSInteger archiveSize;	// -1: Unknown/Not set (in KB)	Not Used??

	@property NSInteger payloadSize;	// -1: Unknown/Not set (in KB)

	@property NSUInteger numberOfFiles;


	@property (readonly) NSMutableArray * downgradableBundles;


	@property (readonly) NSMutableArray * bundlesVersions;

	@property (readonly) NSMutableDictionary * bundlesScripts;

	@property (readonly) NSMutableDictionary * bundlesScriptsTransformedNames;

	@property (copy) NSString * preInstallScriptPath;

	@property (copy) NSString * postInstallScriptPath;


	@property (readonly) NSMutableDictionary * bundlesLocators;





	@property (copy) NSString * referencePath;


	@property BOOL treatMissingPayloadFilesAsWarnings;

	@property NSUInteger temporaryPayloadFolderPathLength;

	@property BOOL preserveExtendedAttributes;

@end

@interface PKGBuildInformation : NSObject

	@property (copy) NSString * contentsPath;

	@property (nonatomic,copy,readonly) NSString * resourcesPath;

	@property (nonatomic,copy,readwrite) NSString * scriptsPath;

	@property (readonly) NSMutableDictionary * languagesPath;


	// Additional distribution options set by requirements

	@property (readonly) NSMutableDictionary * requirementsOptions;



	@property (readonly) NSMutableDictionary * packagesAttributes;

	@property (readonly) NSMutableDictionary * choicesNames;

	@property (readonly) PKGBuildJavaScriptInformation * javaScriptInformation;


	@property (readonly) NSMutableDictionary * localizations;


	@property (readonly) NSMutableArray * resourcesExtras;

@end
