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

#import "PKGFilePath.h"

typedef NS_ENUM(NSUInteger, PKGPreferencesGeneralDistributionProjectPaneTag)
{
	PKGPreferencesGeneralDistributionProjectPaneSettings=0,
	PKGPreferencesGeneralDistributionProjectPanePresentation=1,
	PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources=2,
	PKGPreferencesGeneralDistributionProjectPaneComments=3
};

typedef NS_ENUM(NSUInteger, PKGPreferencesGeneralDistributionPackagePaneTag)
{
	PKGPreferencesGeneralDistributionPackagePaneSettings=0,
	PKGPreferencesGeneralDistributionPackagePanePayload=1,
	PKGPreferencesGeneralDistributionPackagePaneScripts=2
};

typedef NS_ENUM(NSUInteger, PKGPreferencesGeneralPackageProjectPaneTag)
{
	PKGPreferencesGeneralPackageProjectPaneProject=0,
	PKGPreferencesGeneralPackageProjectPaneSettings=1,
	PKGPreferencesGeneralPackageProjectPanePayload=2,
	PKGPreferencesGeneralPackageProjectPaneScriptsAndResources=3,
	PKGPreferencesGeneralPackageProjectPaneComments=4,

};

typedef NS_ENUM(NSUInteger, PKGPreferencesBuildUnsavedProjectSaveBehavior)
{
	PKGPreferencesBuildUnsavedProjectSaveAskBeforeBuild=0,
	PKGPreferencesBuildUnsavedProjectSaveAlways=1,
	PKGPreferencesBuildUnsavedProjectSaveNever=2
};

typedef NS_ENUM(NSUInteger, PKGPreferencesBuildShowBuildWindowBehavior)
{
	PKGPreferencesBuildShowBuildWindowAlways=0,
	PKGPreferencesBuildShowBuildWindowNever=1,
	PKGPreferencesBuildShowBuildWindowOnErrors=2
};

typedef NS_ENUM(NSUInteger, PKGPreferencesBuildHideBuildWindowBehavior)
{
	PKGPreferencesBuildHideBuildWindowNever=0,
	PKGPreferencesBuildHideBuildWindowAlways=1,
	PKGPreferencesBuildHideBuildWindowOnSuccess=2
};

@interface PKGApplicationPreferences : NSObject

	// General

	@property (nonatomic) PKGPreferencesGeneralDistributionProjectPaneTag defaultVisibleDistributionProjectPane;

	@property (nonatomic) PKGPreferencesGeneralDistributionPackagePaneTag defaultVisibleDistributionPackagePane;

	@property (nonatomic) PKGPreferencesGeneralPackageProjectPaneTag defaultVisiblePackageProjectPane;

	@property (nonatomic) PKGFilePathType defaultFilePathReferenceStyle;

	// Files

	@property (nonatomic) BOOL showAllFilesInOpenDialog;

	@property (nonatomic) BOOL highlightExcludedFiles;

	@property (nonatomic) BOOL keepOwnership;

	@property (nonatomic) BOOL showOwnershipAndReferenceStyleCustomizationDialog;

	// Build

	@property (nonatomic) PKGPreferencesBuildUnsavedProjectSaveBehavior unsavedProjectSaveBehavior;

	@property (nonatomic) PKGPreferencesBuildShowBuildWindowBehavior showBuildWindowBehavior;

	@property (nonatomic) PKGPreferencesBuildHideBuildWindowBehavior hideBuildWindowBehavior;

	@property (nonatomic,copy) NSString * playedSoundForSuccessfulBuild;

	@property (nonatomic,copy) NSString * playedSoundForFailedBuild;

	@property (nonatomic) BOOL useBundleVersionForQuickBuild;

	@property (nonatomic,copy) NSString * failOverFolderForQuickBuild;

	@property (nonatomic,copy) NSString * temporaryBuildLocation;

	// Templates


	// Advanced

	@property (nonatomic) BOOL advancedMode;

	@property (nonatomic) BOOL appleMode;

	// Project Assistant

	@property (nonatomic) BOOL dontShowProjectAssistantOnLaunch;


+ (instancetype)sharedPreferences;


@end



extern NSString * const PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification;

extern NSString * const PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification;

extern NSString * const PKGPreferencesAdvancedAppleModeStateDidChangeNotification;