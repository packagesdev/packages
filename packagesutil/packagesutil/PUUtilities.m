#import "PUUtilities.h"

#import "PKGPackages.h"
#import "PKGPackagesError.h"

#import "PKGArchive.h"

#import "PKGBundleIdentifierFormatter.h"

#import "NSString+Packages.h"

#include "usage.h"

#define __PACKAGESUTIL_NAME__	"packagesutil"

@interface PUUtilities () <PKGFilePathConverter>
{
	NSString * _filePath;
	
	
	PKGProject * _project;
	PKGProjectType _projectType;
	
	id _currentObject;
	
	BOOL _helpRequired;
}

- (PKGPackageSettings *)getPackageSettingsDictionaryForPackageType:(PKGPackageComponentType) inPackageType;

- (BOOL)getPathWithArguments:(NSArray *) inArguments fromFilePath:(PKGFilePath *) inFilePath;

- (BOOL)updateFilePath:(PKGFilePath *) inFilePath withArguments:(NSArray *) inArguments usage:(usage_callback) inUsageCallback;

@end

@implementation PUUtilities

+ (PUUtilities *)sharedUtilities
{
	static PUUtilities * sUtilities=nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sUtilities=[PUUtilities new];
	});
	
	return sUtilities;
}

#pragma mark -

- (void)setHelpRequired:(BOOL) inBool
{
	_helpRequired=inBool;
}

