/*
 Copyright (c) 2008-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGQuickBuildDocument.h"

#import "PKGQuickBuildFeedbackWindowController.h"

#import "PKGApplicationController.h"
#import "PKGApplicationPreferences.h"

#import "PKGSmartLocationDetector.h"

#import "PKGPackageProject.h"
#import "PKGPackageProject+Safe.h"
#import "PKGPayloadTreeNode+UI.h"

#import "PKGBuildOrderManager.h"
#import "PKGBuildOrder.h"

#include <sys/stat.h>
#include <unistd.h>

@interface PKGQuickBuildDocument ()
{
	NSUUID * _UUID;
	
	NSURL * _temporaryProjectURL;
}

- (void)delayedBuild:(NSString *)inPath;

// Notifications

- (void)processBuildEventNotification:(NSNotification *)inNotification;

@end

@implementation PKGQuickBuildDocument

- (void)dealloc
{	
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)readFromURL:(NSURL *)inURL ofType:(NSString *)inType error:(NSError **)outError
{
	NSString * tPath=inURL.path;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:NSApp selector:@selector(terminate:) object:nil];
	
	if (tPath==nil)
	{
		// A COMPLETER
		
		return NO;
	}
	
	/* We only support bundles */
	
	NSBundle * tBundle=[NSBundle bundleWithPath:tPath];
	
	if (tBundle==nil)
	{
		// A COMPLETER
		
		return NO;
	}
	
	NSArray * tPotentialDirectories=[PKGSmartLocationDetector potentialInstallationDirectoriesForFileAtPath:tPath];

	if (tPotentialDirectories.count==0)
	{
		NSLog(@"No potential installation directories were found for \"%@\".",tPath);
		
		return NO;
	}
	
	NSDictionary * tInfoDictionary=tBundle.infoDictionary;
	
	PKGPackageProject * tRawPackageProject=[PKGPackageProject new];
	
	// Project Settings
	
	PKGPackageProjectSettings * tProjectSettings=(PKGPackageProjectSettings *)tRawPackageProject.settings;
	
		// Name
	
	NSString * tString=tInfoDictionary[@"CFBundleName"];
	
	if (tString.length==0)
	{
		tString=tInfoDictionary[@"CFBundleExecutable"];
		
		if (tString.length==0)
			tString=tPath.lastPathComponent.stringByDeletingPathExtension;
	}
	
	tProjectSettings.name=tString;
	
	_UUID=[NSUUID UUID];
	
	[[PKGQuickBuildFeedbackWindowController sharedController] addViewForUUID:_UUID fileName:[tString stringByAppendingPathExtension:@"pkg"]];
	
		// Build Path
					
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	NSString * tParentFolderPath=tPath.stringByDeletingLastPathComponent;
	
	if ([tFileManager isWritableFileAtPath:tParentFolderPath]==NO)
	{
		tParentFolderPath=[PKGApplicationPreferences sharedPreferences].failOverFolderForQuickBuild;
		
		if (tParentFolderPath!=nil)
		{
			BOOL isDirectory;
			
			tParentFolderPath=tParentFolderPath.stringByStandardizingPath;
			
			if (tParentFolderPath.length<1 ||
				[tFileManager fileExistsAtPath:tParentFolderPath isDirectory:&isDirectory]==NO ||
				isDirectory==NO ||
				[tFileManager isWritableFileAtPath:tParentFolderPath]==NO)
			{
				NSLog(@"Your custom quick build failover folder does not point to a writable folder. The package will be created in your hone directory.");
				
				tParentFolderPath=nil;
			}
		}
		
		if (tParentFolderPath==nil)
			tParentFolderPath=NSHomeDirectory();
	}
	
	tProjectSettings.buildPath=[PKGFilePath filePathWithAbsolutePath:tParentFolderPath];
	
		// Excluded files
	
	[tProjectSettings.filesFilters removeAllObjects];
	tProjectSettings.filterPayloadOnly=YES;

	// PACKAGE SETTINGS
	
	PKGPackageSettings * tPackageSettings=tRawPackageProject.packageSettings;
	
		// Identifier
						
	tString=tBundle.bundleIdentifier;
	
	if (tString.length==0)
	{
		NSLog(@"No bundle identifiers or empty one for bundle at path \"%@\".",tPath);
		
		return NO;
	}
	
	NSMutableArray * tIdentifierComponents=[[tString componentsSeparatedByString:@"."] mutableCopy];
		
	if (tIdentifierComponents.count>0)
		[tIdentifierComponents insertObject:@"qb-pkg" atIndex:tIdentifierComponents.count-1];
	
	tString=[tIdentifierComponents componentsJoinedByString:@"."];
	
	tPackageSettings.identifier=tString;
	
		// Version
						
	NSString * tPackageVersionString=nil;
	
	if ([PKGApplicationPreferences sharedPreferences].useBundleVersionForQuickBuild==YES)
		tPackageVersionString=tInfoDictionary[@"CFBundleShortVersionString"];
	
	if (tPackageVersionString.length==0)
		tPackageVersionString=@"1.0";
	
	tPackageSettings.version=tPackageVersionString;
	
		// Authentication
	
	tPackageSettings.authenticationMode=PKGPackageAuthenticationRoot;
						
		// Relocation
	
	tPackageSettings.relocatable=NO;
	
		// Overwrite permissions
	
	tPackageSettings.overwriteDirectoryPermissions=NO;
	
		// Follow Symbolic Links
						
	tPackageSettings.followSymbolicLinks=YES;
	
		// Conclusion
	
	tPackageSettings.conclusionAction=PKGPackageConclusionActionNone;
	
	
	// PACKAGE FILES
	
	PKGPackagePayload * tPackagePayload=[tRawPackageProject payload_safe];
	PKGPayloadTreeNode * tRootNode=tPackagePayload.filesTree.rootNode;
	
	PKGPayloadTreeNode * tFinalParentTreeNode=nil;
	
	NSString * tDirectory=nil;
	
	for(tDirectory in tPotentialDirectories)
	{
		PKGPayloadTreeNode * tPayloadTreeNode=[tRootNode descendantNodeAtPath:tDirectory];
		
		if (tPayloadTreeNode==nil)
		{
			if ([PKGSmartLocationDetector canCreateDirectoryPath:tDirectory]==YES)
			{
				tFinalParentTreeNode=[tRootNode createMissingDescendantsForPath:tDirectory];
				
				break;
			}
		}
		else
		{
			NSString * tLastPathComponent=tPath.lastPathComponent;
			
			if ([tPayloadTreeNode indexOfChildMatching:^BOOL(PKGPayloadTreeNode *bTreeNode){
				
				return ([tLastPathComponent caseInsensitiveCompare:bTreeNode.fileName]==NSOrderedSame);
				
			}]==NSNotFound)
			{
				tFinalParentTreeNode=tPayloadTreeNode;
				
				break;
			}
		}
	}
	
	if (tFinalParentTreeNode==nil)
	{
		// A COMPLETER
		
		return NO;
	}
	
	struct stat tStat;
	
	if (lstat([tPath fileSystemRepresentation], &tStat)!=0)
	{
		// A COMPLETER
		
		return NO;
	}
	
	PKGFileItem * tParentFileItem=[tFinalParentTreeNode representedObject];
	
	PKGFileItem * tFileItem=[[PKGFileItem alloc] initWithFilePath:[PKGFilePath filePathWithAbsolutePath:tPath]
															  uid:tParentFileItem.uid
															  gid:tParentFileItem.gid
													  permissions:(tStat.st_mode & ALLPERMS)];
	
	PKGPayloadTreeNode * tPayloadTreeNode=[[PKGPayloadTreeNode alloc] initWithRepresentedObject:tFileItem children:nil];
	
	[tFinalParentTreeNode addChild:tPayloadTreeNode];	// We don't care about the order as the project will not be presented to user
	
	
	// Save Temporary Project
	
	NSError * tError=nil;
	NSURL * tTemporaryFolderURL=[[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
																	   inDomain:NSUserDomainMask
															  appropriateForURL:[NSURL fileURLWithPath:tParentFolderPath]
																		 create:YES
																		  error:&tError];
	
	if (tTemporaryFolderURL==nil)
	{
		// A COMPLETER
		
		return NO;
	}
	
	_temporaryProjectURL=[tTemporaryFolderURL URLByAppendingPathComponent:@"temp_proj.pkgproj"];
	
	if ([tRawPackageProject writeToURL:_temporaryProjectURL atomically:YES]==NO)
	{
		// A COMPLETER
		
		return NO;
	}
	
	// Build
	
	[self performSelector:@selector(delayedBuild:) withObject:nil afterDelay:1.0];
	
	return YES;
	
	NSBeep();
	
	[[PKGQuickBuildFeedbackWindowController sharedController] removeViewForUUID:_UUID];
	
/*worseBail:

	NSBeep();

	if ([[NSApp delegate] launchedNormally]==NO)
	{
		if ([[[NSDocumentController sharedDocumentController] documents] count]==1)
		{
			[NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:1.0];
		}
		
	}*/

	return YES;
}

