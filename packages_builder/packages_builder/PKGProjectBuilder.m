/*
Copyright (c) 2008-2018, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGProjectBuilder.h"
#import "PKGProjectBuilder+PKGBuildEvent.h"

//#import "OHSHITManager.h"

#include <CoreServices/CoreServices.h>
#import <Security/Security.h>

#include <grp.h>
#include <pwd.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <fts.h>

#import "NSArray+WBExtensions.h"
#import "NSDictionary+WBExtensions.h"

#import "NSFileManager+Packages.h"
#import "NSIndexPath+Packages.h"
#import "NSString+Packages.h"

#import "NSString+Random.h"

#import "PKGPackages.h"
#import "PKGPackagesError.h"


#import "PKGPresentationSection+Builder.h"

#import "PKGBuildOrderExecutionAgentInterface.h"

#import "PKGRequirementPluginsManager.h"
#import "PKGRequirementConverter.h"

#import "PKGLocatorPluginsManager.h"
#import "PKGLocatorConverter.h"


#import "PKGStackedEffectiveUserAndGroup.h"

#import "PKGPathComponentPatternsRegister.h"

#import "PKGArchive.h"

#import "PKGBuildInformation.h"

#import "PKGBuildEvent.h"

#import "PKGBuildOrder+Convenience.h"

#import "PKGLicenseProvider.h"

#import "PKGBuildLogger.h"

#import "PKGCertificatesUtilities.h"

#import "PKGLanguageManager.h"
#import "PKGPayloadBundleItem.h"

#import "PKGPresentationBackgroundSettings+Builder.h"


#define SIGNATURE_REQUEST_TIME_OUT		10*60.0f // 10 minutes

typedef NS_ENUM(NSUInteger, PKGArchiveSignatureResult)
{
	PKGArchiveSignatureResultNoError=0,
	PKGArchiveSignatureResultGenericError,
	PKGArchiveSignatureResultTimeOut,
	PKGArchiveSignatureResultAuthenticationDenied,
	PKGArchiveSignatureResultCertificateNotFound,
	PKGArchiveSignatureResultPrivateKeyNotRetrieved,
	PKGArchiveSignatureResultTrustEvaluationFailed,
	PKGArchiveSignatureResultTrustNoAnchor,
	PKGArchiveSignatureResultTrustExpiredCertificate,
	PKGArchiveSignatureResultTrustNotTrustedCertificate,
};

typedef NS_ENUM(NSUInteger, PKGArchiveFormat)
{
	PKGArchiveFormatCPIO=0
};

typedef NS_ENUM(NSUInteger, PKGArchiveCompressionFormat)
{
	PKGArchiveCompressionFormatGZIP=0
};


NSString * const PKGPackagesProjectBuilderErrorDomain=@"fr.whitebox.packages.projectbuilder";

enum {
	PKGProjectBuilderCanNotCreateFolder=1,

};

enum
{
	PKG_errSecMissingPrivateKey=31415
};

#define PKGRenamingAttemptsMax 32768

#define __SET_CORRECT_PERMISSIONS__ 1

NSString * const PKGProjectBuilderAuthoringToolName=@"Packages";

NSString * const PKGProjectBuilderAuthoringToolVersion=@"1.2.6";

NSString * const PKGProjectBuilderToolPath_ditto=@"/usr/bin/ditto";

NSString * const PKGProjectBuilderToolPath_mkbom=@"/usr/bin/mkbom";

NSString * const PKGProjectBuilderToolPath_goldin=@"/usr/local/bin/goldin";


NSString * const PKGProjectBuilderDefaultScratchFolder=@"/private/tmp";


@interface PKGProjectBuilder () <PKGArchiveDelegate>
{
	PKGBuildOrder * _buildOrder;
	
	NSIndexPath * _stepPath;
	
	
	
	BOOL _treatMissingPresentationDocumentsAsWarnings;
	
	NSFileManager * _fileManager;
	
	PKGBuildInformation * _buildInformation;
	
	NSString * _scratchLocation;
	
	PKGProjectBuildFormat _buildFormat;
	
	PKGPathComponentPatternsRegister * _patternsRegister;
	
	
	NSXMLElement * _installerScriptElement;
	
	NSDictionary * _folderAttributes;
	
	
	PKGRequirementPluginsManager * _requirementPluginsManager;
	
	PKGLocatorPluginsManager * _locatorPluginsManager;
	
	SecIdentityRef _secIdentityRef;
	
	PKGArchiveSignatureResult _signatureResult;
	
	
	// Cached classes and objects to speed up things
	
	Class _PKGPayloadBundleItemClass;
}

	@property (readonly) BOOL debug;


	@property (readwrite) PKGProject * project;

	@property (nonatomic,readonly) id<PKGBuildNotificationCenterInterface> buildNotificationCenter;

	@property (nonatomic,readonly) id<PKGBuildSignatureCreatorInterface> signatureCreator;


// Build Notifications wrapper

- (void)postStep:(PKGBuildStep)inStep beginEvent:(PKGBuildEvent *)inEvent;
- (void)postStep:(PKGBuildStep)inStep infoEvent:(PKGBuildEvent *)inEvent;
- (void)postStep:(PKGBuildStep)inStep successEvent:(PKGBuildEvent *)inEvent;
- (void)postStep:(PKGBuildStep)inStep failureEvent:(PKGBuildEvent *)inEvent;
- (void)postStep:(PKGBuildStep)inStep warningEvent:(PKGBuildEvent *)inEvent;

- (void)postCurrentStepInfoEvent:(PKGBuildEvent *)inEvent;
- (void)postCurrentStepSuccessEvent:(PKGBuildEvent *)inEvent;
- (void)postCurrentStepFailureEvent:(PKGBuildEvent *)inEvent;
- (void)postCurrentStepWarningEvent:(PKGBuildEvent *)inEvent;


- (BOOL)isCertificateSetForProjectSettings:(PKGProjectSettings *)inProjectSettings;

- (SecIdentityRef)secIdentifyForProjectSettings:(PKGProjectSettings *)inProjectSettings error:(OSStatus *)outError;
- (SecIdentityRef)secIdentifyForProjectSettings:(PKGProjectSettings *)inProjectSettings;

- (BOOL)createDirectoryAtPath:(NSString *)inDirectoryPath withIntermediateDirectories:(BOOL)inIntermediateDirectories;

- (BOOL)createScratchLocationAtPath:(NSString *)inPath error:(NSError **)outError;

- (NSString *)prepareBuildFolderAtPath:(NSString *)inPath;


- (BOOL)buildDistributionProjectAtPath:(NSString *) inPath;

- (BOOL)buildPackageProjectAtPath:(NSString *) inPath;

- (BOOL)splitForksContentsOfDirectoryAtPath:(NSString *)inDirectoryPath preserveExtendedAttributes:(BOOL)inPreserveExtendedAttributes;

- (BOOL)splitForksContentsOfDirectoryAtPath:(NSString *)inDirectoryPath;

- (BOOL)archiveContentsOfDirectoryAtPath:(NSString *)inDirectoryPath toFileAtPath:(NSString *)inFilePath format:(PKGArchiveFormat)inFormat compressionFormat:(PKGArchiveCompressionFormat)inCompressionFormat;

- (BOOL)buildPackageObject:(NSObject<PKGPackageObjectProtocol> *)inPackageObject atPath:(NSString *) inPath flat:(BOOL)inFlat;

- (BOOL)buildPackageInfoForComponent:(PKGPackageComponent *)inPackageComponent atPath:(NSString *)inPath contextInfo:(PKGBuildPackageAttributes *)inBuildPackageAttributes;


- (BOOL)addRelocators:(NSArray *) inLocatorsArray forBundle:(NSString *) inBundleIdentifier packageInfoElement:(NSXMLElement *) inPackageInfoElement;


- (BOOL)addLocalizedErrorMessages:(NSDictionary *) inLocalizations withName:(NSString *)inName errorMessage:(NSString **)outErrorMessage errorDescription:(NSString **)outErrorDescription;

- (BOOL)buildBundleVersionsDictionaryWithFileHierarchyAtPath:(NSString *)inFileHierarchyPath ofPackageUUID:(NSString *)inPackageUUID;

- (BOOL) addBundleFromArray:(NSArray *) inArray toElement:(NSXMLElement *) inElement withPath:(NSString *) inPath packageInfoElement:(NSXMLElement *) inPackageInfoElement downgradableBundles:(NSMutableArray *) inDowngradableArray;


- (BOOL)buildPayload:(PKGPackagePayload *)inPayload ofPackageUUID:(NSString *) inPackageUUID atPath:(NSString *) inPath;

- (BOOL)buildFileHierarchyComponent:(PKGTreeNode *)inFileTreeNode atPath:(NSString *)inPath contextInfo:(PKGBuildPackageAttributes *)inPackageBuildInformation;

@end

@interface PKGProjectBuilder (Distribution)

- (BOOL)setPosixPermissionsOfDocumentAtPath:(NSString *)inPath;

- (NSDictionary *)localizedPathDictionaryForLocalizations:(NSDictionary *)inLocalizations;

- (NSString *)finalDocumentNameForLocalizationsDirectories:(NSArray *)inLocalizationsDirectories usingBaseName:(NSString *)inBaseName extension:(NSString *)inExtension;

- (BOOL)setDocumentName:(NSString *)inName localizations:(NSDictionary *)inLocalizations;

- (BOOL)setPresentation;

- (void)setTitle;
- (BOOL)setBackground;
- (BOOL)setIntroduction;
- (BOOL)setReadMe;
- (BOOL)setLicense;
- (BOOL)setConclusion;
- (BOOL)setPlugins;

- (BOOL)setChoiceOutline;

- (NSXMLElement *)packageRefeferenceElementWithChoicePackageItem:(PKGChoicePackageItem *) inChoicePackageItem;

- (BOOL)addLinesElementsToElement:(NSXMLElement *) inElement withChoicesArray:(NSArray *) inChoicesArray isInstaller:(BOOL) inIsInstaller prefix:(NSString *) inPrefix;

- (BOOL)hasOneHideAndUnselectRequirementEnabledInArray:(NSArray *) inArray;

- (BOOL)setStateAttributesOfChoiceElement:(NSXMLElement *) inElement name:(NSString *) inName withOptions:(PKGChoiceItemOptions *) inOptions;

- (BOOL)setStateAttributesOfChoiceElement:(NSXMLElement *) inElement name:(NSString *) inName requirementFunctionName:(NSString *) inRequirementFunctionName affectVisible:(BOOL) inAffectVisible withOptions:(PKGChoiceItemOptions *) inOptions;

- (BOOL)setStateAttributesOfChoiceElement:(NSXMLElement *) inElement name:(NSString *) inName withChoiceItem:(PKGChoiceItem *) inChoiceItem;

- (BOOL)setRequirementsFunctionForChoiceName:(NSString *) inName withArray:(NSArray *) inArray functionName:(NSString **) outFunctionName;

- (NSString *)logicStringForDependencyTreeNode:(PKGChoiceDependencyTreeNode *)inDependencyTreeNode;

- (BOOL) createEnabledDependencyFunctionNamed:(NSString *) inFunctionName withDependencyTree:(PKGChoiceDependencyTree *)inDependencyTree;

- (BOOL) createSelectedDependencyFunctionNamed:(NSString *) inFunctionName withEnabledState:(int) inEnabledState  withEnabledFunctionName:(NSString *) inEnabledFunctionName withDependencyTree:(PKGChoiceDependencyTree *)inDependencyTree;

- (BOOL) addChoicesElementsToElement:(NSXMLElement *) inElement withChoicesArray:(NSArray *) inChoicesArray isInstaller:(BOOL) inIsInstaller;


- (BOOL)fillDistributionXMLWithDictionary:(NSDictionary *) inDictionary;


- (void)setDistributionOptions;

- (BOOL)setRequirementsDistributionOptions;

- (BOOL)setDistributionResources;

- (void)setPackagesReferences;

- (void)setJavaScriptScripts;

- (BOOL)setAdvancedDistributionOptions;

- (BOOL)setExtraResources;

- (BOOL)setRequirements;

- (BOOL)setLocalizableStrings;


- (BOOL)buildDistributionScripts;

- (NSString *)getDistributionPathForLanguage:(NSString *) inLanguage;

@end


@implementation PKGProjectBuilder

@synthesize referenceProjectPath=_referenceProjectPath,referenceFolderPath=_referenceFolderPath;

- (id) init
{
	self=[super init];
	
	if (self!=nil)
	{
		_PKGPayloadBundleItemClass=[PKGPayloadBundleItem class];
		
		_stepPath=[[NSIndexPath alloc] init];
		
		_buildInformation=[[PKGBuildInformation alloc] init];
		
		_folderAttributes=@{NSFilePosixPermissions:@(0755)};
		
		_fileManager=[NSFileManager defaultManager];
		
		_buildFormat=PKGProjectBuildFormatFlat;
		
		
		_requirementPluginsManager=[PKGRequirementPluginsManager defaultManager];
		if (_requirementPluginsManager==nil)
			return nil;
		
		_locatorPluginsManager=[PKGLocatorPluginsManager defaultManager];
		if (_locatorPluginsManager==nil)
			return nil;
	}
	
	return self;
}

- (void) dealloc
{
	if (_secIdentityRef!=NULL)
	{
		// Release Memory
									
		CFRelease(_secIdentityRef);
	}
}

#pragma mark -

- (BOOL)debug
{
	return ((_buildOrder.buildOptions & PKGBuildOptionDebugBuild) == PKGBuildOptionDebugBuild);
}

- (id<PKGBuildNotificationCenterInterface>)buildNotificationCenter
{
	return [self.executionAgentConnection remoteObjectProxyWithErrorHandler:^(NSError *bErrror){
		
		// Warning
		
		// A COMPLETER
	}];
}

- (id<PKGBuildSignatureCreatorInterface>)signatureCreator
{
	return [self.executionAgentConnection remoteObjectProxyWithErrorHandler:^(NSError *bErrror){
		
		// Error
		
		// A COMPLETER
	}];
}

#pragma mark -

- (BOOL)isCertificateSetForProjectSettings:(PKGProjectSettings *)inProjectSettings
{
	if (inProjectSettings==nil)
		return NO;
	
	NSString * tCertificateName=inProjectSettings.certificateName;
	
	return (tCertificateName!=nil && [tCertificateName length]>0);
}

- (SecIdentityRef)secIdentifyForProjectSettings:(PKGProjectSettings *)inProjectSettings error:(OSStatus *)outError
{
	if (inProjectSettings==nil)
	{
		if (outError!=NULL)
			*outError=0;
		
		return NULL;
	}
		
	NSString * tCertificateName=inProjectSettings.certificateName;

	if (tCertificateName==nil)
	{
		if (outError!=NULL)
			*outError=0;
		
		return NULL;
	}
	
	PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
			
	NSString * tKeychainPath=[PKGLoginKeychainPath stringByExpandingTildeInPath];
	
	OSStatus tError;
	
	SecIdentityRef tSecIdentityRef=[PKGCertificatesUtilities identityWithName:tCertificateName atPath:tKeychainPath error:&tError];
	
	if (tSecIdentityRef!=NULL)
		return tSecIdentityRef;
	
	SecCertificateRef tCertificateRef=[PKGCertificatesUtilities certificateWithName:tCertificateName atPath:tKeychainPath error:&tError];
	
	if (tCertificateRef!=NULL)
	{
		if (outError!=NULL)
			*outError=PKG_errSecMissingPrivateKey;
		
		return NULL;
	}
	
	tStackedEffectiveUserAndGroup=nil;
	
	NSString * tCertificateKeychainPath=inProjectSettings.certificateKeychainPath;
				
	if (tCertificateKeychainPath==nil)
	{
		if (outError!=NULL)
			*outError=tError;
		
		return NULL;
	}
	
	tError=0;
	
	tSecIdentityRef=[PKGCertificatesUtilities identityWithName:tCertificateName atPath:tCertificateKeychainPath error:&tError];
	
	if (tSecIdentityRef!=NULL)
		return tSecIdentityRef;
	
	tCertificateRef=[PKGCertificatesUtilities certificateWithName:tCertificateName atPath:tCertificateKeychainPath error:&tError];
	
	if (tCertificateRef!=NULL)
	{
		if (outError!=NULL)
			*outError=PKG_errSecMissingPrivateKey;
		
		return NULL;
	}
	
	if (outError!=NULL)
		*outError=tError;
			
	return NULL;
}

- (SecIdentityRef)secIdentifyForProjectSettings:(PKGProjectSettings *)inProjectSettings
{
	OSStatus tIdentityError=errSecSuccess;
	
	SecIdentityRef tSecIdentityRef=[self secIdentifyForProjectSettings:inProjectSettings error:&tIdentityError];
	
	if (tSecIdentityRef!=NULL)
		return tSecIdentityRef;
	
	PKGBuildError tBuildError=PKGBuildErrorSigningUnknown;
	
	PKGBuildErrorEvent * tBuildErrorEvent=[[PKGBuildErrorEvent alloc] init];
	
	switch(tIdentityError)
	{
		case PKG_errSecMissingPrivateKey:
			
			tBuildError=PKGBuildErrorSigningCertificatePrivateKeyNotFound;
			break;
			
		case errSecNoSuchKeychain:
			
			tBuildError=PKGBuildErrorSigningKeychainNotFound;
			break;
			
		case errSecItemNotFound:
			
			tBuildError=PKGBuildErrorSigningCertificateNotFound;
			break;
			
		default:
			
			tBuildErrorEvent.subcode=tIdentityError;
			
			// A COMPLETER
			
			break;
	}
	
	tBuildErrorEvent.code=tBuildError;
	
	[self postCurrentStepFailureEvent:tBuildErrorEvent];
	
	return NULL;
}

#pragma mark -

- (BOOL)createDirectoryAtPath:(NSString *)inDirectoryPath withIntermediateDirectories:(BOOL)inIntermediateDirectories
{
	NSError * tError;
	
	if ([_fileManager createDirectoryAtPath:inDirectoryPath withIntermediateDirectories:inIntermediateDirectories attributes:_folderAttributes error:&tError]==NO)
	{
		PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCreated filePath:inDirectoryPath fileKind:PKGFileKindFolder];
		
		if (tError!=nil)
		{
			switch(tError.code)
			{
				case NSFileWriteFileExistsError:
				{
					// If the attributes are the same then it's fine
				
					NSDictionary * tFolderAttributes=[_fileManager attributesOfItemAtPath:inDirectoryPath error:&tError];
					
					if (tFolderAttributes==nil)
					{
						// A COMPLETER
						
						break;
					}
					
					if ([tFolderAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]==NO)
					{
						// A COMPLETER
						
						break;
					}
					
					for(NSString * tAttributeKey in _folderAttributes)
					{
						if ([tFolderAttributes[tAttributeKey] isEqualTo:_folderAttributes[tAttributeKey]]==NO)
						{
							// A COMPLETER
							
							break;
						}
					}
					
					return YES;
					
				}
				case NSFileWriteOutOfSpaceError:
					tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
					break;
					
				case NSFileWriteVolumeReadOnlyError:
					tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
					break;
				case NSFileWriteNoPermissionError:
					tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
					break;
			}
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		return NO;
	}
	
	return YES;
}

- (BOOL)createScratchLocationAtPath:(NSString *)inPath error:(NSError **)outError
{
	NSString * tParentScratchFolder=inPath;
	
	// Scratch location
	
	if (tParentScratchFolder!=nil)
	{
		BOOL isDirectory;
		
		if ([_fileManager fileExistsAtPath:tParentScratchFolder isDirectory:&isDirectory]==NO || isDirectory==NO)
		{
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelWarning format:@"Scratch folder \"%@\" does not exist. Reverting to default value.",tParentScratchFolder];
			
			tParentScratchFolder=PKGProjectBuilderDefaultScratchFolder;
		}
	}
	else
	{
		tParentScratchFolder=PKGProjectBuilderDefaultScratchFolder;
	}
	
	// Create a unique temporary folder at the scratchLocation
	
	NSUInteger tAttemptCount=0;
	
	do
	{
		NSString * tRandomFolderName=[NSString randomFolderName];
		
		NSString * tRandomFolderPath=[tParentScratchFolder stringByAppendingPathComponent:tRandomFolderName];
		
		if ([_fileManager fileExistsAtPath:tRandomFolderPath]==NO)
		{
			// Try to create the directory
			
			NSError * tError;
			
			if ([_fileManager createDirectoryAtPath:tRandomFolderPath withIntermediateDirectories:NO attributes:_folderAttributes error:&tError]==NO)
			{
				if (outError!=NULL)
					*outError=tError;
				
				return NO;
			}
			
			_scratchLocation=[tRandomFolderPath copy];
			
			return YES;
		}
		
		tAttemptCount++;
	}
	while (tAttemptCount<100);
	
	if (outError!=NULL)
		*outError=[NSError errorWithDomain:PKGPackagesProjectBuilderErrorDomain	code:PKGProjectBuilderCanNotCreateFolder userInfo:nil];
	
	return NO;
}

- (NSString *)prepareBuildFolderAtPath:(NSString *)inPath
{
	NSString * tBuildFolderName=(self.debug==YES) ? @"build_debug" : @"build";
	NSString * tAbsoluteBuildFolderPath=inPath;
	
	if (tAbsoluteBuildFolderPath==nil)
	{
		// We need to create the Build Path by our own
		
		// We use self.notificationPath because it's the real project path
		
		tAbsoluteBuildFolderPath=[_referenceProjectPath stringByAppendingPathComponent:tBuildFolderName];
	}
	else
	{
		if (self.debug==YES)
		{
			if ([[tAbsoluteBuildFolderPath lastPathComponent] caseInsensitiveCompare:@"build"]==NSOrderedSame)
				tAbsoluteBuildFolderPath=[tAbsoluteBuildFolderPath stringByDeletingLastPathComponent];
			
			tAbsoluteBuildFolderPath=[tAbsoluteBuildFolderPath stringByAppendingPathComponent:tBuildFolderName];
		}
	}
	
	[self postStep:PKGBuildStepProjectBuildFolder beginEvent:[PKGBuildInfoEvent eventWithFilePath:tAbsoluteBuildFolderPath]];
	
	PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
	
	BOOL isDirectory;
	
	if ([_fileManager fileExistsAtPath:tAbsoluteBuildFolderPath isDirectory:&isDirectory]==YES)
	{
		if (isDirectory==NO || [_fileManager isWritableFileAtPath:tAbsoluteBuildFolderPath]==NO)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorBuildFolderNotWritable filePath:tAbsoluteBuildFolderPath fileKind:PKGFileKindFolder]];
			
			return nil;
		}
	}
	else
	{
		// Try to create the folder
			
		NSError * tError;
		
		if ([_fileManager createDirectoryAtPath:tAbsoluteBuildFolderPath
					withIntermediateDirectories:YES
									 attributes:@{NSFilePosixPermissions:@(S_IRWXU+S_IRGRP+S_IXGRP+S_IROTH+S_IXOTH),
												  NSFileOwnerAccountID:@(self.userID),
												  NSFileGroupOwnerAccountID:@(self.groupID)}
										  error:&tError]==NO)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCreated filePath:tAbsoluteBuildFolderPath fileKind:PKGFileKindFolder];
			
			if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case NSFileWriteOutOfSpaceError:
						tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
						break;
					
					case NSFileWriteVolumeReadOnlyError:
						tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
						break;
					case NSFileWriteNoPermissionError:
						tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
						break;
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return nil;
		}
	}
	
	tStackedEffectiveUserAndGroup=nil;
	
	[self postCurrentStepSuccessEvent:nil];
	
	return tAbsoluteBuildFolderPath;
}

#pragma mark -

- (void)build
{
	/*NSString * tOhShitFile=[[_buildOrder.projectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"OHSHIT_SimulatedFailures.plist"];
	
	[[OHSHITManager sharedManager] setStorageFailuresList:[OHSHITManager storageFailuresListFromFileAtPath:tOhShitFile]];*/
	
	[self postStep:PKGBuildStepProject beginEvent:[PKGBuildInfoEvent eventWithFilePath:_buildOrder.projectPath]];

	// Check that the command line tools are installed
	
	if ([_fileManager fileExistsAtPath:PKGProjectBuilderToolPath_mkbom]==NO)
	{
		// Could not find mkbom
		
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"mkbom tool can not be found at %@",PKGProjectBuilderToolPath_mkbom];
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:PKGProjectBuilderToolPath_mkbom fileKind:PKGFileKindTool]];
		
		return;
	}
	
	if ([_fileManager fileExistsAtPath:PKGProjectBuilderToolPath_ditto]==NO)
	{
		// Could not find ditto
		
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"ditto tool can not be found at %@",PKGProjectBuilderToolPath_ditto];
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:PKGProjectBuilderToolPath_ditto fileKind:PKGFileKindTool]];
		
		return;
	}
	
	if ([_fileManager fileExistsAtPath:PKGProjectBuilderToolPath_goldin]==NO)
	{
		// Could not find the goldin or custom splitfork tools
		
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"goldin tool can not be found at %@",PKGProjectBuilderToolPath_goldin];
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:PKGProjectBuilderToolPath_goldin fileKind:PKGFileKindTool]];
		
		return;
	}
	
	// Read the document and launch the building
	
	NSError * tError;
	
	self.project=[PKGProject projectWithContentsOfFile:_buildOrder.projectPath error:&tError];
	
	if (self.project==nil)
	{
		PKGBuildErrorEvent * tErrorEvent=nil;
		
		if ([tError.domain isEqualToString:PKGPackagesModelErrorDomain]==YES)
		{
			NSString * tKey=tError.userInfo[PKGKeyPathErrorKey];
			
			switch(tError.code)
			{
				case PKGRepresentationNilRepresentationError:
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing value for key \"%@\"",tKey];
					
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingInformation tag:tKey];
					
					break;
				}
				
				case PKGRepresentationInvalidValueError:
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Incorrect value for key \"%@\"",tKey];
					
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:tKey];
					
					break;
				}
				
				case PKGRepresentationInvalidTypeOfValueError:
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Incorrect type of value for key \"%@\"",tKey];
					
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:tKey];
					
					break;
				}
					
				case PKGFileInvalidTypeOfFileError:
				{
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileIncorrectType filePath:_buildOrder.projectPath fileKind:PKGFileKindRegularFile];
					
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Unable to read file at path '%@'",_buildOrder.projectPath];
					
					break;
				}
			}
		}
		else
		{
			if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case NSFileReadUnknownError:
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeRead filePath:_buildOrder.projectPath fileKind:PKGFileKindRegularFile];
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Unable to read file at path '%@'",_buildOrder.projectPath];
						
						break;
					
					case NSFileNoSuchFileError:
					case NSFileReadNoSuchFileError:
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:_buildOrder.projectPath fileKind:PKGFileKindRegularFile];
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"File not found at path '%@'",_buildOrder.projectPath];
						
						break;
						
					case NSFileReadCorruptFileError:
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileIncorrectType filePath:_buildOrder.projectPath fileKind:PKGFileKindRegularFile];
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Unable to read file at path '%@'",_buildOrder.projectPath];
						
						break;
				}
			}
			else
			{
				tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileIncorrectType filePath:_buildOrder.projectPath fileKind:PKGFileKindRegularFile];
			
				[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Unable to read file at path '%@'",_buildOrder.projectPath];
			}
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		return;
	}
	
	// Create Scratch Location Folder
	
	if ([self createScratchLocationAtPath:[_buildOrder scratchFolderPath] error:&tError]==NO)
	{
		PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCreated filePath:@"Scratch_Location" fileKind:PKGFileKindFolder];
		
		if ([tError.domain isEqualToString:PKGPackagesProjectBuilderErrorDomain]==YES)
		{
			// A COMPLETER
		}
		else if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
		{
			switch(tError.code)
			{
				case NSFileWriteOutOfSpaceError:
					tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
					break;
					
				case NSFileWriteVolumeReadOnlyError:
					tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
					break;
				case NSFileWriteNoPermissionError:
					tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
					break;
			}
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		return;
	}
	
	// Initialize reference folders
	
	PKGProjectSettings * tProjectSettings=self.project.settings;
	
	_referenceProjectPath=[_buildOrder referenceProjectFolderPath];
	
	if (_referenceProjectPath==nil)
		_referenceProjectPath=[_buildOrder.projectPath stringByDeletingLastPathComponent];
	
	_referenceFolderPath=[_buildOrder referenceFolderPath];
	
	if (_referenceFolderPath==nil)
	{
		_referenceFolderPath=[tProjectSettings.referenceFolderPath stringByResolvingSymlinksInPath];
		
		if (_referenceFolderPath==nil)
			_referenceFolderPath=_referenceProjectPath;
	}
	
	// Replace the project values with the user defined ones
	
		// Build Folder
	
	NSString * tUserDefinedBuildFolder=[_buildOrder userDefinedSettingsForKey:PKGBuildOrderExternalSettingsBuildFolderKey];
	
	if (tUserDefinedBuildFolder!=nil)
	{
		if ([tUserDefinedBuildFolder isKindOfClass:NSString.class]==NO)
		{
			if (_scratchLocation!=nil)
			{
				[_fileManager removeItemAtPath:_scratchLocation error:NULL];
				_scratchLocation=nil;
			}
			
			// A COMPLETER
			
			return;
		}
	
		if (tUserDefinedBuildFolder.length>0)
			tProjectSettings.buildPath=[PKGFilePath filePathWithAbsolutePath:tUserDefinedBuildFolder];
	}
	
		// Signing Identity and Keychain
	
	NSString * tUserDefinedSigningIdentity=[_buildOrder userDefinedSettingsForKey:PKGBuildOrderExternalSettingsSigningIdentityKey];
	
	if (tUserDefinedSigningIdentity!=nil)
	{
		if ([tUserDefinedSigningIdentity isKindOfClass:NSString.class]==NO)
		{
			if (_scratchLocation!=nil)
			{
				[_fileManager removeItemAtPath:_scratchLocation error:NULL];
				_scratchLocation=nil;
			}
			
			// A COMPLETER
			
			return;
		}
		
		tProjectSettings.certificateName=tUserDefinedSigningIdentity;
	}
	
	NSString * tUserDefinedKeychain=[_buildOrder userDefinedSettingsForKey:PKGBuildOrderExternalSettingsKeychainKey];
	
	if (tUserDefinedKeychain!=nil)
	{
		if ([tUserDefinedKeychain isKindOfClass:NSString.class]==NO)
		{
			// A COMPLETER
		}
		
		tProjectSettings.certificateKeychainPath=tUserDefinedKeychain;
	}
	
	// Prepare the Build folder
	
	PKGFilePath * tBuildPath=tProjectSettings.buildPath;
	
	if (tBuildPath.isSet==NO)
	{
		switch(tBuildPath.type)
		{
			case PKGFilePathTypeAbsolute:
				
				tBuildPath.string=@"build";
				tBuildPath.type=PKGFilePathTypeRelativeToProject;
				
				break;
				
			case PKGFilePathTypeRelativeToProject:
			case PKGFilePathTypeRelativeToReferenceFolder:
				
				tBuildPath.string=@"build";
				
				break;
				
			default:
				
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:@"BUILD_PATH"]];
				
				return;
		}
	}
	
	NSString * tBuildFolderPath=[self prepareBuildFolderAtPath:[self absolutePathForFilePath:tBuildPath]];
	
	if (tBuildFolderPath==nil)
	{
		if (_scratchLocation!=nil)
		{
			[_fileManager removeItemAtPath:_scratchLocation error:NULL];
			_scratchLocation=nil;
		}
		
		return;
	}
	
	// Excluded files
	
	_patternsRegister=[[PKGPathComponentPatternsRegister alloc] initWithFilesFilters:tProjectSettings.filesFilters];
	
	if (_patternsRegister==nil)
	{
		if (_scratchLocation!=nil)
		{
			[_fileManager removeItemAtPath:_scratchLocation error:NULL];
			_scratchLocation=nil;
		}
		
		[self postCurrentStepFailureEvent:nil];	// A COMPLETER
		
		return;
	}
	
	
	// Start the real building process
	
	PKGProjectType tProjectType=self.project.type;
	BOOL tResult;
	
	// Build the Package or Distribution Script

	switch(tProjectType)
	{
		case PKGProjectTypeDistribution:
			tResult=[self buildDistributionProjectAtPath:tBuildFolderPath];
			break;
			
		case PKGProjectTypePackage:
			tResult=[self buildPackageProjectAtPath:tBuildFolderPath];
			break;
	}
	
	// Try to remove the temporary folder

	if (_scratchLocation!=nil)
	{
		[_fileManager removeItemAtPath:_scratchLocation error:NULL];
		_scratchLocation=nil;
	}
	
	if (tResult==NO)
		return;
		
	[self postStep:PKGBuildStepProject successEvent:nil];
}

#pragma mark -