- (PKGPackageSettings *)getPackageSettingsDictionaryForPackageType:(PKGPackageComponentType) inPackageType
{
	if (inPackageType!=PKGPackageComponentTypeImported)
		return ((id<PKGPackageObjectProtocol>)_currentObject).packageSettings;
	
	PKGPackageComponent * tPackageComponent=(PKGPackageComponent *)_currentObject;
	
	PKGFilePath * tImportPath=tPackageComponent.importPath;
	
	if (tImportPath==nil)
	{
		// A COMPLETER
		
		return nil;
	}
	
	NSString * tAbsolutePath=[self absolutePathForFilePath:tImportPath];
		
	if (tAbsolutePath==nil)
	{
		// A COMPLETER
		
		return nil;
	}
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:tAbsolutePath]==NO)
	{
		(void)fprintf(stderr, "%s: %s: missing imported package.\n",__PACKAGESUTIL_NAME__,[tAbsolutePath UTF8String]);
		return nil;
	}
	
	PKGArchive * tArchive=[PKGArchive archiveAtPath:tAbsolutePath];
	
	if (tArchive==nil)
	{
		//  A COMPLETER
		
		return nil;
	}
	
	NSData * tData=nil;
	
	if ([tArchive extractFile:@"PackageInfo" intoData:&tData error:NULL]==NO)
	{
		//  A COMPLETER
		
		return nil;
	}
	
	PKGPackageSettings * tPackageSettings=[[PKGPackageSettings alloc] initWithXMLData:tData];
	
	return tPackageSettings;
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
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:[_filePath stringByDeletingLastPathComponent]];
			
		case PKGFilePathTypeRelativeToReferenceFolder:
		{
			NSString * tReferenceFolderPath=_project.settings.referenceFolderPath;
			
			if (tReferenceFolderPath==nil)
				tReferenceFolderPath=[_filePath stringByDeletingLastPathComponent];
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:tReferenceFolderPath];
		}
			
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
		tReferencePath=[_filePath stringByDeletingLastPathComponent];
	}
	else if (inType==PKGFilePathTypeRelativeToReferenceFolder)
	{
		tReferencePath=_project.settings.referenceFolderPath;
		
		if (tReferencePath==nil)
			tReferencePath=[_filePath stringByDeletingLastPathComponent];
	}
	
	if (tReferencePath==nil)
	{
		
		return nil;
	}
	
	NSString * tConvertedPath=[inAbsolutePath PKG_stringByRelativizingToPath:tReferencePath];
	
	if (tConvertedPath==nil)
	{
		// A COMPLETER
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

#pragma mark - Package Setters -

- (BOOL)updateFilePath:(PKGFilePath *) inFilePath withArguments:(NSArray *) inArguments usage:(usage_callback) inUsageCallback
{
	if (inFilePath==nil)
		return NO;
	
	NSUInteger tCount=[inArguments count];
	
	if (tCount!=1 && tCount!=2)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		inUsageCallback();
		
		return NO;
	}
	
	if (tCount==1)
	{
		// The path should be absolute (we do not change the path type)
		
		NSString * tNewPath=[inArguments objectAtIndex:0];
		
		if ([tNewPath length]==0)
		{
			(void)fprintf(stderr, "%s: Empty path not allowed\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
		
		PKGFilePath * tFilePath=[self filePathForAbsolutePath:tNewPath type:inFilePath.type];
		
		if (tFilePath==nil)
		{
			// A COMPLETER
			return NO;
		}
		
		inFilePath.string=tFilePath.string;
		
		return YES;
	}
	
	if (tCount==2)
	{
		NSString * tCommand=[inArguments objectAtIndex:0];
		
		if ([tCommand isEqualToString:@"path-type"]==NO && [tCommand isEqualToString:@"path"]==NO)
		{
			(void)fprintf(stderr, "%s: %s: not recognized.\n",__PACKAGESUTIL_NAME__,[tCommand UTF8String]);
			return NO;
		}
		
		if ([tCommand isEqualToString:@"path-type"]==YES)
		{
			NSString * tPathTypeString=[inArguments objectAtIndex:1];
			
			PKGFilePathType tNewPathType;
			
			if ([tPathTypeString isEqualToString:@"absolute"]==YES)
			{
				tNewPathType=PKGFilePathTypeAbsolute;
			}
			else if ([tPathTypeString isEqualToString:@"relative"]==YES)
			{
				tNewPathType=PKGFilePathTypeRelativeToProject;
			}
			else if ([tPathTypeString isEqualToString:@"reference-folder"]==YES)
			{
				tNewPathType=PKGFilePathTypeRelativeToReferenceFolder;
			}
			else
			{
				// Invalid arguments
				
				(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tPathTypeString UTF8String]);
				return NO;
			}
			
			if ([self shiftTypeOfFilePath:inFilePath toType:tNewPathType]==NO)
			{
				// A COMPLETER
				
				return NO;
			}
			
			return YES;
		}
			
		if ([tCommand isEqualToString:@"path"]==YES)
		{
			NSString * tNewPath=[inArguments objectAtIndex:1];
			
			if ([tNewPath length]==0)
			{
				(void)fprintf(stderr, "%s: Empty path not allowed\n",__PACKAGESUTIL_NAME__);
				return NO;
			}
			
			if ([tNewPath rangeOfString:@":"].location!=NSNotFound)
			{
				(void)fprintf(stderr, "%s: Invalid characters in path.\n",__PACKAGESUTIL_NAME__);
				return NO;
			}
			
			inFilePath.string=tNewPath;
			
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)setPackageName:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (_projectType!=PKGProjectTypeDistribution)
	{
		(void)fprintf(stderr, "%s: Can not set the package name. Set project name instead.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if (inPackageType==PKGPackageComponentTypeImported)
	{
		// Package name can not be modified
			
		(void)fprintf(stderr, "%s: Can not modify the name of an imported package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments (usage)
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
	
		return NO;
	}
	
	NSString * tNewName=[inArguments lastObject];

	// Check that the name is OK

	if ([tNewName length]==0)
	{
		(void)fprintf(stderr, "%s: Empty name not allowed\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings==nil)
	{
		return NO;
	}
	
	// Check that the name is not the same as the old one to avoid the incoming comparison
	
	if ([tPackageSettings.name isEqualToString:tNewName]==YES)
		return YES;
	
	// Check that the name is unique
	
	for(PKGPackageComponent * tPackageComponent in ((PKGDistributionProject *)_project).packageComponents)
	{
		if (tPackageComponent!=_currentObject)
		{
			PKGPackageSettings * tOtherPackageSettings=tPackageComponent.packageSettings;
			
			if ([tOtherPackageSettings.name isEqualToString:tNewName]==YES)
			{
				(void)fprintf(stderr, "%s: Name already used for another package.\n",__PACKAGESUTIL_NAME__);
				
				return NO;
			}
		}
	}
	
	tPackageSettings.name=tNewName;
	
	return YES;
}

- (BOOL)setPackageIdentifier:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType==PKGPackageComponentTypeImported)
	{
		// Package identifier can not be modified
		
		(void)fprintf(stderr, "%s: Can not modify the identifier of an imported package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments (usage)
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
	
	NSString * tNewIdentifier=[inArguments lastObject];
	
	// Check that the identifier is OK
	
	if ([tNewIdentifier length]==0)
	{
		(void)fprintf(stderr, "%s: Empty identifier not allowed\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGBundleIdentifierFormatter * tFormatter=[PKGBundleIdentifierFormatter new];
	
	if (tFormatter!=nil)
	{
		(void)fprintf(stderr, "%s: Low memory\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
		
	if ([tFormatter isPartialStringValid:tNewIdentifier newEditingString:NULL errorDescription:NULL]==NO)
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tNewIdentifier UTF8String]);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
		
	if (tPackageSettings==nil)
	{
		return NO;
	}
	
	
	tPackageSettings.identifier=tNewIdentifier;
		
	return YES;
}

- (BOOL)setPackageVersion:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType==PKGPackageComponentTypeImported)
	{
		// Package version can not be modified
		
		(void)fprintf(stderr, "%s: Can not modify the version of an imported package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
	
	NSString * tNewVersion=[inArguments lastObject];
	
	// Check that the version is OK
	
	if ([tNewVersion length]==0)
	{
		(void)fprintf(stderr, "%s: Empty version not allowed\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings!=nil)
	{
		tPackageSettings.version=tNewVersion;
		
		return YES;
	}
	
	return NO;
}

- (BOOL)setPackagePost_Installation_Behavior:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType==PKGPackageComponentTypeImported)
	{
		// Package version can not be modified
		
		(void)fprintf(stderr, "%s: Can not modify the version of an imported package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
	
	NSUInteger tConclusionAction=NSNotFound;
	
	NSString * tConclusion=[inArguments lastObject];
	
	// Set the new behavior
	
	if ([tConclusion isEqualToString:@"do-nothing"]==YES)
	{
		tConclusionAction=PKGPackageConclusionActionNone;
	}
	else if ([tConclusion isEqualToString:@"require-restart"]==YES)
	{
		tConclusionAction=PKGPackageConclusionActionRequireRestart;
	}
	else if ([tConclusion isEqualToString:@"require-shutdown"]==YES)
	{
		tConclusionAction=PKGPackageConclusionActionRequireShutdown;
	}
	else if ([tConclusion isEqualToString:@"require-logout"]==YES)
	{
		tConclusionAction=PKGPackageConclusionActionRequireLogout;
	}
	
	if (tConclusionAction==NSNotFound)
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tConclusion UTF8String]);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings!=nil)
	{
		tPackageSettings.conclusionAction=tConclusionAction;
		
		return YES;
	}
	
	return NO;
}

- (BOOL)setPackageLocation_Type:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (_projectType!=PKGProjectTypeDistribution)
	{
		(void)fprintf(stderr, "%s: Can not set the location type of a raw package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
	
	NSString * tLocationTypeString=[inArguments lastObject];
	
	NSUInteger tLocationType=NSNotFound;
	
	// Set the new behavior
	
	if ([tLocationTypeString isEqualToString:@"embedded"]==YES)
	{
		tLocationType=PKGPackageLocationEmbedded;
	}
	else if ([tLocationTypeString isEqualToString:@"custom"]==YES)
	{
		tLocationType=PKGPackageLocationCustomPath;
	}
	else if ([tLocationTypeString isEqualToString:@"http-url"]==YES)
	{
		tLocationType=PKGPackageLocationHTTPURL;
	}
	else if ([tLocationTypeString isEqualToString:@"removable-media"]==YES)
	{
		tLocationType=PKGPackageLocationRemovableMedia;
	}
	
	if (tLocationType==NSNotFound)
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tLocationTypeString UTF8String]);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings!=nil)
	{
		tPackageSettings.locationType=tLocationType;
		
		return YES;
	}

	return NO;
}

- (BOOL)setPackageLocation_Path:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (_projectType!=PKGProjectTypeDistribution)
	{
		(void)fprintf(stderr, "%s: Can not set the location path of a raw package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
		
	NSString * tLocationURL=[inArguments lastObject];
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings!=nil)
	{
		tPackageSettings.locationURL=tLocationURL;
		
		return YES;
	}
	
	return NO;
}

- (BOOL)setPackageRequire_Admin_Password:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType==PKGPackageComponentTypeImported)
	{
		// Package authentication can not be modified
		
		(void)fprintf(stderr, "%s: Can not modify the require admin password behavior of an imported package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
	
	NSString * tState=[inArguments lastObject];
	
	NSUInteger tAuthenticationMode=NSNotFound;
	
	// Set the new behavior
	
	if ([tState isEqualToString:@"yes"]==YES)
	{
		tAuthenticationMode=PKGPackageAuthenticationRoot;
	}
	else if ([tState isEqualToString:@"no"]==YES)
	{
		tAuthenticationMode=PKGPackageAuthenticationNone;
	}
	
	if (tAuthenticationMode==NSNotFound)
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tState UTF8String]);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings!=nil)
	{
		tPackageSettings.authenticationMode=tAuthenticationMode;
		
		return YES;
	}
	
	return NO;
}

- (BOOL)setPackageRelocatable:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType!=PKGPackageComponentTypeProject)
	{
		// Package relocatable can not be modified
		
		(void)fprintf(stderr, "%s: Can not modify the relocatable option of an imported or referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
	
	NSString * tState=[inArguments lastObject];
	BOOL tStateBool;
	
	// Set the new behavior
	
	if ([tState isEqualToString:@"yes"]==YES)
	{
		tStateBool=YES;
	}
	else if ([tState isEqualToString:@"no"]==YES)
	{
		tStateBool=NO;
	}
	else
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tState UTF8String]);
		return NO;
	}

	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings==nil)
	{
		
		return NO;
	}
	
	tPackageSettings.relocatable=tStateBool;
		
	return YES;
}