- (void)delayedBuild:(id)inObject
{
	NSMutableDictionary * tExternalSettings=[NSMutableDictionary dictionary];
	
	NSString * tScratchFolder=[PKGApplicationPreferences sharedPreferences].temporaryBuildLocation;
	
	if (tScratchFolder!=nil)
		tExternalSettings[PKGBuildOrderExternalSettingsScratchFolderKey]=tScratchFolder;
	
	PKGBuildOrder * tBuildOrder=[PKGBuildOrder new];
	
	tBuildOrder.projectPath=_temporaryProjectURL.path;
	tBuildOrder.buildOptions=0;
	tBuildOrder.externalSettings=[tExternalSettings copy];
	
	if ([[PKGBuildOrderManager defaultManager] executeBuildOrder:tBuildOrder
													setupHandler:^(PKGBuildNotificationCenter * bBuildNotificationCenter){
														
														// Register for notifications
														
														[bBuildNotificationCenter addObserver:self selector:@selector(processBuildEventNotification:) name:PKGBuildEventNotification object:tBuildOrder];
													}
											   completionHandler:^(PKGBuildResult bResult){
												   
												   switch(bResult)
												   {
													   case PKGBuildResultBuildOrderExecutionAgentDidExit:
														   
														   // Post Notification
														   
														   break;
														   
													   default:
														   
														   break;
												   }
											   }
									   communicationErrorHandler:^(NSError * bCommunicationError){
										   
										   NSString * tSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForFailedBuild;
										   
										   if (tSoundName.length>0)
											[[NSSound soundNamed:tSoundName] play];
										   
										   // Remove Temporary Folder
										   
										   [[NSFileManager defaultManager] removeItemAtURL:[_temporaryProjectURL URLByDeletingLastPathComponent] error:NULL];
										   
										   // A COMPLETER
										   
										   /*
											
											NSRunAlertPanel(NSLocalizedStringFromTable(@"No signal from the packages_dispatcher process",@"Build",@"No comment"),
											NSLocalizedStringFromTable(@"The packages_dispatcher process is not responding. Packages can't build any project when this process is not running.",@"Build",@"No comment"),
											nil,
											nil,
											nil,
											nil);
											
											*/
										   
									   }]==NO)
	{
		;
	}
}