- (BOOL)buildDistributionProjectAtPath:(NSString *) inPath
{
	[self postStep:PKGBuildStepDistribution beginEvent:nil];
	
	// Build the Bundle Skeleton
	
	PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)self.project;
	
	PKGDistributionProjectSettings * tDistributionProjectSettings=(PKGDistributionProjectSettings *)tDistributionProject.settings;
	
	_buildFormat=tDistributionProjectSettings.buildFormat;
	
	// Get the name

	NSString * tDistributionName=tDistributionProjectSettings.name;

	if (tDistributionName==nil)
	{
		// Missing Information
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingInformation tag:@"PKGProjectSettingsNameKey"]];
		
		return NO;
	}
	
	if ([tDistributionName length]==0)
	{
		// Empty String Value
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGProjectSettingsNameKey"]];
		
		return NO;
	}
	
	// Build the Packages
	
	NSArray * tPackagesComponents=tDistributionProject.packageComponents;
	
	
	NSString * tBundlePath=nil;		// Only used for bundle
	
	PKGPresentationInstallationTypeStepSettings * tInstallationTypeStepSettings=tDistributionProject.presentationSettings.installationTypeSettings;
	
	if (tInstallationTypeStepSettings==nil)
	{
		tInstallationTypeStepSettings=[[PKGPresentationInstallationTypeStepSettings alloc] initWithPackagesComponents:tPackagesComponents];
		
		if (tInstallationTypeStepSettings==nil)
		{
			// A COMPLETER
			
			return NO;
		}
		
		tDistributionProject.presentationSettings.installationTypeSettings=tInstallationTypeStepSettings;
	}
	
	// Find the list of Packages that are required to be be built
	
	BOOL (^removePreviousBuildIfNeeded)(NSString *)=^BOOL(NSString * inPreviousBuildPath){
	
		if ([_fileManager fileExistsAtPath:inPreviousBuildPath]==YES)
		{
			PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
			
			NSError * tError;
			
			if ([_fileManager removeItemAtPath:inPreviousBuildPath error:&tError]==NO)
			{
				PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:inPreviousBuildPath fileKind:PKGFileKindPackage];
				
				if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
				{
					switch(tError.code)
					{
						case NSFileWriteVolumeReadOnlyError:
							tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
							break;
						case NSFileWriteNoPermissionError:
							tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
							break;
					}
				}
				
				[self postCurrentStepFailureEvent:tErrorEvent];
					
				return NO;
			}
			
			tStackedEffectiveUserAndGroup=nil;
		}
		
		return YES;
	};
	
	NSString * tContentsPath=nil;
	
	switch(_buildFormat)
	{
		case PKGProjectBuildFormatBundle:
		{
			// Bundle
			
			tBundlePath=[inPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mpkg",tDistributionName]];
			
			// Remove a previous build if needed
			
			if (removePreviousBuildIfNeeded(tBundlePath)==NO)
				return NO;
			
			// Build the Skeleton
			
			PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
			
			if ([self createDirectoryAtPath:tBundlePath withIntermediateDirectories:NO]==NO) // .mpkg/
				return NO;
			
			tContentsPath=[tBundlePath stringByAppendingPathComponent:@"Contents"];
			
			if ([self createDirectoryAtPath:tContentsPath withIntermediateDirectories:NO]==NO) // Contents/
				return NO;
			
			NSString * tPackagesPath=[tContentsPath stringByAppendingPathComponent:@"Packages"];
			
			if ([self createDirectoryAtPath:tPackagesPath withIntermediateDirectories:NO]==NO) // Packages/
				return NO;
			
			tStackedEffectiveUserAndGroup=nil;
		
			break;
		}
		
		case PKGProjectBuildFormatFlat:
		{
			// Flat
			
			tBundlePath=[inPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pkg",tDistributionName]];
			
			// Remove a previous build if needed
			
			if (removePreviousBuildIfNeeded(tBundlePath)==NO)
				return NO;
			
			tContentsPath=[_scratchLocation stringByAppendingPathComponent:@"_root_"];
			
			if ([_fileManager fileExistsAtPath:tContentsPath]==NO)
			{
				// Try to create the directory
				
				if ([self createDirectoryAtPath:tContentsPath withIntermediateDirectories:NO]==NO ) // _root_/
					return NO;
			}
			
			break;
		}
	}
	
	_buildInformation.contentsPath=tContentsPath;
	
	// Build the list of Packages that are required to be be built
	
	NSSet * tPackagesToBeBuilt=[tInstallationTypeStepSettings allPackagesUUIDs];
	
	if (tPackagesToBeBuilt.count>0)
		[self postCurrentStepInfoEvent:[PKGBuildInfoEvent infoEventWithPackagesCount:tPackagesToBeBuilt.count]];
	
	BOOL tBuildFlatPackage=(_buildFormat==PKGProjectBuildFormatFlat);
	
	for(PKGPackageComponent * tPackageComponent in tPackagesComponents)
	{
		if ([tPackagesToBeBuilt containsObject:tPackageComponent.UUID]==YES)
		{
			if ([self buildPackageObject:tPackageComponent atPath:tBundlePath flat:tBuildFlatPackage]==NO)
				return NO;
		}
	}
	
	// Build the Distribution Script
					
	NSString * tDistributionScriptsPath=nil;
	
	switch(_buildFormat)
	{
		case PKGProjectBuildFormatBundle:
		{
			PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
			
			tDistributionScriptsPath=_buildInformation.resourcesPath;
			
			tStackedEffectiveUserAndGroup=nil;
			
			break;
		}
		case PKGProjectBuildFormatFlat:
		
			tDistributionScriptsPath=[_scratchLocation stringByAppendingPathComponent:@"_dist_scripts_"];
			
			// Try to create the directory
				
			if ([self createDirectoryAtPath:tDistributionScriptsPath withIntermediateDirectories:NO]==NO)
				return NO;
			
			break;
	}
	
	_buildInformation.scriptsPath=tDistributionScriptsPath;
	
	[self postStep:PKGBuildStepDistributionScript beginEvent:nil];
	
	
	_installerScriptElement=(NSXMLElement *) [NSXMLNode elementWithName:@"installer-gui-script"];
	
	// authoringTool
	
	id tAttribute=[NSXMLNode attributeWithName:@"authoringTool" stringValue:PKGProjectBuilderAuthoringToolName];
	[_installerScriptElement addAttribute:tAttribute];
		
	// authoringToolVersion
		
	tAttribute=[NSXMLNode attributeWithName:@"authoringToolVersion" stringValue:PKGProjectBuilderAuthoringToolVersion];
	[_installerScriptElement addAttribute:tAttribute];
		
	// authoringToolBuild
		
	tAttribute=[NSXMLNode attributeWithName:@"authoringToolBuild" stringValue:@TOOL_BUILD_NUMBER];
	[_installerScriptElement addAttribute:tAttribute];
	
	// Options
	
	[self setDistributionOptions];
	
	// Requirements
	
	if ([self setRequirements]==NO)
		return NO;
	
	// Presentation
	
	if ([self setPresentation]==NO)
		return NO;
	
	// Choices/Requirements
	

				
	// JavaScript Scripts
	
	[self setJavaScriptScripts];
	
	// Create Localizable.strings files

	if ([self setLocalizableStrings]==NO)
		return NO;
	
	// Advanced Options

	if ([self setAdvancedDistributionOptions]==NO)
	{
		[self postCurrentStepFailureEvent:nil];	// A COMPLETER
		
		return NO;
	}
	
	// Requirement additional Options

	if ([self setRequirementsDistributionOptions]==NO)
	{
		[self postCurrentStepFailureEvent:nil];	// A COMPLETER
		
		return NO;
	}
	
	// Add the Resources

	if ([self setDistributionResources]==NO)
	{
		// A COMPLETER (very unlikely to be NO)
		
		return NO;
	}
	
	// Extra Resources

	if ([self setExtraResources]==NO)
		return NO;
	
	// Build the Scripts distribution archive
	
	if (_buildFormat==PKGProjectBuildFormatFlat && [self buildDistributionScripts]==NO)
	{
		// A COMPLETER
		
		if ([_fileManager removeItemAtPath:tContentsPath error:NULL]==NO)
		{
			// A COMPLETER
		}
		
		return NO;
	}
	
	// Plug-ins

	if ([self setPlugins]==NO)
		return NO;

	// XML Document

	NSXMLDocument * tXMLDocument=[[NSXMLDocument alloc] initWithRootElement:_installerScriptElement];
	[tXMLDocument setCharacterEncoding:@"UTF-8"];
	
	
	
	NSData * tData=[tXMLDocument XMLDataWithOptions:NSXMLDocumentTidyHTML|NSXMLNodePrettyPrint|NSXMLNodeCompactEmptyElement];
	
	if (tData==nil)
	{
		// A COMPLETER
		
		return NO;
	}
	
	PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=nil;
	
	NSString * tDistributionScriptFileName=@"";
	
	if (_buildFormat==PKGProjectBuildFormatBundle)
	{
		tDistributionScriptFileName=@"distribution.dist";
		
		tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
	}
	else if (_buildFormat==PKGProjectBuildFormatFlat)
	{
		tDistributionScriptFileName=@"Distribution";
	}
	
	NSError * tError;
	
	if ([tData writeToFile:[tContentsPath stringByAppendingPathComponent:tDistributionScriptFileName] options:0 error:&tError]==NO)
	{
		if (tError!=nil)
		{
			// A COMPLETER
		}
		
		// Unable to write file
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCreated filePath:[tContentsPath stringByAppendingPathComponent:tDistributionScriptFileName] fileKind:PKGFileKindRegularFile]];
		
		return NO;
	}
	
	tStackedEffectiveUserAndGroup=nil;
	
	[self postCurrentStepSuccessEvent:nil];
	
	if (_buildFormat==PKGProjectBuildFormatFlat)
	{
		if ([self isCertificateSetForProjectSettings:self.project.settings]==YES)
		{
			if (_secIdentityRef==NULL)
			{
				_secIdentityRef=[self secIdentifyForProjectSettings:self.project.settings];
				
				if (_secIdentityRef==NULL)
					return NO;
			}
		}
		
		// Build the xar archive
		
		tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];

		NSString * tArchivePath=[inPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pkg",tDistributionName]];
		
		if ([_fileManager fileExistsAtPath:tArchivePath]==YES)
		{
			// We need to remove the existing instance
			
			if ([_fileManager removeItemAtPath:tArchivePath error:NULL]==NO)
			{
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tArchivePath fileKind:PKGFileKindPackage]];
				
				return NO;
			}
		}
		
		PKGArchive * tArchive=[[PKGArchive alloc] initWithPath:tArchivePath];
		tArchive.delegate=self;
		
		[self postStep:PKGBuildStepXarCreate beginEvent:nil];
		
		_signatureResult=0;
		
		if ([tArchive createArchiveWithContentsAtPath:tContentsPath error:&tError]==NO)
		{
			if (tError!=nil)
			{
				PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent new];
				
				if ([tError.domain isEqualToString:PKGArchiveErrorDomain]==YES)
				{
					switch(tError.code)
					{
						case PKGArchiveErrorFileCanNotBeCreated:
							// A COMPLETER
							break;
							
						case PKGArchiveErrorCertificatesCanNotBeRetrieved:
							
							tErrorEvent=[self buildErrorEventWithSignatureResult:_signatureResult];
							
							break;
							
						case PKGArchiveErrorMemoryAllocationFailed:
							
							tErrorEvent.code=PKGBuildErrorOutOfMemory;
							break;
					}
				}
				else if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
				{
					
				}
				
				[self postCurrentStepFailureEvent:tErrorEvent];
			}
			else
			{
				PKGBuildErrorEvent * tErrorEvent=[self buildErrorEventWithSignatureResult:_signatureResult];
				
				[self postCurrentStepFailureEvent:tErrorEvent];
			}
			
			// A COMPLETER
			
			return NO;
		}
		
		[self postCurrentStepSuccessEvent:nil];
		
		tStackedEffectiveUserAndGroup=nil;
		
		// Remove the Packages Working folder
	
		if ([_fileManager removeItemAtPath:tContentsPath error:NULL]==NO)	// A VOIR (Warning plutot non ?)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tContentsPath fileKind:PKGFileKindFolder]];
			
			return NO;
		}
	}

	[self postCurrentStepSuccessEvent:nil];
	
	if ((_buildOrder.buildOptions|PKGBuildOptionLaunchAfterBuild)==PKGBuildOptionLaunchAfterBuild)
		[self postCurrentStepInfoEvent:[PKGBuildInfoEvent eventWithFilePath:tBundlePath]];
	
	return YES;
}

#pragma mark -

- (BOOL)buildPackageProjectAtPath:(NSString *)inPath
{
	[self postStep:PKGBuildStepPackage beginEvent:nil];
	
	PKGProjectSettings * tProjectSettings=self.project.settings;
	
	// Get the Project name
		
	NSString * tPackageName=tProjectSettings.name;
		
	if (tPackageName==nil)
	{
		// Missing Information
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingInformation tag:@"PKGProjectSettingsNameKey"]];
		
		return NO;
	}
	
	if (tPackageName.length==0)
	{
		// String is Empty
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGProjectSettingsNameKey"]];
		
		return NO;
	}
	
	NSString * tPath=[inPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pkg",tPackageName]];
	
	// Package Build Process: Start
	
	if ([self buildPackageObject:(PKGPackageProject *)self.project atPath:tPath flat:YES]==NO)
		return NO;
	
	[self postCurrentStepSuccessEvent:nil];
	
	if ((_buildOrder.buildOptions|PKGBuildOptionLaunchAfterBuild)==PKGBuildOptionLaunchAfterBuild)
		[self postCurrentStepInfoEvent:[PKGBuildInfoEvent eventWithFilePath:tPath]];

	return YES;
}

#pragma mark -

- (void)setDistributionOptions
{
	NSXMLElement * tOptionsElement=(NSXMLElement *) [NSXMLNode elementWithName:@"options"];
	id tAttribute;
	
	// rootVolumeOnly
	
	PKGDistributionProjectRequirementsAndResources * tRequirementsAndResources=((PKGDistributionProject *)self.project).requirementsAndResources;
	
	if (tRequirementsAndResources!=nil && tRequirementsAndResources.rootVolumeOnlyRequirement==YES)
	{
		tAttribute=[NSXMLNode attributeWithName:@"rootVolumeOnly" stringValue:@"true"];
		[tOptionsElement addAttribute:tAttribute];
	}
	
	// customize
	
	PKGDistributionProjectPresentationSettings * tPresentationSettings=((PKGDistributionProject *)self.project).presentationSettings;
	PKGPresentationInstallationTypeStepSettings * tInstallationTypeSettings=tPresentationSettings.installationTypeSettings;
	
	if (tInstallationTypeSettings!=nil)		// If nil PKGPresentationInstallationTypeStandardOrCustomInstall is the default value so nothing to do
	{
		PKGPresentationInstallationTypeMode tInstallationTypeMode=tInstallationTypeSettings.mode;
		
		switch(tInstallationTypeMode)
		{
			case PKGPresentationInstallationTypeStandardOrCustomInstall:
				
				break;
			
			case PKGPresentationInstallationTypeStandardInstallOnly:
				
				tAttribute=[NSXMLNode attributeWithName:@"customize" stringValue:@"never"];
				[tOptionsElement addAttribute:tAttribute];
				break;
				
			case PKGPresentationInstallationTypeCustomInstallOnly:
				
				tAttribute=[NSXMLNode attributeWithName:@"customize" stringValue:@"always"];
				[tOptionsElement addAttribute:tAttribute];
				break;
		}
	}
	
	// allow-external-scripts
	
	// A COMPLETER
	
	[_installerScriptElement addChild:tOptionsElement];
}

- (BOOL)fillDistributionXMLWithDictionary:(NSDictionary *) inDictionary
{
	if (inDictionary==nil)
		return NO;
	
	[inDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bKey,id bValue,BOOL *bOutStop){
	
		if ([bValue isKindOfClass:NSString.class]==YES && [(NSString *)bValue length]==0)
			return;
		
		id tAttribute=nil;
		
		NSArray * tKeyPath=[bKey componentsSeparatedByString:@":"];
		
		if (tKeyPath.count!=2)
		{
			// A COMPLETER
			
			*bOutStop=YES;
			
			return;
		}

		NSString * tAttributeName=tKeyPath[1];
		
		NSArray * tElementsPathArray=[tKeyPath[0] componentsSeparatedByString:@"."];
		
		NSUInteger tCount=tElementsPathArray.count;
		
		if (tCount==0)
		{
			// A COMPLETER
			
			*bOutStop=YES;
			
			return;
		}
		
		NSXMLElement * tElement=_installerScriptElement;
	
		for(NSUInteger tIndex=1;tIndex<tCount;tIndex++)
		{
			NSString * tElementName=tElementsPathArray[tIndex];
			NSXMLElement * tParentElement=tElement;
			
			NSArray * tArray=[tParentElement elementsForName:tElementName];
			
			if (tArray.count==0)
			{
				// Create the element
				
				tElement=[NSXMLNode elementWithName:tElementName];
				[tParentElement addChild:tElement];
			}
			else
			{
				tElement=tArray[0];
			}
		}
		
		NSString * tString=nil;
		
		if ([bValue isKindOfClass:NSNumber.class]==YES)
		{
			tString=([bValue boolValue]==YES) ? @"true" : @"false";
		}
		else if ([bValue isKindOfClass:NSString.class]==YES)
		{
			tString=bValue;
		}
		else if ([bValue isKindOfClass:NSArray.class]==YES)
		{
			tString=[bValue componentsJoinedByString:@","];
			
			if ([tString length]==0)
			{
				// If the string is empty, we do not need to create the options
				
				return;
			}
		}
		else
		{
			// A COMPLETER
			
			return;
		}
		
		tAttribute=[tElement attributeForName:tAttributeName];
		if (tAttribute!=nil)
			[tElement removeAttributeForName:tAttributeName];
		
		tAttribute=[NSXMLNode attributeWithName:tAttributeName stringValue:tString];
		[tElement addAttribute:tAttribute];
	}];
	
	return YES;
}

- (BOOL)setAdvancedDistributionOptions
{
	PKGDistributionProjectSettings * tProjectSettings=(PKGDistributionProjectSettings *)self.project.settings;
	NSDictionary * tAdvancedOptionsDictionary=tProjectSettings.advancedOptions;
	BOOL tMinSpecVersionSet=NO;
	
	if (tAdvancedOptionsDictionary!=nil)
	{
		// Update Keys to use the installer-gui-script name instead of installer-script
		
		NSMutableDictionary * tAdvancedOptionsMutableDictionary=[[tAdvancedOptionsDictionary WB_dictionaryByMappingKeysUsingBlock:^NSString *(NSString *bKey,id bObject){
		
			if ([bKey hasPrefix:@"installer-script"]==NO)
				return bKey;
			
			return [@"installer-gui-script" stringByAppendingString:[bKey substringFromIndex:[@"installer-script" length]]];
		}] mutableCopy];
		
		if (tAdvancedOptionsMutableDictionary==nil)
			return NO;
		
		id tValue=tAdvancedOptionsMutableDictionary[@"installer-gui-script:minSpecVersion"];
	
		if ([tValue isKindOfClass:NSString.class]==YES && [(NSString *)tValue length]>0)
			tMinSpecVersionSet=YES;
		
		// product element
		
		tValue=tAdvancedOptionsMutableDictionary[@"installer-gui-script.product:id"];
		
		if ([tValue isKindOfClass:NSString.class]==YES && [(NSString *)tValue length]==0)
			[tAdvancedOptionsMutableDictionary removeObjectForKey:@"installer-gui-script.product:id"];
		
		tValue=tAdvancedOptionsMutableDictionary[@"installer-gui-script.product:version"];
		
		if ([tValue isKindOfClass:NSString.class]==YES && [(NSString *)tValue length]==0)
			[tAdvancedOptionsMutableDictionary removeObjectForKey:@"installer-gui-script.product:version"];
		
		// domains element
		
		NSNumber * tDomainsAnywhereValue=tAdvancedOptionsMutableDictionary[@"installer-gui-script.domains:enable_anywhere"];
		
		if (tDomainsAnywhereValue!=nil && [tDomainsAnywhereValue isKindOfClass:NSNumber.class]==NO)
			return NO;
		
		NSNumber * tDomainsLocalSystemValue=tAdvancedOptionsMutableDictionary[@"installer-gui-script.domains:enable_localSystem"];
		
		if (tDomainsLocalSystemValue!=nil && [tDomainsLocalSystemValue isKindOfClass:NSNumber.class]==NO)
			return NO;
		
		NSNumber * tDomainsCurrentUserHomeValue=tAdvancedOptionsMutableDictionary[@"installer-gui-script.domains:enable_currentUserHome"];
		
		if (tDomainsCurrentUserHomeValue!=nil && [tDomainsCurrentUserHomeValue isKindOfClass:NSNumber.class]==NO)
			return NO;
		
		if (([tDomainsAnywhereValue boolValue]==YES || [tDomainsLocalSystemValue boolValue]==YES || [tDomainsCurrentUserHomeValue boolValue]==YES) &&
			(tDomainsAnywhereValue==nil || tDomainsLocalSystemValue==nil || tDomainsCurrentUserHomeValue==nil))
		{
			if (tDomainsAnywhereValue==nil)
				tAdvancedOptionsMutableDictionary[@"installer-gui-script.domains:enable_anywhere"]=@(NO);
			
			if (tDomainsLocalSystemValue==nil)
				tAdvancedOptionsMutableDictionary[@"installer-gui-script.domains:enable_localSystem"]=@(NO);

			if (tDomainsCurrentUserHomeValue==nil)
				tAdvancedOptionsMutableDictionary[@"installer-gui-script.domains:enable_currentUserHome"]=@(NO);
		}
		else if ([tDomainsAnywhereValue boolValue]==NO && [tDomainsLocalSystemValue boolValue]==NO && [tDomainsCurrentUserHomeValue boolValue]==NO)
		{
			[tAdvancedOptionsMutableDictionary removeObjectsForKeys:@[@"installer-gui-script.domains:enable_anywhere",
																	  @"installer-gui-script.domains:enable_localSystem",
																	  @"installer-gui-script.domains:enable_currentUserHome"]];
		}
		
		if ([self fillDistributionXMLWithDictionary:[tAdvancedOptionsMutableDictionary copy]]==NO)
			return NO;
	}
	
	if (tMinSpecVersionSet==NO)
	{
		// At least set the minSpecVersion
		
		id tAttribute=[NSXMLNode attributeWithName:@"minSpecVersion" stringValue:@"1.0"];
		[_installerScriptElement addAttribute:tAttribute];
	}
	
	return YES;
}

- (BOOL)setRequirementsDistributionOptions
{
	return [self fillDistributionXMLWithDictionary:_buildInformation.requirementsOptions];
}

- (BOOL)setDistributionResources
{
	PKGDistributionProjectRequirementsAndResources * tRequirementsAndResources=((PKGDistributionProject *)self.project).requirementsAndResources;
	
	if (tRequirementsAndResources==nil)
		return YES;
	
	PKGResourcesForest * tResourcesForest=tRequirementsAndResources.resourcesForest;
	
	PKGRootNodesTuple * tTuple=tResourcesForest.rootNodes;
	
	if (tTuple.error!=nil)
	{
		PKGBuildErrorEvent * tErrorEvent=nil;
		
		if ([tTuple.error.domain isEqualToString:PKGPackagesModelErrorDomain]==YES)
		{
			NSString * tKey=tTuple.error.userInfo[PKGKeyPathErrorKey];
			
			switch(tTuple.error.code)
			{
				case PKGRepresentationNilRepresentationError:
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing value for key \"%@\"",tKey];
					
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingInformation tag:tKey];
					
					break;
				}
					
				case PKGRepresentationInvalidValueError:
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Incorrect value for key \"%@\"",tKey];
					
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:tKey];
					
					break;
				}
					
				case PKGRepresentationInvalidTypeOfValueError:
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Incorrect type of value for key \"%@\"",tKey];
					
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:tKey];
					
					break;
				}
					
				case PKGFileInvalidTypeOfFileError:
				{
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileIncorrectType filePath:_buildOrder.projectPath fileKind:PKGFileKindRegularFile];
					
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Unable to read file at path '%@'",_buildOrder.projectPath];
					
					break;
				}
			}
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		return NO;
	}
	
	if (tTuple.array.count==0)
		return YES;
	
	[self postStep:PKGBuildStepDistributionResources beginEvent:nil];

	
	NSString * tResourcesPath=_buildInformation.scriptsPath;
	
	PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=nil;
	
	if (_buildFormat==PKGProjectBuildFormatBundle)
		tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
	
	// Copy the file hierarchy
	
	for(PKGResourcesTreeNode * tRootNode in tTuple.array)
	{
		if ([self buildFileHierarchyComponent:tRootNode atPath:tResourcesPath contextInfo:nil]==NO)
		{
			// A COMPLETER
			
			return NO;
		}
	}
	
	// Remove the files defined as exceptions
	
	PKGProjectSettings * tProjectSettings=self.project.settings;
	
	if (tProjectSettings.filterPayloadOnly==NO)
	{
		NSError * tError=nil;
		
		if ([_patternsRegister filterContentsAtPath:tResourcesPath error:&tError]==NO)
		{
			PKGBuildErrorEvent * tErrorEvent=nil;
			
			if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tError.userInfo[NSFilePathErrorKey] fileKind:PKGFileKindRegularFile];
				
				if (tErrorEvent!=nil)
				{
					switch(tError.code)
					{
						case NSFileNoSuchFileError:
							
							tErrorEvent.subcode=PKGBuildErrorFileNotFound;
							break;
							
						case NSFileWriteNoPermissionError:
							
							tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
							break;
							
						case NSFileWriteVolumeReadOnlyError:
							
							tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
							break;
					}
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
	}
	
	tStackedEffectiveUserAndGroup=nil;
	
	[self postCurrentStepSuccessEvent:nil];
									   
	return YES;
}

- (BOOL)setExtraResources
{
	NSString * tDestinationDirectory=_buildInformation.scriptsPath;
			
	PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=nil;
	
	if (_buildFormat==PKGProjectBuildFormatBundle)
		tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
	
	// Make sure we only add an extra resource once.
	
	NSMutableSet * tAbsolutePathsSet=[NSMutableSet set];
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	__block BOOL tPathComputeError=NO;
	
	[_buildInformation.resourcesExtras enumerateObjectsUsingBlock:^(PKGAdditionalResource * bAdditionalResource,NSUInteger bIndex,BOOL * bOutStop){
	
		NSString * tSourcePath=[self absolutePathForFilePath:bAdditionalResource.filePath];
		
		if (tSourcePath==nil)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:bAdditionalResource.filePath.string fileKind:PKGFileKindRegularFile]];
			*bOutStop=YES;
			
			tPathComputeError=YES;
			
			return;
		}
		
		if ([tAbsolutePathsSet containsObject:tSourcePath]==NO)
			[tAbsolutePathsSet addObject:tSourcePath];
		else
			[tMutableIndexSet addIndex:bIndex];
	}];
	
	if (tPathComputeError==YES)
		return NO;
	
	[_buildInformation.resourcesExtras removeObjectsAtIndexes:tMutableIndexSet];
	
	
	for(PKGAdditionalResource * tAdditionalResource in _buildInformation.resourcesExtras)
	{
		NSString * tSourcePath=[self absolutePathForFilePath:tAdditionalResource.filePath];
		
		if ([_fileManager fileExistsAtPath:tSourcePath]==NO)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tSourcePath fileKind:PKGFileKindRegularFile]];
			
			return NO;
		}
		
		if ([_fileManager fileExistsAtPath:[tDestinationDirectory stringByAppendingPathComponent:[tSourcePath lastPathComponent]]]==YES)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCopied filePath:tSourcePath fileKind:PKGFileKindRegularFile];
			tErrorEvent.subcode=PKGBuildErrorFileAlreadyExists;
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
		
		// Copy the file
		
		NSString * tDestinationPath=[tDestinationDirectory stringByAppendingPathComponent:tSourcePath.lastPathComponent];
		
		NSError * tCopyError=NULL;
		
		if ([_fileManager copyItemAtPath:tSourcePath toPath:tDestinationPath error:&tCopyError]==NO)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCopied filePath:tSourcePath fileKind:PKGFileKindRegularFile];
			tErrorEvent.otherFilePath=tDestinationDirectory;
			
			if (tCopyError!=nil && [tCopyError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				switch(tCopyError.code)
				{
					case NSFileNoSuchFileError:
						
						tErrorEvent.subcode=PKGBuildErrorFileNotFound;
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"[PKGProjectBuilder setExtraResources] File not found"];
						
						break;
						
					case NSFileWriteOutOfSpaceError:
						
						tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"[PKGProjectBuilder setExtraResources] Not enough free space"];
						
						break;
						
					case NSFileWriteVolumeReadOnlyError:
						
						tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
						
						break;
						
					case NSFileWriteNoPermissionError:
						
						tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"[PKGProjectBuilder setExtraResources] Write permission error"];
						
						break;
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
		
		mode_t tSourcePermissions=tAdditionalResource.mode;
		
		if (tSourcePermissions==0)
			tSourcePermissions=0775;
		
		// Set the Permissions
		
		NSError * tError=nil;
		
		if ([_fileManager PKG_setPosixPermissions:tSourcePermissions ofItemAtPath:tDestinationPath error:&tError]==NO)
		{
			[self postCurrentStepFailureEvent:nil];		// A COMPLETER
			
			return NO;
		}
	}
	
	tStackedEffectiveUserAndGroup=nil;
	
	return YES;
}

#pragma mark -

- (BOOL)addLocalizedErrorMessages:(NSDictionary *)inLocalizationsDictionary withName:(NSString *)inName errorMessage:(NSString **)outErrorMessage errorDescription:(NSString **)outErrorDescription
{
	if (inLocalizationsDictionary==nil || inName==nil || outErrorMessage==NULL)
		return NO;
	
	if (inLocalizationsDictionary.count==0)
		return YES;
	
	(*outErrorMessage)=[NSString stringWithFormat:@"REQUIREMENT_FAILED_MESSAGE_%@",[inName uppercaseString]];

	if (outErrorDescription!=NULL)
		(*outErrorDescription)=nil;
	
	NSMutableDictionary * tLocalizationsDictionary=_buildInformation.localizations;
	
	[inLocalizationsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguage,PKGRequirementFailureMessage * bMessage,BOOL * bOutStop){
	
		NSMutableDictionary * tLanguageLocalizationsDictionary=tLocalizationsDictionary[bLanguage];
		
		if (tLanguageLocalizationsDictionary==nil)
			tLanguageLocalizationsDictionary=tLocalizationsDictionary[bLanguage]=[NSMutableDictionary dictionary];
		
		NSString * tLocalization=bMessage.messageTitle;
		
		if (tLocalization.length==0)
			tLocalization=@" ";
		
		tLanguageLocalizationsDictionary[*outErrorMessage]=tLocalization;
		
		if (outErrorDescription!=NULL)
		{
			tLocalization=bMessage.messageDescription;
			
			if (tLocalization!=nil)
			{
				if ((*outErrorDescription)==nil)
					(*outErrorDescription)=[NSString stringWithFormat:@"REQUIREMENT_FAILED_DESCRIPTION_%@",[inName uppercaseString]];
				
				if ([tLocalization length]==0)
					tLocalization=@" ";
				
				tLanguageLocalizationsDictionary[*outErrorDescription]=tLocalization;
			}
		}
	}];
	
	// Set the default value

	NSMutableDictionary * tDefaultLanguageDictionary=tLocalizationsDictionary[PKGBuildDefaultLanguageKey];
	
	tDefaultLanguageDictionary[(*outErrorMessage)]=@"";
							
	if (outErrorDescription!=NULL && (*outErrorDescription)!=nil)
		tDefaultLanguageDictionary[(*outErrorDescription)]=@"";
	
	return YES;
}