- (BOOL)setPackageOverwrite_Directory_Permission:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType!=PKGPackageComponentTypeProject)
	{
		// Package overwrite directory permission can not be modified
		
		(void)fprintf(stderr, "%s: Can not modify the overwrite directory permission option of an imported or referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
	
	NSString * tState=[inArguments lastObject];
	BOOL tStateBool;
	
	// Set the new behavior
	
	if ([tState isEqualToString:@"yes"]==YES)
	{
		tStateBool=YES;
	}
	else if ([tState isEqualToString:@"no"]==YES)
	{
		tStateBool=NO;
	}
	else
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tState UTF8String]);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings==nil)
	{
		
		return NO;
	}
	
	tPackageSettings.overwriteDirectoryPermissions=tStateBool;
		
	return YES;
}

- (BOOL)setPackageFollow_Symbolic_Links:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType!=PKGPackageComponentTypeProject)
	{
		// Package overwrite directory permission can not be modified
		
		(void)fprintf(stderr, "%s: Can not modify the follow symbolic links option of an imported or referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
	
	NSString * tState=[inArguments lastObject];
	BOOL tStateBool;
	
	// Set the new behavior
	
	if ([tState isEqualToString:@"yes"]==YES)
	{
		tStateBool=YES;
	}
	else if ([tState isEqualToString:@"no"]==YES)
	{
		tStateBool=NO;
	}
	else
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tState UTF8String]);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings==nil)
	{
		
		return NO;
	}
	
	tPackageSettings.followSymbolicLinks=tStateBool;
		
	return YES;
}

- (BOOL)setPackageUse_Hfs_Compression:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType!=PKGPackageComponentTypeProject)
	{
		// Package overwrite directory permission can not be modified
		
		(void)fprintf(stderr, "%s: Can not modify the hfs compression option of an imported or referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
		
		return NO;
	}
	
	NSString * tState=[inArguments lastObject];
	BOOL tStateBool;
	
	// Set the new behavior
	
	if ([tState isEqualToString:@"yes"]==YES)
	{
		tStateBool=YES;
	}
	else if ([tState isEqualToString:@"no"]==YES)
	{
		tStateBool=NO;
	}
	else
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tState UTF8String]);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings==nil)
	{
		
		return NO;
	}
	
	tPackageSettings.useHFSPlusCompression=tStateBool;
		
	return YES;
}