#pragma mark - Notifications

- (void)processBuildEventNotification:(NSNotification *)inNotification
{
	if (inNotification==nil)
		return;
	
	NSDictionary * tUserInfo=inNotification.userInfo;
	
	if (tUserInfo==nil)
		return;
	
	NSNumber * tNumber=tUserInfo[PKGBuildStepKey];
	
	if ([tNumber isKindOfClass:NSNumber.class]==NO)
		return;
	
	PKGBuildStep tStep=tNumber.unsignedIntegerValue;
	
	NSIndexPath * tStepPath=tUserInfo[PKGBuildStepPathKey];
	
	if ([tStepPath isKindOfClass:NSIndexPath.class]==NO)
		return;
	
	
	tNumber=tUserInfo[PKGBuildStateKey];
	
	if ([tNumber isKindOfClass:NSNumber.class]==NO)
		return;
	
	PKGBuildStepState tState=tNumber.unsignedIntegerValue;
	
	
	NSDictionary * tRepresentation=tUserInfo[PKGBuildStepEventRepresentationKey];
	
	if (tRepresentation!=nil && [tRepresentation isKindOfClass:NSDictionary.class]==NO)
		return;
	
	
	if (tState==PKGBuildStepStateFailure)
	{
		NSString * tSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForFailedBuild;
		
		if (tSoundName.length>0)
			[[NSSound soundNamed:tSoundName] play];
		
		[[PKGQuickBuildFeedbackWindowController sharedController] setStatus:PKGQuickBuildStateFailed forUUID:_UUID];
		
		[[PKGQuickBuildFeedbackWindowController sharedController] performSelector:@selector(removeViewForUUID:) withObject:_UUID afterDelay:2.0];
		
		// Remove Temporary Folder
		
		[[NSFileManager defaultManager] removeItemAtURL:[_temporaryProjectURL URLByDeletingLastPathComponent] error:NULL];
		
		if (((PKGApplicationController *)[NSApp delegate]).launchedNormally==NO)
		{
			if ([[NSDocumentController sharedDocumentController] documents].count==1)
			{
				[NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:3.0];
				
				return;
			}
		}
		
		[self close];
		
		return;
	}
	
	if (tState==PKGBuildStepStateSuccess)
	{
		if (tStep==PKGBuildStepProject)
		{
			NSString * tSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForSuccessfulBuild;
			
			if (tSoundName.length>0)
				[[NSSound soundNamed:tSoundName] play];
			
			[[PKGQuickBuildFeedbackWindowController sharedController] setStatus:PKGQuickBuildStateSuccessful forUUID:_UUID];
			
			[[PKGQuickBuildFeedbackWindowController sharedController] performSelector:@selector(removeViewForUUID:) withObject:_UUID afterDelay:1.0];
			
			// Remove Temporary Folder
			
			[[NSFileManager defaultManager] removeItemAtURL:[_temporaryProjectURL URLByDeletingLastPathComponent] error:NULL];
			
			if (((PKGApplicationController *)[NSApp delegate]).launchedNormally==NO)
			{
				if ([[NSDocumentController sharedDocumentController] documents].count==1)
				{
					[NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:1.0];
					
					return;
				}
			}
			
			[self close];
		}
		
		return;
	}
}

@end