- (BOOL)setRequirements
{
	PKGDistributionProjectRequirementsAndResources * tProjectRequirementsAndResources=((PKGDistributionProject *)self.project).requirementsAndResources;
	
	BOOL tLeopardInstallationCheckRequired=(_buildFormat==PKGProjectBuildFormatBundle);
	
	if (tProjectRequirementsAndResources==nil && tLeopardInstallationCheckRequired==NO)
		return YES;
	
	NSMutableArray * tRequirementsArray=(tProjectRequirementsAndResources!=nil) ? tProjectRequirementsAndResources.requirements : [NSMutableArray array];

	if (tLeopardInstallationCheckRequired==YES)
	{
		// We need to add a OS requirement
		
		NSDictionary * tSettingsRepresentation=@{@"IC_REQUIREMENT_OS_DISK_TYPE":@(1),
												 @"IC_REQUIREMENT_OS_DISTRIBUTION_TYPE":@(0),
												 @"IC_REQUIREMENT_OS_MINIMUM_VERSION":@(100500)};
		
		PKGRequirement * tLeopardRequirement=[[PKGRequirement alloc] init];
		
		tLeopardRequirement.enabled=YES;
		tLeopardRequirement.identifier=@"fr.whitebox.Packages.requirement.os";
		tLeopardRequirement.type=PKGRequirementTypeInstallation;
		tLeopardRequirement.settingsRepresentation=tSettingsRepresentation;
		tLeopardRequirement.failureBehavior=PKGRequirementOnFailureBehaviorInstallationStop;
		
		[tRequirementsArray insertObject:tLeopardRequirement atIndex:0];
	}
	
	// Filter the requirements based on the enabled state
	
	tRequirementsArray=[tRequirementsArray WB_filteredArrayUsingBlock:^BOOL(PKGRequirement * bRequirement,NSUInteger bIndex) {
	
		return bRequirement.enabled;
	}];
	
	if (tRequirementsArray.count==0)
		return YES;
	
	[self postStep:PKGBuildStepDistributionInstallationRequirements beginEvent:nil];
	
	// Sort by Failure Priority
	
	[tRequirementsArray sortUsingSelector:@selector(compareFailureBehavior:)];
	
	int tInstallationCheckDepth=-1,tVolumeCheckDepth=-1;
	NSString * tInstallationCheckTabulationDepth=@"\t",* tVolumeCheckTabulationDepth=@"\t";
	int tInstallationCheckIndex=0,tVolumeCheckIndex=0;
	int tRequirementIndex=0;
	NSString * tVolumeCheckPreTest=@"", * tInstallationCheckPreTest=@"";
	
	NSMutableString * tVolumeCheckFunctionCode=[NSMutableString stringWithString:@"\tfunction volume_check()\n\
\t{\n\
\t\tvar tResult;\n\n"];

	NSMutableString * tInstallationCheckFunctionCode=[NSMutableString stringWithString:@"\tfunction installation_check()\n\
\t{\n\
\t\tvar tResult;\n\n"];
				
	PKGBuildJavaScriptInformation * tJavaScriptInformation=_buildInformation.javaScriptInformation;

	
	//while (tContinue==YES && (tDictionary=[tEnumerator nextObject]))
	for(PKGRequirement * tRequirement in tRequirementsArray)
	{
		NSString * tRequirementIdentifier=tRequirement.identifier;
	
		// Find the appropriate Requirement Converter plugin
		
		PKGRequirementConverter * tRequirementConverter=(PKGRequirementConverter *)[_requirementPluginsManager createConverterForIdentifier:tRequirementIdentifier project:(PKGDistributionProject *)self.project];
		
		if (tRequirementConverter==nil)
		{
			// Converter not found
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorRequirementMissingConverter tag:tRequirementIdentifier]];
			
			// A COMPLETER
			
			return NO;
		}
		
		NSDictionary * tRequirementSettingsRepresentation=tRequirement.settingsRepresentation;
		
		// Find whether it's an installation or volumeCheck requirements
				
		PKGRequirementType tRequirementType=[tRequirementConverter requirementTypeWithParameters:tRequirementSettingsRepresentation];
				
		if (tRequirementType==PKGRequirementTypeUndefined)
			tRequirementType=tRequirement.type;
		
		int tIndex;
		int tDepth;
		NSString * tPretest;
		NSMutableString * tFunctionCode;
		NSString * tTabulationDepth;
		
		switch(tRequirementType)
		{
			case PKGRequirementTypeInstallation:
		
				tIndex=tInstallationCheckIndex;
			
				tFunctionCode=tInstallationCheckFunctionCode;
		
				tTabulationDepth=tInstallationCheckTabulationDepth;
			
				tDepth=tInstallationCheckDepth;
			
				tPretest=tInstallationCheckPreTest;
		
				break;
				
			case PKGRequirementTypeTarget:
				
				tIndex=tVolumeCheckIndex;
			
				tFunctionCode=tVolumeCheckFunctionCode;
			
				tTabulationDepth=tVolumeCheckTabulationDepth;
			
				tDepth=tVolumeCheckDepth;
			
				tPretest=tVolumeCheckPreTest;
				
				break;
				
			default:
				
				// Incorrect Value
				
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:@"IC_REQUIREMENT_CHECK_TYPE"]];
				
				// A COMPLETER
				
				return NO;
		}
		
		NSError * tError=nil;
		NSString * tInvocationCode=[tRequirementConverter invocationWithParameters:tRequirementSettingsRepresentation index:tIndex error:&tError];
		
		if (tInvocationCode==nil)
		{
			PKGBuildErrorEvent * tErrorEvent=nil;
			
			// Code not generated
			
			if ([tError.domain isEqualToString:PKGConverterErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case PKGConverterErrorMissingParameter:
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorRequirementConversionError tag:tRequirement.name];
						tErrorEvent.subcode=PKGBuildErrorConverterMissingParameter;
						tErrorEvent.otherFilePath=tError.userInfo[PKGConverterErrorParameterKey];
						
						break;
						
					case PKGConverterErrorInvalidParameter:
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorRequirementConversionError tag:tRequirement.name];
						tErrorEvent.subcode=PKGBuildErrorConverterInvalidParameter;
						tErrorEvent.otherFilePath=tError.userInfo[PKGConverterErrorParameterKey];
						
						break;
						
					case PKConverterErrorLowMemory:
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorRequirementConversionError tag:tRequirement.name];
						tErrorEvent.subcode=PKGBuildErrorOutOfMemory;
						
						break;
				}
			}
			else
			{
				tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorRequirementConversionError];
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
		
		PKGRequirementOnFailureBehavior tFailureBehavior=tRequirement.failureBehavior;
		
		NSString * tCodePart;
		NSString * tErrorMessage,* tErrorDescription;
		
		// Add the shared functions
			
		NSDictionary * tSharedFunctionDictionary=[tRequirementConverter sharedFunctionsImplementation];
		
		[tSharedFunctionDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bFunctionName,NSString * bFunctionImplementation,BOOL * bOutStop){
		
			if ([tJavaScriptInformation containsFunctionNamed:bFunctionName]==NO)
			{
				if ([bFunctionImplementation length]>0)
					[tJavaScriptInformation addFunctionName:bFunctionName implementation:bFunctionImplementation];
			}
		}];
			
		// Add the shared constants
		
		NSSet * tNewConstantsNamesSet=[tJavaScriptInformation unknownConstantsNameInSet:[tRequirementConverter sharedConstantsNames]];
		
		if (tNewConstantsNamesSet.count>0)
		{
			NSString * tString=[tRequirementConverter constantsForNames:tNewConstantsNamesSet];
			
			if (tString!=nil)
			{
				[tJavaScriptInformation  addConstantsNamed:tNewConstantsNamesSet declaration:tString];
			}
			else
			{
				// A COMPLETER
				
				return NO;
			}
		}
		
		tDepth++;
		
		tTabulationDepth=[tTabulationDepth stringByAppendingString:@"\t"];
		
		// Add the vars if needed
		
		NSString * tVariables=[tRequirementConverter variablesWithIndex:tIndex tabulationDepth:tTabulationDepth parameters:tRequirementSettingsRepresentation error:&tError];
		
		if (tVariables==nil)
		{
			// A COMPLETER
			
			return NO;
		}
		
		// Get the list of attributes to set
		
		NSDictionary * tAttributesDictionary=[tRequirementConverter requiredOptionsValuesWithParameters:tRequirementSettingsRepresentation];

		if (tAttributesDictionary.count>0)
			[_buildInformation.requirementsOptions addEntriesFromDictionary:tAttributesDictionary];
		
		// Get the list of resources to add
		
		NSArray * tExtraResources=[tRequirementConverter requiredAdditionalResourcesWithParameters:tRequirementSettingsRepresentation];
		
		if (tExtraResources.count>0)
			[_buildInformation.resourcesExtras addObjectsFromArray:tExtraResources];
		
		tIndex++;
		
		NSDictionary* tLocalizations=tRequirement.messages;
		
		NSString * tLocalizationKeyPrefix;
		BOOL noErrorMessage=NO;
		
		if (tLocalizations.count==0)
		{
			noErrorMessage=YES;
		}
		else
		{
			tRequirementIndex++;
		}
		
		/*switch(tRequirementType)	// Essai de factorisation en cours
		{
			case PKGRequirementTypeInstallation:
				
				tLocalizationKeyPrefix=[NSString stringWithFormat:@"INSTALLATION_CHECK_%d",tRequirementIndex];
				break;
			
			case PKGRequirementTypeTarget:
				
				tLocalizationKeyPrefix=[NSString stringWithFormat:@"VOLUME_CHECK_%d",tRequirementIndex];
				break;
				
			default:
				
				break;
		}
		
		if (noErrorMessage==NO)
		{
			if ([self addLocalizedErrorMessages:tLocalizations withName:tLocalizationKeyPrefix errorMessage:&tErrorMessage errorDescription:&tErrorDescription]==NO)
			{
				// A COMPLETER
				
				return NO;
			}
			
			noErrorMessage=(tErrorMessage==nil);
		}*/
		
		if (tRequirementType==PKGRequirementTypeInstallation)
		{
			if (noErrorMessage==NO)
			{
				tLocalizationKeyPrefix=[NSString stringWithFormat:@"INSTALLATION_CHECK_%d",tRequirementIndex];
				
				if ([self addLocalizedErrorMessages:tLocalizations withName:tLocalizationKeyPrefix errorMessage:&tErrorMessage errorDescription:&tErrorDescription]==NO)
				{
					// A COMPLETER
					
					return NO;
				}
				
				noErrorMessage=(tErrorMessage==nil);
			}
			
			tCodePart=[NSString stringWithFormat:@"%@%@%@tResult=%@;\n\n\
%@if (tResult==false)\n\
%@{\n",tPretest,tVariables,tTabulationDepth,tInvocationCode,tTabulationDepth,tTabulationDepth];

			if (noErrorMessage==NO)
			{
				tCodePart=[tCodePart stringByAppendingFormat:@"%@\tmy.result.title = system.localizedString(\'%@\');\n\
%@\tmy.result.message = system.localizedString(\'%@\');\n",tTabulationDepth,tErrorMessage,tTabulationDepth,tErrorDescription];
			}
			else
			{
				tCodePart=[tCodePart stringByAppendingFormat:@"%@\tmy.result.title = system.localizedStandardStringWithFormat(\'InstallationCheckError\', system.localizedString(\'DISTRIBUTION_TITLE\'));\n\
%@\tmy.result.message = ' ';\n",tTabulationDepth,tTabulationDepth];
			}
			
			if (tFailureBehavior==PKGRequirementOnFailureBehaviorInstallationStop)
			{
				tCodePart=[tCodePart stringByAppendingFormat:@"%@\tmy.result.type = 'Fatal';\n",tTabulationDepth];
				
			}
			else if (tFailureBehavior==PKGRequirementOnFailureBehaviorInstallationWarning)
			{
				tCodePart=[tCodePart stringByAppendingFormat:@"%@\tmy.result.type = 'Warn';\n",tTabulationDepth];
			}
			else
			{
				// Incorrect Value
				
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:@"ICDOCUMENT_REQUIREMENT_FAILURE_BEHAVIOR"]];
				
				// A COMPLETER
				
				return NO;
			}
		}
		else if (tRequirementType==PKGRequirementTypeTarget)
		{
			if (noErrorMessage==NO)
			{
				tLocalizationKeyPrefix=[NSString stringWithFormat:@"VOLUME_CHECK_%d",tRequirementIndex];
				
				if ([self addLocalizedErrorMessages:tLocalizations withName:tLocalizationKeyPrefix errorMessage:&tErrorMessage errorDescription:nil]==NO)
				{
					// A COMPLETER
					
					return NO;
				}
				
				noErrorMessage=(tErrorMessage==nil);
			}
			
			tCodePart=[NSString stringWithFormat:@"%@%@%@tResult=%@;\n\n\
%@if (tResult==false)\n\
%@{\n",tPretest,tVariables,tTabulationDepth,tInvocationCode,tTabulationDepth,tTabulationDepth];

			if (noErrorMessage==NO)
			{
				tCodePart=[tCodePart stringByAppendingFormat:@"%@\tmy.result.message = system.localizedString(\'%@\');\n",tTabulationDepth,tErrorMessage];
			}
			
			if (tFailureBehavior==PKGRequirementOnFailureBehaviorInstallationStop)
			{
				tCodePart=[tCodePart stringByAppendingFormat:@"%@\tmy.result.type = 'Fatal';\n",tTabulationDepth];
				
			}
			else
			{
				// Incorrect Value
				
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:@"ICDOCUMENT_REQUIREMENT_FAILURE_BEHAVIOR"]];
				
				// A COMPLETER
				
				return NO;
			}
		}
		
		tCodePart=[tCodePart stringByAppendingFormat:@"%@}\n",tTabulationDepth];
	
		tPretest=[NSString stringWithFormat:@"\n%@if (tResult==true)\n\%@{\n",tTabulationDepth,tTabulationDepth];
		
		[tFunctionCode appendString:tCodePart];
		
		switch(tRequirementType)
		{
			case PKGRequirementTypeInstallation:
				
				tInstallationCheckIndex=tIndex;
				
				tInstallationCheckTabulationDepth=tTabulationDepth;
				
				tInstallationCheckDepth=tDepth;
				
				tInstallationCheckPreTest=tPretest;
				
				break;
			
			case PKGRequirementTypeTarget:
				
				tVolumeCheckIndex=tIndex;
				
				tVolumeCheckTabulationDepth=tTabulationDepth;
				
				tVolumeCheckDepth=tDepth;
				
				tVolumeCheckPreTest=tPretest;
				
				break;
				
			default:
				
				break;
		}
	}

	if (tInstallationCheckDepth!=-1)
	{
		for(int i=0;i<tInstallationCheckDepth;i++)
		{
			tInstallationCheckTabulationDepth=[tInstallationCheckTabulationDepth substringToIndex:[tInstallationCheckTabulationDepth length]-1];
			
			[tInstallationCheckFunctionCode appendString:[NSString stringWithFormat:@"%@}\n",tInstallationCheckTabulationDepth]];
		}
		
		[tInstallationCheckFunctionCode appendString:@"\n\t\treturn tResult;\n\t}"];
		
		[tJavaScriptInformation addFunctionName:@"installation_check" implementation:tInstallationCheckFunctionCode];

		
		NSXMLElement * tElement=(NSXMLElement *) [NSXMLNode elementWithName:@"installation-check"];
		
		id tAttribute=[NSXMLNode attributeWithName:@"script" stringValue:@"installation_check()"];
								
		[tElement addAttribute:tAttribute];
			
		[_installerScriptElement addChild:tElement];
	}

	if (tVolumeCheckDepth!=-1)
	{
		for(int i=0;i<tVolumeCheckDepth;i++)
		{
			tVolumeCheckTabulationDepth=[tVolumeCheckTabulationDepth substringToIndex:[tVolumeCheckTabulationDepth length]-1];
			
			[tVolumeCheckFunctionCode appendString:[NSString stringWithFormat:@"%@}\n",tVolumeCheckTabulationDepth]];
		}
		
		[tVolumeCheckFunctionCode appendString:@"\n\t\treturn tResult;\n\t}"];
		
		[tJavaScriptInformation addFunctionName:@"volume_check" implementation:tVolumeCheckFunctionCode];

		
		NSXMLElement * tElement=(NSXMLElement *) [NSXMLNode elementWithName:@"volume-check"];
		
		id tAttribute=[NSXMLNode attributeWithName:@"script" stringValue:@"volume_check()"];
		[tElement addAttribute:tAttribute];
			
		[_installerScriptElement addChild:tElement];
	}

	[self postCurrentStepSuccessEvent:nil];
	
	return YES;
}

#pragma mark - Distribution Documents utilities

- (NSString *)distributionResources
{
	return _buildInformation.resourcesPath;
}

- (NSString *)suitableFileNameForProposedFileName:(NSString *)inName inDirectory:(NSString *)inDirectory
{
	NSUInteger tIndex=1;
	NSString * tFileName=inName;
	
	do
	{
		NSString * tFilePath=[inDirectory stringByAppendingPathComponent:tFileName];
		
		if ([_fileManager fileExistsAtPath:tFilePath]==NO)
			return tFileName;
		
		tFileName=[NSString stringWithFormat:@"%@_%d",inName,(int)tIndex];
		
		tIndex++;
	}
	while (tIndex<PKGRenamingAttemptsMax);
	
	return nil;
	
}

- (BOOL)setPosixPermissionsOfDocumentAtPath:(NSString *)inPath
{
	if (inPath==nil)
		return NO;
	
	NSError * tError=nil;
	
	NSDictionary * tAttributesDictionary=[_fileManager attributesOfItemAtPath:inPath error:&tError];
	
	if (tAttributesDictionary==nil)
	{
		// A COMPLETER
		
		[self postCurrentStepFailureEvent:nil];
		
		return NO;
	}
	
	NSDictionary * tPosixPermissionsAttributes=nil;
	
	if ([[tAttributesDictionary fileType] isEqualToString:NSFileTypeDirectory]==YES)
	{
		tPosixPermissionsAttributes=@{NSFilePosixPermissions:@(S_IRWXU+S_IRGRP+S_IXGRP+S_IROTH+S_IXOTH)};	// 0755
	}
	else
	{
		tPosixPermissionsAttributes=@{NSFilePosixPermissions:@(S_IRUSR+S_IWUSR+S_IRGRP+S_IROTH)};	// 0644
	}
	
	if ([_fileManager setAttributes:tPosixPermissionsAttributes ofItemAtPath:inPath error:&tError]==NO)
	{
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFilePosixPermissionsCanNotBeSet filePath:inPath fileKind:PKGFileKindRegularFile]];
		
		return NO;
	}
	
	return YES;
}

- (NSDictionary *)localizedPathDictionaryForLocalizations:(NSDictionary *)inLocalizations
{
	NSMutableDictionary * tLocalizedPathDictionary=[NSMutableDictionary dictionary];
	__block BOOL tInterrupted=NO;
	
	[inLocalizations enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguage,PKGFilePath * bLocalizedDocumentPath,BOOL * bOutStop){
		
		if ([bLocalizedDocumentPath isSet]==NO)		// The Path has not been set. This is fine.
			return;
		
		NSString * tAbsolutePath=[self absolutePathForFilePath:bLocalizedDocumentPath];
		
		if (tAbsolutePath==nil)
		{
			tInterrupted=YES;
			*bOutStop=YES;
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:bLocalizedDocumentPath.string fileKind:PKGFileKindRegularFile]];
			
			return;
		}
		
		if ([_fileManager fileExistsAtPath:tAbsolutePath]==NO)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tAbsolutePath fileKind:PKGFileKindRegularFile];
			
			int tLevel;
			
			if (_treatMissingPresentationDocumentsAsWarnings==YES)
			{
				tLevel=PKGLogLevelWarning;
				
				*bOutStop=NO;
				[self postCurrentStepWarningEvent:tErrorEvent];
			}
			else
			{
				tInterrupted=YES;
				
				tLevel=PKGLogLevelError;
				
				*bOutStop=YES;
				[self postCurrentStepFailureEvent:tErrorEvent];
				
			}
			
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:tLevel format:@"File not found: '%@'",tAbsolutePath];
			
			return;
		}
		
		NSString * tLanguagePath=[self getDistributionPathForLanguage:bLanguage];
		
		if (tLanguagePath==nil)
		{
			tInterrupted=YES;
			
			// Unknown language
			
			*bOutStop=NO;
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorUnknownLanguage tag:bLanguage]];
			
			return;
		}
		
		tLocalizedPathDictionary[tLanguagePath]=tAbsolutePath;
	}];
	
	if (tInterrupted==YES)
		return nil;
	
	return [tLocalizedPathDictionary copy];
}

- (NSString *)finalDocumentNameForLocalizationsDirectories:(NSArray *)inLocalizationsDirectories usingBaseName:(NSString *)inBaseName extension:(NSString *)inExtension
{
	if (inBaseName==nil || inLocalizationsDirectories.count==0)
		return nil;
	
	NSString * tFileName=([inExtension length]==0)? inBaseName : [inBaseName stringByAppendingPathExtension:inExtension];
	NSString * tFileNameFormat=([inExtension length]==0)? [inBaseName stringByAppendingString:@"_%lu"]: [[inBaseName stringByAppendingString:@"_%lu"] stringByAppendingPathExtension:inExtension];
	
	NSUInteger tAttemptCount=0;
	NSUInteger tCount=inLocalizationsDirectories.count;
	
	while (tAttemptCount<PKGRenamingAttemptsMax)
	{
		NSUInteger tIndex=0;
		
		for(NSString * tLocalizationDirectory in inLocalizationsDirectories)
		{
			NSString * tDestinationPath=[tLocalizationDirectory stringByAppendingPathComponent:tFileName];
			
			if ([_fileManager fileExistsAtPath:tDestinationPath]==YES)
				break;
			
			tIndex++;
		}
		
		if (tIndex==tCount)
			break;
		
		tAttemptCount++;
		
		tFileName=[NSString stringWithFormat:tFileNameFormat,(unsigned long)tAttemptCount];
	}
	
	if (tAttemptCount==PKGRenamingAttemptsMax)
	{
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAlreadyExists tag:inBaseName]];
		
		// A COMPLETER
		
		return nil;
	}
	
	return tFileName;
}

- (BOOL)setDocumentName:(NSString *)inName localizations:(NSDictionary *)inLocalizations
{
	if (inName==nil || inLocalizations.count==0)
		return NO;
	
	NSDictionary * tLocalizedPathDictionary=[self localizedPathDictionaryForLocalizations:inLocalizations];
	
	if (tLocalizedPathDictionary==nil)
		return NO;
	
	if (tLocalizedPathDictionary.count==0)
		return YES;
	
	NSArray * tAllLocalizationsDirectories=tLocalizedPathDictionary.allKeys;
	
	NSString * tFileName=[self finalDocumentNameForLocalizationsDirectories:tAllLocalizationsDirectories usingBaseName:inName extension:[tLocalizedPathDictionary[tAllLocalizationsDirectories[0]] pathExtension]];
	
	if (tFileName==nil)
		return NO;
	
	// Copy the files to the destination
	
	for(NSString * tLocalizationDirectory in tAllLocalizationsDirectories)
	{
		NSString * tDestinationPath=[tLocalizationDirectory stringByAppendingPathComponent:tFileName];
		
		NSError * tError=nil;
		
		if ([_fileManager PKG_copyItemAtPath:tLocalizedPathDictionary[tLocalizationDirectory] toPath:tDestinationPath options:PKG_NSDeleteExisting error:&tError]==NO)
		{
			if (tError!=nil)
				NSLog(@"%@",tError.localizedDescription);
			
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCopied filePath:tLocalizedPathDictionary[tLocalizationDirectory] fileKind:PKGFileKindRegularFile];
			tErrorEvent.otherFilePath=tDestinationPath;
			
			if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case NSFileWriteVolumeReadOnlyError:
						tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
						break;
						
					case NSFileWriteNoPermissionError:
						tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
						break;
						
					case NSFileWriteOutOfSpaceError:
						tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
						break;
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
		
		if ([self setPosixPermissionsOfDocumentAtPath:tDestinationPath]==NO)
			return NO;
	}
	
	// document element
	
	NSXMLElement * tDocumentElement=(NSXMLElement *) [NSXMLNode elementWithName:inName];
	
	// file
	
	id tAttribute=[NSXMLNode attributeWithName:@"file" stringValue:tFileName];
	[tDocumentElement addAttribute:tAttribute];
	[_installerScriptElement addChild:tDocumentElement];
	
	return YES;
}

#pragma mark - Distribution Documents

- (void)setTitle
{
	// Get the project name
	
	PKGDistributionProjectSettings * tDistributionProjectSettings=(PKGDistributionProjectSettings *)self.project.settings;

	NSString * tProjectName=tDistributionProjectSettings.name;
	
	PKGDistributionProjectPresentationSettings *tPresentationSettings=((PKGDistributionProject *)self.project).presentationSettings;
	PKGPresentationTitleSettings * tPresentationTitleSettings=tPresentationSettings.titleSettings;
	
	NSDictionary * tLocalizations=tPresentationTitleSettings.localizations;
	
	NSXMLNode * tNode;
	
	if (tLocalizations.count==0)	// Use the name of the project
	{
		// Use the name of the project
		
		tNode=[NSXMLNode textWithStringValue:tProjectName];
	}
	else
	{
		// Make the title localizable
		
		NSString * tKey=@"DISTRIBUTION_TITLE";
		
		tNode=[NSXMLNode textWithStringValue:tKey];
		
		__block BOOL tAtLeastOneLocalizedTitle=NO;
		
		NSMutableDictionary * tDefaultLocalizedTitlesDictionary=[NSMutableDictionary dictionary];
		
		NSMutableDictionary * tLocalizationsDictionary=_buildInformation.localizations;
		
		[tLocalizations enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguage,NSString * bLocalizedTitle,BOOL * bOutStop){
			
			if (tLocalizationsDictionary[bLanguage]==nil)
				tLocalizationsDictionary[bLanguage]=[NSMutableDictionary dictionary];
			
			if ([bLocalizedTitle length]>0)
			{
				tAtLeastOneLocalizedTitle=YES;
				
				tLocalizationsDictionary[bLanguage][tKey]=bLocalizedTitle;
				tDefaultLocalizedTitlesDictionary[bLanguage]=bLocalizedTitle;
			}
			
		}];
		
		if (tAtLeastOneLocalizedTitle==NO)
		{
			tNode=[NSXMLNode textWithStringValue:tProjectName];
		}
		else
		{
			// Set the default value
			
			NSMutableDictionary * tDefaultLanguageDictionary=tLocalizationsDictionary[PKGBuildDefaultLanguageKey];
			
			// Try to use English, French, Spanish, Germanm as the default localization
			
			NSArray * tPreferredDefaultLanguagesArray=@[@"English",@"French", @"Spanish", @"German"];
			BOOL tLocalizationFound=NO;
			NSString * tDefaultLocalizedTitle=tProjectName;
			
			for(NSString * tLanguage in tPreferredDefaultLanguagesArray)
			{
				NSString * tLocalization=tDefaultLocalizedTitlesDictionary[tLanguage];
				
				if (tLocalization!=nil)
				{
					tDefaultLocalizedTitle=tLocalization;
					tLocalizationFound=YES;
					break;
				}
			}
			
			if (tLocalizationFound==NO && tDefaultLocalizedTitlesDictionary.count>0)
				tDefaultLocalizedTitle=tDefaultLocalizedTitlesDictionary.allValues.firstObject;
			
			tDefaultLanguageDictionary[tKey]=tDefaultLocalizedTitle;
		}
	}
	
	// title
	
	NSXMLElement * tTitleElement=(NSXMLElement *) [NSXMLNode elementWithName:@"title"];
	[tTitleElement addChild:tNode];
	[_installerScriptElement addChild:tTitleElement];
}

- (BOOL)setBackground
{
	PKGDistributionProjectPresentationSettings *tPresentationSettings=((PKGDistributionProject *)self.project).presentationSettings;
	PKGPresentationBackgroundSettings * tPresentationBackgroundSettings=tPresentationSettings.backgroundSettings;
	
	if (tPresentationBackgroundSettings==nil)
		return YES;
	
	NSArray * tElements=[tPresentationBackgroundSettings elementsForProjectBuilder:self];
	
	if (tElements==nil)
	{
		return NO;
	}
	
	for(NSXMLElement * tBackgroundElement in tElements)
		[_installerScriptElement addChild:tBackgroundElement];
	
	return YES;
}

- (BOOL)setIntroduction
{
	PKGDistributionProjectPresentationSettings * tPresentationSettings=((PKGDistributionProject *)self.project).presentationSettings;
	PKGPresentationWelcomeStepSettings * tPresentationWelcomeSettings=tPresentationSettings.welcomeSettings;
	
	NSDictionary * tLocalizations=tPresentationWelcomeSettings.localizations;
	
	if (tLocalizations.count==0)
		return YES;
	
	[self postStep:PKGBuildStepDistributionWelcomeMessage beginEvent:nil];
	
	if ([self setDocumentName:@"welcome" localizations:tLocalizations]==NO)
		return NO;
	
	[self postCurrentStepSuccessEvent:nil];
	
	return YES;
}

- (BOOL)setReadMe
{
	PKGDistributionProjectPresentationSettings * tPresentationSettings=((PKGDistributionProject *)self.project).presentationSettings;
	PKGPresentationReadMeStepSettings * tPresentationReadMeSettings=tPresentationSettings.readMeSettings;
	
	NSDictionary * tLocalizations=tPresentationReadMeSettings.localizations;
	
	if (tLocalizations.count==0)
		return YES;
	
	[self postStep:PKGBuildStepDistributionReadMeMessage beginEvent:nil];

	if ([self setDocumentName:@"readme" localizations:tLocalizations]==NO)
		return NO;
	
	[self postCurrentStepSuccessEvent:nil];
	
	return YES;
}

- (BOOL)setLicense
{
	PKGDistributionProjectPresentationSettings * tPresentationSettings=((PKGDistributionProject *)self.project).presentationSettings;
	PKGPresentationLicenseStepSettings * tPresentationLicenseSettings=tPresentationSettings.licenseSettings;
	
	PKGLicenseType tLicenseMode=tPresentationLicenseSettings.licenseType;
	
	if (tLicenseMode==PKGLicenseTypeCustom)
	{
		NSDictionary * tLocalizations=tPresentationLicenseSettings.localizations;
		
		if (tLocalizations.count==0)
			return YES;
		
		[self postStep:PKGBuildStepDistributionLicenseMessage beginEvent:nil];
		
		if ([self setDocumentName:@"license" localizations:tLocalizations]==NO)
			return NO;
		
		[self postCurrentStepSuccessEvent:nil];
		
		return YES;
	}
	
	// (tLicenseMode==PKGLicenseTypeTemplate)
	
	[self postStep:PKGBuildStepDistributionLicenseMessage beginEvent:nil];
		
	NSString * tLicenseTemplateName=tPresentationLicenseSettings.templateName;
	PKGLicenseTemplate * tLicenseTemplate=[[PKGLicenseProvider defaultProvider] licenseTemplateNamed:tLicenseTemplateName];
	
	NSDictionary * tLocalizations=nil;
	NSString * tSlaString=nil;
	
	if (tLicenseTemplate!=nil)
	{
		tLocalizations=tLicenseTemplate.localizations;
		tSlaString=tLicenseTemplate.slaReference;
	}
	
	if (tLocalizations.count==0)
	{
		// Missing Templates
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorLicenseTemplateNotFound tag:tLicenseTemplateName]];
		
		return NO;
	}
	
	__block NSMutableDictionary * tLocalizedPathDictionary=[NSMutableDictionary dictionary];
	
	[tLocalizations enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguage,PKGFilePath *bFilePath,BOOL * bOutStop){
		
		NSString * tPath=[self absolutePathForFilePath:bFilePath];
		
		if (tPath==nil)
		{
			*bOutStop=YES;
			tLocalizedPathDictionary=nil;
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:bFilePath.string fileKind:PKGFileKindRegularFile]];
			
			return;
		}
		
		if ([_fileManager fileExistsAtPath:tPath]==NO)
		{
			int tLevel;
			
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tPath fileKind:PKGFileKindRegularFile];
			
			if (_treatMissingPresentationDocumentsAsWarnings==YES)
			{
				tLevel=PKGLogLevelWarning;
				*bOutStop=NO;
				
				[self postCurrentStepWarningEvent:tErrorEvent];
			}
			else
			{
				tLevel=PKGLogLevelError;
				*bOutStop=YES;
				tLocalizedPathDictionary=nil;
				
				[self postCurrentStepFailureEvent:tErrorEvent];
			}
			
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:tLevel format:@"File not found: '%@'",tPath];
			
			return;
		}
		
		NSString * tLanguagePath=[self getDistributionPathForLanguage:bLanguage];
			
		if (tLanguagePath==nil)
		{
			// Unknown language
			
			*bOutStop=YES;
			tLocalizedPathDictionary=nil;
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorUnknownLanguage tag:bLanguage]];
			
			// A COMPLETER
			
			return;
		}
		
		tLocalizedPathDictionary[tLanguagePath]=tPath;
	}];
	
	if (tLocalizedPathDictionary==nil)
		return NO;
	
	if (tLocalizedPathDictionary.count==0)
	{
		[self postCurrentStepSuccessEvent:nil];
		
		return YES;
	}
	
	NSArray * tAllLlocalizationsDirectories=tLocalizedPathDictionary.allKeys;
	
	NSString * tFileName=[self finalDocumentNameForLocalizationsDirectories:tAllLlocalizationsDirectories usingBaseName:@"license" extension:[tLocalizedPathDictionary[tAllLlocalizationsDirectories[0]] pathExtension]];
	
	if (tFileName==nil)
		return NO;
	
	NSDictionary * tKeywordsDictionary=tPresentationLicenseSettings.templateValues;
	
	for(NSString * tLocalizationDirectory in tAllLlocalizationsDirectories)
	{
		NSString * tFilePath=tLocalizedPathDictionary[tLocalizationDirectory];
		
		NSStringEncoding tEncoding;
		NSError * tError;
		
		NSMutableString * tMutableString=[[NSMutableString alloc] initWithContentsOfFile:tFilePath
																			usedEncoding:&tEncoding
																				   error:&tError];
		if (tMutableString==nil)
		{
			NSStringEncoding tPotentialEncodings[4]={
													NSMacOSRomanStringEncoding,
													NSUTF8StringEncoding,
													NSISOLatin1StringEncoding,
													NSASCIIStringEncoding
													};
												
			for(NSStringEncoding tEncodingIndex=NSASCIIStringEncoding;tEncodingIndex<NSUTF8StringEncoding;tEncodingIndex++)
			{
				tEncoding=tPotentialEncodings[tEncodingIndex];
				
				tMutableString=[[NSMutableString alloc] initWithContentsOfFile:tFilePath
																	  encoding:tEncoding
																		 error:&tError];
				if (tMutableString!=nil)
					break;
			}
		}
		
		if (tMutableString==nil)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeRead filePath:tFilePath fileKind:PKGFileKindRegularFile];
			// A COMPLETER
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
		
		if (tKeywordsDictionary!=nil)
			[PKGLicenseProvider replaceKeywords:tKeywordsDictionary inString:tMutableString];
		
		NSString * tDestinationPath=[tLocalizationDirectory stringByAppendingPathComponent:tFileName];
		
		if ([tMutableString writeToFile:tDestinationPath atomically:NO encoding:tEncoding error:&tError]==NO)
		{
			if (tError!=nil)
			{
				// A COMPLETER
			}
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCreated filePath:tDestinationPath fileKind:PKGFileKindRegularFile]];
			
			return NO;
		}
		
		if ([self setPosixPermissionsOfDocumentAtPath:tDestinationPath]==NO)
			return NO;
	}

	// license
		
	NSXMLElement * tLicenseElement=(NSXMLElement *) [NSXMLNode elementWithName:@"license"];
					
	// file
	
	id tAttribute=[NSXMLNode attributeWithName:@"file" stringValue:tFileName];
	[tLicenseElement addAttribute:tAttribute];
		
	[_installerScriptElement addChild:tLicenseElement];
	
	// sla

	if (tSlaString!=nil)
	{
		tAttribute=[NSXMLNode attributeWithName:@"sla" stringValue:tSlaString];
		[tLicenseElement addAttribute:tAttribute];
	}
	
	[self postCurrentStepSuccessEvent:nil];
										   
	return YES;
}

- (BOOL)setConclusion
{
	PKGDistributionProjectPresentationSettings *tPresentationSettings=((PKGDistributionProject *)self.project).presentationSettings;
	PKGPresentationSummaryStepSettings * tPresentationSummarySettings=tPresentationSettings.summarySettings;
	
	NSDictionary * tLocalizations=tPresentationSummarySettings.localizations;
	
	if (tLocalizations.count==0)
		return YES;
	
	[self postStep:PKGBuildStepDistributionConclusionMessage beginEvent:nil];
	
	if ([self setDocumentName:@"conclusion" localizations:tLocalizations]==NO)
		return NO;
	
	[self postCurrentStepSuccessEvent:nil];
	
	return YES;
}

