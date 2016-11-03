/*
Copyright (c) 2004-2016, Stéphane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGCommandLineBuildObserver.h"

#import "PKGBuildNotificationCenter.h"

#import "PKGBuildEvent.h"

#include <time.h>

@interface PKGCommandLineBuildObserver ()
{
	time_t _startTime;
	
	BOOL _buildDistribution;
	
	BOOL _warningSeenDuringStep;
	
	NSString * _currentPackageName;
}

- (void)printStepPath:(NSIndexPath *)inStepPath;

@end

@implementation PKGCommandLineBuildObserver

- (void)printStepPath:(NSIndexPath *)inStepPath
{
	if (inStepPath==nil)
		return;
	
	(void)fprintf(stdout, "\nStep:\n\n");
	
	NSUInteger tLength=inStepPath.length;
	
	if (tLength>0)
	{
		for(NSUInteger tPosition=0;tPosition<tLength;tPosition++)
		{
			PKGBuildStep tBuildStep=[inStepPath indexAtPosition:tPosition];
			
			if (tPosition>0)
				(void)fprintf(stdout, " > ");
			
			switch(tBuildStep)
			{
				case PKGBuildStepProject:
					
					(void)fprintf(stdout, "Project");
					break;
			
				case PKGBuildStepDistribution:
					
					(void)fprintf(stdout, "Distribution");
					break;
					
				case PKGBuildStepPackage:
					
					(void)fprintf(stdout, "Package");
					break;
				
				case PKGBuildStepProjectBuildFolder:
					
					(void)fprintf(stdout, "Build Folder");
					break;
					
				case PKGBuildStepProjectClean:
					
					(void)fprintf(stdout, "Clean");
					break;
					
				case PKGBuildStepDistributionBackgroundImage:
					
					(void)fprintf(stdout, "Background");
					break;
					
				case PKGBuildStepDistributionWelcomeMessage:
					
					(void)fprintf(stdout, "Introduction");
					break;
					
				case PKGBuildStepDistributionReadMeMessage:
					
					(void)fprintf(stdout, "ReadMe");
					break;
					
				case PKGBuildStepDistributionLicenseMessage:
					
					(void)fprintf(stdout, "License");
					break;
					
				case PKGBuildStepDistributionConclusionMessage:
					
					(void)fprintf(stdout, "Conclusion");
					break;
					
				case PKGBuildStepDistributionScript:
					
					(void)fprintf(stdout, "Definition");
					break;
					
				case PKGBuildStepDistributionChoicesHierarchies:
					
					(void)fprintf(stdout, "Choices Hierarchies");
					break;
					
				case PKGBuildStepDistributionInstallationRequirements:
					
					(void)fprintf(stdout, "Installation|Volume Requirements");
					break;
					
				case PKGBuildStepDistributionJavaScript:
					
					(void)fprintf(stdout, "JavaScript Scripts");
					break;
					
				case PKGBuildStepDistributionResources:
					
					(void)fprintf(stdout, "Resources");
					break;
					
				case PKGBuildStepDistributionScripts:
					
					(void)fprintf(stdout, "Scripts");
					break;
					
				case PKGBuildStepDistributionInstallerPlugins:
					
					(void)fprintf(stdout, "Plugins");
					break;
					
				case PKGBuildStepPackageCreate:
				case PKGBuildStepPackageReference:
				case PKGBuildStepPackageImport:
					
					(void)fprintf(stdout, "Package");
					
					if (_currentPackageName!=nil)
						(void)fprintf(stdout, " '%s'",[_currentPackageName UTF8String]);
					
					break;
			
				case PKGBuildStepPackageInfo:
					
					(void)fprintf(stdout, "PackageInfo");
					break;
					
				case PKGBuildStepPackagePayload:
					
					(void)fprintf(stdout, "Payload");
					break;
				
				case PKGBuildStepScriptsPayload:
					
					(void)fprintf(stdout, "Scripts");
					break;
					
				case PKGBuildStepPayloadAssemble:
					
					(void)fprintf(stdout, "Assemble");
					break;
					
				case PKGBuildStepPayloadSplit:
					
					(void)fprintf(stdout, "Split Forks");
					break;
					
				case PKGBuildStepPayloadBom:
					
					(void)fprintf(stdout, "Bom");
					break;
					
				case PKGBuildStepPayloadPax:
					
					(void)fprintf(stdout, "Pax");
					break;
					
				default:
					break;
			}
		}
	}
	
	(void)fprintf(stdout, "\n");
}

- (void)processBuildEventNotification:(NSNotification *)inNotification
{
	if (inNotification==nil)
		return;
	
	NSDictionary * tUserInfo=[inNotification userInfo];
	
	if (tUserInfo==nil)
		return;
	
	NSNumber * tNumber=tUserInfo[PKGBuildStepKey];
	
	if ([tNumber isKindOfClass:[NSNumber class]]==NO)
		return;
	
	PKGBuildStep tStep=[tNumber unsignedIntegerValue];
	
	NSIndexPath * tStepPath=tUserInfo[PKGBuildStepPathKey];
	
	if ([tStepPath isKindOfClass:[NSIndexPath class]]==NO)
		return;
	
	
	tNumber=tUserInfo[PKGBuildStateKey];
	
	if ([tNumber isKindOfClass:[NSNumber class]]==NO)
		return;
	
	PKGBuildStepState tState=[tNumber unsignedIntegerValue];
	
	
	NSDictionary * tRepresentation=tUserInfo[PKGBuildStepEventRepresentationKey];
	
	if (tRepresentation!=nil && [tRepresentation isKindOfClass:[NSDictionary class]]==NO)
		return;
	
	const char * (^fileItemTypeName)(PKGBuildErrorFileKind)=^const char *(PKGBuildErrorFileKind bFileKind)
	{
		switch(bFileKind)
		{
			case PKGFileKindRegularFile:
				
				return "file";
				
			case PKGFileKindFolder:
				
				return "folder";
				
			case PKGFileKindPlugin:
				
				return "plugin";
				
			case PKGFileKindTool:
				
				return "tool";
				
			case PKGFileKindPackage:
				
				return "package";
		}
		
		return NULL;
	};
	
	
	if (tState==PKGBuildStepStateFailure)
	{
		if (self.verbose==YES)
			(void)fprintf(stdout, "\n\n");
		
		(void)fprintf(stdout, "==============================================================================\n");
		
		(void)fprintf(stdout, "ERROR:\n");
		
		PKGBuildError tFailureReason=PKGBuildErrorUnknown;
		
		PKGBuildErrorEvent * tErrorEvent=[[PKGBuildErrorEvent alloc] initWithRepresentation:tRepresentation];
		
		if (tErrorEvent!=nil)
		{
			tFailureReason=tErrorEvent.code;
		}
		
		(void)fprintf(stdout, "\nDescription:\n\n");
		
		if (tFailureReason==PKGBuildErrorUnknown)
		{
			(void)fprintf(stdout, "Unknow Error\n");
		}
		else if (tFailureReason==PKGBuildErrorOutOfMemory)
		{
			(void)fprintf(stdout, "Not enough memory to perform operation.\n");
		}
		else
		{
			NSString * tTag=tErrorEvent.tag;
			
			NSString * tFilePath=tErrorEvent.filePath;
			PKGBuildErrorFileKind tFileKind=tErrorEvent.fileKind;
			
			NSString * tTitle=nil;
			
			switch(tFailureReason)
			{
				case PKGBuildErrorMissingInformation:
					
					if ([tTag isEqualToString:@"ICDOCUMENT_PACKAGE_SETTINGS_LOCATION_PATH"]==YES)
						tTitle=@"The location of the referenced package has not been fully defined.";
					else
						tTitle=[NSString stringWithFormat:@"Missing information for tag '%@'",tTag];
					
					(void)fprintf(stdout, "%s",[tTitle UTF8String]);
					break;
					
				case PKGBuildErrorMissingBuildData:
				
					(void)fprintf(stdout, "Missing build data for tag '%s'\n",[tTag UTF8String]);
					break;
					
				case PKGBuildErrorIncorrectValue:
					
					(void)fprintf(stdout, "Incorrect value for object with tag '%s'\n",[tTag UTF8String]);
					break;
					
				case PKGBuildErrorFileIncorrectType:
					
					(void)fprintf(stdout, "Incorrect type for file at path \"%s\"",[[tFilePath lastPathComponent] UTF8String]);
					break;
				
				case PKGBuildErrorFileAbsolutePathCanNotBeComputed:
					
					(void)fprintf(stdout, "An absolute path can not be computed from path \"%s\"",[[tFilePath lastPathComponent] UTF8String]);
					break;
					
				case PKGBuildErrorFilePosixPermissionsCanNotBeSet:
					
					(void)fprintf(stdout, "Insufficient privileges to set permissions for path \"%s\"",[[tFilePath lastPathComponent] UTF8String]);
					break;
				
				case PKGBuildErrorFileAccountsCanNotBeSet:
					
					(void)fprintf(stdout, "Insufficient privileges to set accounts for path \"%s\"",[[tFilePath lastPathComponent] UTF8String]);
					break;
				
				case PKGBuildErrorFileAttributesCanNotBeRead:
					
					(void)fprintf(stdout, "Unable to read attributes of item at path \"%s\"",[[tFilePath lastPathComponent] UTF8String]);
					break;
					
				case PKGBuildErrorFileAttributesCanNotBeSet:
					
					(void)fprintf(stdout, "Unable to set attributes of item at path \"%s\"",[[tFilePath lastPathComponent] UTF8String]);
					break;
					
				case PKGBuildErrorFileExtendedAttributesCanNotBeRead:
					
					(void)fprintf(stdout, "Unable to read exteneded attributes of item at path \"%s\"",[[tFilePath lastPathComponent] UTF8String]);
					break;
				
				case PKGBuildErrorFileExtendedAttributesCanNotBeSet:
					
					(void)fprintf(stdout, "Unable to set extended attributes of item at path \"%s\"",[[tFilePath lastPathComponent] UTF8String]);
					break;
					
				case PKGBuildErrorExternalToolFailure:
					
					(void)fprintf(stdout, "%s returned error code '%d'",[[tFilePath lastPathComponent] UTF8String],tErrorEvent.toolTerminationStatus);
					break;
					
				case PKGBuildErrorExternalToolFailureSplitForkNonHFSVolume:
					
					(void)fprintf(stdout, "The Temporary Build Path is on a non HFS volume");
					break;
					
				case PKGBuildErrorLicenseTemplateNotFound:
					
					(void)fprintf(stdout, "License template for \"%s\" can not be found",[tTag UTF8String]);
					break;
				
				case PKGBuildErrorBundleIdentifierNotFound:
					
					(void)fprintf(stdout, "No identifier could be found for bundle at path '%s'",[[tFilePath lastPathComponent] UTF8String]);
					break;
					
				case  PKGBuildErrorUnknownLanguage:
					
					(void)fprintf(stdout, "Language(%s) not supported",[tTag UTF8String]);
					break;
					
				/*case IC_BUILDER_FAILURE_REASON_PACKAGE_SAME_NAME:
					
					// A COMPLETER
					
					break;*/
				
				case PKGBuildErrorEmptyString:
					
					tTitle=nil;
					
					if (tStep==PKGBuildStepPackageInfo)
					{
						if ([tTag isEqualToString:@"ICDOCUMENT_PACKAGE_SETTINGS_IDENTIFIER"]==YES)
							tTitle=@"The identifier of the package can not be empty.";
						else if ([tTag isEqualToString:@"ICDOCUMENT_PACKAGE_SETTINGS_VERSION"]==YES)
							tTitle=@"The version of the package can not be empty.";
					}
					else if (tStep==PKGBuildStepDistribution)
					{
						if ([tTag isEqualToString:@"ICDOCUMENT_PROJECT_SETTINGS_NAME"]==YES)
							tTitle=@"The name of the project can not be empty.";
						
					}
					else if (tStep==PKGBuildStepPackageCreate)
					{
						if ([tTag isEqualToString:@"ICDOCUMENT_PACKAGE_SETTINGS_NAME"]==YES)
							tTitle=@"The name of the package can not be empty.";
					}
					else
					{
						if ([tTag isEqualToString:@"ICDOCUMENT_PACKAGE_SETTINGS_LOCATION_PATH"]==YES)
							tTitle=@"The location of the referenced package has not been fully defined.";
					}
					
					if (tTitle==nil)
						tTitle=[NSString stringWithFormat:@"String can not be empty for tag '%@'",tTag];
					
					(void)fprintf(stdout, "%s",[tTitle UTF8String]);
					break;
					
				case PKGBuildErrorRequirementMissingConverter:
					
					(void)fprintf(stdout, "Converter not found for requirement of type '%s'",[tTag UTF8String]);
					break;
					
				case PKGBuildErrorRequirementMissingCode:
					
					(void)fprintf(stdout, "No code generated for requirement of type '%s'",[tTag UTF8String]);
					break;
					
				case PKGBuildErrorLocatorMissingConverter:
					
					(void)fprintf(stdout, "Converter not found for locator of type '%s'",[tTag UTF8String]);
					break;
					
				case PKGBuildErrorLocatorConversionError:
					
					(void)fprintf(stdout, "No code generated for locator of type '%s'",[tTag UTF8String]);
					break;
					
				case PKGBuildErrorFileNotFound:
					
					tTitle=nil;
					
					if (tStep==PKGBuildStepPackageImport)
					{
						if (tTag!=nil)
						{
							if ([tTag isEqualToString:@"ICDOCUMENT_PACKAGE_REFERENCE_PATH"]==YES)
								tTitle=[NSString stringWithFormat:@"Unable to find package at path '%@'",tFilePath];
						}
					}
					
					if (tTitle==nil)
						tTitle=[NSString stringWithFormat:@"Unable to find %s '%@'",fileItemTypeName(tFileKind),[tFilePath lastPathComponent]];
					
					(void)fprintf(stdout, "%s",[tTitle UTF8String]);
					
					break;
					
				case PKGBuildErrorFileCanNotBeCreated:
					
					if ([tFilePath isEqualToString:@"Scratch_Location"]==NO)
						(void)fprintf(stdout, "Unable to create %s at path '%s'",fileItemTypeName(tFileKind),[tFilePath UTF8String]);
					else
						(void)fprintf(stdout, "Unable to create scratch location folder");
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorNoMoreSpaceOnVolume:
							
							(void)fprintf(stdout, " because there's no space left on disk");
							break;
							
						case PKGBuildErrorReadOnlyVolume:
							
							(void)fprintf(stdout, " because the disk is read only");
							break;
							
						case PKGBuildErrorWriteNoPermission:
							
							(void)fprintf(stdout, " because you don't have permission to create it in the folder ");
							
							if ([tFilePath isEqualToString:@"Scratch_Location"]==YES)
								(void)fprintf(stdout, "\'/tmp/private/\'");
							else
								(void)fprintf(stdout, "\'%s\'",[[[tFilePath stringByDeletingLastPathComponent] lastPathComponent] UTF8String]);
							
							break;
						
						default:
							break;
					}
					
					(void)fprintf(stdout, "\n");
					
					break;
					
				case PKGBuildErrorFileCanNotBeCopied:
					
					(void)fprintf(stdout, "Unable to copy item at path '%s'",[tFilePath UTF8String]);
					
					if (tErrorEvent.otherFilePath!=nil)
						(void)fprintf(stdout, " to '%s'",[tErrorEvent.otherFilePath UTF8String]);
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorFileNotFound:
							(void)fprintf(stdout, " because the item could not be found");
							break;
						
						case PKGBuildErrorNoMoreSpaceOnVolume:
						
							(void)fprintf(stdout, " because there's no space left on disk");
							break;
						
						case PKGBuildErrorReadOnlyVolume:
						
							(void)fprintf(stdout, " because the disk is read only");
							break;
						
						case PKGBuildErrorWriteNoPermission:
							
							(void)fprintf(stdout, " because you don't have permission to create it to the folder \'%s\'",[[[tFilePath stringByDeletingLastPathComponent] lastPathComponent] UTF8String]);
							break;
							
						default:
							break;
					}
					
					(void)fprintf(stdout, "\n");
					
					break;
					
				case PKGBuildErrorFileCanNotBeDeleted:
					
					(void)fprintf(stdout, "Unable to remove %s at path '%s'",fileItemTypeName(tFileKind),[tFilePath UTF8String]);
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorReadOnlyVolume:
							
							(void)fprintf(stdout, " because the disk is read only");
							break;
							
						case PKGBuildErrorWriteNoPermission:
							
							(void)fprintf(stdout, " because you don't have permission to access it");
							break;
							
						default:
							break;
					}
					
					(void)fprintf(stdout, "\n");
					
					break;
					
				case PKGBuildErrorSigningUnknown:
					
					(void)fprintf(stdout, "Unable to sign the data");
					break;
					
				case PKGBuildErrorSigningTimeOut:
					
					(void)fprintf(stdout, "Signing operation timed out");
					break;
					
				case PKGBuildErrorSigningAuthorizationDenied:
					
					(void)fprintf(stdout, "Signing operation denied");
					break;
					
				case PKGBuildErrorSigningCertificateNotFound:
					
					(void)fprintf(stdout, "Unable to find signing certificate");
					break;
					
				default:
					
					// A COMPLETER
					
					break;
			}
		}
		
		
		if (self.verbose==NO)
			[self printStepPath:tStepPath];
		
		(void)fprintf(stdout, "\n==============================================================================");
		
		(void)fprintf(stdout, "\nBuild Failed\n");
		
		exit(1);
	}
	
	if (tState==PKGBuildStepStateWarning)
	{
		_warningSeenDuringStep=YES;
		
		(void)fprintf(stdout, "\nWARNING: ");
		
		PKGBuildError tFailureReason=PKGBuildErrorUnknown;
		
		PKGBuildErrorEvent * tErrorEvent=[[PKGBuildErrorEvent alloc] initWithRepresentation:tRepresentation];
		
		if (tErrorEvent!=nil)
			tFailureReason=tErrorEvent.code;
		
		if (tFailureReason==PKGBuildErrorUnknown)
		{
			(void)fprintf(stdout, "Unknow Warning\n");
		}
		else
		{
			NSString * tTag=tErrorEvent.tag;
			
			NSString * tFilePath=tErrorEvent.filePath;
			PKGBuildErrorFileKind tFileKind=tErrorEvent.fileKind;
			
			NSString * tTitle=nil;
			
			switch(tFailureReason)
			{
				case PKGBuildErrorFileNotFound:
					
					tTitle=nil;
					
					if (tStep==PKGBuildStepPackageImport && tTag!=nil)
					{
						if ([tTag isEqualToString:@"ICDOCUMENT_PACKAGE_REFERENCE_PATH"]==YES)
							tTitle=[NSString stringWithFormat:@"Unable to find package at path '%@'\n",tFilePath];
					}
					
					if (tTitle==nil)
						tTitle=[NSString stringWithFormat:@"Unable to find %s at path '%@'\n",fileItemTypeName(tErrorEvent.fileKind),tFilePath];
					
					(void)fprintf(stdout, "%s",[tTitle UTF8String]);
					
					break;
					
				case PKGBuildErrorFileCanNotBeCopied:
					
					(void)fprintf(stdout, "Unable to copy item at path '%s'",[tFilePath UTF8String]);
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorFileNotFound:
							
							(void)fprintf(stdout, " because the item could not be found");
							break;
							
						default:
							break;
					}
					
					(void)fprintf(stdout, "\n");
					
					break;
					
				case PKGBuildErrorFileCanNotBeDeleted:
					
					(void)fprintf(stdout, "Unable to remove %s at path '%s'",fileItemTypeName(tFileKind),[tFilePath UTF8String]);
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorReadOnlyVolume:
							
							(void)fprintf(stdout, " because the disk is read only");
							break;
							
						case PKGBuildErrorWriteNoPermission:
							
							(void)fprintf(stdout, " because you don't have permission to access it");
							break;
							
						default:
							break;
					}
					
					(void)fprintf(stdout, "\n");
					
					break;
					
				default:
					
					// A COMPLETER
					
					break;
			}
		}
	
		if (self.verbose==NO)
			[self printStepPath:tStepPath];
	
		return;
	}

	PKGBuildInfoEvent * tInfoEvent=[[PKGBuildInfoEvent alloc] initWithRepresentation:tRepresentation];
	
	// Step

	if (tState==PKGBuildStepStateBegin)
		_warningSeenDuringStep=NO;
	
	char * tStateString="";
	char * tOffsetString="";
	
	if (tState==PKGBuildStepStateSuccess)
		tStateString=" (Completed)";
	
	if (_buildDistribution==YES)
		tOffsetString="\t";
	
	if (tState==PKGBuildStepStateBegin)
	{
		switch(tStep)
		{
			case PKGBuildStepPackageCreate:
			case PKGBuildStepPackageReference:
			case PKGBuildStepPackageImport:
				
				_currentPackageName=tInfoEvent.packageName;
				break;
				
			default:
				break;
		}
	}

	if (self.verbose==YES)
	{
		switch(tStep)
		{
			case PKGBuildStepProject:
				
				if (tState==PKGBuildStepStateBegin)
				{
					_startTime=time(NULL);
					
					struct tm *tTimeStructure=localtime(&_startTime);
					
					NSString * tProjectPath=tInfoEvent.filePath;
					
					(void)fprintf(stdout, "Building Project (%02d:%02d:%02d) at path: %s \n",tTimeStructure->tm_hour,tTimeStructure->tm_min,tTimeStructure->tm_sec,[tProjectPath fileSystemRepresentation]);
					(void)fprintf(stdout, "------------------------------------------------------------------------------\n\n");
				}
				else
				{
					double tDiffTime=difftime(time(NULL),_startTime);
					
					(void)fprintf(stdout, "\n------------------------------------------------------------------------------\n");
					
					if (tDiffTime>=2.0)
					{
						(void)fprintf(stdout, "Build Successful (%g seconds)\n",tDiffTime);
					}
					else if (tDiffTime<1.0)
					{
						(void)fprintf(stdout, "Build Successful (less than a second)\n");
					}
					else
					{
						(void)fprintf(stdout, "Build Successful (1 second)\n");
					}
					
					exit(0);
				}
				
				break;
				
			case PKGBuildStepDistribution:
				
				if (tState==PKGBuildStepStateBegin)
				{
					_buildDistribution=YES;
					
					(void)fprintf(stdout, "Distribution\n\n");
				}
				
				break;
				
			case PKGBuildStepPackage:
				
				break;
				
			case PKGBuildStepProjectBuildFolder:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "Build Folder");
				else
					(void)fprintf(stdout, " (done)\n\n");
				
				break;
				
			case PKGBuildStepProjectClean:
				
				(void)fprintf(stdout, "\tClean%s\n",tStateString);
				break;
				
				
			case PKGBuildStepDistributionBackgroundImage:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\t\tBackground picture");
				else
					(void)fprintf(stdout, (_warningSeenDuringStep==NO) ? " (done)\n" : "\n\t\t(done)\n");
				
				break;
				
			case PKGBuildStepDistributionWelcomeMessage:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\t\tIntroduction");
				else
					(void)fprintf(stdout, (_warningSeenDuringStep==NO) ? " (done)\n" : "\n\t\t(done)\n");
				
				break;
				
			case PKGBuildStepDistributionReadMeMessage:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\t\tRead Me");
				else
					(void)fprintf(stdout, (_warningSeenDuringStep==NO) ? " (done)\n" : "\n\t\t(done)\n");
				
				break;
				
			case PKGBuildStepDistributionLicenseMessage:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\t\tLicense");
				else
					(void)fprintf(stdout, (_warningSeenDuringStep==NO) ? " (done)\n" : "\n\t\t(done)\n");
				
				break;
				
			case PKGBuildStepDistributionConclusionMessage:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\t\tConclusion");
				else
					(void)fprintf(stdout, (_warningSeenDuringStep==NO) ? " (done)\n" : "\n\t\t(done)\n");
				
				break;
				
			case PKGBuildStepDistributionScript:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\tDefinition\n\n");
				
				break;
				
			case PKGBuildStepDistributionChoicesHierarchies:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\t\tChoices hierarchies");
				else
					(void)fprintf(stdout, " (done)\n");
				
				break;
				
			case PKGBuildStepDistributionJavaScript:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\n\t\tJavaScript scripts");
				else
					(void)fprintf(stdout, " (done)\n");
				
				break;
				
			case PKGBuildStepDistributionInstallationRequirements:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\t\tInstallation|Volume requirements");
				else
					(void)fprintf(stdout, " (done)\n\n");
				
				break;
				
				
			case PKGBuildStepDistributionResources:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\n\tResources");
				else
					(void)fprintf(stdout, " (done)\n");
				
				break;
				
			case PKGBuildStepDistributionScripts:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "%s\tScripts\n\n",tOffsetString);
				else
					(void)fprintf(stdout, "%s\t\n",tOffsetString);

				break;
				
			case PKGBuildStepDistributionInstallerPlugins:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "\n\tPlugins");
				else
					(void)fprintf(stdout, " (done)\n");
				
				break;
			
			case PKGBuildStepPackageCreate:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "%sPackage \"%s\"\n\n",tOffsetString,[_currentPackageName UTF8String]);
				else
					(void)fprintf(stdout, "\n%s----------------------------------------------\n\n",tOffsetString);

				break;
				
			case PKGBuildStepPackageReference:
				
				if (tState==PKGBuildStepStateBegin)
				{
					(void)fprintf(stdout, "%sPackage \"%s\"\n\n",tOffsetString,[_currentPackageName UTF8String]);
					(void)fprintf(stdout, "%s\tReference package",tOffsetString);
				}
				else
				{
					(void)fprintf(stdout, " (done)\n");
					
					(void)fprintf(stdout, "\n%s----------------------------------------------\n\n",tOffsetString);
				}
				
				break;
				
				break;
				
			case PKGBuildStepPackageImport:
				
				if (tState==PKGBuildStepStateBegin)
				{
					(void)fprintf(stdout, "%sPackage \"%s\"\n\n",tOffsetString,[_currentPackageName UTF8String]);
					(void)fprintf(stdout, "%s\tCopy imported package",tOffsetString);
				}
				else
				{
					(void)fprintf(stdout, " (done)\n");
					
					(void)fprintf(stdout, "\n%s----------------------------------------------\n\n",tOffsetString);
				}
				
				break;
				
			case PKGBuildStepPackageInfo:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "%s\tPackageInfo",tOffsetString);
				else
					(void)fprintf(stdout, " (done)\n");
				
				break;
				
			case PKGBuildStepPackagePayload:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "%s\tPayload\n\n",tOffsetString);
				else
					(void)fprintf(stdout, "%s\t\n",tOffsetString);

				break;
				
			case PKGBuildStepScriptsPayload:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "%s\tScripts\n\n",tOffsetString);
				else
					(void)fprintf(stdout, "%s\t\n",tOffsetString);

				break;
				
			case PKGBuildStepPayloadAssemble:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "%s\t\tAssemble file hierarchy",tOffsetString);
				else
					(void)fprintf(stdout, " (done)\n");
				
				break;
				
			case PKGBuildStepPayloadSplit:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "%s\t\tSplit forks",tOffsetString);
				else
					(void)fprintf(stdout, " (done)\n");
				
				break;
				
			case PKGBuildStepPayloadBom:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "%s\t\tCreate bill of material",tOffsetString);
				else
					(void)fprintf(stdout, " (done)\n");
				
				break;
				
			case PKGBuildStepPayloadPax:
				
				if (tState==PKGBuildStepStateBegin)
					(void)fprintf(stdout, "%s\t\tCreate pax archive",tOffsetString);
				else
					(void)fprintf(stdout, " (done)\n");
				
				break;
				
			default:
				break;
		}
	}
	else
	{
		if (tStep==PKGBuildStepProject)
		{
			if (tState==PKGBuildStepStateSuccess)
			{
				double tDiffTime=difftime(time(NULL),_startTime);
				
				if (tDiffTime>=2.0)
				{
					(void)fprintf(stdout, "Build Successful (%g seconds)\n",tDiffTime);
				}
				else if (tDiffTime<1.0)
				{
					(void)fprintf(stdout, "Build Successful (less than a second)\n");
				}
				else
				{
					(void)fprintf(stdout, "Build Successful (1 second)\n");
				}
				
				exit(0);
			}
			
			_startTime=time(NULL);	// Necessarily state begin
		}
	}
	
	if (tState==PKGBuildStepStateSuccess)
		_warningSeenDuringStep=NO;
}

- (void)processBuildDebugNotification:(NSNotification *)inNotification
{
	NSDictionary * tUserInfo=[inNotification userInfo];
	
	NSLog(@"DEBUG_DATA: %@",tUserInfo[PKGBuildStepEventRepresentationKey]);
}

@end