- (BOOL)setPackagePre_Installation_Script:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType!=PKGPackageComponentTypeProject)
	{
		// Package pre-installation script can not be modified
		
		(void)fprintf(stderr, "%s: Can not set information about the pre-installation script of an imported or referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	id<PKGPackageObjectProtocol> tPackageProject=_currentObject;
	
	PKGPackageScriptsAndResources * tPackageScriptsAndResources=tPackageProject.scriptsAndResources;
	
	if (tPackageScriptsAndResources==nil)
	{
		tPackageScriptsAndResources=[[PKGPackageScriptsAndResources alloc] init];
		
		if (tPackageScriptsAndResources==nil)
		{
			(void)fprintf(stderr, "%s: Low memory\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
		
		tPackageProject.scriptsAndResources=tPackageScriptsAndResources;
	}
	
	PKGFilePath * tFilePath=tPackageScriptsAndResources.preInstallationScriptPath;
	
	if (tFilePath==nil)
		tFilePath=[[PKGFilePath alloc] init];
	
	if ([self updateFilePath:tFilePath withArguments:inArguments usage:usage_set_package]==NO)
	{
		
		return NO;
	}
	
	tPackageScriptsAndResources.preInstallationScriptPath=tFilePath;
	
	return YES;
}

- (BOOL)setPackagePost_Installation_Script:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (inPackageType!=PKGPackageComponentTypeProject)
	{
		// Package post-installation script can not be modified
		
		(void)fprintf(stderr, "%s: Can not set information about the post-installation script of an imported or referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	id<PKGPackageObjectProtocol> tPackageProject=_currentObject;
	
	PKGPackageScriptsAndResources * tPackageScriptsAndResources=tPackageProject.scriptsAndResources;
	
	if (tPackageScriptsAndResources==nil)
	{
		tPackageScriptsAndResources=[[PKGPackageScriptsAndResources alloc] init];
		
		if (tPackageScriptsAndResources==nil)
		{
			(void)fprintf(stderr, "%s: Low memory\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
		
		tPackageProject.scriptsAndResources=tPackageScriptsAndResources;
	}
	
	PKGFilePath * tFilePath=tPackageScriptsAndResources.postInstallationScriptPath;
	
	if (tFilePath==nil)
		tFilePath=[[PKGFilePath alloc] init];
	
	if ([self updateFilePath:tFilePath withArguments:inArguments usage:usage_set_package]==NO)
	{
		
		return NO;
	}
	
	tPackageScriptsAndResources.postInstallationScriptPath=tFilePath;
	
	return YES;
}


- (BOOL)setPackageValue:(NSMutableArray *) inArguments
{
	if ([inArguments count]<2)
	{
		(void)fprintf(stderr, "%s: Missing arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_package();
	
		return NO;
	}
	
	PKGPackageComponentType tPackageType=PKGPackageComponentTypeProject;
	
	// Check later the Package Type (we can't modify an imported package and some settings of a referenced package)
	
	if (_projectType==PKGProjectTypeDistribution)
		tPackageType=((PKGPackageComponent *)_currentObject).type;
	
	NSString * tObject=[inArguments objectAtIndex:0];
	
	// Build the method suffix
	
	NSArray * tComponents=[tObject componentsSeparatedByString:@"-"];
	
	if (tComponents!=nil)
	{
		NSMutableArray * tMutableComponents=[NSMutableArray arrayWithCapacity:[tComponents count]];
		
		if (tMutableComponents!=nil)
		{
			for(NSString * tComponent in tComponents)
				[tMutableComponents addObject:[tComponent capitalizedString]];
			
			tObject=[tMutableComponents componentsJoinedByString:@"_"];
		}
	}
	else
	{
		tObject=[tObject capitalizedString];
	}
	
	NSString * tMethodName=[NSString stringWithFormat:@"setPackage%@:type:",tObject];
	
	SEL tSelector=NSSelectorFromString(tMethodName);
	
	if ([self respondsToSelector:tSelector]==NO)
	{
		(void)fprintf(stderr, "%s: %s: not recognized.\n",__PACKAGESUTIL_NAME__,[[inArguments objectAtIndex:0] UTF8String]);
		
		usage_set_package();
		
		return NO;
	}
	
	NSMethodSignature * tMethodSignature=[self methodSignatureForSelector:tSelector];
	
	if (tMethodSignature!=nil)
	{
		NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:tMethodSignature];
		
		if (tInvocation!=nil)
		{
			BOOL tResult;
			
			[tInvocation setTarget:self];
			
			[tInvocation setSelector:tSelector];
			
			[inArguments removeObjectAtIndex:0];
			
			[tInvocation setArgument:&inArguments atIndex:2];
			
			[tInvocation setArgument:&tPackageType atIndex:3];
			
			[tInvocation invoke];
			
			[tInvocation getReturnValue:&tResult];
			
			return tResult;
		}
	}
			
	return NO;
}

#pragma mark - Project Setters -

- (BOOL)setProjectName:(NSMutableArray *) inArguments
{
	if ([inArguments count]!=1)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_project();
	
		return NO;
	}
	
	NSString * tNewName=[inArguments lastObject];
		
	if ([tNewName length]==0)
	{
		// A Project Name can not be empty
		
		(void)fprintf(stderr, "%s: A project name can not be empty.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}

	PKGProjectSettings * tProjectSettings=_project.settings;
	
	if (tProjectSettings==nil)
	{
		(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	tProjectSettings.name=tNewName;
		
	return YES;
}

- (BOOL)setProjectBuild_Format:(NSMutableArray *) inArguments
{
	if (_projectType!=PKGProjectTypeDistribution)
	{
		(void)fprintf(stderr, "%s: Can not change the build format of a raw package project.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_project();
		
		return NO;
	}

	NSString * tFormat=[inArguments lastObject];
	PKGProjectBuildFormat tFormatValue;
	
	// Set the new format
	
	if ([tFormat isEqualToString:@"flat"]==YES)
	{
		tFormatValue=PKGProjectBuildFormatFlat;
	}
	else if ([tFormat isEqualToString:@"bundle"]==YES)
	{
		tFormatValue=PKGProjectBuildFormatBundle;
	}
	else
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tFormat UTF8String]);
		return NO;
	}
	
	PKGDistributionProjectSettings * tProjectSettings=(PKGDistributionProjectSettings *)((PKGDistributionProject *)_project).settings;
	
	if (tProjectSettings==nil)
	{
		(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	tProjectSettings.buildFormat=tFormatValue;
	
	return YES;
}

- (BOOL)setProjectBuild_Folder:(NSMutableArray *) inArguments
{
	PKGProjectSettings * tProjectSettings=_project.settings;
	
	if (tProjectSettings==nil)
	{
		(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([self updateFilePath:tProjectSettings.buildPath withArguments:inArguments usage:usage_set_project]==NO)
	{
		
		return NO;
	}
	
	return YES;
}

- (BOOL)setProjectCertificate_Keychain:(NSMutableArray *) inArguments
{
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_project();
	
		return NO;
	}
	
	if (_projectType==PKGProjectTypeDistribution)
	{
		PKGDistributionProjectSettings * tProjectSettings=(PKGDistributionProjectSettings *)((PKGDistributionProject *)_project).settings;
		
		if (tProjectSettings==nil)
		{
			(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
		
		if (tProjectSettings.buildFormat==PKGProjectBuildFormatBundle);
		{
			// Bundle
			
			(void)fprintf(stderr, "%s: Bundle distributions can not be signed with a certificate.\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
	}
	
	PKGProjectSettings * tProjectSettings=_project.settings;
	
	if (tProjectSettings==nil)
	{
		(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	NSString * tPath=[inArguments lastObject];
	
	if ([tPath length]==0)
	{
		// A Keychain path can not be empty
		
		(void)fprintf(stderr, "%s: A keychain path can not be empty.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	tProjectSettings.certificateKeychainPath=tPath;
	
	return YES;
}

- (BOOL)setProjectCertificate_Identity:(NSMutableArray *) inArguments
{
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_project();
		
		return NO;
	}
	
	if (_projectType==PKGProjectTypeDistribution)
	{
		PKGDistributionProjectSettings * tProjectSettings=(PKGDistributionProjectSettings *)((PKGDistributionProject *)_project).settings;
		
		if (tProjectSettings==nil)
		{
			(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
		
		if (tProjectSettings.buildFormat==PKGProjectBuildFormatBundle);
		{
			// Bundle
			
			(void)fprintf(stderr, "%s: Bundle distributions can not be signed with a certificate.\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
	}
	
	PKGProjectSettings * tProjectSettings=_project.settings;
	
	if (tProjectSettings==nil)
	{
		(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	NSString * tName=[inArguments lastObject];
	
	if ([tName length]==0)
	{
		// A Certificate Identity can not be empty
		
		(void)fprintf(stderr, "%s: A signing identity can not be empty.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	
	tProjectSettings.certificateName=tName;
	
	return YES;
}

- (BOOL)setProjectTreat_Missing_Items_As_Warnings:(NSMutableArray *) inArguments
{
	if ([inArguments count]!=1)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_project();
	
		return NO;
	}
	
	NSString * tState=[inArguments lastObject];
	BOOL tStateBool;
	
	// Set the new format
	
	if ([tState isEqualToString:@"yes"]==YES)
	{
		tStateBool=YES;
	}
	else if ([tState isEqualToString:@"no"]==YES)
	{
		tStateBool=NO;
	}
	else
	{
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tState UTF8String]);
		return NO;
	}
	
	if (_projectType==PKGProjectTypeDistribution)
	{
		PKGDistributionProjectSettings * tProjectSettings=(PKGDistributionProjectSettings *)_project.settings;
		
		if (tProjectSettings==nil)
		{
			(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
		
		tProjectSettings.treatMissingPresentationDocumentsAsWarnings=tStateBool;
		
		for(PKGPackageComponent * tPackageComponent in ((PKGDistributionProject *) _project).packageComponents)
		{
			PKGPackagePayload * tPackagePayload=tPackageComponent.payload;
			
			if (tPackagePayload==nil)
			{
				tPackagePayload=[[PKGPackagePayload alloc] init];
				
				if (tPackagePayload==nil)
				{
					(void)fprintf(stderr, "%s: Low memory\n",__PACKAGESUTIL_NAME__);
					return NO;
				}
				
				tPackageComponent.payload=tPackagePayload;
			}
			
			tPackagePayload.treatMissingPayloadFilesAsWarnings=tStateBool;
		}
	}
	else
	{
		PKGPackageProject * tPackageProject=(PKGPackageProject *)_project;
		
		PKGPackagePayload * tPackagePayload=tPackageProject.payload;
		
		if (tPackagePayload==nil)
		{
			tPackagePayload=[[PKGPackagePayload alloc] init];
			
			if (tPackagePayload==nil)
			{
				(void)fprintf(stderr, "%s: Low memory\n",__PACKAGESUTIL_NAME__);
				return NO;
			}
			
			tPackageProject.payload=tPackagePayload;
		}
		
		tPackagePayload.treatMissingPayloadFilesAsWarnings=tStateBool;
	}
	
	return YES;
}

- (BOOL)setProjectValue:(NSMutableArray *) inArguments
{
	if ([inArguments count]<2)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_set_project();
	
		return NO;
	}
	
	NSString * tObject=[inArguments objectAtIndex:0];
	
	// Build the method suffix
	
	NSArray * tComponents=[tObject componentsSeparatedByString:@"-"];
	
	if ([tComponents count]>1)
	{
		NSMutableArray * tMutableComponents=[NSMutableArray arrayWithCapacity:[tComponents count]];
		
		if (tMutableComponents!=nil)
		{
			for(NSString * tComponent in tComponents)
				[tMutableComponents addObject:[tComponent capitalizedString]];
			
			tObject=[tMutableComponents componentsJoinedByString:@"_"];
		}
	}
	else
	{
		tObject=[tObject capitalizedString];
	}
	
	NSString * tMethodName=[NSString stringWithFormat:@"setProject%@:",tObject];
	
	SEL tSelector=NSSelectorFromString(tMethodName);
	
	if ([self respondsToSelector:tSelector]==NO)
	{
		(void)fprintf(stderr, "%s: %s: not recognized.\n",__PACKAGESUTIL_NAME__,[[inArguments objectAtIndex:0] UTF8String]);
		
		usage_set_project();
	
		return NO;
	}
	
	NSMethodSignature * tMethodSignature=[self methodSignatureForSelector:tSelector];
	
	if (tMethodSignature!=nil)
	{
		NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:tMethodSignature];
		
		if (tInvocation!=nil)
		{
			BOOL tResult;
			
			[tInvocation setTarget:self];
			
			[tInvocation setSelector:tSelector];
			
			[inArguments removeObjectAtIndex:0];
			
			[tInvocation setArgument:&inArguments atIndex:2];
			
			[tInvocation invoke];
			
			[tInvocation getReturnValue:&tResult];
			
			return tResult;
		}
	}

	return NO;
}

- (BOOL)setValue:(NSMutableArray *) inArguments forFileAtPath:(NSString *) inPath
{
	BOOL tResult=NO;
	
	_projectType=-1;
	
	if (inPath!=nil && _helpRequired==NO)
	{
		NSError * tError=nil;
		
		_project=[PKGProject projectWithContentsOfFile:inPath error:&tError];
		
		if (_project==nil)
		{
			if ([tError.domain isEqualToString:PKGPackagesModelErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case PKGRepresentationInvalidTypeOfValueError:
						
						(void)fprintf(stderr, "%s: %s: Invalid type for value: %s\n",__PACKAGESUTIL_NAME__,[inPath fileSystemRepresentation],[tError.userInfo[PKGKeyPathErrorKey] UTF8String]);
						
						break;
						
					case PKGRepresentationInvalidValue:
						
						(void)fprintf(stderr, "%s: %s: Invalid value for %s\n",__PACKAGESUTIL_NAME__,[inPath fileSystemRepresentation],[tError.userInfo[PKGKeyPathErrorKey] UTF8String]);
						
						break;
				}
			}
			
			return NO;
		}
		
		_projectType=_project.type;
		
		_filePath=inPath;
	}
	
	// Check it's a Packages project
	
	if (_projectType==PKGProjectTypePackage)
	{
		_currentObject=_project;
		
		if ([inArguments count]>0 && [[inArguments objectAtIndex:0] isEqualToString:@"project"]==YES)
		{
			[inArguments removeObjectAtIndex:0];
			
			tResult=[self setProjectValue:inArguments];
		}
		else
		{
			tResult=[self setPackageValue:inArguments];
		}
	}
	else if (_projectType==PKGProjectTypeDistribution)
	{
		// Check if we are targeting the package
		
		if ([inArguments count]>0)
		{
			NSString * tComponent=[inArguments objectAtIndex:0];
			
			if ([tComponent isEqualToString:@"project"]==YES)
			{
				_currentObject=_project;
				
				[inArguments removeObjectAtIndex:0];
				
				tResult=[self setProjectValue:inArguments];
			}
			else
			{
				if ([tComponent hasPrefix:@"package-"]==YES)
				{
					// Search Package by Index
					
					NSString * tIndexString=[tComponent substringFromIndex:8];
					
					NSUInteger tIndex=[tIndexString integerValue];
					
					if (tIndex>0)
					{
						NSArray * tPackageComponents=((PKGDistributionProject *)_project).packageComponents;
						
						if ([tPackageComponents count]<tIndex)
						{
							(void)fprintf(stderr, "%s: %s: No package at index %d\n",__PACKAGESUTIL_NAME__,[inPath fileSystemRepresentation],(int) tIndex);
							return NO;
						}
						
						_currentObject=tPackageComponents[tIndex-1];
							
						[inArguments removeObjectAtIndex:0];
							
						tResult=[self setPackageValue:inArguments];
					}
				}
				else
				{
					if ([tComponent isEqualToString:@"package"]==YES)
					{
						[inArguments removeObjectAtIndex:0];
						
						if ([inArguments count]>0)
							tComponent=[inArguments objectAtIndex:0];
					}
					
					// Search Package by Identifier
					
					_currentObject=[((PKGDistributionProject *)_project) packageComponentWithIdentifier:tComponent];
					
					if (_currentObject==nil)
					{
						(void)fprintf(stderr, "%s: %s: No package with identifier \"%s\" found\n",__PACKAGESUTIL_NAME__,[inPath fileSystemRepresentation],[tComponent UTF8String]);
						return NO;
					}
					
					[inArguments removeObjectAtIndex:0];
								
					tResult=[self setPackageValue:inArguments];
				}
			}
		}
		else
		{
			// Missing arguments
			
			usage_set();
		}
	}
	else if (_helpRequired==YES)
	{
		if ([inArguments count]>0)
		{
			NSString * tComponent=[inArguments objectAtIndex:0];
			
			if ([tComponent isEqualToString:@"project"]==YES)
			{
				usage_set_project();
			}
			else if ([tComponent isEqualToString:@"package"]==YES)
			{
				usage_set_package();
			}
		}
		else
		{
			usage_set();
		}
		
		return YES;
	}
			
	if (tResult==YES)
	{
		if ([_project writeToFile:_filePath atomically:YES]==NO)
		{
			// A COMPLETER
			
			tResult=NO;
		}
	}
	
	return tResult;
}

#pragma mark - Package Getters -

- (BOOL)getPathWithArguments:(NSArray *) inArguments fromFilePath:(PKGFilePath *) inFilePath
{
	if (inFilePath==nil || inFilePath.string==nil)
	{
		(void)fprintf(stderr, "%s: No path set.\n",__PACKAGESUTIL_NAME__);
		return YES;
	}
	
	if ([inArguments count]==0)
	{
		// Return the absolute path
		
		NSString * tAbsolutePath=[self absolutePathForFilePath:inFilePath];
		
		if (tAbsolutePath==nil)
		{
			return NO;
		}
		
		(void)fprintf(stdout, "%s\n",[tAbsolutePath fileSystemRepresentation]);
			
		return YES;
	}
	
	if ([inArguments count]==1)
	{
		NSString * tCommand=[inArguments objectAtIndex:0];
		
		if ([tCommand isEqualToString:@"path-type"]==YES)
		{
			switch (inFilePath.type)
			{
				case PKGFilePathTypeAbsolute:
					
					(void)fprintf(stdout, "absolute\n");
					
					break;
					
				case PKGFilePathTypeRelativeToProject:
					
					(void)fprintf(stdout, "relative\n");
					
					break;
					
				case PKGFilePathTypeRelativeToReferenceFolder:
					
					(void)fprintf(stdout, "reference-folder\n");
					
					break;
					
				default:
					
					(void)fprintf(stderr, "%s: Unknown type of path.\n",__PACKAGESUTIL_NAME__);
					return NO;
			}
			
			return YES;
		}
		
		if ([tCommand isEqualToString:@"path"]==YES)
		{
			NSString * tPath=inFilePath.string;
			
			(void)fprintf(stdout, "%s\n",[tPath fileSystemRepresentation]);
			
			return YES;
		}
		
		(void)fprintf(stderr, "%s: %s: Invalid argument.\n",__PACKAGESUTIL_NAME__,[tCommand UTF8String]);
	}

	return NO;
}

#pragma mark -

- (BOOL)getPackageName:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
	
		return NO;
	}
	
	if (_projectType!=PKGProjectTypeDistribution)
	{
		(void)fprintf(stderr, "%s: Can not get package name. Get project name instead.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>) _currentObject).packageSettings;
	
	if (tPackageSettings==nil)
	{
		return NO;
	}
	
	NSString * tPackageName=tPackageSettings.name;
	
	(void)fprintf(stdout, "%s\n",[tPackageName UTF8String]);
	
	return YES;
}

- (BOOL)getPackageIdentifier:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
	
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=[self getPackageSettingsDictionaryForPackageType:inPackageType];
	
	if (tPackageSettings==nil)
		return NO;
	
	NSString * tIdentifier=tPackageSettings.identifier;
	
	(void)fprintf(stdout, "%s\n",[tIdentifier UTF8String]);
	
	return YES;
}

- (BOOL)getPackageVersion:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
		
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=[self getPackageSettingsDictionaryForPackageType:inPackageType];
	
	if (tPackageSettings==nil)
		return NO;
	
	NSString * tPackageVersion=tPackageSettings.version;
	
	(void)fprintf(stdout, "%s\n",[tPackageVersion UTF8String]);
	
	return YES;
}

- (BOOL)getPackagePost_Installation_Behavior:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
		
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=[self getPackageSettingsDictionaryForPackageType:inPackageType];
	
	if (tPackageSettings==nil)
		return NO;
	
	PKGPackageConclusionAction tConclusionAction=tPackageSettings.conclusionAction;
	
	switch(tConclusionAction)
	{
		case PKGPackageConclusionActionNone:
			
			(void)fprintf(stdout, "do-nothing\n");
			break;
			
		case PKGPackageConclusionActionRequireRestart:
			
			(void)fprintf(stdout, "require-restart\n");
			break;
			
		case PKGPackageConclusionActionRequireShutdown:
			
			(void)fprintf(stdout, "require-shutdown\n");
			break;
			
		case PKGPackageConclusionActionRequireLogout:
			
			(void)fprintf(stdout, "require-logout\n");
			break;
			
		default:
			
			return NO;
	}
	
	return YES;
}

- (BOOL)getPackageLocation_Type:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (_projectType!=PKGProjectTypeDistribution)
	{
		(void)fprintf(stderr, "%s: Can not get the location type of a raw package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=[self getPackageSettingsDictionaryForPackageType:inPackageType];
	
	if (tPackageSettings==nil)
		return NO;
	
	PKGPackageLocationType tPackageLocationType=tPackageSettings.locationType;
	
	switch(tPackageLocationType)
	{
		case PKGPackageLocationEmbedded:
			
			(void)fprintf(stdout, "embedded\n");
			break;
			
		case PKGPackageLocationCustomPath:
			
			(void)fprintf(stdout, "custom\n");
			break;
			
		case PKGPackageLocationHTTPURL:
			
			(void)fprintf(stdout, "http-url\n");
			break;
			
		case PKGPackageLocationRemovableMedia:
			
			(void)fprintf(stdout, "removable-media\n");
			break;
		
		default:
			
			return NO;
	}
	
	return YES;
}

- (BOOL)getPackageLocation_Path:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if (_projectType!=PKGProjectTypeDistribution)
	{
		(void)fprintf(stderr, "%s: Can not get the location path of a raw package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=((id<PKGPackageObjectProtocol>)_currentObject).packageSettings;
	
	if (tPackageSettings==nil)
	{
		
		return NO;
	}
	
	NSString * tLocationPath=tPackageSettings.locationPath;
	
	if (tLocationPath!=nil)
		(void)fprintf(stdout, "%s\n",[tLocationPath UTF8String]);
	
	return YES;
}

- (BOOL)getPackageRequire_Admin_Password:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
		
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=[self getPackageSettingsDictionaryForPackageType:inPackageType];
	
	if (tPackageSettings==nil)
		return NO;
		
	(void)fprintf(stdout, (tPackageSettings.authenticationMode==PKGPackageAuthenticationRoot)? "yes\n" : "no\n");
	
	return YES;
}

- (BOOL)getPackageRelocatable:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
		
		return NO;
	}

	if (inPackageType==PKGPackageComponentTypeReference)
	{
		// Package relocatable can not be obtained
		
		(void)fprintf(stderr, "%s: Can not get the relocatable option of a referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=[self getPackageSettingsDictionaryForPackageType:inPackageType];
	
	if (tPackageSettings==nil)
		return NO;
	
	(void)fprintf(stdout, (tPackageSettings.relocatable==YES)? "yes\n" : "no\n");
	
	return YES;
}

- (BOOL)getPackageOverwrite_Directory_Permission:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
		
		return NO;
	}
	
	if (inPackageType==PKGPackageComponentTypeReference)
	{
		// Package overwrite directory permissions can not be obtained
		
		(void)fprintf(stderr, "%s: Can not get the overwrite directory option of a referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=[self getPackageSettingsDictionaryForPackageType:inPackageType];
	
	if (tPackageSettings==nil)
		return NO;
	
	(void)fprintf(stdout, (tPackageSettings.overwriteDirectoryPermissions==YES)? "yes\n" : "no\n");
	
	return YES;
}

- (BOOL)getPackageFollow_Symbolic_Links:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
		
		return NO;
	}
	
	if (inPackageType==PKGPackageComponentTypeReference)
	{
		// Package follow symbolic links can not be obtained
		
		(void)fprintf(stderr, "%s: Can not get the follow symbolic links option of a referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=[self getPackageSettingsDictionaryForPackageType:inPackageType];
	
	if (tPackageSettings==nil)
		return NO;
	
	(void)fprintf(stdout, (tPackageSettings.followSymbolicLinks==YES)? "yes\n" : "no\n");
	
	return YES;
}

- (BOOL)getPackageUse_Hfs_Compression:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
		
		return NO;
	}
	
	if (inPackageType==PKGPackageComponentTypeReference)
	{
		// Package HFS+ Compression Option can not be obtained
		
		(void)fprintf(stderr, "%s: Can not get the hfs+ compression option of a referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageSettings * tPackageSettings=[self getPackageSettingsDictionaryForPackageType:inPackageType];
	
	if (tPackageSettings==nil)
		return NO;
	
	(void)fprintf(stdout, (tPackageSettings.useHFSPlusCompression==YES)? "yes\n" : "no\n");
	
	return YES;
}


- (BOOL)getPackagePre_Installation_Script:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]>=2)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
		
		return NO;
	}
	
	if (inPackageType!=PKGPackageComponentTypeProject)
	{
		// Package pre-installation script can not be obtained
		
		(void)fprintf(stderr, "%s: Can not get information about the pre-installation script of an imported or referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageScriptsAndResources * tScriptsAndResources=((id<PKGPackageObjectProtocol>)_currentObject).scriptsAndResources;
	
	if (tScriptsAndResources==nil)
	{
		(void)fprintf(stderr, "%s: No path set.\n",__PACKAGESUTIL_NAME__);
		return YES;
	}
	
	if ([self getPathWithArguments:inArguments
						  fromFilePath:tScriptsAndResources.preInstallationScriptPath]==YES)
		return YES;
		
	usage_get_package();
	
	return NO;
}

- (BOOL)getPackagePost_Installation_Script:(NSArray *) inArguments type:(PKGPackageComponentType) inPackageType
{
	if ([inArguments count]>=2)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
		
		return NO;
	}
	
	if (inPackageType!=PKGPackageComponentTypeProject)
	{
		// Package post-installation script can not be obtained
		
		(void)fprintf(stderr, "%s: Can not get information about the post-installation script of an imported or referenced package.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	PKGPackageScriptsAndResources * tScriptsAndResources=((id<PKGPackageObjectProtocol>)_currentObject).scriptsAndResources;
	
	if (tScriptsAndResources==nil)
	{
		(void)fprintf(stderr, "%s: No path set.\n",__PACKAGESUTIL_NAME__);
		return YES;
	}
	
	if ([self getPathWithArguments:inArguments
						  fromFilePath:tScriptsAndResources.postInstallationScriptPath]==YES)
		return YES;
		
	usage_get_package();
	
	return NO;
}


- (BOOL)getPackageValue:(NSMutableArray *) inArguments
{
	if ([inArguments count]>0)
	{
		PKGPackageComponentType tPackageType=PKGPackageComponentTypeProject;
		NSString * tObject;
		
		// Check later the Package Type (we can't modify an imported package and some settings of a referenced package)
		
		if (_projectType==PKGProjectTypeDistribution)
			tPackageType=((PKGPackageComponent *) _currentObject).type;
		
		tObject=[inArguments objectAtIndex:0];
		
		// Build the method suffix
		
		NSArray * tComponents=[tObject componentsSeparatedByString:@"-"];
		
		if (tComponents!=nil)
		{
			NSMutableArray * tMutableComponents=[NSMutableArray arrayWithCapacity:[tComponents count]];
			
			if (tMutableComponents!=nil)
			{
				for(NSString * tComponent in tComponents)
					[tMutableComponents addObject:[tComponent capitalizedString]];
				
				tObject=[tMutableComponents componentsJoinedByString:@"_"];
			}
		}
		else
		{
			tObject=[tObject capitalizedString];
		}
		
		NSString * tMethodName=[NSString stringWithFormat:@"getPackage%@:type:",tObject];
		
		SEL tSelector=NSSelectorFromString(tMethodName);
		
		if ([self respondsToSelector:tSelector]==YES)
		{
			NSMethodSignature * tMethodSignature=[self methodSignatureForSelector:tSelector];
			
			if (tMethodSignature!=nil)
			{
				NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:tMethodSignature];
				
				if (tInvocation!=nil)
				{
					BOOL tResult;
					
					[tInvocation setTarget:self];
					
					[tInvocation setSelector:tSelector];
					
					[inArguments removeObjectAtIndex:0];
					
					[tInvocation setArgument:&inArguments atIndex:2];
					
					[tInvocation setArgument:&tPackageType atIndex:3];
					
					[tInvocation invoke];
					
					[tInvocation getReturnValue:&tResult];
					
					return tResult;
				}
			}
		}
		else
		{
			(void)fprintf(stderr, "%s: %s: not recognized.\n",__PACKAGESUTIL_NAME__,[[inArguments objectAtIndex:0] UTF8String]);
			
			usage_get_package();
		}
	}
	else
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_package();
	}
	
	return NO;
}

#pragma mark - Project Getters -

- (BOOL)getProjectName:(NSMutableArray *) inArguments
{
	if ([inArguments count]!=0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_project();
	
		return NO;
	}
	
	PKGProjectSettings * tProjectSettings=_project.settings;
	
	if (tProjectSettings==nil)
	{
		(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	NSString * tProjectName=tProjectSettings.name;
	
	if (tProjectName==nil)
	{
		(void)fprintf(stderr, "%s: Missing project name\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	(void)fprintf(stdout, "%s\n",[tProjectName UTF8String]);
		
	return YES;
}
	
- (BOOL)getProjectBuild_Format:(NSMutableArray *) inArguments
{
	if ([inArguments count]!=0)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_project();
	
		return NO;
	}
	
	switch(_projectType)
	{
		case PKGProjectTypePackage:
			
			(void)fprintf(stdout, "flat\n");
			return YES;
		
		case PKGProjectTypeDistribution:
		{
			PKGDistributionProjectSettings * tProjectSettings=(PKGDistributionProjectSettings *)_project.settings;
			
			if (tProjectSettings==nil)
			{
				(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
				return NO;
			}
			
			switch(tProjectSettings.buildFormat)
			{
				case PKGProjectBuildFormatFlat:
					
					(void)fprintf(stdout, "flat\n");
					return YES;
					
				case PKGProjectBuildFormatBundle:
					
					(void)fprintf(stdout, "bundle\n");
					return YES;
			}
		}
	}
	
	return NO;
}

- (BOOL)getProjectBuild_Folder:(NSMutableArray *) inArguments
{
	if ([inArguments count]>=2)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_project();
		
		return NO;
	}
	
	PKGProjectSettings * tProjectSettings=_project.settings;
	
	if (tProjectSettings==nil)
	{
		(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([self getPathWithArguments:inArguments
					  fromFilePath:tProjectSettings.buildPath]==YES)
		return YES;
		
	usage_get_project();
	
	return NO;
}

- (BOOL)getProjectCertificate_Keychain:(NSMutableArray *) inArguments
{
	if ([inArguments count]!=0)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_project();
		
		return NO;
	}

	if (_projectType==PKGProjectTypeDistribution)
	{
		PKGDistributionProjectSettings * tProjectSettings=(PKGDistributionProjectSettings *)((PKGDistributionProject *)_project).settings;
		
		if (tProjectSettings==nil)
		{
			(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
		
		if (tProjectSettings.buildFormat==PKGProjectBuildFormatBundle);
		{
			// Bundle
			
			(void)fprintf(stderr, "%s: Bundle distributions can not be signed with a certificate.\n",__PACKAGESUTIL_NAME__);
			
			return NO;
		}
	}
	
	PKGProjectSettings * tProjectSettings=_project.settings;
	
	if (tProjectSettings==nil)
	{
		(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([tProjectSettings.certificateKeychainPath length]==0)
	{
		(void)fprintf(stderr, "No keychain path set for this project.\n");
		return YES;
	}
	
	(void)fprintf(stdout, "%s\n",[tProjectSettings.certificateKeychainPath UTF8String]);

	return YES;
}

- (BOOL)getProjectCertificate_Identity:(NSMutableArray *) inArguments
{
	if ([inArguments count]!=0)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_project();
		
		return NO;
	}
	
	if (_projectType==PKGProjectTypeDistribution)
	{
		PKGDistributionProjectSettings * tProjectSettings=(PKGDistributionProjectSettings *)((PKGDistributionProject *)_project).settings;
		
		if (tProjectSettings==nil)
		{
			(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
		
		if (tProjectSettings.buildFormat==PKGProjectBuildFormatBundle);
		{
			// Bundle
			
			(void)fprintf(stderr, "%s: Bundle distributions can not be signed with a certificate.\n",__PACKAGESUTIL_NAME__);
			return NO;
		}
	}
	
	PKGProjectSettings * tProjectSettings=_project.settings;
	
	if (tProjectSettings==nil)
	{
		(void)fprintf(stderr, "%s: Missing project settings\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([tProjectSettings.certificateName length]==0)
	{
		(void)fprintf(stderr, "No signing identity set for this project.\n");
		return YES;
	}
	
	(void)fprintf(stdout, "%s\n",[tProjectSettings.certificateName UTF8String]);
	
	return YES;
}

- (BOOL)getProjectPackages:(NSMutableArray *) inArguments
{
	if (_projectType==PKGProjectTypePackage)
	{
		(void)fprintf(stderr, "%s: Raw package projects do not embed packages.\n",__PACKAGESUTIL_NAME__);
		return NO;
	}
	
	if ([inArguments count]!=1)
	{
		// Too many arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_project();
	
		return NO;
	}
	
	NSArray * tPackageComponents=((PKGDistributionProject *)_project).packageComponents;
	
	NSString * tArgument=[inArguments objectAtIndex:0];
	
	if ([tArgument isEqualToString:@"count"]==YES)
	{
		(void)fprintf(stdout, "%lu\n",(unsigned long)[tPackageComponents count]);
	}
	else if ([tArgument isEqualToString:@"list"]==YES)
	{
		for(PKGPackageComponent * tPackageComponent in tPackageComponents)
		{
			PKGPackageSettings * tPackageSettings=tPackageComponent.packageSettings;
			NSString * tPackageName=nil;
			
			if (tPackageSettings!=nil)
				tPackageName=tPackageSettings.name;
			
			if ([tPackageName length]>0)
			{
				(void)fprintf(stdout, "%s\n",[tPackageName UTF8String]);
			}
			else
			{
				(void)fprintf(stdout, "\n");
			}
		}
	}
	else
	{
		return NO;
	}
	
	return YES;
}

- (BOOL)getProjectValue:(NSMutableArray *) inArguments
{
	if ([inArguments count]==0)
	{
		// Invalid number of arguments
		
		(void)fprintf(stderr, "%s: Invalid number of arguments.\n",__PACKAGESUTIL_NAME__);
		
		usage_get_project();
		
		return NO;
	}
	
	NSString * tObject=[inArguments objectAtIndex:0];
	
	// Build the method suffix
	
	NSArray * tComponents=[tObject componentsSeparatedByString:@"-"];
	
	if ([tComponents count]>1)
	{
		NSMutableArray * tMutableComponents=[NSMutableArray arrayWithCapacity:[tComponents count]];
		
		if (tMutableComponents!=nil)
		{
			for(NSString * tComponent in tComponents)
				[tMutableComponents addObject:[tComponent capitalizedString]];
			
			tObject=[tMutableComponents componentsJoinedByString:@"_"];
		}
	}
	else
	{
		tObject=[tObject capitalizedString];
	}

	NSString * tMethodName=[NSString stringWithFormat:@"getProject%@:",tObject];
	
	SEL tSelector=NSSelectorFromString(tMethodName);
	
	if ([self respondsToSelector:tSelector]==NO)
	{
		(void)fprintf(stderr, "%s: %s: not recognized.\n",__PACKAGESUTIL_NAME__,[[inArguments objectAtIndex:0] UTF8String]);
		
		usage_get_project();
		
		return NO;
	}
	
	NSMethodSignature * tMethodSignature=[self methodSignatureForSelector:tSelector];
	
	if (tMethodSignature!=nil)
	{
		NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:tMethodSignature];
		
		if (tInvocation!=nil)
		{
			BOOL tResult;
			
			[tInvocation setTarget:self];
			
			[tInvocation setSelector:tSelector];
			
			[inArguments removeObjectAtIndex:0];

			[tInvocation setArgument:&inArguments atIndex:2];
			
			[tInvocation invoke];
			
			[tInvocation getReturnValue:&tResult];
			
			return tResult;
		}
	}
	
	return NO;
}

- (BOOL)getValue:(NSMutableArray *) inArguments forFileAtPath:(NSString *) inPath
{
	BOOL tResult=NO;
	
	_projectType=-1;
	
	if (inPath!=nil && _helpRequired==NO)
	{
		NSError * tError=nil;
		
		_project=[PKGProject projectWithContentsOfFile:inPath error:&tError];
		
		if (_project==nil)
		{
			if ([tError.domain isEqualToString:PKGPackagesModelErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case PKGRepresentationInvalidTypeOfValueError:
						
						(void)fprintf(stderr, "%s: %s: Invalid type for value: %s\n",__PACKAGESUTIL_NAME__,[inPath fileSystemRepresentation],[tError.userInfo[PKGKeyPathErrorKey] UTF8String]);
						break;
						
					case PKGRepresentationInvalidValue:
						
						(void)fprintf(stderr, "%s: %s: Invalid value for %s\n",__PACKAGESUTIL_NAME__,[inPath fileSystemRepresentation],[tError.userInfo[PKGKeyPathErrorKey] UTF8String]);
						break;
				}
			}
			
			return NO;
		}
		
		_projectType=_project.type;
		
		_filePath=inPath;
	}
	
	if (_projectType==PKGProjectTypePackage)
	{
		_currentObject=_project;
		
		if ([inArguments count]>0 && [[inArguments objectAtIndex:0] isEqualToString:@"project"]==YES)
		{
			[inArguments removeObjectAtIndex:0];
			
			tResult=[self getProjectValue:inArguments];
		}
		else
		{
			tResult=[self getPackageValue:inArguments];
		}
	}
	else if (_projectType==PKGProjectTypeDistribution)
	{
		// Check if we are targeting the package
		
		if ([inArguments count]>0)
		{
			NSString * tComponent=[inArguments objectAtIndex:0];
			
			if ([tComponent isEqualToString:@"project"]==YES)
			{
				_currentObject=_project;
				
				[inArguments removeObjectAtIndex:0];
				
				tResult=[self getProjectValue:inArguments];
			}
			else
			{
				if ([tComponent hasPrefix:@"package-"]==YES)
				{
					// Search Package by Index
					
					NSString * tIndexString=[tComponent substringFromIndex:8];
					
					NSUInteger tIndex=[tIndexString integerValue];
					
					if (tIndex>0)
					{
						NSArray * tPackageComponents=((PKGDistributionProject *)_project).packageComponents;
						
						if ([tPackageComponents count]<tIndex)
						{
							(void)fprintf(stderr, "%s: %s: No package at index %d\n",__PACKAGESUTIL_NAME__,[inPath fileSystemRepresentation],(int) tIndex);
							return NO;
						}
						
						_currentObject=tPackageComponents[tIndex-1];
						
						[inArguments removeObjectAtIndex:0];
						
						tResult=[self getPackageValue:inArguments];
					}
				}
				else
				{
					if ([tComponent isEqualToString:@"package"]==YES)
					{
						[inArguments removeObjectAtIndex:0];
						
						if ([inArguments count]>0)
							tComponent=[inArguments objectAtIndex:0];
					}
					
					// Search Package by Identifier
					
					_currentObject=[((PKGDistributionProject *)_project) packageComponentWithIdentifier:tComponent];
					
					if (_currentObject==nil)
					{
						(void)fprintf(stderr, "%s: %s: No package with identifier \"%s\" found\n",__PACKAGESUTIL_NAME__,[inPath fileSystemRepresentation],[tComponent UTF8String]);
						return NO;
					}
					
					[inArguments removeObjectAtIndex:0];
					
					tResult=[self getPackageValue:inArguments];
				}
			}
		}
		else
		{
			// Missing arguments
			
			usage_get();
		}
	}
	else if (_helpRequired==YES)
	{
		if ([inArguments count]==0)
		{
			usage_get();
			
			return YES;
		}
		
		NSString * tComponent=[inArguments objectAtIndex:0];
		
		if ([tComponent isEqualToString:@"project"]==YES)
		{
			usage_get_project();
			
			return YES;
		}
		
		if ([tComponent isEqualToString:@"package"]==YES)
		{
			usage_get_package();
			
			return YES;
		}
		
		return NO;
	}
	
	return tResult;
}

@end