#pragma mark -

- (BOOL)setChoiceOutline
{
	[self postStep:PKGBuildStepDistributionChoicesHierarchies beginEvent:nil];
	
	PKGDistributionProjectPresentationSettings *tPresentationSettings=((PKGDistributionProject *)self.project).presentationSettings;
	PKGPresentationInstallationTypeStepSettings * tInstallationTypeSettings=tPresentationSettings.installationTypeSettings;
	
	NSMutableDictionary * tHierarchies=tInstallationTypeSettings.hierarchies;
	
	__block BOOL tFailed=NO;
	
	[tHierarchies enumerateKeysAndObjectsUsingBlock:^(NSString * bHierarchyName,PKGInstallationHierarchy * bHierarchy,BOOL * bOutStop){
		
		PKGChoicesForest * tChoicesForest=bHierarchy.choicesForest;
	
		// choices-outline
		
		NSXMLElement * tChoicesOutlineElement=(NSXMLElement *) [NSXMLNode elementWithName:@"choices-outline"];
						
		BOOL isInstallerHierarchy=[bHierarchyName isEqualToString:PKGPresentationInstallationTypeInstallerHierarchyKey];
		id tComment;
		NSString * tPrefix;
		
		// ui
		
		if (isInstallerHierarchy==NO)
		{
			id tAttribute=nil;
			
			if ([bHierarchyName isEqualToString:PKGPresentationInstallationTypeSoftwareUpdateHierarchyKey]==YES)
			{
				tAttribute=[NSXMLNode attributeWithName:@"ui" stringValue:@"SoftwareUpdate"];
				
				tComment=[NSXMLNode commentWithStringValue:@"+==========================+\n        |      Software Update     |\n        +==========================+"];
				
				tPrefix=@"software_update_choice_";
			}
			else if ([bHierarchyName isEqualToString:PKGPresentationInstallationTypeInvisibleHierarchyKey]==YES)
			{
				tAttribute=[NSXMLNode attributeWithName:@"ui" stringValue:@"Invisible"];
				
				tComment=[NSXMLNode commentWithStringValue:@"+==========================+\n        |         Invisible        |\n        +==========================+"];
				
				tPrefix=@"invisible_choice_";
			}
		
			[tChoicesOutlineElement addAttribute:tAttribute];
		}
		else
		{
			tComment=[NSXMLNode commentWithStringValue:@"+==========================+\n        |         Installer        |\n        +==========================+"];
			
			tPrefix=@"installer_choice_";
		}
		
		[_installerScriptElement addChild:tComment];
		
		PKGRootNodesTuple * tTuple=tChoicesForest.rootNodes;
		
		if (tTuple.error!=nil)
		{
			PKGBuildErrorEvent * tErrorEvent=nil;
			
			if ([tTuple.error.domain isEqualToString:PKGPackagesModelErrorDomain]==YES)
			{
				NSString * tKey=tTuple.error.userInfo[PKGKeyPathErrorKey];
				
				switch(tTuple.error.code)
				{
					case PKGRepresentationNilRepresentationError:
					{
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing value for key \"%@\"",tKey];
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingInformation tag:tKey];
						
						break;
					}
						
					case PKGRepresentationInvalidValueError:
					{
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Incorrect value for key \"%@\"",tKey];
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:tKey];
						
						break;
					}
						
					case PKGRepresentationInvalidTypeOfValueError:
					{
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Incorrect type of value for key \"%@\"",tKey];
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:tKey];
						
						break;
					}
						
					case PKGFileInvalidTypeOfFileError:
					{
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileIncorrectType filePath:_buildOrder.projectPath fileKind:PKGFileKindRegularFile];
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Unable to read file at path '%@'",_buildOrder.projectPath];
						
						break;
					}
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			tFailed=YES;
			
			*bOutStop=YES;
			return;
		}
		
		if ([self addLinesElementsToElement:tChoicesOutlineElement withChoicesArray:tTuple.array isInstaller:isInstallerHierarchy prefix:tPrefix]==NO)
		{
			[self postCurrentStepFailureEvent:nil];
			
			// A COMPLETER
			
			tFailed=YES;
			
			*bOutStop=YES;
			return;
		}
			
		[_installerScriptElement addChild:tChoicesOutlineElement];
		
		if ([self addChoicesElementsToElement:_installerScriptElement withChoicesArray:tTuple.array isInstaller:isInstallerHierarchy]==NO)
		{
			// A COMPLETER
			
			tFailed=YES;
			
			*bOutStop=YES;
			return;
		}
	}];
	
	if (tFailed==YES)
		return NO;
	
	[self postCurrentStepSuccessEvent:nil];
							   
	return YES;
}

- (NSXMLElement *)packageRefeferenceElementWithChoicePackageItem:(PKGChoicePackageItem *) inChoicePackageItem
{
	if (inChoicePackageItem==nil)
		return nil;
	
	NSString * tPackageUUID=inChoicePackageItem.packageUUID;

	// pkg-ref

	NSXMLElement * tPackageRefElement=(NSXMLElement *) [NSXMLNode elementWithName:@"pkg-ref"];

	PKGBuildPackageAttributes * tBuildPackageAttributes=_buildInformation.packagesAttributes[tPackageUUID];
	
	NSString * tPackageReferenceID=tBuildPackageAttributes.identifier;
		
	id tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:tPackageReferenceID];
	[tPackageRefElement addAttribute:tAttribute];
			
	return tPackageRefElement;
}

- (BOOL)hasOneHideAndUnselectRequirementEnabledInArray:(NSArray *) inArray
{
	for(PKGRequirement * tRequirement in inArray)
	{
		if (tRequirement.enabled==YES && tRequirement.failureBehavior==PKGRequirementOnFailureBehaviorDeselectAndHideChoice)
			return YES;
	}
	
	return NO;
}

- (BOOL)setRequirementsFunctionForChoiceName:(NSString *) inName withArray:(NSArray *) inArray functionName:(NSString **) outFunctionName
{
	if (inName==nil || inArray==nil || outFunctionName==NULL)
		return NO;

	PKGBuildJavaScriptInformation * tJavaScriptInformation=_buildInformation.javaScriptInformation;
	
	(*outFunctionName)=[inName stringByAppendingString:@"_requirement"];
	
	NSMutableString * tFunctionCode=[NSMutableString stringWithFormat:@"\tfunction %@(inCheckVisibilityOnly,inShowFailedToolTip)\n\
\t{\n\
\t\tvar tResult;\n\n",*outFunctionName];
	
	int tDepth=-1;
	NSString * tTabulationDepth=@"\t";
	NSString * tPretest=@"";
	NSInteger tIndex=0;
	__block int tErrorIndex=1;
	
	for(PKGRequirement * tRequirement in inArray)
	{
		NSString * tIdentifier=tRequirement.identifier;
		
		// Find the appropriate Requirement Converter plugin
		
		PKGRequirementConverter * tRequirementConverter=(PKGRequirementConverter *)[_requirementPluginsManager createConverterForIdentifier:tIdentifier project:(PKGDistributionProject *)self.project];
		
		if (tRequirementConverter==nil)
		{
			// Converter not found
			
			// A COMPLETER
			
			return NO;
		}
		
			
		NSDictionary * tRequirementSettingsRepresentation=tRequirement.settingsRepresentation;
		
		NSError * tError=nil;
		
		NSString * tInvocationCode=[tRequirementConverter invocationWithParameters:tRequirementSettingsRepresentation index:tIndex error:&tError];
		
		if (tInvocationCode==nil)
		{
			// A COMPLETER
			
			return NO;
		}
	
		NSString * tCodePart;
		NSDictionary * tAttributesDictionary;
		NSArray * tExtraResources;
		
		// Add the shared functions
			
		NSDictionary * tSharedFunctionDictionary=[tRequirementConverter sharedFunctionsImplementation];
		
		[tSharedFunctionDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bSharedRequirementFunctionName,NSString *bImplementationCode,BOOL * bOutStop){
		
			if ([tJavaScriptInformation containsFunctionNamed:bSharedRequirementFunctionName]==NO)
			{
				if (bImplementationCode.length>0)
					[tJavaScriptInformation addFunctionName:bSharedRequirementFunctionName implementation:bImplementationCode];
			}
		}];
			
		// Add the shared constants
		
		NSSet * tNewConstantsNamesSet=[tJavaScriptInformation unknownConstantsNameInSet:[tRequirementConverter sharedConstantsNames]];
		
		if (tNewConstantsNamesSet.count>0)
		{
			NSString * tString=[tRequirementConverter constantsForNames:tNewConstantsNamesSet];
			
			if (tString!=nil)
			{
				[tJavaScriptInformation  addConstantsNamed:tNewConstantsNamesSet declaration:tString];
			}
			else
			{
				// A COMPLETER
			}
		}
		
		tDepth++;
		
		tTabulationDepth=[tTabulationDepth stringByAppendingString:@"\t"];
		
		// Add the vars if needed
		
		NSString * tVariables=[tRequirementConverter variablesWithIndex:tIndex tabulationDepth:tTabulationDepth parameters:tRequirementSettingsRepresentation error:&tError];
		
		if (tVariables==nil)
		{
			// A COMPLETER
		
			return NO;
		}
	
		// Get the list of resources to add
	
		tAttributesDictionary=[tRequirementConverter requiredOptionsValuesWithParameters:tRequirementSettingsRepresentation];

		if (tAttributesDictionary.count>0)
			[_buildInformation.requirementsOptions addEntriesFromDictionary:tAttributesDictionary];
		
		// Get the list of attributes to set
		
		tExtraResources=[tRequirementConverter requiredAdditionalResourcesWithParameters:tRequirementSettingsRepresentation];
		
		if (tExtraResources.count>0)
			[_buildInformation.resourcesExtras addObjectsFromArray:tExtraResources];
		
		tIndex++;
		
		PKGRequirementOnFailureBehavior tFailureBehavior=tRequirement.failureBehavior;
		
		if (tFailureBehavior==PKGRequirementOnFailureBehaviorDeselectAndHideChoice)
		{
			tCodePart=[NSString stringWithFormat:@"%@%@%@tResult=%@;\n\n",tPretest,tVariables,tTabulationDepth,tInvocationCode];

			tPretest=[NSString stringWithFormat:@"%@if (tResult==true)\n\%@{\n",tTabulationDepth,tTabulationDepth];
			
			[tFunctionCode appendString:tCodePart];
			
			continue;
		}
		
		if (tFailureBehavior==PKGRequirementOnFailureBehaviorDeselectAndDisableChoice)
		{
			NSDictionary * tLocalizations=tRequirement.messages;
			NSString * tErrorMessage=nil;
			
			if (tLocalizations.count>0)
			{
				NSMutableDictionary * tLocalizationsDictionary=_buildInformation.localizations;
				
				tErrorMessage=[NSString stringWithFormat:@"%@_REQUIREMENT_FAILED_%d",[inName uppercaseString],tErrorIndex];
				
				[tLocalizations enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguage,PKGRequirementFailureMessage * bMessage,BOOL * bOutStop){
				
					NSMutableDictionary * tLanguageLocalizationsDictionary=tLocalizationsDictionary[bLanguage];
					
					if (tLanguageLocalizationsDictionary==nil)
						tLocalizationsDictionary[bLanguage]=tLanguageLocalizationsDictionary=[NSMutableDictionary dictionary];
					
					tLanguageLocalizationsDictionary[tErrorMessage]=bMessage.messageTitle;
					
					tErrorIndex++;
				}];

				// Set the default value
				
				NSMutableDictionary * tDefaultLanguageDictionary=tLocalizationsDictionary[PKGBuildDefaultLanguageKey];
				
				tDefaultLanguageDictionary[tErrorMessage]=@"";
			}
			
			if (tErrorMessage==nil)
			{
				tCodePart=[NSString stringWithFormat:@"%@%@%@tResult=%@;\n\n\
%@if (tResult==false)\n\
%@{\n\
%@\tif (inCheckVisibilityOnly==true)\n\
%@\t{\n\
%@\t\ttResult=true;\n\
%@\t}\n\
%@}\n",tPretest,tVariables,tTabulationDepth,tInvocationCode,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth];
			}
			else
			{
				tCodePart=[NSString stringWithFormat:@"%@%@%@tResult=%@;\n\n\
%@if (tResult==false)\n\
%@{\n\
%@\tif (inCheckVisibilityOnly==true)\n\
%@\t{\n\
%@\t\ttResult=true;\n\
%@\t}\n\
%@\telse\n\
%@\t{\n\
%@\t\tif (inShowFailedToolTip==true)\n\
%@\t\t{\n\
%@\t\t\tchoices.%@.tooltip=system.localizedString(\'%@\');\n\
%@\t\t}\n\
%@\t}\n\
%@}\n",tPretest,tVariables,tTabulationDepth,tInvocationCode,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,tTabulationDepth,inName,tErrorMessage,tTabulationDepth,tTabulationDepth,tTabulationDepth];
			}
			
			tPretest=[NSString stringWithFormat:@"\n%@if (tResult==true)\n\%@{\n",tTabulationDepth,tTabulationDepth];
			
			[tFunctionCode appendString:tCodePart];
		}
	}
	
	for(int i=0;i<tDepth;i++)
	{
		tTabulationDepth=[tTabulationDepth substringToIndex:[tTabulationDepth length]-1];
		
		NSString * tClosingLine=[NSString stringWithFormat:@"%@}\n",tTabulationDepth];
		
		[tFunctionCode appendString:tClosingLine];
	}
	
	[tFunctionCode appendString:@"\n\t\treturn tResult;\n\t}"];
	
	[tJavaScriptInformation addFunctionName:*outFunctionName implementation:tFunctionCode];
		
	return YES;
}

- (NSString *)logicStringForDependencyTreeNode:(PKGChoiceDependencyTreeNode *)inDependencyTreeNode
{
	if (inDependencyTreeNode==nil)
		return nil;
	
	NSString * tString=nil;
	
	if ([inDependencyTreeNode isKindOfClass:[PKGChoiceDependencyTreePredicateNode class]]==YES)
	{
		// Leaf
		
		PKGChoiceDependencyTreePredicateNode *tPredicateNode=(PKGChoiceDependencyTreePredicateNode *)inDependencyTreeNode;
		
		NSString * tChoiceReadableID=_buildInformation.choicesNames[tPredicateNode.choiceUUID];
		
		if (tChoiceReadableID==nil)
		{
			// Missing Information
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingInformation tag:tPredicateNode.choiceUUID]];
			
			return nil;
		}
		
		switch(tPredicateNode.operatorType)
		{
			case PKGPredicateOperatorTypeEqualTo:
				
				tString=[NSString stringWithFormat:@"choices.%@.",tChoiceReadableID];
				break;
				
			case PKGPredicateOperatorTypeNotEqualTo:
				
				tString=[NSString stringWithFormat:@"!choices.%@.",tChoiceReadableID];
				break;
		}
		
		switch(tPredicateNode.referenceState)
		{
			case PKGPredicateReferenceStateEnabled:
				
				tString=[tString stringByAppendingString:@"enabled"];
				break;
				
			case PKGPredicateReferenceStateSelected:
				
				tString=[tString stringByAppendingString:@"selected"];
				break;
				
		}
	}
	else if ([inDependencyTreeNode isKindOfClass:[PKGChoiceDependencyTreeLogicNode class]]==YES)
	{
		PKGChoiceDependencyTreeLogicNode * tLogicNode=(PKGChoiceDependencyTreeLogicNode *)inDependencyTreeNode;
		
		// Branch
		
		NSString * tTopString=[self logicStringForDependencyTreeNode:tLogicNode.topChildNode];
		
		NSString * tBottomString=[self logicStringForDependencyTreeNode:tLogicNode.bottomChildNode];
		
		if (tTopString==nil || tBottomString==nil)
			return nil;
		
		switch(tLogicNode.operatorType)
		{
			case PKGLogicOperatorTypeConjunction:
			
				tString=[NSString stringWithFormat:@"(%@ && %@)",tTopString,tBottomString];
				break;
				
			case PKGLogicOperatorTypeDisjunction:
				
				tString=[NSString stringWithFormat:@"(%@ || %@)",tTopString,tBottomString];
				break;
		}
	}
	
	return tString;
}

- (BOOL)createEnabledDependencyFunctionNamed:(NSString *) inFunctionName withDependencyTree:(PKGChoiceDependencyTree *)inDependencyTree
{
	if (inFunctionName==nil || inDependencyTree==nil)
		return NO;
	
	NSString * tLogicString=[self logicStringForDependencyTreeNode:inDependencyTree.rootNode];
	
	if (tLogicString==nil)
		return NO;
	
	NSString * tFunctionCode=[NSString stringWithFormat:@"\tfunction %@()\n\t{\n\t\treturn %@;\t\n\t}",inFunctionName,tLogicString];
	
	[_buildInformation.javaScriptInformation addFunctionName:inFunctionName implementation:tFunctionCode];
		
	return YES;
}

- (BOOL) createSelectedDependencyFunctionNamed:(NSString *) inFunctionName withEnabledState:(int) inEnabledState withEnabledFunctionName:(NSString *) inEnabledFunctionName withDependencyTree:(PKGChoiceDependencyTree *)inDependencyTree
{
	if (inFunctionName==nil || inDependencyTree==nil || inEnabledFunctionName==nil)
		return NO;
	
	NSString * tLogicString=[self logicStringForDependencyTreeNode:inDependencyTree.rootNode];
	
	if (tLogicString==nil)
		return NO;
	
	NSString * tFunctionCode;
	
	if (inEnabledState==PKGEnabledStateDependencyTypeAlways)
	{
		tFunctionCode=[NSString stringWithFormat:@"\tfunction %@(isStart)\n\t{\n\t\tvar tSelected;\n\n\t\ttSelected=%@;\n\n\t\tif (isStart==true)\n\t\t{\n\t\t\treturn tSelected;\n\t\t}\n\n\t\treturn (tSelected && my.choice.selected);\n\t}",inFunctionName,tLogicString];
	}
	else if (inEnabledState==PKGEnabledStateDependencyTypeNever)
	{
		tFunctionCode=[NSString stringWithFormat:@"\tfunction %@()\n\t{\n\t\treturn %@;\n\t}",inFunctionName,tLogicString];
	}
	else
	{
		tFunctionCode=[NSString stringWithFormat:@"\tfunction %@(isStart)\n\t{\n\t\tvar tSelected;\n\n\t\ttSelected=%@;\n\n\t\tif (%@()==false || isStart==true)\n\t\t{\n\t\t\treturn tSelected;\n\t\t}\n\n\t\treturn (tSelected && my.choice.selected);\n\t}",inFunctionName,tLogicString,inEnabledFunctionName];
	}
	
	[_buildInformation.javaScriptInformation addFunctionName:inFunctionName implementation:tFunctionCode];
	
	return YES;
}

- (BOOL)setStateAttributesOfChoiceElement:(NSXMLElement *) inElement name:(NSString *) inName requirementFunctionName:(NSString *) inRequirementFunctionName affectVisible:(BOOL) inAffectVisible withOptions:(PKGChoiceItemOptions *) inOptions
{
	if (inElement==nil || inName==nil || inOptions==nil || inRequirementFunctionName==nil)
		return NO;
	
	// Requirements

	id tAttribute;
	
	// start_visible
	
	if ([inOptions isHidden]==YES)
	{
		tAttribute=[NSXMLNode attributeWithName:@"start_visible" stringValue:@"false"];
		[inElement addAttribute:tAttribute];
	}
	else
	{
		if (inAffectVisible==YES)
		{
			tAttribute=[NSXMLNode attributeWithName:@"start_visible" stringValue:[NSString stringWithFormat:@"%@(true,false)",inRequirementFunctionName]];
			[inElement addAttribute:tAttribute];
		}
	}
	
	PKGChoiceState tState=inOptions.state;
	
	switch(tState)
	{
		// Choice or Merged Choices
		
		case PKGRequiredChoiceState:
			
			// start_enabled
			
			tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:@"false"];
			[inElement addAttribute:tAttribute];
				
			// start_selected
		
			tAttribute=[NSXMLNode attributeWithName:@"start_selected" stringValue:[NSString stringWithFormat:@"%@(false,true)",inRequirementFunctionName]];
			[inElement addAttribute:tAttribute];
			
			break;
			
		case PKGSelectedChoiceState:
		
			// start_enabled
			
			tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:[NSString stringWithFormat:@"%@(false,true)",inRequirementFunctionName]];
			[inElement addAttribute:tAttribute];
				
			// start_selected
			
			tAttribute=[NSXMLNode attributeWithName:@"start_selected" stringValue:[NSString stringWithFormat:@"%@(false,false)",inRequirementFunctionName]];
			[inElement addAttribute:tAttribute];
			
			break;
			
		case PKGUnselectedChoiceState:
		
			// start_enabled
			
			tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:[NSString stringWithFormat:@"%@(false,true)",inRequirementFunctionName]];
			[inElement addAttribute:tAttribute];
				
			// start_selected
			
			tAttribute=[NSXMLNode attributeWithName:@"start_selected" stringValue:@"false"];
			[inElement addAttribute:tAttribute];
			
			break;
			
		case PKGDependentChoiceState:
		{
			PKGChoiceItemOptionsDependencies * tOptionsDependencies=inOptions.stateDependencies;
			
			// enabled
			
			PKGEnabledStateDependencyType tEnabledState=tOptionsDependencies.enabledStateDependencyType;
			
			switch (tEnabledState)
			{
				case PKGEnabledStateDependencyTypeAlways:
					
					tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:[NSString stringWithFormat:@"%@(false,false)",inRequirementFunctionName]];
					[inElement addAttribute:tAttribute];
					break;
					
				case PKGEnabledStateDependencyTypeNever:
					
					tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:@"false"];
					[inElement addAttribute:tAttribute];
					break;
				
				case PKGEnabledStateDependencyTypeDependent:
				{
					NSString * tEnabledFunctionName=[inName stringByAppendingString:@"_enabled"];
					
					if ([self createEnabledDependencyFunctionNamed:tEnabledFunctionName
												withDependencyTree:tOptionsDependencies.enabledStateDependenciesTree]==NO)
						return NO;
					
					tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:[NSString stringWithFormat:@"%@() && %@(false,false)",tEnabledFunctionName,inRequirementFunctionName]];
					[inElement addAttribute:tAttribute];
						
					tAttribute=[NSXMLNode attributeWithName:@"enabled" stringValue:[NSString stringWithFormat:@"%@() && %@(false,false)",tEnabledFunctionName,inRequirementFunctionName]];
					[inElement addAttribute:tAttribute];
					
					break;
				}
			}
			
			// selected
			
			NSString * tSelectedFunctionName=[inName stringByAppendingString:@"_selected"];
		
			if ([self createSelectedDependencyFunctionNamed:tSelectedFunctionName
										   withEnabledState:tEnabledState
									withEnabledFunctionName:[inName stringByAppendingString:@"_enabled"]
										 withDependencyTree:tOptionsDependencies.selectedStateDependenciesTree]==NO)
				return NO;
			
			tAttribute=[NSXMLNode attributeWithName:@"start_selected" stringValue:[NSString stringWithFormat:@"%@(true) && %@(false,true)",tSelectedFunctionName,inRequirementFunctionName]];
			[inElement addAttribute:tAttribute];
					
			tAttribute=[NSXMLNode attributeWithName:@"selected" stringValue:[NSString stringWithFormat:@"%@(false) && %@(false,true)",tSelectedFunctionName,inRequirementFunctionName]];
			[inElement addAttribute:tAttribute];
		
			break;
		}
		// Groups
		
		case PKGEnabledChoiceGroupState:
		
			// Nothing to do
			
			break;
			
		case PKGDisabledChoiceGroupState:
			
			// start_enabled
			
			tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:@"false"];
			[inElement addAttribute:tAttribute];
				
			break;
			
		case PKGDependentChoiceGroupState:
			{
				PKGChoiceItemOptionsDependencies * tOptionsDependencies=inOptions.stateDependencies;
				
				NSString * tEnabledFunctionName=[inName stringByAppendingString:@"_enabled"];
					
				if ([self createEnabledDependencyFunctionNamed:tEnabledFunctionName
											withDependencyTree:tOptionsDependencies.enabledStateDependenciesTree]==NO)
				{
					// A COMPLETER
					
					return NO;
				}

				tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:[NSString stringWithFormat:@"%@()",tEnabledFunctionName]];
				[inElement addAttribute:tAttribute];
					
				tAttribute=[NSXMLNode attributeWithName:@"enabled" stringValue:[NSString stringWithFormat:@"%@()",tEnabledFunctionName]];
				[inElement addAttribute:tAttribute];
			
				break;
			}
	}

	return YES;
}

- (BOOL) setStateAttributesOfChoiceElement:(NSXMLElement *) inElement name:(NSString *) inName withOptions:(PKGChoiceItemOptions *) inOptions
{
	// No requirements

	if (inElement==nil || inOptions==nil)
		return NO;
	
	id tAttribute;
	PKGChoiceItemOptionsDependencies * tStateDependencies;
	
	// start_visible
	
	if ([inOptions isHidden]==YES)
	{
		tAttribute=[NSXMLNode attributeWithName:@"start_visible" stringValue:@"false"];
		[inElement addAttribute:tAttribute];
	}
	
	PKGChoiceState tState=inOptions.state;
	
	switch(tState)
	{
		// Choice or Merged Choices
		
		case PKGRequiredChoiceState:
			
			// start_enabled
			
			tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:@"false"];
			[inElement addAttribute:tAttribute];
				
			// start_selected
			
			tAttribute=[NSXMLNode attributeWithName:@"start_selected" stringValue:@"true"];
			[inElement addAttribute:tAttribute];
					
			break;
			
		case PKGSelectedChoiceState:
		
			// Nothing to do
			
			break;
			
		case PKGUnselectedChoiceState:
		
			// start_selected
			
			tAttribute=[NSXMLNode attributeWithName:@"start_selected" stringValue:@"false"];
			[inElement addAttribute:tAttribute];
				
			break;
			
		case PKGDependentChoiceState:
		{
			tStateDependencies=inOptions.stateDependencies;
				
			// enabled
			
			PKGEnabledStateDependencyType tEnabledState=tStateDependencies.enabledStateDependencyType;
			
			switch(tEnabledState)
			{
				case PKGEnabledStateDependencyTypeAlways:
					
					// Nothing to do
					
					break;
					
				case PKGEnabledStateDependencyTypeNever:
					
					tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:@"false"];
					[inElement addAttribute:tAttribute];
					
					break;
					
				case PKGEnabledStateDependencyTypeDependent:
				{
					NSString * tEnabledFunctionName=[inName stringByAppendingString:@"_enabled"];
					
					if ([self createEnabledDependencyFunctionNamed:tEnabledFunctionName
												withDependencyTree:tStateDependencies.enabledStateDependenciesTree]==NO)
					{
						// A COMPLETER
						
						return NO;
					}
					
					tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:[NSString stringWithFormat:@"%@()",tEnabledFunctionName]];
					[inElement addAttribute:tAttribute];
					
					tAttribute=[NSXMLNode attributeWithName:@"enabled" stringValue:[NSString stringWithFormat:@"%@()",tEnabledFunctionName]];
					[inElement addAttribute:tAttribute];
					
					break;
				}
			}
			
			// selected
			
			NSString * tSelectedFunctionName=[inName stringByAppendingString:@"_selected"];
			
			if ([self createSelectedDependencyFunctionNamed:tSelectedFunctionName
										   withEnabledState:tEnabledState
									withEnabledFunctionName:[inName stringByAppendingString:@"_enabled"]
										 withDependencyTree:tStateDependencies.selectedStateDependenciesTree]==NO)
			{
				// A COMPLETER
				
				return NO;
			}

			tAttribute=[NSXMLNode attributeWithName:@"start_selected" stringValue:[NSString stringWithFormat:@"%@(true)",tSelectedFunctionName]];
			[inElement addAttribute:tAttribute];
				
			tAttribute=[NSXMLNode attributeWithName:@"selected" stringValue:[NSString stringWithFormat:@"%@(false)",tSelectedFunctionName]];
			[inElement addAttribute:tAttribute];
		
			break;
		}
			
		// Groups
		
		case PKGEnabledChoiceGroupState:
		
			// Nothing to do
			
			break;
			
		case PKGDisabledChoiceGroupState:
			
			// start_enabled
			
			tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:@"false"];
			[inElement addAttribute:tAttribute];
				
			break;
			
		case PKGDependentChoiceGroupState:
		{
			tStateDependencies=inOptions.stateDependencies;
				
			NSString * tEnabledFunctionName=[inName stringByAppendingString:@"_enabled"];
			
			if ([self createEnabledDependencyFunctionNamed:tEnabledFunctionName
										withDependencyTree:tStateDependencies.enabledStateDependenciesTree]==YES)
			{
				// A COMPLETER
				
				return NO;
			}
			
			tAttribute=[NSXMLNode attributeWithName:@"start_enabled" stringValue:[NSString stringWithFormat:@"%@()",tEnabledFunctionName]];
			[inElement addAttribute:tAttribute];
				
			tAttribute=[NSXMLNode attributeWithName:@"enabled" stringValue:[NSString stringWithFormat:@"%@()",tEnabledFunctionName]];
			[inElement addAttribute:tAttribute];
		
			break;
		}
	}
	
	return YES;
}

- (BOOL)setStateAttributesOfChoiceElement:(NSXMLElement *) inElement name:(NSString *) inName withChoiceItem:(PKGChoiceItem *) inChoiceItem
{
	if (inElement==nil || inChoiceItem==nil)
		return NO;
	
	NSString * tRequirementFunctionName=nil;
	BOOL tAtLeastOneUnselectAndHideRequirementEnabled=NO;
	
	if (inChoiceItem.requirements.count>0)
	{
		NSMutableArray * tRequirementsArray=inChoiceItem.requirements;
		
		NSMutableArray * tEnabledRequirementsArray=[tRequirementsArray WB_filteredArrayUsingBlock:^BOOL(PKGRequirement * bRequirement,NSUInteger bIndex){
			
			return bRequirement.enabled;
		}];
		
		if (tEnabledRequirementsArray.count>0)
		{
			if ([self setRequirementsFunctionForChoiceName:inName withArray:tEnabledRequirementsArray functionName:&tRequirementFunctionName]==NO)
			{
				// A COMPLETER
				
				return NO;
			}
			
			tAtLeastOneUnselectAndHideRequirementEnabled=[self hasOneHideAndUnselectRequirementEnabledInArray:tEnabledRequirementsArray];
		}
	}
	
	if (tRequirementFunctionName==nil)
	{
		// No Requirements
						
		return [self setStateAttributesOfChoiceElement:inElement
												  name:inName
										   withOptions:inChoiceItem.options];
	}
	
	// Requirements
		
	return [self setStateAttributesOfChoiceElement:inElement
											  name:inName
						   requirementFunctionName:tRequirementFunctionName
									 affectVisible:tAtLeastOneUnselectAndHideRequirementEnabled
									   withOptions:inChoiceItem.options];
}

- (BOOL)addChoicesElementsToElement:(NSXMLElement *) inElement withChoicesArray:(NSArray *) inChoicesArray isInstaller:(BOOL) inIsInstaller
{
	if (inElement==nil || inChoicesArray==nil)
		return NO;
	
	NSMutableDictionary * tChoicesNamesDictionary=_buildInformation.choicesNames;
	
	for(PKGChoiceTreeNode * tChoiceTreeNode in inChoicesArray)
	{
		// choice
		
		NSXMLElement * tChoiceElement=(NSXMLElement *) [NSXMLNode elementWithName:@"choice"];
			
		PKGChoiceItem * tChoiceItem=(PKGChoiceItem *)tChoiceTreeNode.representedObject;
			
		// id
		
		NSString * tChoiceUUID=tChoiceItem.UUID;
		NSString * tChoiceReadableID=tChoicesNamesDictionary[tChoiceUUID];
		
		id tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:tChoiceReadableID];
		[tChoiceElement addAttribute:tAttribute];
		
		if (tChoiceItem.type==PKGChoiceItemTypePackage)
		{
			// Package choice
			
			NSXMLElement * tPkgRefElement=[self packageRefeferenceElementWithChoicePackageItem:(PKGChoicePackageItem *)tChoiceItem];
			
			if (tPkgRefElement==nil)
			{
				// A COMPLETER
				
				return NO;
			}
			
#ifdef __SUPPORT_CUSTOM_LOCATION__
			
			NSString * tPackageUUID=((PKGChoicePackageItem *)tChoiceItem).packageUUID;
			
			PKGBuildPackageAttributes * tBuildPackageAttributes=_buildInformation.packagesAttributes[tPackageUUID];
			
			if (tBuildPackageAttributes.customLocation!=nil)
			{
				tAttribute=[NSXMLNode attributeWithName:@"customLocation" stringValue:tBuildPackageAttributes.customLocation];
				[tChoiceElement addAttribute:tAttribute];
			}
#endif
			
			[tChoiceElement addChild:tPkgRefElement];
		}
		else
		{
			if ([tChoiceTreeNode numberOfChildren]==0)
			{
				if (inIsInstaller==NO)		// If it's not a hierarchy for Installer.app, we skip empty folder
					continue;
			}
			else
			{
				PKGChoiceItemOptions * tOptions=tChoiceItem.options;
				
				if (tOptions.hideChildren==NO)
				{
					if ([self addChoicesElementsToElement:inElement withChoicesArray:[tChoiceTreeNode children] isInstaller:inIsInstaller]==NO)
					{
						// A COMPLETER
						
						return NO;
					}
				}
				else
				{
					// Add the pkg-refs
					
					for(PKGChoiceTreeNode * tChildTreeNode in [tChoiceTreeNode children])
					{
						NSXMLElement * tPkgRefElement=[self packageRefeferenceElementWithChoicePackageItem:(PKGChoicePackageItem *)tChildTreeNode.representedObject];
						
						if (tPkgRefElement==nil)
						{
							// A COMPLETER
							
							return NO;
						}
						
						[tChoiceElement addChild:tPkgRefElement];
					}
				}
				
			}
		}
		
		if ([self setStateAttributesOfChoiceElement:tChoiceElement name:tChoiceReadableID withChoiceItem:tChoiceItem]==NO)
			return NO;
		
		// title
		
		NSString * tDefaultTitle=nil;
		
			// Get the default title
		
		if (tChoiceItem.type==PKGChoiceItemTypePackage)
		{
			PKGChoicePackageItem * tChoicePackageItem=(PKGChoicePackageItem *) tChoiceItem;
			
			NSString * tPackageUUID=tChoicePackageItem.packageUUID;
		
			// Use the name of the package (if it's a package)
			
			PKGBuildPackageAttributes * tBuildPackageAttributes=_buildInformation.packagesAttributes[tPackageUUID];
			
			if (tBuildPackageAttributes==nil)
			{
				// A COMPLETER
				
				return NO;
			}
			
			tDefaultTitle=tBuildPackageAttributes.name;
		}
		else
		{
			tDefaultTitle=@"Choice";
			
			// Try to get something better
			
			NSArray * tComponents=[tChoiceReadableID componentsSeparatedByString:@"_"];
			
			NSUInteger tCount=tComponents.count;
				
			if (tCount>2)
			{
				NSArray * tIndexesArray=[tComponents subarrayWithRange:NSMakeRange(2,tCount-2)];
				
				tDefaultTitle=[NSString stringWithFormat:@"%@ %@",tComponents[1],[tIndexesArray componentsJoinedByString:@"."]];
			}
		}
		
		
		
		NSMutableDictionary * tLocalizationsDictionary=_buildInformation.localizations;
		
		NSString * tTitleString=tDefaultTitle;
		
		NSDictionary * tLocalizations=tChoiceItem.localizedTitles;
		
		if (tLocalizations.count>0)
		{
			__block BOOL tAtLeastOneLocalizedTitle=NO;
			
			// Make the title localizable
			
			NSString *tTitleKey=[NSString stringWithFormat:@"%@_TITLE",[tChoiceReadableID uppercaseString]];
			
			[tLocalizations enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguageKey,NSString *bLocalizedTitle,BOOL * bOutStop){
				
				NSMutableDictionary * tLanguageLocalizationsDictionary=tLocalizationsDictionary[bLanguageKey];
				
				if (tLanguageLocalizationsDictionary==nil)
					tLocalizationsDictionary[bLanguageKey]=tLanguageLocalizationsDictionary=[NSMutableDictionary dictionary];
				
				if ([bLocalizedTitle length]>0)
				{
					tLanguageLocalizationsDictionary[tTitleKey]=bLocalizedTitle;
					tAtLeastOneLocalizedTitle=YES;
				}
				
			}];
			
			if (tAtLeastOneLocalizedTitle==YES)
			{
				// Set the default value
				
				NSMutableDictionary * tDefaultLanguageDictionary=tLocalizationsDictionary[PKGBuildDefaultLanguageKey];
					
				tDefaultLanguageDictionary[tTitleKey]=tDefaultTitle;
				
				tTitleString=tTitleKey;
			}
		}
		
		tAttribute=[NSXMLNode attributeWithName:@"title" stringValue:tTitleString];
		[tChoiceElement addAttribute:tAttribute];
		
		
		// description
		
		NSString * tDescriptionString=@"";	// Default is empty string
		
		tLocalizations=tChoiceItem.localizedDescriptions;
		
		if (tLocalizations.count>0)
		{
			__block BOOL tAtLeastOneLocalizedDescription=NO;
			
			// Make the description localizable
			
			NSString *tDescriptionKey=[NSString stringWithFormat:@"%@_DESCRIPTION",[tChoiceReadableID uppercaseString]];
			
			[tLocalizations enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguageKey,NSString *bLocalizedDescription,BOOL * bOutStop){
				
				NSMutableDictionary * tLanguageLocalizationsDictionary=tLocalizationsDictionary[bLanguageKey];
				
				if (tLanguageLocalizationsDictionary==nil)
					tLocalizationsDictionary[bLanguageKey]=tLanguageLocalizationsDictionary=[NSMutableDictionary dictionary];
				
				if ([bLocalizedDescription length]>0)
				{
					tLanguageLocalizationsDictionary[tDescriptionKey]=bLocalizedDescription;
					tAtLeastOneLocalizedDescription=YES;
				}
				
			}];
			
			if (tAtLeastOneLocalizedDescription==YES)
			{
				// Set the default value
				
				NSMutableDictionary * tDefaultLanguageDictionary=tLocalizationsDictionary[PKGBuildDefaultLanguageKey];
				
				tDefaultLanguageDictionary[tDescriptionKey]=@"";
				
				tDescriptionString=tDescriptionKey;
			}
		}
		
		tAttribute=[NSXMLNode attributeWithName:@"description" stringValue:tDescriptionString];
		[tChoiceElement addAttribute:tAttribute];
		
		[inElement addChild:tChoiceElement];
	}
	
	return YES;
}

- (BOOL)addLinesElementsToElement:(NSXMLElement *) inElement withChoicesArray:(NSArray *) inChoicesArray isInstaller:(BOOL) inIsInstaller prefix:(NSString *) inPrefix
{
	if (inElement==nil || inChoicesArray==nil || inPrefix==nil)
		return NO;

	unsigned long tIndex=1;
	
	NSMutableDictionary * tChoicesNamesDictionary=_buildInformation.choicesNames;

	for(PKGChoiceTreeNode * tChoiceTreeNode in inChoicesArray)
	{
		NSXMLElement * tLineElement=(NSXMLElement *) [NSXMLNode elementWithName:@"line"];
		
		PKGChoiceItem * tChoiceItem=(PKGChoiceItem *)tChoiceTreeNode.representedObject;
		
		// choice
		
		NSString * tChoiceUUID=tChoiceItem.UUID;
		
		NSString * tChoiceReadableID=[NSString stringWithFormat:@"%@%lu",inPrefix,tIndex];
		
		tIndex++;
		
		tChoicesNamesDictionary[tChoiceUUID]=tChoiceReadableID;
		
		id tAttribute=[NSXMLNode attributeWithName:@"choice" stringValue:tChoiceReadableID];
		[tLineElement addAttribute:tAttribute];
		
		if (tChoiceItem.type!=PKGChoiceItemTypeGroup)
		{
			[inElement addChild:tLineElement];
			continue;
		}
		
		if ([tChoiceTreeNode numberOfChildren]==0)
		{
			if (inIsInstaller==NO)	// If it's not a hierarchy for Installer.app, we skip empty folder
				continue;
		}
		
		if (tChoiceItem.options.hideChildren==NO)
		{
			if ([self addLinesElementsToElement:tLineElement withChoicesArray:[tChoiceTreeNode children] isInstaller:inIsInstaller prefix:[tChoiceReadableID stringByAppendingString:@"_"]]==NO)
				return NO;
		}
		
		[inElement addChild:tLineElement];
	}
	
	return YES;
}

- (void)setPackagesReferences
{
	id tComment=[NSXMLNode commentWithStringValue:@"+==========================+\n        |    Package References    |\n        +==========================+"];
	[_installerScriptElement addChild:tComment];
	
	[_buildInformation.packagesAttributes enumerateKeysAndObjectsUsingBlock:^(NSString * bKey,PKGBuildPackageAttributes * bBuildPackageAttributes,BOOL * bOutStop){
		
		NSXMLElement * tPkgRefElement=(NSXMLElement *) [NSXMLNode elementWithName:@"pkg-ref"];
		id tAttribute;
		
		// id
		
		NSString * tString=bBuildPackageAttributes.identifier;
		
		tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:tString];
		[tPkgRefElement addAttribute:tAttribute];
		
		// version
		
		tString=bBuildPackageAttributes.version;
		
		tAttribute=[NSXMLNode attributeWithName:@"version" stringValue:tString];
		[tPkgRefElement addAttribute:tAttribute];
		
		// path
		
		tString=bBuildPackageAttributes.referencePath;
		
		NSXMLNode * tNode=[NSXMLNode textWithStringValue:tString];
		[tPkgRefElement addChild:tNode];
		
		// auth
		
		if (bBuildPackageAttributes.authenticationMode==PKGPackageAuthenticationRoot)
		{
			tAttribute=[NSXMLNode attributeWithName:@"auth" stringValue:@"Root"];
			[tPkgRefElement addAttribute:tAttribute];
		}
		
		// Optional data
		
		NSInteger tPayloadSize=bBuildPackageAttributes.payloadSize;
		
		if (tPayloadSize!=-1)
		{
			tAttribute=[NSXMLNode attributeWithName:@"installKBytes" stringValue:[NSString stringWithFormat:@"%ld",(long)tPayloadSize]];
			[tPkgRefElement addAttribute:tAttribute];
		}
		
		// onConclusion
		
		PKGPackageConclusionAction tConclusionAction=bBuildPackageAttributes.conclusionAction;
		
		if (tConclusionAction>PKGPackageConclusionActionNone)
		{
			switch(tConclusionAction)
			{
				case PKGPackageConclusionActionRequireRestart:
					
					tString=@"RequireRestart";
					
					break;
					
				case PKGPackageConclusionActionRequireShutdown:
					
					tString=@"RequireShutdown";
					
					break;
					
				case PKGPackageConclusionActionRequireLogout:
					
					tString=@"RequireLogout";
					
					break;
					
				default:
					break;
			}
			
			tAttribute=[NSXMLNode attributeWithName:@"onConclusion" stringValue:tString];
			[tPkgRefElement addAttribute:tAttribute];
		}
		
		[_installerScriptElement addChild:tPkgRefElement];
		
		// Must Close ApplicationIDs
		
		if (bBuildPackageAttributes.mustBeClosedApplicationIDs.count>0)
		{
			// We need to add another pkg-ref entry because xml parsing does not work that well on 10.7 at least
			
			NSXMLElement * tAdditionalPkgRefElement=(NSXMLElement *) [NSXMLNode elementWithName:@"pkg-ref"];
			
			// id
			
			tString=bBuildPackageAttributes.identifier;
			
			tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:tString];
			[tAdditionalPkgRefElement addAttribute:tAttribute];
			
			NSXMLElement * tMustCloseElement=(NSXMLElement *) [NSXMLNode elementWithName:@"must-close"];
			
			[bBuildPackageAttributes.mustBeClosedApplicationIDs enumerateObjectsUsingBlock:^(NSString * bApplicationID, NSUInteger bIndex, BOOL *bOutStop2) {
				
				NSXMLElement * tApplicationElement=(NSXMLElement *) [NSXMLNode elementWithName:@"app"];
				
				id tIDAttribute=[NSXMLNode attributeWithName:@"id" stringValue:bApplicationID];
				[tApplicationElement addAttribute:tIDAttribute];
				
				[tMustCloseElement addChild:tApplicationElement];
				
			}];
			
			[tAdditionalPkgRefElement addChild:tMustCloseElement];
			
			[_installerScriptElement addChild:tAdditionalPkgRefElement];
		}
	}];
}

- (BOOL)setPresentation
{
	id tComment=[NSXMLNode commentWithStringValue:@"+==========================+\n        |       Presentation       |\n        +==========================+"];
	[_installerScriptElement addChild:tComment];
	
	// Title
	
	[self setTitle];
	
	
	_treatMissingPresentationDocumentsAsWarnings=((PKGDistributionProjectSettings *)self.project.settings).treatMissingPresentationDocumentsAsWarnings;
	
	
	PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=nil;

	if (_buildFormat==PKGProjectBuildFormatBundle)
		tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
	
	// Background

	if ([self setBackground]==NO)
		return NO;
	
	// Introduction

	if ([self setIntroduction]==NO)
		return NO;
	
	// ReadMe

	if ([self setReadMe]==NO)
		return NO;
	
	// License

	if ([self setLicense]==NO)
		return NO;
	
	// Conclusion
	
	if ([self setConclusion]==NO)
		return NO;
	
	tStackedEffectiveUserAndGroup=nil;
	
	// Package Hierarchy

	if ([self setChoiceOutline]==NO)
		return NO;
	
	// Packages References
		
	[self setPackagesReferences];
	
	return YES;
}

- (void)setJavaScriptScripts
{
	NSArray * tJavaScriptFunctionsArray=_buildInformation.javaScriptInformation.functions;
	
	if (tJavaScriptFunctionsArray.count==0)
		return;
	
	id tComment=[NSXMLNode commentWithStringValue:@"+==========================+\n        |    JavaScript Scripts    |\n        +==========================+"];
	[_installerScriptElement addChild:tComment];
	
	[self postStep:PKGBuildStepDistributionJavaScript beginEvent:nil];

	NSXMLElement * tScriptElement=(NSXMLElement *) [NSXMLNode elementWithName:@"script"];
				
	// Constants
	
	NSMutableString * tMutableString=[NSMutableString stringWithFormat:@"\n\n\tconst __IC_FLAT_DISTRIBUTION__=%@;\n",(_buildFormat==PKGProjectBuildFormatFlat) ? @"true" : @"false"];
	
	

	NSArray * tJavaScriptConstantsArray=_buildInformation.javaScriptInformation.constants;
	
	for(NSString * tConstantsDeclaration in tJavaScriptConstantsArray)
		[tMutableString appendFormat:@"%@\n",tConstantsDeclaration];
	
	// Functions
	
	for(NSString * tFunctionCode in tJavaScriptFunctionsArray)
		[tMutableString appendFormat:@"%@\n\n",tFunctionCode];

	// To re-align the </script> tag
	
	[tMutableString appendString:@"    "];
	
	id tNode=[NSXMLNode textWithStringValue:tMutableString];
	[tScriptElement addChild:tNode];
	
	[_installerScriptElement addChild:tScriptElement];
	
	[self postCurrentStepSuccessEvent:nil];
}

- (BOOL)setLocalizableStrings
{
	NSDictionary * tLocalizationsDictionary=_buildInformation.localizations;
	
	// Get the default values and the list of keys
	
	NSMutableDictionary * tDefaultLanguageDictionary=tLocalizationsDictionary[PKGBuildDefaultLanguageKey];
	
	PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=nil;
	
	if (_buildFormat==PKGProjectBuildFormatBundle)
		tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
	
	for(NSString * tLanguage in [tLocalizationsDictionary allKeys])
	{
		if ([tLanguage isEqualToString:PKGBuildDefaultLanguageKey]==YES)
			continue;
		
		NSString * tLanguagePath=[self getDistributionPathForLanguage:tLanguage];
		
		if (tLanguagePath==nil)
		{
			// Unknown language
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorUnknownLanguage tag:tLanguage]];
			
			// A COMPLETER
			
			return NO;
		}
		
		NSMutableString * tMutableString=[NSMutableString string];
		
		NSDictionary * tLocalizedStringsDictionary=tLocalizationsDictionary[tLanguage];
		
		for(NSString * tKey in tDefaultLanguageDictionary)
		{
			NSString * tLocalizedString=tLocalizedStringsDictionary[tKey];
			
			if (tLocalizedString==nil)
				tLocalizedString=tDefaultLanguageDictionary[tKey];
			
			if (tLocalizedString==nil)
			{
				// Missing Build Data
				
				[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing Build Data: %@",tKey];
				
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingBuildData tag:PKGBuildDefaultLanguageKey]];	// A VOIR tag

				// A COMPLETER
				
				return NO;
			}
			
			NSMutableString * tMutableLocalizedString=[tLocalizedString mutableCopy];
		
			[tMutableLocalizedString replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0,[tMutableLocalizedString length])];
			
			[tMutableLocalizedString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0,[tMutableLocalizedString length])];
			
			[tMutableLocalizedString replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0,[tMutableLocalizedString length])];
			
			[tMutableLocalizedString replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0,[tMutableLocalizedString length])];
			
			[tMutableLocalizedString replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0,[tMutableLocalizedString length])];
			
			[tMutableString appendString:[NSString stringWithFormat:@"\"%@\" = \"%@\";\n\n",tKey,tMutableLocalizedString]];
		}
		
		NSError * tError;
		
		if ([tMutableString writeToFile:[tLanguagePath stringByAppendingPathComponent:@"Localizable.strings"] atomically:NO encoding:NSUnicodeStringEncoding error:&tError]==NO)
		{
			NSLog(@"%@",tError);	// A VIRER (once the errorEvent is set and sent)
			
			[self postCurrentStepFailureEvent:nil];
			
			// A COMPLETER
	
			return NO;
		}
	}
	
	tStackedEffectiveUserAndGroup=nil;
	
	return YES;
}

- (BOOL)setPlugins
{
	[self postStep:PKGBuildStepDistributionInstallerPlugins beginEvent:nil];
	
	PKGDistributionProjectPresentationSettings * tPresentationSettings=((PKGDistributionProject *) self.project).presentationSettings;
	
	NSMutableArray * tSectionOrdersMutableArray=[NSMutableArray array];
	BOOL tHasCustomPlugin=NO;
	BOOL tDirectoryCreated=NO;
	
	NSString * tContentsPath=_buildInformation.contentsPath;
	
	for(PKGPresentationSection * tSection in tPresentationSettings.sections)
	{
		if (tSection.isPlugin==NO)
		{
			[tSectionOrdersMutableArray addObject:tSection.installerSectionName];
			continue;
		}
		
		tHasCustomPlugin=YES;
		
		PKGFilePath * tFilePath=tSection.pluginPath;
		
		NSString * tAbsolutePluginPath=[self absolutePathForFilePath:tFilePath];
		
		if (tAbsolutePluginPath==nil)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:tFilePath.string fileKind:PKGFileKindRegularFile]];
			
			return NO;
		}
		
		BOOL isDirectory;
			
		if ([_fileManager fileExistsAtPath:tAbsolutePluginPath isDirectory:&isDirectory]==NO || isDirectory==NO)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tAbsolutePluginPath fileKind:PKGFileKindPlugin]];
			
			return NO;
		}
		
		// Note to future self: check which minimum version of Mac OS X or Installer.app do support cpio.gz Plugins (also check case sensitivity, PlugIns?)
		
		NSString * tDestinationPluginsDirectoryPath=[tContentsPath stringByAppendingPathComponent:@"Plugins"];
		
		PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=nil;
		
		if (_buildFormat==PKGProjectBuildFormatBundle)
			tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
		
		// Build the Plugins folder if needed
		
		if (tDirectoryCreated==NO)
		{
			if ([self createDirectoryAtPath:tDestinationPluginsDirectoryPath withIntermediateDirectories:NO]==NO)
				return NO;
			
			tDirectoryCreated=YES;
		}
		
		NSString * tBundleName=tAbsolutePluginPath.lastPathComponent;
		
		// Copy the plugin to the Plugins folder
		
		NSString * tDestinationPluginPath=[tDestinationPluginsDirectoryPath stringByAppendingPathComponent:tBundleName];
		
		NSError * tCopyError=NULL;
		
		BOOL tCopyResult=[_fileManager copyItemAtPath:tAbsolutePluginPath toPath:tDestinationPluginPath error:&tCopyError];
		
		tStackedEffectiveUserAndGroup=nil;
		
		if (tCopyResult==NO)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCopied filePath:tAbsolutePluginPath fileKind:PKGFileKindPlugin];
			tErrorEvent.otherFilePath=tDestinationPluginsDirectoryPath;
			
			if (tCopyError!=nil && [tCopyError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				switch(tCopyError.code)
				{
					case NSFileNoSuchFileError:
						
						tErrorEvent.subcode=PKGBuildErrorFileNotFound;
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"[PKGProjectBuilder setPlugins] File not found"];
						
						break;
						
					case NSFileWriteOutOfSpaceError:
						
						tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"[PKGProjectBuilder setPlugins] Not enough free space"];
						
						break;
						
					case NSFileWriteVolumeReadOnlyError:
						
						tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
						
						break;
						
					case NSFileWriteNoPermissionError:
						
						tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
						
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"[PKGProjectBuilder setPlugins] Write permission error"];
						
						break;
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
		
		[tSectionOrdersMutableArray addObject:tBundleName];
	}
	
	if (tHasCustomPlugin==NO)
	{
		[self postCurrentStepSuccessEvent:nil];
		
		return YES;
	}
	
	NSDictionary * tDictionary=@{@"SectionOrder":tSectionOrdersMutableArray};
	
	NSString * tPlistPath=[tContentsPath stringByAppendingPathComponent:@"Plugins/InstallerSections.plist"];

	PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=nil;
	
	if (_buildFormat==PKGProjectBuildFormatBundle)
		tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
	
	if ([tDictionary writeToFile:tPlistPath atomically:NO]==NO)
	{
		// A COMPLETER
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCreated filePath:tPlistPath fileKind:PKGFileKindRegularFile]];
		
		return NO;
	}
	
	NSError * tError=nil;
	
	if ([_fileManager setAttributes:@{NSFilePosixPermissions:@(S_IRUSR+S_IWUSR+S_IRGRP+S_IROTH)} ofItemAtPath:tPlistPath error:&tError]==NO)
	{
		if (tError!=nil)
		{
			// A COMPLETER
		}
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFilePosixPermissionsCanNotBeSet filePath:tPlistPath fileKind:PKGFileKindRegularFile]];
		
		return NO;
	}
	
	tStackedEffectiveUserAndGroup=nil;
	
	[self postCurrentStepSuccessEvent:nil];
	
	return YES;
}

- (NSString *) getDistributionPathForLanguage:(NSString *) inLanguage
{
	NSString * tLanguagePathKey=[NSString stringWithFormat:@"_%@",inLanguage];
	
	NSString * tLanguagePath=_buildInformation.languagesPath[tLanguagePathKey];
	
	if (tLanguagePath!=nil)
		return tLanguagePath;
	
	NSString * tResourcesPath=_buildInformation.resourcesPath;
	
	if (tResourcesPath==nil)
	{
		// could not create resources folder
		
		return nil;
	}
	
	NSString * tFolderName;
	
	switch(_buildFormat)
	{
		case PKGProjectBuildFormatFlat:
		
			tFolderName=[PKGLanguageManager shortFolderNameForEnglishLanguage:inLanguage];
			break;
		
		case PKGProjectBuildFormatBundle:
		
			tFolderName=[PKGLanguageManager folderNameForEnglishLanguage:inLanguage];
			break;
	}
	
	tLanguagePath=[tResourcesPath stringByAppendingPathComponent:tFolderName];
	
	NSError * tError=nil;
	
	if ([_fileManager createDirectoryAtPath:tLanguagePath withIntermediateDirectories:NO attributes:_folderAttributes error:&tError]==NO)
		return nil;
			
	_buildInformation.languagesPath[tLanguagePathKey]=tLanguagePath;
	
	return tLanguagePath;
}

#pragma mark - Archiving Tasks



- (BOOL)splitForksContentsOfDirectoryAtPath:(NSString *)inDirectoryPath
{
	return [self splitForksContentsOfDirectoryAtPath:inDirectoryPath preserveExtendedAttributes:NO];
}

- (BOOL)splitForksContentsOfDirectoryAtPath:(NSString *)inDirectoryPath preserveExtendedAttributes:(BOOL)inPreserveExtendedAttributes;
{
	if (inDirectoryPath==nil)
		return NO;
	
	// Split Forks if needed
	
	[self postStep:PKGBuildStepPayloadSplit beginEvent:nil];
	
	NSTask * tTask=[NSTask new];
	
	tTask.launchPath=PKGProjectBuilderToolPath_goldin;
	
	if (inPreserveExtendedAttributes==NO)
		tTask.arguments=@[inDirectoryPath];
	else
		tTask.arguments=@[@"-e",inDirectoryPath];
		
	NSPipe * tOutputPipe = [NSPipe pipe];
	
	tTask.standardOutput=tOutputPipe;
	tTask.standardError=tOutputPipe;
	
	[tTask launch];
	[tTask waitUntilExit];
	
	int tReturnValue=tTask.terminationStatus;
	
	if (0!=tReturnValue)
	{
		PKGBuildErrorEvent * tErrorEvent=nil;
		
		switch(tReturnValue)
		{
			default:
				
				tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorExternalToolFailure filePath:PKGProjectBuilderToolPath_goldin fileKind:PKGFileKindTool];
				tErrorEvent.toolTerminationStatus=tReturnValue;
				
				NSData * tData=[tOutputPipe.fileHandleForReading readDataToEndOfFile];
				
				NSString * tErrorString=[[NSString alloc] initWithData:tData encoding:NSUTF8StringEncoding];
				
				if (tErrorString.length>0)
					tErrorEvent.tag=tErrorString;
				
				break;
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		return NO;
	}
	
	[self postCurrentStepSuccessEvent:nil];
	
	return YES;
}

- (BOOL)archiveContentsOfDirectoryAtPath:(NSString *)inDirectoryPath toFileAtPath:(NSString *)inFilePath format:(PKGArchiveFormat)inFormat compressionFormat:(PKGArchiveCompressionFormat)inCompressionFormat
{
	if (inDirectoryPath==nil || inFilePath==nil)
		return NO;
	
	[self postStep:PKGBuildStepPayloadPax beginEvent:nil];

	NSTask * tTask=[NSTask new];
	
	tTask.launchPath=PKGProjectBuilderToolPath_ditto;
	tTask.arguments=@[
					  @"--noextattr",
					  @"--noqtn",
					  @"--noacl",
					  @"--norsrc",
					  @"-c",
					  @"-z",
					  @".",
					  inFilePath];
	tTask.currentDirectoryPath=inDirectoryPath;

	[tTask launch];
	[tTask waitUntilExit];

	int tReturnValue=tTask.terminationStatus;

	if (tReturnValue!=0)
	{
		PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorExternalToolFailure filePath:PKGProjectBuilderToolPath_ditto fileKind:PKGFileKindTool];
		tErrorEvent.toolTerminationStatus=tReturnValue;
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		return NO;
	}

	[self postCurrentStepSuccessEvent:nil];
	
	return YES;
}

#pragma mark -

- (BOOL)buildPackageInfoForComponent:(PKGPackageComponent *)inPackageComponent atPath:(NSString *)inPath contextInfo:(PKGBuildPackageAttributes *)inBuildPackageAttributes
{
	if (inPackageComponent==nil || inPath==nil)
	{
		[self postCurrentStepFailureEvent:nil];
		
		return NO;
	}
	
	[self postStep:PKGBuildStepPackageInfo beginEvent:nil];
	
	// Create the XML Document
	
	PKGPackageSettings * tPackageSettings=inPackageComponent.packageSettings;
	
	NSXMLElement * tPackageInfoElement=(NSXMLElement *) [NSXMLNode elementWithName:@"pkg-info"];
	
	// format-version
	
	id tAttribute=[NSXMLNode attributeWithName:@"format-version" stringValue:@"2"];
	[tPackageInfoElement addAttribute:tAttribute];
	
	// identifier
	
	NSString * tPackageIdentifier=tPackageSettings.identifier;
	
	if ([tPackageIdentifier length]==0)
	{
		// Incorrect Value (Empty String)
		
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"IDENTIFIER string can not be empty."];
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsIdentifierKey"]];
		
		return NO;
	}
	
	inBuildPackageAttributes.identifier=tPackageIdentifier;
	
	tAttribute=[NSXMLNode attributeWithName:@"identifier" stringValue:tPackageIdentifier];
	[tPackageInfoElement addAttribute:tAttribute];
	
	// version
	
	NSString * tVersion=tPackageSettings.version;
	
	if ([inPackageComponent isKindOfClass:PKGPackageProject.class]==YES)
	{
		NSString * tUserDefinedVersion=[_buildOrder userDefinedSettingsForKey:PKGBuildOrderExternalSettingsPackageVersionKey];
		
		if ([tUserDefinedVersion isKindOfClass:NSString.class]==YES)
			tVersion=[tUserDefinedVersion copy];
	}
	
	if (tVersion.length==0)
	{
		// Incorrect Value
		
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"VERSION string can not be empty."];
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsVersionKey"]];
		
		return NO;
	}
	
	inBuildPackageAttributes.version=tVersion;
	
	tAttribute=[NSXMLNode attributeWithName:@"version" stringValue:tVersion];
	[tPackageInfoElement addAttribute:tAttribute];
	
	// relocatable
	
	tAttribute=[NSXMLNode attributeWithName:@"relocatable" stringValue:(tPackageSettings.relocatable==YES) ? @"true" : @"false"];
	[tPackageInfoElement addAttribute:tAttribute];
	
	// overwrite-permissions
	
	tAttribute=[NSXMLNode attributeWithName:@"overwrite-permissions" stringValue:(tPackageSettings.overwriteDirectoryPermissions==YES) ? @"true" : @"false"];
	[tPackageInfoElement addAttribute:tAttribute];
	
	// followSymLinks
	
	tAttribute=[NSXMLNode attributeWithName:@"followSymLinks" stringValue:(tPackageSettings.followSymbolicLinks==YES) ? @"true" : @"false"];
	[tPackageInfoElement addAttribute:tAttribute];
	
	// useHFSPlusCompression
	
	if (tPackageSettings.useHFSPlusCompression==YES)
	{
		tAttribute=[NSXMLNode attributeWithName:@"useHFSPlusCompression" stringValue:@"true"];
		[tPackageInfoElement addAttribute:tAttribute];
	}
	
	// install-location
	
	PKGPackagePayload * tPackagePayload=inPackageComponent.payload;
	
	if (tPackagePayload==nil)
		tPackagePayload=[PKGPackagePayload emptyPayload];
	
	NSString * tInstallLocation=(tPackagePayload.type==PKGPayloadExternal) ? @"/" : tPackagePayload.defaultInstallLocation;
	
	tAttribute=[NSXMLNode attributeWithName:@"install-location" stringValue:tInstallLocation];
	[tPackageInfoElement addAttribute:tAttribute];
	
	// auth
	
	PKGPackageAuthentication tAuthenticationMode=tPackageSettings.authenticationMode;
	
	inBuildPackageAttributes.authenticationMode=tAuthenticationMode;
	
	tAttribute=[NSXMLNode attributeWithName:@"auth" stringValue:(tAuthenticationMode==PKGPackageAuthenticationRoot) ? @"root" : @"none"];
	[tPackageInfoElement addAttribute:tAttribute];
	
	// post-install-action
	
	PKGPackageConclusionAction tConclusionAction=tPackageSettings.conclusionAction;
	
	inBuildPackageAttributes.conclusionAction=tConclusionAction;
	
	if (tConclusionAction>PKGPackageConclusionActionRecommendRestart)
	{
		NSString * tActionString;
		
		switch(tConclusionAction)
		{
			case PKGPackageConclusionActionRequireRestart:
				
				tActionString=@"restart";
				break;
				
			case PKGPackageConclusionActionRequireShutdown:
				
				tActionString=@"shutdown";
				break;
				
			case PKGPackageConclusionActionRequireLogout:
				
				tActionString=@"logout";
				break;
				
			default:
				
				break;
		}
		
		tAttribute=[NSXMLNode attributeWithName:@"postinstall-action" stringValue:tActionString];
		[tPackageInfoElement addAttribute:tAttribute];
	}
	
	// preserve-xattr
	
	if (tPackagePayload.preserveExtendedAttributes==YES)
	{
		tAttribute=[NSXMLNode attributeWithName:@"preserve-xattr" stringValue:@"true"];
		[tPackageInfoElement addAttribute:tAttribute];
	}
	
	// payload
	
	NSXMLElement * tPayloadElement=(NSXMLElement *) [NSXMLNode elementWithName:@"payload"];
	
	// installKBytes
	
	NSInteger tPayloadSize=inBuildPackageAttributes.payloadSize;
	
	if (tPayloadSize==-1)
	{
		// Missing Build Data
		
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing Build Data: payloadSize"];
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingBuildData tag:@"build packageAttributes > payloadSize"]];
		
		return NO;
	}
	
	tAttribute=[NSXMLNode attributeWithName:@"installKBytes" stringValue:[NSString stringWithFormat:@"%ld",(long)tPayloadSize]];
	[tPayloadElement addAttribute:tAttribute];
	
	// numberOfFiles
	
	tAttribute=[NSXMLNode attributeWithName:@"numberOfFiles" stringValue:[NSString stringWithFormat:@"%ld",(long)inBuildPackageAttributes.numberOfFiles]];
	[tPayloadElement addAttribute:tAttribute];
	
	if (tPackagePayload.type==PKGPayloadExternal)
	{
		/*tAttribute=[NSXMLNode attributeWithName:@"external-root" stringValue:@"/Users/Shared/externalroot/"];		// A COMPLETER
		 [tPayloadElement addAttribute:tAttribute];*/
	}
	
	[tPackageInfoElement addChild:tPayloadElement];
	
	// scripts
	
	NSXMLElement * tScriptsElement=nil;
	
	if (inBuildPackageAttributes.preInstallScriptPath!=nil || inBuildPackageAttributes.postInstallScriptPath!=nil)
	{
		tScriptsElement=(NSXMLElement *) [NSXMLNode elementWithName:@"scripts"];
		
		// preinstall
		
		NSString * tPath=inBuildPackageAttributes.preInstallScriptPath;
		
		if (tPath!=nil)
		{
			NSXMLElement * tScriptsFileElement=(NSXMLElement *) [NSXMLNode elementWithName:@"preinstall"];
			
			tAttribute=[NSXMLNode attributeWithName:@"file" stringValue:tPath];
			
			[tScriptsFileElement addAttribute:tAttribute];
			[tScriptsElement addChild:tScriptsFileElement];
		}
		
		// postinstall
		
		tPath=inBuildPackageAttributes.postInstallScriptPath;
		
		if (tPath!=nil)
		{
			NSXMLElement * tScriptsFileElement=(NSXMLElement *) [NSXMLNode elementWithName:@"postinstall"];
			
			tAttribute=[NSXMLNode attributeWithName:@"file" stringValue:tPath];
			
			[tScriptsFileElement addAttribute:tAttribute];
			[tScriptsElement addChild:tScriptsFileElement];
		}
	}
	
	NSDictionary * tFinalScriptDictionary=inBuildPackageAttributes.bundlesScriptsTransformedNames;
	
	if (tScriptsElement==nil)
		tScriptsElement=(NSXMLElement *) [NSXMLNode elementWithName:@"scripts"];
		
	[inBuildPackageAttributes.bundlesScripts enumerateKeysAndObjectsUsingBlock:^(NSString * bBundleIdentifier,PKGBuildBundleScripts * bBundleScripts,BOOL * bOutStop){
		
		// Pre-installation
		
		NSString * tPath=bBundleScripts.preInstallScriptPath;
		
		if (tPath!=nil)
		{
			NSString * tFinalScriptPath=tFinalScriptDictionary[tPath];
			
			if (tFinalScriptPath!=nil)
			{
				NSXMLElement * tScriptsFileElement=(NSXMLElement *) [NSXMLNode elementWithName:@"preinstall"];
				
				id tScriptAttribute=[NSXMLNode attributeWithName:@"file" stringValue:tFinalScriptPath];
				[tScriptsFileElement addAttribute:tScriptAttribute];
				
				tScriptAttribute=[NSXMLNode attributeWithName:@"component-id" stringValue:bBundleIdentifier];
				[tScriptsFileElement addAttribute:tScriptAttribute];
				
				[tScriptsElement addChild:tScriptsFileElement];
			}
		}
		
		// Post-installation
		
		tPath=bBundleScripts.postInstallScriptPath;
		
		if (tPath!=nil)
		{
			NSString * tFinalScriptPath=tFinalScriptDictionary[tPath];
			
			if (tFinalScriptPath!=nil)
			{
				NSXMLElement * tScriptsFileElement=(NSXMLElement *) [NSXMLNode elementWithName:@"postinstall"];
				
				id tScriptAttribute=[NSXMLNode attributeWithName:@"file" stringValue:tFinalScriptPath];
				[tScriptsFileElement addAttribute:tScriptAttribute];
				
				tScriptAttribute=[NSXMLNode attributeWithName:@"component-id" stringValue:bBundleIdentifier];
				[tScriptsFileElement addAttribute:tScriptAttribute];
				
				[tScriptsElement addChild:tScriptsFileElement];
			}
		}
	}];
	
	if (tScriptsElement.childCount>0)
		[tPackageInfoElement addChild:tScriptsElement];
	
	// bundle-version
	
	NSArray * tArray=inBuildPackageAttributes.bundlesVersions;
	
	if (tArray.count>0)
	{
		NSXMLElement * tBundleVersionElement=(NSXMLElement *) [NSXMLNode elementWithName:@"bundle-version"];
		
		if ([self addBundleFromArray:tArray toElement:tBundleVersionElement withPath:@"" packageInfoElement:tPackageInfoElement downgradableBundles:inBuildPackageAttributes.downgradableBundles]==NO)
		{
			[self postCurrentStepFailureEvent:nil];	// A COMPLETER
			
			return NO;
		}
		
		if (tBundleVersionElement.childCount>0)
			[tPackageInfoElement addChild:tBundleVersionElement];
	}
	
	// relocate
	
	if (self.debug==NO)
	{
		NSDictionary * tDictionary=inBuildPackageAttributes.bundlesLocators;
		
		if (tDictionary.count>0)
		{
			NSXMLNode * tComment=[NSXMLNode commentWithStringValue:@"+==========================+\n    |         Locators         |\n    +==========================+"];
			[tPackageInfoElement addChild:tComment];
			
			__block BOOL tFailed=NO;
			
			[tDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bIdentifier,NSArray *bLocatorsArray,BOOL *bOutStop){
			
				if ([self addRelocators:bLocatorsArray forBundle:bIdentifier packageInfoElement:tPackageInfoElement]==NO)
				{
					*bOutStop=YES;
					tFailed=YES;
					return;
				}
			}];
			 
			if (tFailed==YES)
				return NO;
		}
	}
	
	// Save the XML
	
	NSString * tPackageInfoXML=[tPackageInfoElement XMLStringWithOptions:NSXMLNodePrettyPrint|NSXMLNodeCompactEmptyElement];
	
	if (tPackageInfoXML==nil)
	{
		[self postCurrentStepFailureEvent:nil];
		
		// A COMPLETER
		
		return NO;
	}
	
	NSError * tError;
	
	if ([tPackageInfoXML writeToFile:inPath atomically:NO encoding:NSUTF8StringEncoding error:&tError]==NO)
	{
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCreated filePath:inPath fileKind:PKGFileKindRegularFile]];
		
		return NO;
	}
	
	[self postCurrentStepSuccessEvent:nil];
	
	return YES;
}

- (BOOL)buildPackageObject:(NSObject<PKGPackageObjectProtocol> *)inPackageObject atPath:(NSString *) inPath flat:(BOOL)inFlat
{
	if (inPackageObject==nil || inPath==nil)
	{
		// A COMPLETER
		
		return NO;
	}
	
	NSString * tPackageUUID;
	PKGPackageComponentType tPackageType;
	
	BOOL tIsPackageProject=[inPackageObject isKindOfClass:PKGPackageProject.class];
	
	if (tIsPackageProject==YES)
	{
		tPackageUUID=@"StandAlone Package";
		tPackageType=PKGPackageComponentTypeProject;
	}
	else
	{
		if ([inPackageObject isKindOfClass:PKGPackageComponent.class]==NO)
		{
			// A COMPLETER
			
			return NO;
		}
		
		PKGPackageComponent * tPackageComponent=(PKGPackageComponent *)inPackageObject;
		
		tPackageUUID=tPackageComponent.UUID;
		tPackageType=tPackageComponent.type;
	}
	
	// Build Information

	PKGBuildPackageAttributes * tBuildPackageAttributes=_buildInformation.packagesAttributes[tPackageUUID]=[PKGBuildPackageAttributes new];
	
	NSString * (^stringByDeletingPkgExtension)(NSString *) = ^NSString *(NSString * bPath) {
	
		if ([[bPath pathExtension] caseInsensitiveCompare:@"pkg"]==NSOrderedSame)
			return [bPath stringByDeletingPathExtension];
		
		return bPath;
	};
	
	PKGPackageSettings * tPackageSettings=inPackageObject.packageSettings;
				 
	// Package Name
	
	NSString * tPackageName;
	
	if (tIsPackageProject==YES)
	{
		tPackageName=stringByDeletingPkgExtension([inPath lastPathComponent]);
		
		inPath=[inPath stringByDeletingLastPathComponent];
	}
	else
	{
		tPackageName=stringByDeletingPkgExtension(tPackageSettings.name);
		
		tBuildPackageAttributes.name=tPackageName;
	}
	
	// Must Close Applications
	
	if (tIsPackageProject==NO)
	{
		PKGPackageComponent * tPackageComponent=(PKGPackageComponent *)inPackageObject;
		
		if (tPackageComponent.mustCloseApplications==YES && tPackageComponent.mustCloseApplicationItems.count>0)
		{
			NSMutableArray * tFilteredArray=[tPackageComponent.mustCloseApplicationItems WB_arrayByMappingObjectsLenientlyUsingBlock:^NSString *(PKGMustCloseApplicationItem * bMustCloseApplicationItem, NSUInteger bIndex) {
			
				if (bMustCloseApplicationItem.isEnabled==NO || bMustCloseApplicationItem.applicationID.length==0)
					return nil;
				
				return bMustCloseApplicationItem.applicationID;
			
			}];
			
			NSSet * tFilteredApplicationIDs=[NSSet setWithArray:tFilteredArray];
			
			if (tFilteredApplicationIDs.count>0)
				tBuildPackageAttributes.mustBeClosedApplicationIDs=tFilteredApplicationIDs.allObjects;
		}
	}
	
	if (tPackageType==PKGPackageComponentTypeReference)
	{
		/* Nothing to build on disk, we just need to retrieve the information for the choices hierarchy */
		
		[self postStep:PKGBuildStepPackageReference beginEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:tPackageUUID name:tPackageName]];
		
		PKGPackageLocationType tLocationType=tPackageSettings.locationType;
		
		if (tLocationType!=PKGPackageLocationHTTPURL && tLocationType!=PKGPackageLocationHTTPSURL && tLocationType!=PKGPackageLocationRemovableMedia)
		{
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Incorrect location type for referenced package"];
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:@"LOCATION"]];
			
			return NO;
		}
		
		tBuildPackageAttributes.locationType=tLocationType;
		
		NSString * tLocationPath=[tPackageSettings locationPath];
			
		if (tLocationPath==nil || [tLocationPath length]==0)
		{
			// Incorrect Value (Empty String)
			
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"LOCATION string can not be empty."];
			
			
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsLocationTypeKey"]];
			
			return NO;
		}
		
		tLocationPath=[tLocationPath stringByAppendingPathComponent:tPackageName];
			
		tBuildPackageAttributes.referencePath=[NSString stringWithFormat:@"%@%@.pkg",[tPackageSettings locationScheme],[tLocationPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
		
		// Get the Package ID
		
		NSString * tPackageIdentifier=tPackageSettings.identifier;
		
		if ([tPackageIdentifier length]==0)
		{
			// Incorrect Value
			
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"IDENTIFIER string can not be empty."];
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsIdentifierKey"]];
			
			return NO;
		}
		
		tBuildPackageAttributes.identifier=tPackageIdentifier;
		
		// Get the Version Number

		NSString * tVersion=tPackageSettings.version;
		
		if ([tVersion length]==0)
		{
			// Incorrect Value (Empty String)
			
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"VERSION string can not be empty."];
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsVersionKey"]];
			
			return NO;
		}
		
		tBuildPackageAttributes.version=tVersion;
		
		// Get the Conclusion Action

		tBuildPackageAttributes.conclusionAction=tPackageSettings.conclusionAction;
		
		// Get the Authentication

		tBuildPackageAttributes.authenticationMode=tPackageSettings.authenticationMode;
		
		// Payload Size (May not be known)
		
		if (tPackageSettings.payloadSize>=0)
			tBuildPackageAttributes.payloadSize=tPackageSettings.payloadSize;

		[self postCurrentStepSuccessEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:tPackageUUID name:tPackageName]];
		
		return YES;
	}
	
	NSString * tLocationPath;
	NSString * tPackageFinalDestination=nil;
	id tFinalPackageName=nil;
	
	PKGPackageLocationType tLocationType=PKGPackageLocationEmbedded;
	
	if (tIsPackageProject==NO)
	{
		tLocationType=tPackageSettings.locationType;
	
		tBuildPackageAttributes.locationType=tLocationType;
	}
	
	BOOL(^cleanPackageFolder)(NSString *)=^BOOL(NSString *inFolderPath){
		return [_fileManager removeItemAtPath:inFolderPath error:NULL];
	};
	
	
	if (tPackageType==PKGPackageComponentTypeImported)
	{
		[self postStep:PKGBuildStepPackageImport beginEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:tPackageUUID name:tPackageName]];
		
		PKGPackageComponent * tPackageComponent=(PKGPackageComponent *)inPackageObject;
		
		PKGFilePath * tImportFilePath=tPackageComponent.importPath;
		
		NSString * tImportedPackagePath=[self absolutePathForFilePath:tImportFilePath];
		
		if (tImportedPackagePath==nil)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:tImportFilePath.string fileKind:PKGFileKindRegularFile]];
			
			return NO;
		}
		
		// Does the file exist on disk
		
		if ([_fileManager fileExistsAtPath:tImportedPackagePath]==NO)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tImportedPackagePath fileKind:PKGFileKindPackage]];
			
			return NO;
		}
		
		// Get the Package Name
		
		PKGArchive * tArchive=[[PKGArchive alloc] initWithPath:tImportedPackagePath];
		
		if ([tArchive isFlatPackage]==NO)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileIncorrectType filePath:tImportedPackagePath fileKind:PKGFileKindPackage]];
			
			return NO;
		}
		
		void(^handleArchiveExtractionError)(NSError *)=^void(NSError *inError){
			
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent new];
			
			if (inError!=nil)
			{
				if ([inError.domain isEqualToString:PKGArchiveErrorDomain]==YES)
				{
					switch(inError.code)
					{
						case PKGArchiveErrorMemoryAllocationFailed:
							
							tErrorEvent.code=PKGBuildErrorOutOfMemory;
							
							break;
							
						case PKGArchiveErrorFileCanNotBeExtracted:
							
							tErrorEvent.code=PKGBuildErrorCanNotExtractFileFromImportedPackage;
							tErrorEvent.filePath=inError.userInfo[PKGArchiveErrorFilePath];
							
							break;
							
						case PKGArchiveErrorFileNotFound:
							
							tErrorEvent.code=PKGBuildErrorFileNotFound;
							tErrorEvent.filePath=tImportedPackagePath;
							tErrorEvent.fileKind=PKGFileKindPackage;
							
							break;
							
						case PKGArchiveErrorFileNotReadable:
							
							tErrorEvent.code=PKGBuildErrorFileCanNotBeRead;
							tErrorEvent.filePath=tImportedPackagePath;
							tErrorEvent.fileKind=PKGFileKindPackage;
							
							break;
					}
				}
				else
				{
					// A COMPLETER
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
		};
		
		NSData * tData;
		NSError * tError=nil;
		
		if ([tArchive extractFile:@"PackageInfo" intoData:&tData error:&tError]==NO)
		{
			handleArchiveExtractionError(tError);
			
			return NO;
		}
		
		PKGPackageSettings * tImportedPackageSettings=[[PKGPackageSettings alloc] initWithXMLData:tData];
		
		if (tImportedPackageSettings==nil)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorCanNotExtractInfoFromImportedPackage]];
			
			return NO;
		}
		
		tFinalPackageName=tPackageName=[stringByDeletingPkgExtension([tImportedPackagePath lastPathComponent]) stringByAppendingPathExtension:@"pkg"];
		
		// We need to copy the package except if it's to be embedded in a flat distribution
	
		if (tLocationType==PKGPackageLocationEmbedded)
		{
			if (inFlat==NO)
			{
				NSString * tRelativePath=[@"./Contents/Packages" stringByAppendingPathComponent:tPackageName];
				
				tBuildPackageAttributes.referencePath=[NSString stringWithFormat:@"%@%@",[tPackageSettings locationScheme],[tRelativePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			
				tPackageFinalDestination=[[inPath stringByAppendingPathComponent:tRelativePath] stringByStandardizingPath];
			}
			else
			{
				tFinalPackageName=[tPackageName mutableCopy];
					
				[tFinalPackageName replaceOccurrencesOfString:@" " withString:@"_" options:0 range:NSMakeRange(0,[tFinalPackageName length])];
				
				tFinalPackageName=[[[tFinalPackageName decomposedStringWithCanonicalMapping] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] mutableCopy];
				
				[tFinalPackageName replaceOccurrencesOfString:@"%" withString:@"_" options:0 range:NSMakeRange(0,[tFinalPackageName length])];
				
				tBuildPackageAttributes.referencePath=[NSString stringWithFormat:@"#%@",tFinalPackageName];
			}
		}
		else
		{
			tLocationPath=[tPackageSettings locationPath];
			
			if (tLocationPath.length==0)
			{
				// Incorrect Value (Empty String)
				
				[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"PKGPackageSettingsLocationTypeKey string can not be empty."];
				
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsLocationTypeKey"]];
				
				return NO;
			}
			
			if (tLocationType==PKGPackageLocationCustomPath)
			{
				NSString * tRelativePath=[tLocationPath stringByAppendingPathComponent:tPackageName];

				NSString * tFilePath=[tPackageSettings locationScheme];
				
				if ([tRelativePath hasPrefix:@"/"]==NO)
					tFilePath=[tFilePath stringByAppendingString:(inFlat==NO) ? @"../" : @"./"];
				
				tFilePath=[tFilePath stringByAppendingString:tRelativePath];
				
				tBuildPackageAttributes.referencePath=[tFilePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				
				if ([tLocationPath isEqualToString:@"./"]==YES ||
					[tLocationPath isEqualToString:@"../"]==YES)
					tPackageFinalDestination=[[[inPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:tRelativePath] stringByStandardizingPath];
				else
					tPackageFinalDestination=[[[inPath stringByAppendingPathComponent:@"../packages"] stringByAppendingPathComponent:tPackageName] stringByStandardizingPath];
			}
			else
			{
				tLocationPath=[tLocationPath stringByAppendingPathComponent:tPackageName];
				
				tBuildPackageAttributes.referencePath=[NSString stringWithFormat:@"%@%@",[tPackageSettings locationScheme],[tLocationPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				
				
				if (tLocationType==PKGPackageLocationHTTPURL)
				{
					tPackageFinalDestination=[[[inPath stringByAppendingPathComponent:@"../http"] stringByAppendingPathComponent:tPackageName] stringByStandardizingPath];
				}
				else if (tLocationType==PKGPackageLocationHTTPSURL)
				{
					tPackageFinalDestination=[[[inPath stringByAppendingPathComponent:@"../https"] stringByAppendingPathComponent:tPackageName] stringByStandardizingPath];
				}
				else if (tLocationType==PKGPackageLocationRemovableMedia)
				{
					tPackageFinalDestination=[[[inPath stringByAppendingPathComponent:@"../x-disc"] stringByAppendingPathComponent:tPackageName] stringByStandardizingPath];
				}
				
			
				// When it's not local we need these pieces of informartion
				
				
				
				// Get the Archive Size
				
				// A COMPLETER
			}
		}
		
		// Get the Conclusion Action
	
		tBuildPackageAttributes.conclusionAction=tImportedPackageSettings.conclusionAction;
		
		// Get the Authentication
		
		tBuildPackageAttributes.authenticationMode=tImportedPackageSettings.authenticationMode;
		
		// Get the Install Size
		
		if (tImportedPackageSettings.payloadSize>=0)
			tBuildPackageAttributes.payloadSize=tImportedPackageSettings.payloadSize;
	
		// Get the Package ID

		NSString * tPackageIdentifier=tImportedPackageSettings.identifier;
		
		if ([tPackageIdentifier length]==0)
		{
			// Incorrect Value (Empty String)
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsIdentifierKey"]];
			
			return NO;
		}

		tBuildPackageAttributes.identifier=tPackageIdentifier;
		
		// Get the Version Number
	
		NSString * tVersion=tImportedPackageSettings.version;
		
		if ([tVersion length]==0)
		{
			// Incorrect Value (Empty String)
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsVersionKey"]];
			
			return NO;
		}
		
		tBuildPackageAttributes.version=tVersion;
		
		// Create the intermediate folder if needed

		if (tLocationType==PKGPackageLocationEmbedded && inFlat==YES)
		{
			// Create the Package folder
			 
			NSString * tPackageFolderPath=[_buildInformation.contentsPath stringByAppendingPathComponent:tFinalPackageName];
			
			if ([self createDirectoryAtPath:tPackageFolderPath withIntermediateDirectories:NO]==NO)
				return NO;
			
			// Extract all the files in the xar archive into the folder
			
			if ([tArchive extractToPath:tPackageFolderPath error:&tError]==NO)
			{
				handleArchiveExtractionError(tError);
				
				cleanPackageFolder(tPackageFolderPath);
				
				return NO;
			}
			
			[self postCurrentStepSuccessEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:tPackageUUID name:tPackageName]];
						
			return YES;
		}

		PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
		
		if ([self createDirectoryAtPath:[tPackageFinalDestination stringByDeletingLastPathComponent] withIntermediateDirectories:NO]==NO)
			return NO;
		
		tStackedEffectiveUserAndGroup=nil;
		
		if ([self isCertificateSetForProjectSettings:self.project.settings]==YES)
		{
			if (_secIdentityRef==NULL)
			{
				_secIdentityRef=[self secIdentifyForProjectSettings:self.project.settings];
				
				if (_secIdentityRef==NULL)
					return NO;
			}
		}
		
		tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
		
		if (_secIdentityRef==NULL)
		{
			// We don't need to sign the package
			
			// Copy the package

			if ([_fileManager PKG_copyItemAtPath:tImportedPackagePath toPath:tPackageFinalDestination options:PKG_NSDeleteExisting error:NULL]==NO)
			{
				PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCopied filePath:tImportedPackagePath fileKind:PKGFileKindRegularFile];
				tErrorEvent.otherFilePath=tPackageFinalDestination;
				
				[self postCurrentStepFailureEvent:tErrorEvent];
				
				return NO;
			}
			
			[self postCurrentStepSuccessEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:tPackageUUID name:tPackageName]];
			
			return YES;
		}

		// We need to sign the package
		
		NSString * tPackageFolderPath=[_scratchLocation stringByAppendingPathComponent:tPackageName];
		
		if ([self createDirectoryAtPath:tPackageFolderPath withIntermediateDirectories:NO]==NO)
			return NO;
		
		tStackedEffectiveUserAndGroup=nil;
		
		// Extract the package to a folder
		
		if ([tArchive extractToPath:tPackageFolderPath error:&tError]==NO)
		{
			handleArchiveExtractionError(tError);
			
			[_fileManager removeItemAtPath:tPackageFolderPath error:NULL];
			
			return NO;
		}
		
		// Recreate the xar archive
	
		tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
		
		NSString * tNewArchivePath=[[tPackageFinalDestination stringByDeletingLastPathComponent] stringByAppendingPathComponent:tPackageName];
		
		if ([_fileManager fileExistsAtPath:tNewArchivePath]==YES)
		{
			// We need to remove the existing instance
				
			if ([_fileManager removeItemAtPath:tNewArchivePath error:NULL]==NO)
			{
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tNewArchivePath fileKind:PKGFileKindPackage]];
					
				return NO;
			}
		}
		
		PKGArchive * tNewArchive=[[PKGArchive alloc] initWithPath:tNewArchivePath];
		tNewArchive.delegate=self;
		
		[self postStep:PKGBuildStepXarCreate beginEvent:nil];
		
		_signatureResult=0;
		
		if ([tNewArchive createArchiveWithContentsAtPath:tPackageFolderPath error:&tError]==NO)
		{
			if (tError!=nil)
			{
				PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent new];
				
				if ([tError.domain isEqualToString:PKGArchiveErrorDomain]==YES)
				{
					switch(tError.code)
					{
						case PKGArchiveErrorFileCanNotBeCreated:
							// A COMPLETER
							break;
							
						case PKGArchiveErrorCertificatesCanNotBeRetrieved:
							
							tErrorEvent=[self buildErrorEventWithSignatureResult:_signatureResult];
							
							break;
							
						case PKGArchiveErrorMemoryAllocationFailed:
							
							tErrorEvent.code=PKGBuildErrorOutOfMemory;
							break;
					}
				}
				else if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
				{
					
				}
				
				[self postCurrentStepFailureEvent:tErrorEvent];
			}
			else
			{
				PKGBuildErrorEvent * tErrorEvent=[self buildErrorEventWithSignatureResult:_signatureResult];
				
				[self postCurrentStepFailureEvent:tErrorEvent];
			}
			
			[_fileManager removeItemAtPath:tPackageFolderPath error:NULL];
			
			return NO;
		}

		[self postCurrentStepSuccessEvent:nil];
		
		tStackedEffectiveUserAndGroup=nil;
		
		// Compute the SHA256 hash
		
		/*if (tLocationType==PKGPackageLocationHTTPURL || tLocationType==PKGPackageLocationRemovableMedia)
		{
			// A COMPLETER
		}*/
		
		// Remove the Package Working folder
		
		if ([_fileManager removeItemAtPath:tPackageFolderPath error:NULL]==NO)
		{
			[self postCurrentStepWarningEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tPackageFolderPath fileKind:PKGFileKindFolder]];
		}
		
		[self postCurrentStepSuccessEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:tPackageUUID name:tPackageName]];
			
		return YES;
	}
	
	
	// (tPackageType==PKGPackageComponentTypeProject)

	[self postStep:PKGBuildStepPackageCreate beginEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:tPackageUUID name:tPackageName]];
	
	if ([tPackageName length]==0)
	{
		// Incorrect value (Empty String)
		
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"PKGPackageSettingsNameKey string can not be empty."];
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsNameKey"]];
		
		return NO;
	}
	
	tFinalPackageName=tPackageName;
	
	
	NSString * tPackageFolderPath;
	
	// Create the Package Working Directory
	
	if (tIsPackageProject==NO && inFlat==YES && tLocationType==PKGPackageLocationEmbedded)
	{
		tFinalPackageName=[NSMutableString stringWithString:tPackageName];
				
		[tFinalPackageName replaceOccurrencesOfString:@" " withString:@"_" options:0 range:NSMakeRange(0,[tFinalPackageName length])];

		tFinalPackageName=[[[tFinalPackageName decomposedStringWithCanonicalMapping] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] mutableCopy];
		
		[tFinalPackageName replaceOccurrencesOfString:@"%" withString:@"_" options:0 range:NSMakeRange(0,[tFinalPackageName length])];
		
		tPackageFolderPath=[_buildInformation.contentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pkg",tFinalPackageName]];
	}
	else
	{
		tPackageFolderPath=[_scratchLocation stringByAppendingPathComponent:tPackageName];
	}
	
	if ([self createDirectoryAtPath:tPackageFolderPath withIntermediateDirectories:NO]==NO)
		return NO;
		
	// Build the Payload
	
	PKGPackagePayload * tPackagePayload=inPackageObject.payload;
	
	if (tPackagePayload==nil)
		tPackagePayload=[PKGPackagePayload emptyPayload];
	
	PKGPayloadType tPayloadType=tPackagePayload.type;

	switch(tPayloadType)
	{
		case PKGPayloadInternal:
			
			if ([self buildPayload:tPackagePayload ofPackageUUID:tPackageUUID atPath:tPackageFolderPath]==NO)
			{
				cleanPackageFolder(tPackageFolderPath);
				
				return NO;
			}
			
			break;
			
		case PKGPayloadExternal:
			
			// A COMPLETER
			
			break;
	}
	
	// Prepare the Scripts if needed
	
	PKGPackageScriptsAndResources * tPackageScriptAndResources=inPackageObject.scriptsAndResources;
	
	if (tPackageScriptAndResources!=nil || tBuildPackageAttributes.bundlesScripts.count>0)
	{
		if ([self buildScriptsAndResources:tPackageScriptAndResources forPackageUUID:tPackageUUID atPath:tPackageFolderPath]==NO)
		{
			cleanPackageFolder(tPackageFolderPath);
			
			return NO;
		}
	}
	
	// Settings

#ifdef __SUPPORT_CUSTOM_LOCATION__
	
	if (tIsPackageProject==NO && inPackageObject.packageSettings.relocatable==YES)
	{
		// Get the Custom Location
		
		// A VOIR (pour le PKGPayloadExternal)
		
		tBuildPackageAttributes.customLocation=tPackagePayload.defaultInstallLocation;
		
		// Set the default installation path to / to work around logical bug in the Installation engine.
		
		tPackagePayload.defaultInstallLocation=@"/";
	}

#endif
	
	// Create the XML Document
	
	if ([self buildPackageInfoForComponent:(PKGPackageComponent *)inPackageObject atPath:[tPackageFolderPath stringByAppendingPathComponent:@"PackageInfo"] contextInfo:tBuildPackageAttributes]==NO)
	{
		cleanPackageFolder(tPackageFolderPath);
		
		return NO;
	}

#ifdef __SUPPORT_CUSTOM_LOCATION__
	
	if (tIsPackageProject==NO && inPackageObject.packageSettings.relocatable==YES)
	{
		// Restore the default installation path
		
		tPackagePayload.defaultInstallLocation=tBuildPackageAttributes.customLocation;
	}
	
#endif
	
	tPackageName=[tPackageName stringByAppendingPathExtension:@"pkg"];

	// Create the package at the appropriate location

	if (tIsPackageProject==NO)
	{
		if (tLocationType==PKGPackageLocationEmbedded)
		{
			if (inFlat==YES)		// Flat Distribution
			{
				tBuildPackageAttributes.referencePath=[NSString stringWithFormat:@"#%@.pkg",tFinalPackageName];
				
				[self postCurrentStepSuccessEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:tPackageUUID name:tPackageName]];
				
				return YES;
			}
			
			// Bundle Distribution
			
			NSString * tRelativePath=[@"./Contents/Packages" stringByAppendingPathComponent:tPackageName];
			
			tBuildPackageAttributes.referencePath=[NSString stringWithFormat:@"%@%@",[tPackageSettings locationScheme],[tRelativePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

			tPackageFinalDestination=[[inPath stringByAppendingPathComponent:tRelativePath] stringByStandardizingPath];
		}
		else
		{
			tLocationPath=tPackageSettings.locationPath;
			
			if ([tLocationPath length]==0)
			{
				// Incorrect Value (Empty String)
				
				[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"PKGPackageSettingsLocationTypeKey string can not be empty."];
				
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorEmptyString tag:@"PKGPackageSettingsLocationTypeKey"]];
				
				return NO;
			}
			
			if (tLocationType==PKGPackageLocationCustomPath)
			{
				NSString * tRelativePath=[tLocationPath stringByAppendingPathComponent:tPackageName];
				
				NSString * tFilePath=[tPackageSettings locationScheme];
				
				if ([tRelativePath hasPrefix:@"/"]==NO)
					tFilePath=[tFilePath stringByAppendingString:(inFlat==NO) ? @"../" : @"./"];
					
				tFilePath=[tFilePath stringByAppendingString:tRelativePath];
				
				tBuildPackageAttributes.referencePath=[tFilePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				
				
				if ([tLocationPath isEqualToString:@"./"]==YES ||
					[tLocationPath isEqualToString:@"../"]==YES)
				{
					tPackageFinalDestination=[[[inPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:tRelativePath] stringByStandardizingPath];
				}
				else
				{
					tPackageFinalDestination=[[[inPath stringByAppendingPathComponent:@"../packages"] stringByAppendingPathComponent:tPackageName] stringByStandardizingPath];
				}
			}
			else
			{
				tLocationPath=[tLocationPath stringByAppendingPathComponent:tPackageName];
				
				tBuildPackageAttributes.referencePath=[NSString stringWithFormat:@"%@%@",[tPackageSettings locationScheme],[tLocationPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

				
				if (tLocationType==PKGPackageLocationHTTPURL)
				{
					tPackageFinalDestination=[[[inPath stringByAppendingPathComponent:@"../http"] stringByAppendingPathComponent:tPackageName] stringByStandardizingPath];
				}
				else if (tLocationType==PKGPackageLocationHTTPSURL)
				{
					tPackageFinalDestination=[[[inPath stringByAppendingPathComponent:@"../https"] stringByAppendingPathComponent:tPackageName] stringByStandardizingPath];
				}
				else if (tLocationType==PKGPackageLocationRemovableMedia)
				{
					tPackageFinalDestination=[[[inPath stringByAppendingPathComponent:@"../x-disc"] stringByAppendingPathComponent:tPackageName] stringByStandardizingPath];
				}
			}
		}
	}
	else
	{
		tPackageFinalDestination=[[inPath stringByAppendingPathComponent:tPackageName] stringByStandardizingPath];
	}
	
	PKGStackedEffectiveUserAndGroup * tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
	
	// Create the intermediate folder if needed
	
	if ([self createDirectoryAtPath:[tPackageFinalDestination stringByDeletingLastPathComponent] withIntermediateDirectories:YES]==NO)
		return NO;

	tStackedEffectiveUserAndGroup=nil;
	
	// Prepare for signing if needed

	if (inFlat==YES)
	{
		if ([self isCertificateSetForProjectSettings:self.project.settings]==YES)
		{
			if (_secIdentityRef==NULL)
			{
				_secIdentityRef=[self secIdentifyForProjectSettings:self.project.settings];
				
				if (_secIdentityRef==NULL)
					return NO;
			}
		}
	}
	
	// Build the xar archive
	
	NSString * tArchivePath=[[tPackageFinalDestination stringByDeletingLastPathComponent] stringByAppendingPathComponent:tPackageName];
	
	if ([_fileManager fileExistsAtPath:tArchivePath]==YES)
	{
		// We need to remove the existing instance
		
		if ([_fileManager removeItemAtPath:tArchivePath error:NULL]==NO)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tArchivePath fileKind:PKGFileKindPackage]];
			
			return NO;
		}
	}
	
	PKGArchive * tArchive=[[PKGArchive alloc] initWithPath:tArchivePath];
	tArchive.delegate=self;
	
	// Preflight folder contents
	
	int tPreflightError=[tArchive preflightContentsAtPath:tPackageFolderPath];
	
	if (tPreflightError!=0)
	{
		[self postCurrentStepFailureEvent:nil];	// A COMPLETER
		
		cleanPackageFolder(tPackageFolderPath);
		
		return NO;
	}
	
	tStackedEffectiveUserAndGroup=[[PKGStackedEffectiveUserAndGroup alloc] initWithUserID:self.userID andGroupID:self.groupID];
	
	[self postStep:PKGBuildStepXarCreate beginEvent:nil];
	
	_signatureResult=0;
	
	NSError * tError=nil;
	
	if ([tArchive createArchiveWithContentsAtPath:tPackageFolderPath error:&tError]==NO)
	{
		if (tError!=nil)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent new];
			
			if ([tError.domain isEqualToString:PKGArchiveErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case PKGArchiveErrorFileCanNotBeCreated:
						
						tErrorEvent.code=PKGBuildErrorFileCanNotBeCreated;
						tErrorEvent.filePath=tArchivePath;
						tErrorEvent.fileKind=PKGFileKindPackage;
						
						// A COMPLETER
						
						break;
					
					case PKGArchiveErrorCertificatesCanNotBeRetrieved:
						
						tErrorEvent=[self buildErrorEventWithSignatureResult:_signatureResult];
						
						break;
						
					case PKGArchiveErrorMemoryAllocationFailed:
						
						tErrorEvent.code=PKGBuildErrorOutOfMemory;
						break;
				}
			}
			else if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
		}
		else
		{
			PKGBuildErrorEvent * tErrorEvent=[self buildErrorEventWithSignatureResult:_signatureResult];
			
			[self postCurrentStepFailureEvent:tErrorEvent];
		}
		
		// A COMPLETER
		
		cleanPackageFolder(tPackageFolderPath);
		
		return NO;
	}
	
	[self postCurrentStepSuccessEvent:nil];
	
	tStackedEffectiveUserAndGroup=nil;
	
	// Compute the SHA256 hash
	
	/*if (tPackageType!=PKGPackageComponentTypeProject || tLocationType==PKGPackageLocationHTTPURL)
	{
		// A COMPLETER
	}*/
	
	// Remove the Package Working folder
	
	if (cleanPackageFolder(tPackageFolderPath)==NO)
	{
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tPackageFolderPath fileKind:PKGFileKindFolder]];

		// A COMPLETER
		
		return NO;
	}
	
	[self postCurrentStepSuccessEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:tPackageUUID name:tPackageName]];
	
	return YES;
}

- (BOOL) addRelocators:(NSArray *) inLocatorsArray forBundle:(NSString *) inBundleIdentifier packageInfoElement:(NSXMLElement *) inPackageInfoElement
{
	if (inLocatorsArray==nil || inBundleIdentifier==nil || inPackageInfoElement==nil)
		return NO;
	
	NSString * tSearchID=[@"relocate." stringByAppendingString:inBundleIdentifier];
	
	// relocate
	
	NSXMLElement * tRelocateElement=(NSXMLElement *) [NSXMLNode elementWithName:@"relocate"];
									
	// search-id
	
	id tAttribute=[NSXMLNode attributeWithName:@"search-id" stringValue:tSearchID];
	[tRelocateElement addAttribute:tAttribute];
	
	NSXMLElement * tBundleElement=(NSXMLElement *) [NSXMLNode elementWithName:@"bundle"];

	// search-id
	
	tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:inBundleIdentifier];
	[tBundleElement addAttribute:tAttribute];
	
	[tRelocateElement addChild:tBundleElement];

	// locators

	NSXMLElement * tLocatorElement=(NSXMLElement *) [NSXMLNode elementWithName:@"locator"];

	NSUInteger tSearchIndex=1;
	NSXMLElement * tSearchElement=nil;
	
	NSMutableArray * tSearchIDsArray=[NSMutableArray array];
	
	for (PKGLocator * tLocator in inLocatorsArray)
	{
		NSString * tLocatorIdentifier=tLocator.identifier;
		
		// Find the appropriate Locator Converter plugin
		
		PKGLocatorConverter * tLocatorConverter=(PKGLocatorConverter*)[_locatorPluginsManager createConverterForIdentifier:tLocatorIdentifier project:(PKGDistributionProject *)self.project];
		
		if (tLocatorConverter==nil)
		{
			// Converter not found
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorLocatorMissingConverter tag:tLocatorIdentifier]];
			
			return NO;
		}
		
		NSDictionary * tLocatorSettingsDictionary=tLocator.settingsRepresentation;
		
		if (tLocatorSettingsDictionary==nil)
		{
			// Missing Information
			
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingInformation tag:@"ICDOCUMENT_LOCATOR_DICTIONARY"]];
			
			return NO;
		}

		NSError * tError=nil;
		
		NSString * tUniqueSearchID=[NSString stringWithFormat:@"search.%d.%@",(int)tSearchIndex,inBundleIdentifier];
		
		NSArray * tElementsArray=[tLocatorConverter elementsWithSettings:tLocatorSettingsDictionary withUniqueSearchID:tUniqueSearchID error:&tError];
							
		if (tElementsArray==nil)
		{
			PKGBuildErrorEvent * tErrorEvent=nil;
			
			// Code not generated
			
			if ([tError.domain isEqualToString:PKGConverterErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case PKGConverterErrorMissingParameter:
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorLocatorConversionError tag:tLocator.name];
						tErrorEvent.subcode=PKGBuildErrorConverterMissingParameter;
						tErrorEvent.otherFilePath=tError.userInfo[PKGConverterErrorParameterKey];
						
						break;
						
					case PKGConverterErrorInvalidParameter:
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorLocatorConversionError tag:tLocator.name];
						tErrorEvent.subcode=PKGBuildErrorConverterInvalidParameter;
						tErrorEvent.otherFilePath=tError.userInfo[PKGConverterErrorParameterKey];
						
						break;
						
					case PKConverterErrorLowMemory:
						
						tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorLocatorConversionError tag:tLocator.name];
						tErrorEvent.subcode=PKGBuildErrorOutOfMemory;
						
						break;
				}
			}
			else
			{
				tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorLocatorConversionError];
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
		
		for(NSXMLElement * tElement in tElementsArray)
			[tLocatorElement addChild:tElement];
		
		[tSearchIDsArray addObject:[NSString stringWithFormat:@"\'%@\'",tUniqueSearchID]];
		
		tSearchIndex++;
	}
	
	if (tLocatorElement.childCount==0)
		return YES;
	
	if (tSearchIDsArray.count==1)
	{
		// A TESTER
		
		// search-id
		
		tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:tSearchID];
		[tSearchElement removeAttributeForName:@"id"];
		[tSearchElement addAttribute:tAttribute];
	
		[inPackageInfoElement addChild:tRelocateElement];

		[inPackageInfoElement addChild:tLocatorElement];
		
		return YES;
	}

	// Merge all the results
	
	NSXMLElement * tSearchScriptElement=(NSXMLElement *) [NSXMLNode elementWithName:@"search"];

	// type
	
	tAttribute=[NSXMLNode attributeWithName:@"type" stringValue:@"script"];
	[tSearchScriptElement addAttribute:tAttribute];
	
	// id
	
	tAttribute=[NSXMLNode attributeWithName:@"id" stringValue:tSearchID];
	[tSearchScriptElement addAttribute:tAttribute];

	// script
	
	tAttribute=[NSXMLNode attributeWithName:@"script" stringValue:@"processSearchResults()"];
	[tSearchScriptElement addAttribute:tAttribute];
	
	NSXMLElement * tScriptElement=(NSXMLElement *) [NSXMLNode elementWithName:@"script"];
	
	NSString * tCodePart=[NSString stringWithFormat:@"\n\n\t\tfunction processSearchResults()\n\
\t\t{\n\
\t\t\tvar tIDsArray;\n\
\t\t\tvar tProcessedResults;\n\
\t\t\tvar i,tCount;\n\
\n\
\t\t\ttIDsArray = new Array(%@);\n\
\n\
\t\t\ttProcessedResults = new Array;\n\
\n\
\t\t\ttCount=tIDsArray.length;\n\
\n\
\t\t\tfor(i=0;i<tCount;i++)\n\
\t\t\t{\n\
\t\t\t\tvar tResults;\n\
\n\
\t\t\t\ttResults=my.search.results[tIDsArray[i]];\n\
\n\
\t\t\t\tif (typeof(tResults) == \'object\')\n\
\t\t\t\t{\n\
\t\t\t\t\tvar j,tLength;\n\
\n\
\t\t\t\t\ttLength=tResults.length;\n\
\n\
\t\t\t\t\tfor(j=0;j<tLength;j++)\n\
\t\t\t\t\t{\n\
\t\t\t\t\t\tvar tValue;\n\
\n\
\t\t\t\t\t\ttValue=tResults[j];\n\
\n\
\t\t\t\t\t\tif (tValue)\n\
\t\t\t\t\t\t{\n\
\t\t\t\t\t\t\ttProcessedResults.push(tValue);\n\
\t\t\t\t\t\t}\n\
\t\t\t\t\t}\n\
\t\t\t\t}\n\
\t\t\t\telse if (tResults)\n\
\t\t\t\t{\n\
\t\t\t\t\ttProcessedResults.push(tResults);\n\
\t\t\t\t}\n\
\t\t\t}\n\
\n\
\t\t\treturn tProcessedResults;\n\
\t\t}\n\n        ",[tSearchIDsArray componentsJoinedByString:@",\n\t\t\t                      "]];

/*else
{
	tCodePart=[NSString stringWithFormat:@"\n\n\t\tfunction processSearchResults()\n\
\t\t{\n\
\t\t\treturn my.search.results[%@];\n\
\t\t}\n\n        ",[tSearchIDsArray objectAtIndex:0]];
}*/

	if (tCodePart==nil)
		return NO;
	
	NSXMLNode * tNode=[NSXMLNode textWithStringValue:tCodePart];

	[tScriptElement addChild:tNode];
	
	[tSearchScriptElement addChild:tScriptElement]; 
	
	[tLocatorElement addChild:tSearchScriptElement];
	
	
	[inPackageInfoElement addChild:tRelocateElement];

	[inPackageInfoElement addChild:tLocatorElement];
	
	return YES;
}

- (BOOL) addBundleFromArray:(NSArray *) inArray toElement:(NSXMLElement *) inElement withPath:(NSString *) inPath packageInfoElement:(NSXMLElement *) inPackageInfoElement downgradableBundles:(NSMutableArray *) inDowngradableArray
{
	if (inArray==nil || inElement==nil || inPath==nil)
		return NO;
	
	NSUInteger tLength=[inPath length];
					
	for (NSDictionary * tBundleInformationDictionary in inArray)
	{
		NSArray * tChildren=[tBundleInformationDictionary objectForKey:@"Children"];
		
		if (tBundleInformationDictionary[@"id"]==nil)
		{
			if (tChildren!=nil)
				[self addBundleFromArray:tChildren toElement:inElement withPath:inPath packageInfoElement:inPackageInfoElement downgradableBundles:inDowngradableArray];
		}
		else
		{
			NSXMLElement * tBundleElement=(NSXMLElement *) [NSXMLNode elementWithName:@"bundle"];
		
			NSString * tPath=nil;
			BOOL tAddToPackageInfoElement=NO;
			
			for (NSString *tKey in tBundleInformationDictionary)
			{
				if ([tKey isEqualToString:@"Children"]==YES)
				{
				}
				else if ([tKey isEqualToString:@"path"]==YES)
				{
					tPath=tBundleInformationDictionary[tKey];
					
					NSUInteger tIndex=[inDowngradableArray indexOfObject:tPath];
					id tAttribute;
					
					if (tIndex!=NSNotFound)
					{
						[inDowngradableArray removeObjectAtIndex:tIndex];
					
						tAddToPackageInfoElement=YES;
						
						tAttribute=[NSXMLNode attributeWithName:tKey stringValue:[NSString stringWithFormat:@".%@",tPath]];
					}
					else
					{
						tAttribute=[NSXMLNode attributeWithName:tKey stringValue:[NSString stringWithFormat:@".%@",[tPath substringFromIndex:tLength]]];
					}
					
					[tBundleElement addAttribute:tAttribute];
				}
				else
				{
					id tAttribute=[NSXMLNode attributeWithName:tKey stringValue:[tBundleInformationDictionary objectForKey:tKey]];

					[tBundleElement addAttribute:tAttribute];
				}
			}
			
			if (tAddToPackageInfoElement==YES)
				[inPackageInfoElement addChild:tBundleElement];
			else
				[inElement addChild:tBundleElement];
			
			if (tChildren.count>0)
			{
				[self addBundleFromArray:tChildren toElement:tBundleElement withPath:tPath packageInfoElement:inPackageInfoElement downgradableBundles:inDowngradableArray];
			}
		}
	}
	
	return YES;
}

- (BOOL)buildDistributionScripts
{
	NSString * tTemporaryDirectoryPath=_buildInformation.scriptsPath;
	
	// Check if we need to create the Scripts archive
	
	if ([_fileManager PKG_isEmptyDirectoryAtPath:tTemporaryDirectoryPath]==YES)
		return YES;
	
	[self postStep:PKGBuildStepDistributionScripts beginEvent:nil];

	// Set the privileges (root:wheel 0755 ) for the tTemporaryDirectoryPath path and its children
	
	NSError * tError=nil;
	
#ifdef __SET_CORRECT_PERMISSIONS__
	if ([_fileManager PKG_setOwnerAccountID:0 groupAccountID:0 ofItemAndDescendantsAtPath:tTemporaryDirectoryPath error:&tError]==NO)
	{
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAccountsCanNotBeSet filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder]];
		
		return NO;
	}
#endif
	
	if ([_fileManager PKG_setPosixPermissions:0755 ofItemAndDescendantsAtPath:tTemporaryDirectoryPath error:&tError]==NO)
	{
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFilePosixPermissionsCanNotBeSet filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder]];
		
		return NO;
	}

	// Split Forks if needed
							
	if ([self splitForksContentsOfDirectoryAtPath:tTemporaryDirectoryPath]==NO)
		return NO;

	// Create the pax archive
	
	if ([self archiveContentsOfDirectoryAtPath:tTemporaryDirectoryPath
								  toFileAtPath:[_buildInformation.contentsPath stringByAppendingPathComponent:@"Scripts"]
										format:PKGArchiveFormatCPIO
							 compressionFormat:PKGArchiveCompressionFormatGZIP]==NO)
		return NO;
	
	// Clean up
		
	if ([_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL]==NO)
		[self postCurrentStepWarningEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder]];
	
	[self postCurrentStepSuccessEvent:nil];
			
	return YES;
}

- (BOOL)buildScriptsAndResources:(PKGPackageScriptsAndResources *)inScriptsAnResources forPackageUUID:(NSString *)inPackageUUID atPath:(NSString *)inPath
{
	if (inPackageUUID==nil || inPath==nil)
		return NO;

	[self postStep:PKGBuildStepScriptsPayload beginEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:inPackageUUID name:nil]];
	
	// Create the Temporary directory
	
	NSString * tTemporaryDirectoryPath=[_scratchLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%@",self.userID,[[_buildOrder.projectPath lastPathComponent] stringByDeletingPathExtension]]];
	
	if ([_fileManager fileExistsAtPath:tTemporaryDirectoryPath]==YES)
	{
		// Delete the directory
		
		if ([_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL]==NO)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder]];
			
			return NO;
		}
	}
	
	if ([self createDirectoryAtPath:tTemporaryDirectoryPath withIntermediateDirectories:NO]==NO)
		return NO;
	
	[self postStep:PKGBuildStepPayloadAssemble beginEvent:nil];

	// Copy the extra resources
	
	PKGRootNodesTuple * tTuple=inScriptsAnResources.resourcesForest.rootNodes;
	
	if (tTuple.error!=nil)
	{
		PKGBuildErrorEvent * tErrorEvent=nil;
		
		if ([tTuple.error.domain isEqualToString:PKGPackagesModelErrorDomain]==YES)
		{
			NSString * tKey=tTuple.error.userInfo[PKGKeyPathErrorKey];
			
			switch(tTuple.error.code)
			{
				case PKGRepresentationNilRepresentationError:
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing value for key \"%@\"",tKey];
					
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingInformation tag:tKey];
					
					break;
				}
					
				case PKGRepresentationInvalidValueError:
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Incorrect value for key \"%@\"",tKey];
					
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:tKey];
					
					break;
				}
					
				case PKGRepresentationInvalidTypeOfValueError:
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Incorrect type of value for key \"%@\"",tKey];
					
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorIncorrectValue tag:tKey];
					
					break;
				}
					
				case PKGFileInvalidTypeOfFileError:
				{
					tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileIncorrectType filePath:_buildOrder.projectPath fileKind:PKGFileKindRegularFile];
					
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Unable to read file at path '%@'",_buildOrder.projectPath];
					
					break;
				}
			}
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		return NO;
	}
	
	for(PKGResourcesTreeNode * tResourceTreeNode in tTuple.array)
	{
		if ([self buildFileHierarchyComponent:tResourceTreeNode atPath:tTemporaryDirectoryPath contextInfo:nil]==NO)
			return NO;
	}
		
	// Remove the files defined as exceptions
		
	PKGProjectSettings * tProjectSettings=self.project.settings;
	
	if (tProjectSettings.filterPayloadOnly==NO)
	{
		NSError * tError=nil;
		
		if ([_patternsRegister filterContentsAtPath:tTemporaryDirectoryPath error:&tError]==NO)
		{
			PKGBuildErrorEvent * tErrorEvent=nil;
			
			if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tError.userInfo[NSFilePathErrorKey] fileKind:PKGFileKindRegularFile];
				
				if (tErrorEvent!=nil)
				{
					switch(tError.code)
					{
						case NSFileNoSuchFileError:
							
							tErrorEvent.subcode=PKGBuildErrorFileNotFound;
							break;
							
						case NSFileWriteNoPermissionError:
							
							tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
							break;
							
						case NSFileWriteVolumeReadOnlyError:
							
							tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
							break;
					}
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
	}
	
	BOOL (^copyScript)(NSString *,NSString *,NSString *__autoreleasing *)=^BOOL(NSString * bSourcePath,NSString *bDestinationPath,NSString *__autoreleasing *bOutScriptName){
	
		NSString * tDestinationFolder=[bDestinationPath stringByDeletingLastPathComponent];
		NSString * tBaseName=[[bDestinationPath lastPathComponent] stringByDeletingPathExtension];
		NSString * tSuitableFileName=[self suitableFileNameForProposedFileName:tBaseName inDirectory:tDestinationFolder];
		
		if (tSuitableFileName==nil)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAlreadyExists tag:tBaseName]];
			
			return NO;
		}
		
		NSString * tDestinationPath=[tDestinationFolder stringByAppendingPathComponent:tSuitableFileName];
		
		NSError * tError=nil;
		
		if ([_fileManager PKG_copyItemAtPath:bSourcePath toPath:tDestinationPath options:0 error:&tError]==NO)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCopied filePath:bSourcePath fileKind:PKGFileKindRegularFile];
			tErrorEvent.otherFilePath=tDestinationPath;
			
			if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case NSFileWriteVolumeReadOnlyError:
						tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
						break;
						
					case NSFileWriteNoPermissionError:
						tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
						break;
						
					case NSFileWriteOutOfSpaceError:
						tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
						break;
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
		
		if (bOutScriptName!=NULL)
			*bOutScriptName=tSuitableFileName;
		
		return YES;
		
		
		/*NSString * tBaseName=[[bDestinationPath lastPathComponent] stringByDeletingPathExtension];
		
		NSUInteger tIndex=1;
		NSString * tFileScriptName=tBaseName;
		
		do
		{
			NSString * tDestinationPath=[tDestinationFolder stringByAppendingPathComponent:tFileScriptName];
			
			if ([_fileManager fileExistsAtPath:tDestinationPath]==NO)
			{
				NSError * tError=nil;
				
				if ([_fileManager PKG_copyItemAtPath:bSourcePath toPath:tDestinationPath options:0 error:&tError]==NO)
				{
					PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCopied filePath:bSourcePath fileKind:PKGFileKindRegularFile];
					tErrorEvent.otherFilePath=tDestinationPath;
					
					if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
					{
						switch(tError.code)
						{
							case NSFileWriteVolumeReadOnlyError:
								tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
								break;
								
							case NSFileWriteNoPermissionError:
								tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
								break;
								
							case NSFileWriteOutOfSpaceError:
								tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
								break;
						}
					}
					
					[self postCurrentStepFailureEvent:tErrorEvent];
					
					return NO;
				}
				
				if (bOutScriptName!=NULL)
					*bOutScriptName=tFileScriptName;
				
				return YES;
			}
			
			tFileScriptName=[NSString stringWithFormat:@"%@_%d",tBaseName,(int)tIndex];
			
			tIndex++;
		}
		while (tIndex<PKGRenamingAttemptsMax);
		
		[self postCurrentStepFailureEvent:nil];
		 
		 // A COMPLETER
		
		return NO;*/
	
	};
	
	
	// Copy the scripts if needed
	
	PKGBuildPackageAttributes * tBuildPackageAttributes=_buildInformation.packagesAttributes[inPackageUUID];
	
	PKGFilePath * tFilePath=inScriptsAnResources.preInstallationScriptPath;
	
	if ([tFilePath isSet]==YES)
	{
		NSString * tPath=[self absolutePathForFilePath:tFilePath];
		
		if (tPath==nil)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:tFilePath.string fileKind:PKGFileKindRegularFile]];
			
			return NO;
		}
		
		if ([_fileManager fileExistsAtPath:tPath]==NO)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tPath fileKind:PKGFileKindRegularFile]];
			
			return NO;
		}
	
		NSString * tFileScriptName=nil;
		
		if (copyScript(tPath,[tTemporaryDirectoryPath stringByAppendingPathComponent:@"preinstall"],&tFileScriptName)==NO)
			return NO;
		
		tBuildPackageAttributes.preInstallScriptPath=[NSString stringWithFormat:@"./%@",tFileScriptName];
	}
	
	tFilePath=inScriptsAnResources.postInstallationScriptPath;
	
	if ([tFilePath isSet]==YES)
	{
		NSString * tPath=[self absolutePathForFilePath:tFilePath];
		
		if (tPath==nil)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:tFilePath.string fileKind:PKGFileKindRegularFile]];
			
			return NO;
		}
		
		if ([_fileManager fileExistsAtPath:tPath]==NO)
		{
			[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tPath fileKind:PKGFileKindRegularFile]];
			
			return NO;
		}
		
		NSString * tFileScriptName=nil;
		
		if (copyScript(tPath,[tTemporaryDirectoryPath stringByAppendingPathComponent:@"postinstall"],&tFileScriptName)==NO)
			return NO;
		
		tBuildPackageAttributes.postInstallScriptPath=[NSString stringWithFormat:@"./%@",tFileScriptName];
	}
	
	// Copy the bundle pre-installation and post-installation scripts
				
	NSMutableDictionary * tFinalDictionary=[NSMutableDictionary dictionary];
	
	__block BOOL tFailed=NO;
	
	[tBuildPackageAttributes.bundlesScripts enumerateKeysAndObjectsUsingBlock:^(NSString *bBundleIdentifier,PKGBuildBundleScripts *bBundleScripts,BOOL *bOutStop){
		
		// Pre-installation
		
		NSString * tPath=bBundleScripts.preInstallScriptPath;
		
		if (tPath!=nil)
		{
			NSString * tFileScriptName=tFinalDictionary[tPath];
			
			if (tFileScriptName==nil)
			{
				if ([_fileManager fileExistsAtPath:tPath]==NO)
				{
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tPath fileKind:PKGFileKindRegularFile]];
					
					*bOutStop=YES;
					tFailed=YES;
					return;
				}

				if (copyScript(tPath,[tTemporaryDirectoryPath stringByAppendingPathComponent:[tPath lastPathComponent]],&tFileScriptName)==NO)
				{
					*bOutStop=YES;
					tFailed=YES;
					return;
				}
					
				tFinalDictionary[tPath]=[NSString stringWithFormat:@"./%@",tFileScriptName];
			}
		}
		
		// Post-installation
		
		tPath=bBundleScripts.postInstallScriptPath;
		
		if (tPath!=nil)
		{
			NSString * tFileScriptName=tFinalDictionary[tPath];
			
			if (tFileScriptName==nil)
			{
				if ([_fileManager fileExistsAtPath:tPath]==NO)
				{
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tPath fileKind:PKGFileKindRegularFile]];
					
					*bOutStop=YES;
					tFailed=YES;
					return;
				}
				
				if (copyScript(tPath,[tTemporaryDirectoryPath stringByAppendingPathComponent:[tPath lastPathComponent]],&tFileScriptName)==NO)
				{
					*bOutStop=YES;
					tFailed=YES;
					return;
				}
				
				tFinalDictionary[tPath]=[NSString stringWithFormat:@"./%@",tFileScriptName];
			}
		}
	}];
	
	if (tFailed==YES)
		return NO;
	
	[tBuildPackageAttributes.bundlesScriptsTransformedNames addEntriesFromDictionary:tFinalDictionary];
	
	[self postCurrentStepSuccessEvent:nil];
	
	
	
	// Set the privileges (root:wheel 0755 ) for the tTemporaryDirectoryPath path and its children
	
	NSError * tError=nil;
	
#ifdef __SET_CORRECT_PERMISSIONS__
	if ([_fileManager PKG_setOwnerAccountID:0 groupAccountID:0 ofItemAndDescendantsAtPath:tTemporaryDirectoryPath error:&tError]==NO)
	{
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAccountsCanNotBeSet filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder]];
		
		return NO;
	}
#endif
	
	if ([_fileManager PKG_setPosixPermissions:0755 ofItemAndDescendantsAtPath:tTemporaryDirectoryPath error:&tError]==NO)
	{
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFilePosixPermissionsCanNotBeSet filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder]];
		
		return NO;
	}
	
	// Split Forks if needed
	
	if ([self splitForksContentsOfDirectoryAtPath:tTemporaryDirectoryPath]==NO)
		return NO;
	
	// Create the pax archive
	
	if ([self archiveContentsOfDirectoryAtPath:tTemporaryDirectoryPath
								  toFileAtPath:[inPath stringByAppendingPathComponent:@"Scripts"]
										format:PKGArchiveFormatCPIO
							 compressionFormat:PKGArchiveCompressionFormatGZIP]==NO)
		return NO;

	// Clean up
	
	if ([_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL]==NO)
		[self postCurrentStepWarningEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder]];
	
	[self postCurrentStepSuccessEvent:nil];
	
	return YES;
}

- (BOOL)buildPayload:(PKGPackagePayload *)inPayload ofPackageUUID:(NSString *) inPackageUUID atPath:(NSString *) inPath
{
	if (inPayload==nil || inPath==nil)
		return NO;
	
	[self postStep:PKGBuildStepPackagePayload beginEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:inPackageUUID name:nil]];
	
	[self postStep:PKGBuildStepPayloadAssemble beginEvent:nil];
	
	PKGPayloadTreeNode * tRootNode=inPayload.filesTree.rootNode;
	
	if (tRootNode==nil)
	{
		// Missing Information
		
		[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorMissingInformation tag:@"ICDOCUMENT_PACKAGE_FILES_FILE_HIERARCHY"]];
		
		// A COMPLETER
		
		return NO;
	}
	
	// Create the Temporary directory
	
	NSString * tTemporaryDirectoryPath=[_scratchLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%@",self.userID,[[_buildOrder.projectPath lastPathComponent] stringByDeletingPathExtension]]];
	
	if ([_fileManager fileExistsAtPath:tTemporaryDirectoryPath]==YES)
	{
		// Delete the directory
		
		NSError * tError=nil;
		
		if ([_fileManager removeItemAtPath:tTemporaryDirectoryPath error:&tError]==NO)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder];
			
			if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case NSFileWriteVolumeReadOnlyError:
						tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
						break;
					
					case NSFileWriteNoPermissionError:
						tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
						break;
				}
			}
			
			[self postCurrentStepFailureEvent:tErrorEvent];
			
			return NO;
		}
	}
	
	if ([self createDirectoryAtPath:tTemporaryDirectoryPath withIntermediateDirectories:YES]==NO)
		return NO;
	
	PKGBuildPackageAttributes * tBuildPackageAttributes=_buildInformation.packagesAttributes[inPackageUUID];
	
	// Find the beginning of the hierarchy according to the Default Location value
	
	PKGPayloadTreeNode * tRelativeRootTreeNode=[tRootNode descendantNodeAtPath:inPayload.defaultInstallLocation];	// can't be nil since defaultInstallation can not be nil
	
	// Optimize the Hierarchy if needed (Remove the empty branches)
	
	[tRelativeRootTreeNode optimizePayloadHierarchy];

	tBuildPackageAttributes.temporaryPayloadFolderPathLength=[tTemporaryDirectoryPath length];
	tBuildPackageAttributes.treatMissingPayloadFilesAsWarnings=inPayload.treatMissingPayloadFilesAsWarnings;
	tBuildPackageAttributes.preserveExtendedAttributes=(inPayload.splitForksIfNeeded==YES && inPayload.preserveExtendedAttributes==YES);
	
	// Copy the file hierarchy

	for(PKGPayloadTreeNode * tTreeNode in [tRelativeRootTreeNode children])
	{
		if ([self buildFileHierarchyComponent:tTreeNode atPath:tTemporaryDirectoryPath contextInfo:tBuildPackageAttributes]==NO)
		{
			// Clean up
			
			[_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL];
			
			return NO;
		}
	}

	// Remove the files defined as exceptions
	
	NSError * tError=nil;
	
	if ([_patternsRegister filterContentsAtPath:tTemporaryDirectoryPath error:&tError]==NO)
	{
		PKGBuildErrorEvent * tErrorEvent=nil;
		
		if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
		{
			tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tError.userInfo[NSFilePathErrorKey] fileKind:PKGFileKindRegularFile];
			
			if (tErrorEvent!=nil)
			{
				switch(tError.code)
				{
					case NSFileNoSuchFileError:
						
						tErrorEvent.subcode=PKGBuildErrorFileNotFound;
						break;
						
					case NSFileWriteNoPermissionError:
						
						tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
						break;
						
					case NSFileWriteVolumeReadOnlyError:
						
						tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
						break;
				}
			}
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		// Clean up
		
		[_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL];
		
		return NO;
	}
	
	inPayload.filesTree.rootNode=nil;	// To free memory
	
	// Look for bundles to populate the <bundle-version> section

	if ([self buildBundleVersionsDictionaryWithFileHierarchyAtPath:tTemporaryDirectoryPath ofPackageUUID:inPackageUUID]==NO)
	{
		// Clean up
		
		[_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL];
		
		return NO;
	}
	
	PKGFileItem * tFileItem=(PKGFileItem *)tRelativeRootTreeNode.representedObject;
	
	// Set the privileges of the Default Location to the tTemporaryDirectoryPath path

	
#ifdef __SET_CORRECT_PERMISSIONS__						
	
	if (chown([tTemporaryDirectoryPath fileSystemRepresentation], tFileItem.uid, tFileItem.gid)!=0)
	{
		PKGBuildErrorEvent * tErrorEvent=nil;
		
		switch(errno)
		{
			case EPERM:
				
				tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAccountsCanNotBeSet];
				tErrorEvent.filePath=tTemporaryDirectoryPath;
				break;
				
			case ENAMETOOLONG:
				
				[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Path(%@) is too long",tTemporaryDirectoryPath];
				
				break;
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		// Clean up
		
		[_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL];
		
		return NO;
	}
#endif

	[self postCurrentStepSuccessEvent:nil];
	
	// Split Forks if needed
	
	if (inPayload.splitForksIfNeeded==YES)
	{
		if ([self splitForksContentsOfDirectoryAtPath:tTemporaryDirectoryPath preserveExtendedAttributes:inPayload.preserveExtendedAttributes]==NO)
		{
			// Clean up
			
			[_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL];
			
			return NO;
		}
	}
	
	// Compute the installed size
	
	off_t tHierarchySize=0;
	NSInteger tNumberOfItems=[_fileManager PKG_numberOfItemsInDirectoryAtPath:tTemporaryDirectoryPath sizeOnDisk:&tHierarchySize];
	
	if (tNumberOfItems==-1)
	{
		// A COMPLETER
		
		// Clean up
		
		[_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL];
		
		return NO;
	}
	
	tBuildPackageAttributes.payloadSize=(tHierarchySize/1024);
	tBuildPackageAttributes.numberOfFiles=tNumberOfItems;
	
	if (chmod([tTemporaryDirectoryPath fileSystemRepresentation],tFileItem.permissions)!=0)
	{
		PKGBuildErrorEvent * tErrorEvent=nil;
		
		switch(errno)
		{
			case EPERM:
				
				tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFilePosixPermissionsCanNotBeSet filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder];
				
				break;
				
			case ENAMETOOLONG:
				
				[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Path(%@) is too long",inPath];
				
				break;
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"chmod failed for \"%@\"",tTemporaryDirectoryPath];
		
		// Clean up
		
		[_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL];
		
		return NO;
	}
	
	// Create Archive.bom

	[self postStep:PKGBuildStepPayloadBom beginEvent:nil];
	
	NSTask * tTask=[NSTask new];

	//[tArguments addObject:@"/Users/Shared/externalroot/"];
	
	tTask.launchPath=PKGProjectBuilderToolPath_mkbom;
	tTask.arguments=@[tTemporaryDirectoryPath,
					  [inPath stringByAppendingPathComponent:@"Bom"]];
	
	[tTask launch];
	[tTask waitUntilExit];
	
	int tReturnValue=tTask.terminationStatus;
	
	tTask=nil;
	
	if (tReturnValue!=0)
	{
		PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorExternalToolFailure filePath:PKGProjectBuilderToolPath_mkbom fileKind:PKGFileKindTool];
		tErrorEvent.toolTerminationStatus=tReturnValue;
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		// Clean up
		
		[_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL];
		
		return NO;
	}
	
	[self postCurrentStepSuccessEvent:nil];
											   
	// Create the pax archive
	
	if ([self archiveContentsOfDirectoryAtPath:tTemporaryDirectoryPath
								  toFileAtPath:[inPath stringByAppendingPathComponent:@"Payload"]
										format:PKGArchiveFormatCPIO
							 compressionFormat:PKGArchiveCompressionFormatGZIP]==NO)
	{
		// Clean up
		
		[_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL];
		
		return NO;
	}
	
	// Compute Size
	
	if (tHierarchySize!=-1)
	{
		int64_t tArchiveSize=0;
		struct stat tFileStat;
		
		if (stat([[inPath stringByAppendingPathComponent:@"Payload"] fileSystemRepresentation],&tFileStat)==0)
			tArchiveSize=tFileStat.st_size/1024;
		
		tBuildPackageAttributes.archiveSize=tArchiveSize;
	}
	
	// Clean the file from disk

	if ([_fileManager removeItemAtPath:tTemporaryDirectoryPath error:NULL]==NO)
	{
		[self postCurrentStepWarningEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeDeleted filePath:tTemporaryDirectoryPath fileKind:PKGFileKindFolder]];
	}
	
	[self postCurrentStepSuccessEvent:[PKGBuildInfoEvent infoEventWithPackageUUID:inPackageUUID name:nil]];

	return YES;
            
	// Size Does Matter
	
	/*if ([self buildArchiveInfoAtPath:[inPath stringByAppendingPathComponent:@"Resources"]]!=0)
	{
		// A COMPLETER
	}*/
}

- (BOOL)buildFileHierarchyComponent:(PKGTreeNode *) inFileTreeNode atPath:(NSString *) inPath contextInfo:(PKGBuildPackageAttributes *)inBuildPackageAttributes
{
	if (inFileTreeNode==nil || inPath==nil)
		return NO;
	
	PKGFileItem * tFileItem=(PKGFileItem *)inFileTreeNode.representedObject;
	PKGFileItemType tType=tFileItem.type;
	
	NSString * tDestinationPath=nil;
	
	uid_t tUID=tFileItem.uid;
	gid_t tGID=tFileItem.gid;
	mode_t tPrivileges=tFileItem.permissions;
	
	BOOL (^setOwnerAndGroupForItemAtPath)(NSString *)=^BOOL(NSString * inItemPath){
		
#ifndef __SET_CORRECT_PERMISSIONS__
		return YES;
#endif
		
		if (lchown([inItemPath fileSystemRepresentation], tUID, tGID)==0)
			return YES;
		
		PKGBuildErrorEvent * tErrorEvent=nil;
		
		switch(errno)
		{
			case EPERM:
				
				tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAccountsCanNotBeSet filePath:inItemPath fileKind:PKGFileKindFolder];
				break;
				
			case ENAMETOOLONG:
				
				[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Path(%@) is too long",inItemPath];
				
				break;
		}
		
		[self postCurrentStepFailureEvent:tErrorEvent];
		
		return NO;
	};
	
	PKGFilePath * tFilePath=tFileItem.filePath;
	
	switch(tType)
	{
		case PKGFileItemTypeHiddenFolderTemplate:
		case PKGFileItemTypeFolderTemplate:	// Base Node
		case PKGFileItemTypeNewFolder:	// New Folder
			
			tDestinationPath=[inPath stringByAppendingPathComponent:tFilePath.string];
			
			if ([self createDirectoryAtPath:tDestinationPath withIntermediateDirectories:NO]==NO)
				return NO;
			
			if (inBuildPackageAttributes!=nil || _buildFormat==PKGProjectBuildFormatFlat)
			{
				NSError * tError=nil;
				
				if ([_fileManager PKG_setPosixPermissions:tPrivileges ofItemAtPath:tDestinationPath error:&tError]==NO)
				{
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFilePosixPermissionsCanNotBeSet filePath:tDestinationPath fileKind:PKGFileKindFolder]];
					
					return NO;
				}
				
				if (setOwnerAndGroupForItemAtPath(tDestinationPath)==NO)
					return NO;
			}
			
			break;

		case PKGFileItemTypeFileSystemItem:	// Real Node Item
		{
			NSString * tFullPath=[self absolutePathForFilePath:tFilePath];
	
			if (tFullPath==nil)
			{
				[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:tFilePath.string fileKind:PKGFileKindRegularFile]];
				
				return NO;
			}
			
			if (tFileItem.payloadFileName!=nil)
				tDestinationPath=[inPath stringByAppendingPathComponent:tFileItem.payloadFileName];
			else
				tDestinationPath=[inPath stringByAppendingPathComponent:[tFullPath lastPathComponent]];
			
			// We need to check the item is not expanded and empty in fact
			
			if ([inFileTreeNode numberOfChildren]==0 && tFileItem.isContentsDisclosed==NO)
			{
				// Copy the path
				
				NSError * tCopyError=NULL;
				
				if ([_fileManager copyItemAtPath:tFullPath toPath:tDestinationPath error:&tCopyError]==NO)
				{
					PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCopied filePath:tFullPath fileKind:PKGFileKindRegularFile];
					tErrorEvent.otherFilePath=inPath;
					
					if (tCopyError!=nil && [tCopyError.domain isEqualToString:NSCocoaErrorDomain]==YES)
					{
						switch(tCopyError.code)
						{
							case NSFileReadNoSuchFileError:
							case NSFileNoSuchFileError:
								
								tErrorEvent.subcode=PKGBuildErrorFileNotFound;
								
								if (inBuildPackageAttributes.treatMissingPayloadFilesAsWarnings==YES)
								{
									[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelWarning format:@"[PKGProjectBuilder buildFileHierarchyComponent:atPath:contextInfo:] File not found"];
									
									[self postCurrentStepWarningEvent:tErrorEvent];
									
									return YES;
								}
								
								[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"[PKGProjectBuilder buildFileHierarchyComponent:atPath:contextInfo:] File not found"];
								
								break;
								
							case NSFileWriteOutOfSpaceError:
								
								tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
								
								[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"[PKGProjectBuilder buildFileHierarchyComponent:atPath:contextInfo:] Not enough free space"];
								
								break;
								
							case NSFileWriteVolumeReadOnlyError:
								
								tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
								
								break;
								
							case NSFileWriteNoPermissionError:
								
								tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
								
								[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"[PKGProjectBuilder buildFileHierarchyComponent:atPath:contextInfo:] Write permission error"];
								
								break;
						}
					}
					
					[self postCurrentStepFailureEvent:tErrorEvent];
					
					return NO;
				}
				
				if (inBuildPackageAttributes!=nil || _buildFormat==PKGProjectBuildFormatFlat)	// A VOIR
				{
					NSError * tError=nil;
					
					// Set the Privileges of the item
					
					if ([_fileManager PKG_setPosixPermissions:tPrivileges ofItemAtPath:tDestinationPath error:&tError]==NO)
					{
						[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFilePosixPermissionsCanNotBeSet filePath:tDestinationPath fileKind:PKGFileKindRegularFile]];
						
						return NO;
					}
				
					// Set the owner and group recursively
					
					if ([_fileManager PKG_setOwnerAccountID:tFileItem.uid groupAccountID:tFileItem.gid ofItemAndDescendantsAtPath:tDestinationPath error:&tError]==NO)
					{
						[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAccountsCanNotBeSet filePath:tDestinationPath fileKind:PKGFileKindRegularFile]];
						
						return NO;
					}
				}
			}
			else
			{
				// It's a folder whose contents is disclosed => Create the folder at the destination
				
				NSError * tError=nil;
				NSDictionary * tItemAttributes=[_fileManager attributesOfItemAtPath:tFullPath error:NULL];
				
				if (tItemAttributes==nil)
				{
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAttributesCanNotBeRead filePath:tFullPath fileKind:PKGFileKindFolder]];
					
					return NO;
				}
				
				// Create the folder
				
				if ([self createDirectoryAtPath:tDestinationPath withIntermediateDirectories:NO]==NO)
					return NO;
				
				// Get and set the FinderInfo and ResourceFork extra attributes
				
				NSDictionary * tExtendedAttributes=[_fileManager PKG_extendedAttributesOfItemAtPath:tFullPath error:&tError];
				
				if (tExtendedAttributes==nil)
				{
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileExtendedAttributesCanNotBeRead filePath:tFullPath fileKind:PKGFileKindFolder]];
					
					return NO;
				}
				
				// Only keep the FinderInfo and ResourceFork extended attributes
				
				NSDictionary * tFilteredDictionary=tExtendedAttributes;
				
				if (inBuildPackageAttributes.preserveExtendedAttributes==NO)
				{
					tFilteredDictionary=[tExtendedAttributes WB_filteredDictionaryUsingBlock:^BOOL(NSString * bAttributeName,id bObject) {
						
						return ([bAttributeName isEqualToString:PKGFileFinderInfoKey]==YES || [bAttributeName isEqualToString:PKGFileResourceForkKey]);
						
					}];
				}
				
				if ([_fileManager PKG_setExtendedAttributes:tFilteredDictionary ofItemAtPath:tDestinationPath error:&tError]==NO)
				{
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileExtendedAttributesCanNotBeSet filePath:tDestinationPath fileKind:PKGFileKindFolder]];
					
					return NO;
				}
				
				// Set back the attributes (not done earlier because setting the Resource Fork will update the modification date according to xattr.h)
				
				if ([_fileManager setAttributes:tItemAttributes ofItemAtPath:tDestinationPath error:&tError]==NO)
				{
					[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"%@",tError.description];
					
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAttributesCanNotBeSet filePath:tDestinationPath fileKind:PKGFileKindFolder]];
					
					return NO;
				}
				
				// Set the Posix Permissions defined for the payload item
				
				if ([_fileManager PKG_setPosixPermissions:tPrivileges ofItemAtPath:tDestinationPath error:&tError]==NO)
				{
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFilePosixPermissionsCanNotBeSet filePath:tDestinationPath fileKind:PKGFileKindFolder]];
					
					return NO;
				}
				
				// Set the Owner and Group accounts defined for the payload item
				
				if (setOwnerAndGroupForItemAtPath(tDestinationPath)==NO)
					return NO;
			}
			
			// We're not building the payload hierarchy so no need to check for bundle options
			
			if (inBuildPackageAttributes==nil || [tFileItem isMemberOfClass:_PKGPayloadBundleItemClass]==NO)
				break;
			
			// We do this here so that if the item is a bundle built from misc items, we are sure to have a built bundle before trying to retrieve the bundle identifier
			
			for(PKGTreeNode * tTreeNode in [inFileTreeNode children])
			{
				if ([self buildFileHierarchyComponent:tTreeNode atPath:tDestinationPath contextInfo:inBuildPackageAttributes]==NO)
					return NO;
			}
			
			// Bundle payload extras
			
			PKGPayloadBundleItem * tPayloadBundleItem=(PKGPayloadBundleItem *)tFileItem;
				
			// Find the bundle identifier
			
			NSString * tBundleIdentifier=[NSBundle bundleWithPath:tFullPath].bundleIdentifier;
			
			if (tBundleIdentifier==nil)
			{
				[self postCurrentStepWarningEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorBundleIdentifierNotFound filePath:tFullPath fileKind:PKGFileKindBundle]];
				
				return YES;
			}
			
			// Can Downgrade
			
			if (tPayloadBundleItem.allowDowngrade==YES)
			{
				NSString * tRelativePath=[tDestinationPath substringFromIndex:inBuildPackageAttributes.temporaryPayloadFolderPathLength];
				
				[inBuildPackageAttributes.downgradableBundles addObject:tRelativePath];
			}
			
			PKGBuildBundleScripts * tBuildBundleScripts=[PKGBuildBundleScripts new];
			
			// Pre-installation script
			
			PKGFilePath * tScriptFilePath=tPayloadBundleItem.preInstallationScriptPath;
			
			if (tScriptFilePath!=nil && [tScriptFilePath isSet]==YES)
			{
				NSString * tScriptSourcePath=[self absolutePathForFilePath:tScriptFilePath];
				
				if (tScriptSourcePath==nil)
				{
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:tScriptFilePath.string fileKind:PKGFileKindRegularFile]];
					
					return NO;
				}
				
				tBuildBundleScripts.preInstallScriptPath=tScriptSourcePath;
			}
			
			// Post-installation script
			
			tScriptFilePath=tPayloadBundleItem.postInstallationScriptPath;
			
			if (tScriptFilePath!=nil && [tScriptFilePath isSet]==YES)
			{
				NSString * tScriptSourcePath=[self absolutePathForFilePath:tScriptFilePath];
				
				if (tScriptSourcePath==nil)
				{
					[self postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:tScriptFilePath.string fileKind:PKGFileKindRegularFile]];
					
					return NO;
				}
				
				tBuildBundleScripts.postInstallScriptPath=tScriptSourcePath;
			}
			
			if (tBuildBundleScripts.hasScripts==YES)
				inBuildPackageAttributes.bundlesScripts[tBundleIdentifier]=tBuildBundleScripts;
			
			if (self.debug==NO)
			{
				// Locators
				
				NSArray * tFilteredLocatorsArray=[tPayloadBundleItem.locators WB_filteredArrayUsingBlock:^BOOL(PKGLocator * bLocator,NSUInteger bIndex){
				
					return (bLocator.isEnabled==YES);
				}];
				
				if (tFilteredLocatorsArray.count>0)
					(inBuildPackageAttributes.bundlesLocators)[tBundleIdentifier]=tFilteredLocatorsArray;
			}
			
			return YES;
		}
			
		default:
			break;
	}
	
	for(PKGTreeNode * tTreeNode in [inFileTreeNode children])
	{
		if ([self buildFileHierarchyComponent:tTreeNode atPath:tDestinationPath contextInfo:inBuildPackageAttributes]==NO)
			return NO;
	}

	return YES;
}

#pragma mark -

- (BOOL)buildBundleVersionsDictionaryWithFileHierarchyAtPath:(NSString *)inFileHierarchyPath ofPackageUUID:(NSString *)inPackageUUID
{
	if (inFileHierarchyPath==nil || inPackageUUID==nil)
		return NO;
	
	char * tPath[2]={(char *) [inFileHierarchyPath fileSystemRepresentation],NULL};
	
	FTS * ftsp = fts_open(tPath, FTS_PHYSICAL, 0);
	
    if (ftsp == NULL)
		return YES;
    
	NSMutableArray * tLevelsArray=[NSMutableArray array];
	
	NSMutableArray * tParentsChildrenArray=[NSMutableArray array];
    NSMutableArray * tMutableArray=[NSMutableArray array];
	
	short tCurrentBundleLevel=-100;
	
	NSUInteger tLength=[inFileHierarchyPath length];
	
    FTSENT * tFile;
	
	while ((tFile = fts_read(ftsp)) != NULL)
    {
        switch (tFile->fts_info)
        {
            case FTS_DC:
			case FTS_DNR:
            case FTS_ERR:
            case FTS_NS:
                    fts_close(ftsp);
                    
                    return NO;
            case FTS_D:
			{
				NSString * tBundlePath=nil;
				NSString * tAbsolutePath=nil;
				
				if (!strncmp(tFile->fts_name,"Contents",8))
				{
					tAbsolutePath=[NSString stringWithUTF8String:tFile->fts_path];
					
					tBundlePath=[tAbsolutePath stringByDeletingLastPathComponent];
				}
				else if (strstr(tFile->fts_name,".framework")!=NULL)
				{
					tBundlePath=[NSString stringWithUTF8String:tFile->fts_path];
					
					tAbsolutePath=[tBundlePath stringByAppendingPathComponent:@"Resources"];
				}
				
				if (tBundlePath!=nil && tAbsolutePath!=nil)
				{
					NSBundle * tBundle=[NSBundle bundleWithPath:tBundlePath];
				
					if (tBundle==nil)
						continue;
					
					NSDictionary * tInfoDictionary=[tBundle infoDictionary];
					
					if (tInfoDictionary!=nil)
					{
						tCurrentBundleLevel=tFile->fts_level;
						
						NSString * tStringPath=[tBundlePath substringFromIndex:tLength];
						
						NSMutableDictionary * tMutableBundleVersionDictionary=[NSMutableDictionary dictionary];
						
						tMutableBundleVersionDictionary[@"path"]=tStringPath;
						
						// Get Information from the Info.plist file
						
						// CFBundleShortVersionString
						
						id tObject=tInfoDictionary[@"CFBundleShortVersionString"];
						
						if (tObject!=nil)
							tMutableBundleVersionDictionary[@"CFBundleShortVersionString"]=tObject;
						
						// CFBundleVersion
						
						tObject=tInfoDictionary[@"CFBundleVersion"];
						
						if (tObject!=nil)
							tMutableBundleVersionDictionary[@"CFBundleVersion"]=tObject;
						
						// CFBundleIdentifier
						
						tObject=tInfoDictionary[@"CFBundleIdentifier"];
						
						if (tObject!=nil)
						{
							tMutableBundleVersionDictionary[@"CFBundleIdentifier"]=tObject;
							
							tMutableBundleVersionDictionary[@"id"]=tObject;
						}
						
						
						// Look for a version.plist file
						
						NSString * tVersionFilePath=[tAbsolutePath stringByAppendingPathComponent:@"version.plist"];
						
						NSDictionary * tVersionDictionary=[NSDictionary dictionaryWithContentsOfFile:tVersionFilePath];
						
						if (tVersionDictionary!=nil)
						{
							// BuildVersion
						
							tObject=tVersionDictionary[@"BuildVersion"];
							
							if (tObject!=nil)
								tMutableBundleVersionDictionary[@"BuildVersion"]=tObject;
							
							// ProjectName
						
							tObject=tVersionDictionary[@"ProjectName"];
							
							if (tObject!=nil)
								tMutableBundleVersionDictionary[@"ProjectName"]=tObject;
							
							// SourceVersion
							
							tObject=tVersionDictionary[@"SourceVersion"];
							
							if (tObject!=nil)
								tMutableBundleVersionDictionary[@"SourceVersion"]=tObject;

							// CFBundleShortVersionString
						
							tObject=tVersionDictionary[@"CFBundleShortVersionString"];
							
							if (tObject!=nil && tMutableBundleVersionDictionary[@"CFBundleShortVersionString"]==nil)
								tMutableBundleVersionDictionary[@"CFBundleShortVersionString"]=tObject;
							
							// CFBundleVersion
							
							tObject=tVersionDictionary[@"CFBundleVersion"];
							
							if (tObject!=nil && tMutableBundleVersionDictionary[@"CFBundleShortVersionString"]==nil)
								tMutableBundleVersionDictionary[@"CFBundleVersion"]=tObject;
						}
						
						NSMutableArray * tChildrenArray=[tParentsChildrenArray lastObject];
					
						if (tChildrenArray!=nil)
							[tChildrenArray addObject:tMutableBundleVersionDictionary];
						else
							[tMutableArray addObject:tMutableBundleVersionDictionary];
						
						[tLevelsArray addObject:@(tFile->fts_level)];
						
						tChildrenArray=[NSMutableArray array];
						
						tMutableBundleVersionDictionary[@"Children"]=tChildrenArray;
						
						[tParentsChildrenArray addObject:tChildrenArray];
					}
				}
			
				break;
			}
				
			case FTS_DP:
			
				if (tCurrentBundleLevel==tFile->fts_level)
				{
					[tParentsChildrenArray removeLastObject];
					
					[tLevelsArray removeLastObject];
					
					NSNumber * tNumber=[tLevelsArray lastObject];
					
					tCurrentBundleLevel=(tNumber!=nil) ? [tNumber shortValue] : -100;
				}
				
				break;
            case FTS_SL:
            case FTS_SLNONE:
			case FTS_F:
                    continue;
            default:
                    break;
        }
    }
	
	if (tMutableArray.count>0)
	{
		PKGBuildPackageAttributes * tBuildPackageAttributes=_buildInformation.packagesAttributes[inPackageUUID];
		
		[tBuildPackageAttributes.bundlesVersions addObjectsFromArray:tMutableArray];
	}
    
    fts_close(ftsp);
    
    return YES;
}

#pragma mark - Build Notifications Wrappers

- (void)postStep:(PKGBuildStep)inStep beginEvent:(PKGBuildEvent *)inEvent
{
	_stepPath=[_stepPath indexPathByAddingIndex:inStep];
	
	[self.buildNotificationCenter postNotificationStepPath:[_stepPath PKG_stringRepresentation]
													 state:PKGBuildStepStateBegin
												  userInfo:[inEvent representation]];
}

- (void)postStep:(PKGBuildStep)inStep infoEvent:(PKGBuildEvent *)inEvent
{
	[self.buildNotificationCenter postNotificationStepPath:[_stepPath PKG_stringRepresentation]
													 state:PKGBuildStepStateInfo
												  userInfo:[inEvent representation]];
}

- (void)postStep:(PKGBuildStep)inStep successEvent:(PKGBuildEvent *)inEvent
{
	[self.buildNotificationCenter postNotificationStepPath:[_stepPath PKG_stringRepresentation]
													 state:PKGBuildStepStateSuccess
												  userInfo:[inEvent representation]];
	
	_stepPath=[_stepPath indexPathByRemovingLastIndex];
}

- (void)postStep:(PKGBuildStep)inStep failureEvent:(PKGBuildEvent *)inEvent
{
	[self.buildNotificationCenter postNotificationStepPath:[_stepPath PKG_stringRepresentation]
													 state:PKGBuildStepStateFailure
												  userInfo:[inEvent representation]];
}

- (void)postStep:(PKGBuildStep)inStep warningEvent:(PKGBuildEvent *)inEvent
{
	[self.buildNotificationCenter postNotificationStepPath:[_stepPath PKG_stringRepresentation]
													 state:PKGBuildStepStateWarning
												  userInfo:[inEvent representation]];
}

- (void)postCurrentStepInfoEvent:(PKGBuildEvent *)inEvent
{
	[self postStep:PKGBuildStepCurrent infoEvent:inEvent];
}

- (void)postCurrentStepSuccessEvent:(PKGBuildEvent *)inEvent
{
	[self postStep:PKGBuildStepCurrent successEvent:inEvent];
}

- (void)postCurrentStepFailureEvent:(PKGBuildEvent *)inEvent
{
	[self postStep:PKGBuildStepCurrent failureEvent:inEvent];
}

- (void)postCurrentStepWarningEvent:(PKGBuildEvent *)inEvent
{
	[self postStep:PKGBuildStepCurrent warningEvent:inEvent];
}

#pragma mark - PKGProjectBuilderInterface

- (void)buildProjectOfBuildOrderRepresentation:(NSDictionary *)inRepresentation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		
		if (inRepresentation==nil)
		{
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Representation for build order is missing.\n"];
			
			exit(EXIT_FAILURE);
		}
		
		_buildOrder=[[PKGBuildOrder alloc] initWithRepresentation:inRepresentation];
		
		if (_buildOrder==nil)
		{
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Representation for build order is corrupted.\n"];
			
			exit(EXIT_FAILURE);
		}
	
		/* Init Supplemental Groups */
		
		struct passwd * tPasswordPtr=getpwuid((uid_t)self.userID);
		
		if (tPasswordPtr==NULL)
		{
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Could not retrieve user name from uid"];
			exit(EXIT_FAILURE);
		}
		
		initgroups(tPasswordPtr->pw_name, (int)self.groupID);
		
		/* Build */
		
		[self build];
	
		// Delayed exit to make sure the last even notification is sent
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			exit(EXIT_SUCCESS);
		});
	});
}

- (void)cancelBuild
{
	dispatch_async(dispatch_get_main_queue(), ^{
		
		// A COMPLETER
	
		exit(EXIT_SUCCESS);
	});
}

#pragma mark - PKGFilePathConverter

- (NSString *)absolutePathForFilePath:(PKGFilePath *)inFilePath
{
	if (inFilePath==nil)
		return nil;
	
	switch(inFilePath.type)
	{
		case PKGFilePathTypeAbsolute:
			
			return inFilePath.string;
			
		case PKGFilePathTypeRelativeToProject:
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:_referenceProjectPath];
			
		case PKGFilePathTypeRelativeToReferenceFolder:
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:_referenceFolderPath];
			
		default:
			break;
	}
	
	return nil;
}

- (PKGFilePath *)filePathForAbsolutePath:(NSString *)inAbsolutePath type:(PKGFilePathType)inType
{
	if (inAbsolutePath==nil)
		return nil;
	
	if (inType==PKGFilePathTypeAbsolute)
		return [[PKGFilePath alloc] initWithString:inAbsolutePath type:PKGFilePathTypeAbsolute];
	
	NSString * tReferencePath=nil;
	
	if (inType==PKGFilePathTypeRelativeToProject)
	{
		tReferencePath=_referenceProjectPath;
	}
	else if (inType==PKGFilePathTypeRelativeToReferenceFolder)
	{
		tReferencePath=_referenceFolderPath;
	}
	
	if (tReferencePath==nil)
	{
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Reference path is nil.\n"];
		return nil;
	}
	
	NSString * tConvertedPath=[inAbsolutePath PKG_stringByRelativizingToPath:tReferencePath];
	
	if (tConvertedPath==nil)
	{
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Error during conversion of path \"%@\".\n",inAbsolutePath];
		return nil;
	}
	
	return [[PKGFilePath alloc] initWithString:tConvertedPath type:inType];
}

- (BOOL)shiftTypeOfFilePath:(PKGFilePath *)inFilePath toType:(PKGFilePathType)inType
{
	if (inFilePath==nil)
		return NO;
	
	if (inFilePath.type==inType)
		return YES;
	
	if (inFilePath.string!=nil)
	{
		NSString * tAbsolutePath=[self absolutePathForFilePath:inFilePath];
		
		if (tAbsolutePath==nil)
			return NO;
		
		PKGFilePath * tFilePath=[self filePathForAbsolutePath:tAbsolutePath type:inType];
		
		if (tFilePath==nil)
			return NO;
		
		inFilePath.string=tFilePath.string;
	}
	
	inFilePath.type=inType;
	
	return YES;
}

#pragma mark - PKGArchiveDelegate

- (PKGBuildErrorEvent *)buildErrorEventWithSignatureResult:(PKGArchiveSignatureResult)inSignatureResult
{
	PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent new];
	
	switch(_signatureResult)
	{
		case PKGArchiveSignatureResultGenericError:
			
			tErrorEvent.code=PKGBuildErrorSigningUnknown;
			break;
			
		case PKGArchiveSignatureResultTimeOut:
			
			tErrorEvent.code=PKGBuildErrorSigningTimeOut;
			break;
			
		case PKGArchiveSignatureResultAuthenticationDenied:
			
			tErrorEvent.code=PKGBuildErrorSigningAuthorizationDenied;
			break;
			
		case PKGArchiveSignatureResultCertificateNotFound:
			
			tErrorEvent.code=PKGBuildErrorSigningCertificateNotFound;
			break;
			
		case PKGArchiveSignatureResultPrivateKeyNotRetrieved:
			
			tErrorEvent.code=PKGBuildErrorSigningCertificatePrivateKeyNotFound;
			break;
			
		case PKGArchiveSignatureResultTrustEvaluationFailed:
			
			tErrorEvent.code=PKGBuildErrorSigningTrustEvaluationFailure;
			break;
			
		case PKGArchiveSignatureResultTrustNoAnchor:
			
			tErrorEvent.code=PKGBuildErrorSigningCertificateChainBroken;
			break;
			
		case PKGArchiveSignatureResultTrustExpiredCertificate:
			
			tErrorEvent.code=PKGBuildErrorSigningCertificateExpired;
			break;
			
		case PKGArchiveSignatureResultTrustNotTrustedCertificate:
			
			tErrorEvent.code=PKGBuildErrorSigningNotTrustedCertificate;
			break;
			
		default:
			break;
	}
	
	return tErrorEvent;
}

- (BOOL)archiveShouldSign:(PKGArchive *)inArchive
{
	return (_secIdentityRef!=NULL);
}

- (int32_t)signatureSizeForArchive:(PKGArchive *)inArchive
{
	SecKeyRef tPrivateKeyRef;
	
	OSStatus tStatus=SecIdentityCopyPrivateKey(_secIdentityRef,&tPrivateKeyRef);
	
	if (tStatus!=noErr)
	{
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Unable to copy identity private key"];
		
		_signatureResult=PKGArchiveSignatureResultPrivateKeyNotRetrieved;
		
		return 0;
	}
	
	return (int32_t) SecKeyGetBlockSize(tPrivateKeyRef);
}

- (NSArray *)certificatesDataForArchive:(PKGArchive *)inArchive
{
	SecCertificateRef tCertificateRef=NULL;
	
	SecIdentityCopyCertificate(_secIdentityRef,&tCertificateRef);
	
	if (tCertificateRef==NULL)
	{
		_signatureResult=PKGArchiveSignatureResultGenericError;
		
		return nil;
	}
	
	SecPolicyRef tPolicyRef=SecPolicyCreateBasicX509();
	
	SecTrustRef tTrustRef;
	
	OSStatus tStatus=SecTrustCreateWithCertificates(tCertificateRef, tPolicyRef, &tTrustRef);
	
	CFRelease(tPolicyRef);
	CFRelease(tCertificateRef);
	
	if (tStatus!=errSecSuccess)
	{
		_signatureResult=PKGArchiveSignatureResultGenericError;
		
		return nil;
	}
	
	SecTrustResultType tTrustEvaluationResult;
	
	tStatus=SecTrustEvaluate(tTrustRef, &tTrustEvaluationResult);
	
	if (tStatus!=errSecSuccess)
	{
		_signatureResult=PKGArchiveSignatureResultGenericError;
		
		CFRelease(tTrustRef);
		
		return nil;
	}
	
	switch(tTrustEvaluationResult)
	{
		case kSecTrustResultUnspecified:
		case kSecTrustResultProceed:
			
			break;
			
		case kSecTrustResultDeny:
			
			_signatureResult=PKGArchiveSignatureResultTrustNotTrustedCertificate;
			
			return nil;
			
		case kSecTrustResultRecoverableTrustFailure:
			
			
			{
				NSDictionary * tResultDictionary=(__bridge_transfer NSDictionary *)SecTrustCopyResult(tTrustRef);
				
				CFRelease(tTrustRef);
				
				NSString * const PRIVATE_TRUSTRESULTDETAILS_KEY=@"TrustResultDetails";
				NSString * const PRIVATE_STATUSCODES_KEY=@"StatusCodes";
				
				NSArray * tDetailsArray=tResultDictionary[PRIVATE_TRUSTRESULTDETAILS_KEY];
				
				if (tDetailsArray.count==0)
				{
					NSLog(@"kSecTrustResultRecoverableTrustFailure > Missing TrustResultDetails key");
					
					_signatureResult=PKGArchiveSignatureResultTrustEvaluationFailed;
					
					return nil;
				}
				
				NSDictionary * tDetailOfTopCertificate=tDetailsArray[0];
				
				NSArray * tStatusCodes=tDetailOfTopCertificate[PRIVATE_STATUSCODES_KEY];
				
				NSNumber * tNumber=tStatusCodes.firstObject;
					
				if (tNumber==nil || [tNumber isKindOfClass:NSNumber.class]==NO)
				{
					NSLog(@"kSecTrustResultRecoverableTrustFailure > Missing StatusCodes key");
					
					_signatureResult=PKGArchiveSignatureResultTrustEvaluationFailed;
					
					return nil;
				}
				
				NSInteger tStatusCode=[tNumber integerValue];
				
				switch (tStatusCode)
				{
					case errSecCertificateExpired:
						
						_signatureResult=PKGArchiveSignatureResultTrustExpiredCertificate;
						
						break;
						
					default:
						
						_signatureResult=PKGArchiveSignatureResultTrustEvaluationFailed;
						
						break;
				}
				
				return nil;
			}
			break;
			
		default:
			
			_signatureResult=PKGArchiveSignatureResultTrustEvaluationFailed;
			
			CFRelease(tTrustRef);
			
			return nil;
	}
	
	CFIndex tCertificatesChainLength=SecTrustGetCertificateCount(tTrustRef);
	NSMutableArray * tCertificatesData=[NSMutableArray array];
	
	if (tCertificatesChainLength<2)
	{
		// No anchor
		
		_signatureResult=PKGArchiveSignatureResultTrustNoAnchor;
		
		CFRelease(tTrustRef);
		
		return nil;
	}
	
	for(CFIndex tIndex=0;tIndex<tCertificatesChainLength;tIndex++)
	{
		tCertificateRef=SecTrustGetCertificateAtIndex(tTrustRef, tIndex);
		
		NSData * tData=(__bridge_transfer NSData *)SecCertificateCopyData(tCertificateRef);
		
		if (tData==nil)
		{
			tCertificatesData=nil;
			break;
		}
		
		[tCertificatesData addObject:tData];
	}
	
	CFRelease(tTrustRef);
	
	return [tCertificatesData copy];
}

- (NSData *)archive:(PKGArchive *)inArchive signatureOfType:(PKGSignatureType)inSignatureType forData:(NSData *)inData
{
	if (inData==nil)
		return nil;

	// Make synchroneous with semaphore + timeout
	
	id<PKGBuildSignatureCreatorInterface> tSignatureCreator=self.signatureCreator;
	
	if (tSignatureCreator==nil)
		return nil;
	
	__block NSData * tSignature=nil;
	
	dispatch_group_t syncGroup = dispatch_group_create();
	dispatch_group_enter(syncGroup);
	
	[tSignatureCreator createSignatureOfType:inSignatureType
									 forData:inData
								usingIdentity:self.project.settings.certificateName
									 keychain:self.project.settings.certificateKeychainPath
								replyHandler:^(PKGSignatureStatus bStatus,NSData *bSignedData){
									 
									 switch(bStatus)
									 {
										 case PKGSignatureStatusSuccess:
											 
											 tSignature=bSignedData;
											 
											 break;
											 
										 case PKGSignatureStatusKeychainAccessDenied:
											 
											 _signatureResult=PKGArchiveSignatureResultAuthenticationDenied;
											 
											 [[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Signature Error: Authorization Denied"];
											 
											 break;
											 
										 case PKGSignatureStatusIdentityNotFound:
											 
											 _signatureResult=PKGArchiveSignatureResultCertificateNotFound;
											 
											 [[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Signature Error: Certificate not found"];
											 
											 break;
											 
										 default:
											 
											 _signatureResult=PKGArchiveSignatureResultGenericError;
											 
											 [[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Signature Error: Generic Error"];
											 
											 break;
									 }
									 
									 dispatch_group_leave(syncGroup);
								 }];
	
	dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * SIGNATURE_REQUEST_TIME_OUT));
	
	if(dispatch_group_wait(syncGroup, waitTime) != 0)
	{
		_signatureResult=PKGArchiveSignatureResultTimeOut;
		
		[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Signature Error: Timed Out"];
	}
	
	return tSignature;
}

@end
