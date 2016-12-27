/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGApplicationPreferences.h"

// General

NSString * const PKGPreferencesGeneralDefaultVisibleDistributionProjectPaneKey=@"general.project.pane.default";

NSString * const PKGPreferencesGeneralDefaultVisibleDistributionPackagePaneKey=@"general.package.pane.default";

NSString * const PKGPreferencesGeneralDefaultVisiblePackageProjectPaneKey=@"general.package.standalone.pane.default";

NSString * const PKGPreferencesGeneralDefaultFilePathReferenceStyleKey=@"general.file.defaultReferenceStyle";

// Files

NSString * const PKGPreferencesFilesShowAllFilesInOpenDialogKey=@"file.opensavedialog.showAllFiles";

NSString * const PKGPreferencesFilesHighlightExcludedFilesKey=@"file.list.highlight.excluded";

NSString * const PKGPreferencesFilesKeepOwnershipKey=@"file.customizationdialog.keepPermission";

NSString * const PKGPreferencesFilesShowOwnershipAndReferenceStyleCustomizationDialogKey=@"file.customizationdialog.ui.showCustomizationDialog";

// Build

NSString * const PKGPreferencesBuildUnsavedProjectSaveBehaviorKey=@"build.project.unsaved.behavior";

NSString * const PKGPreferencesBuildShowBuildWindowBehaviorKey=@"build.window.event.show";

NSString * const PKGPreferencesBuildHideBuildWindowBehaviorKey=@"build.window.event.hide";

NSString * const PKGPreferencesBuildPlayedSoundForSuccessfulBuildKey=@"build.sound.play.success";

NSString * const PKGPreferencesBuildPlayedSoundForFailedBuildKey=@"build.sound.play.errors";

NSString * const PKGPreferencesQuickBuildUseBundleVersionKey=@"quickbuild.version.useBundle";

NSString * const PKGPreferencesQuickBuildFailOverFolderKey=@"quickbuild.failover.folder";

NSString * const PKGPreferencesBuildTemporaryBuildLocationKey=@"build.location.temporary";

NSString * const PKGPreferencesBuildDefautTemporationLocation=@"/private/tmp";

// Templates

// Advanced

NSString * const PKGPreferencesAdvancedAdvancedModeStateKey=@"advanced.advanced.mode";

NSString * const PKGPreferencesAdvancedAppleModeStateKey=@"advanced.apple.mode";

// Project Creation Assistant

NSString * const  PKGPreferencesProjectAssistantDontShowOnLaunchKey=@"projectassistant.ui.dontShowOnLaunch";


// Notifications

NSString * const PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification=@"PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification";

NSString * const PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification=@"PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification";

NSString * const PKGPreferencesAdvancedAppleModeStateDidChangeNotification=@"PKGPreferencesAdvancedAppleModeStateDidChangeNotification";


@interface PKGApplicationPreferences ()
{
	NSUserDefaults * _defaults;
}

@end

@implementation PKGApplicationPreferences

+ (instancetype)sharedPreferences
{
	static dispatch_once_t onceToken;
	static PKGApplicationPreferences * sPreferences=nil;
	
	dispatch_once(&onceToken, ^{
		
		sPreferences=[PKGApplicationPreferences new];
	});
	
	return sPreferences;
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_defaults=[NSUserDefaults standardUserDefaults];
		
		[_defaults registerDefaults:@{
									  PKGPreferencesGeneralDefaultVisibleDistributionProjectPaneKey:@(PKGPreferencesGeneralDistributionProjectPaneSettings),
									  PKGPreferencesGeneralDefaultVisibleDistributionPackagePaneKey:@(PKGPreferencesGeneralDistributionPackagePaneSettings),
									  PKGPreferencesGeneralDefaultVisiblePackageProjectPaneKey:@(PKGPreferencesGeneralPackageProjectPaneProject),
									  PKGPreferencesGeneralDefaultFilePathReferenceStyleKey:@(PKGFilePathTypeAbsolute),
									  
									  PKGPreferencesFilesShowAllFilesInOpenDialogKey:@(NO),
									  PKGPreferencesFilesHighlightExcludedFilesKey:@(NO),
									  PKGPreferencesFilesKeepOwnershipKey:@(NO),
									  PKGPreferencesFilesShowOwnershipAndReferenceStyleCustomizationDialogKey:@(YES),
									  
									  PKGPreferencesBuildUnsavedProjectSaveBehaviorKey:@(PKGPreferencesBuildUnsavedProjectSaveAskBeforeBuild),
									  PKGPreferencesBuildShowBuildWindowBehaviorKey:@(PKGPreferencesBuildShowBuildWindowAlways),
									  PKGPreferencesBuildHideBuildWindowBehaviorKey:@(PKGPreferencesBuildHideBuildWindowNever),
									  PKGPreferencesBuildPlayedSoundForSuccessfulBuildKey:@"",
									  PKGPreferencesBuildPlayedSoundForFailedBuildKey:@"",
									  PKGPreferencesQuickBuildUseBundleVersionKey:@(NO),
									  //PKGPreferencesQuickBuildFailOverFolderKey = nil <=> NSHomeDirectory()
									  PKGPreferencesBuildTemporaryBuildLocationKey:PKGPreferencesBuildDefautTemporationLocation,
									  
									  
									  
									  PKGPreferencesAdvancedAdvancedModeStateKey:@(NO),
									  PKGPreferencesAdvancedAppleModeStateKey:@(NO),
									  
									  PKGPreferencesProjectAssistantDontShowOnLaunchKey:@(NO)
									  
									  }];
		
		// General
		
		_defaultVisibleDistributionProjectPane=[_defaults integerForKey:PKGPreferencesGeneralDefaultVisibleDistributionProjectPaneKey];
		
		_defaultVisibleDistributionPackagePane=[_defaults integerForKey:PKGPreferencesGeneralDefaultVisibleDistributionPackagePaneKey];
		
		_defaultVisiblePackageProjectPane=[_defaults integerForKey:PKGPreferencesGeneralDefaultVisiblePackageProjectPaneKey];
		
		_defaultFilePathReferenceStyle=[_defaults integerForKey:PKGPreferencesGeneralDefaultFilePathReferenceStyleKey];
		
		// Files
		
		_showAllFilesInOpenDialog=[_defaults boolForKey:PKGPreferencesFilesShowAllFilesInOpenDialogKey];
		
		_highlightExcludedFiles=[_defaults boolForKey:PKGPreferencesFilesHighlightExcludedFilesKey];
		
		_keepOwnership=[_defaults boolForKey:PKGPreferencesFilesKeepOwnershipKey];
		
		_showOwnershipAndReferenceStyleCustomizationDialog=[_defaults boolForKey:PKGPreferencesFilesShowOwnershipAndReferenceStyleCustomizationDialogKey];
		
		// Build
		
		_unsavedProjectSaveBehavior=[_defaults integerForKey:PKGPreferencesBuildUnsavedProjectSaveBehaviorKey];
		
		_showBuildWindowBehavior=[_defaults integerForKey:PKGPreferencesBuildShowBuildWindowBehaviorKey];
		
		_hideBuildWindowBehavior=[_defaults integerForKey:PKGPreferencesBuildHideBuildWindowBehaviorKey];
		
		_playedSoundForSuccessfulBuild=[_defaults stringForKey:PKGPreferencesBuildPlayedSoundForSuccessfulBuildKey];
		
		_playedSoundForFailedBuild=[_defaults stringForKey:PKGPreferencesBuildPlayedSoundForFailedBuildKey];
		
		_useBundleVersionForQuickBuild=[_defaults boolForKey:PKGPreferencesQuickBuildUseBundleVersionKey];
		
		_failOverFolderForQuickBuild=[_defaults stringForKey:PKGPreferencesQuickBuildFailOverFolderKey];
		
		_temporaryBuildLocation=[_defaults stringForKey:PKGPreferencesBuildTemporaryBuildLocationKey];
		
		// Templates
		
		// Advanced
		
		_advancedMode=[_defaults boolForKey:PKGPreferencesAdvancedAdvancedModeStateKey];
		
		_appleMode=[_defaults boolForKey:PKGPreferencesAdvancedAppleModeStateKey];
		
		// Project Assistant
		
		_dontShowProjectAssistantOnLaunch=[_defaults boolForKey:PKGPreferencesProjectAssistantDontShowOnLaunchKey];
	}
	
	return self;
}

#pragma mark - General

- (void)setDefaultVisibleDistributionProjectPane:(PKGPreferencesGeneralDistributionProjectPaneTag)inTag
{
	_defaultVisibleDistributionProjectPane=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesGeneralDefaultVisibleDistributionProjectPaneKey];
}

- (void)setDefaultVisibleDistributionPackagePane:(PKGPreferencesGeneralDistributionPackagePaneTag)inTag
{
	_defaultVisibleDistributionPackagePane=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesGeneralDefaultVisibleDistributionPackagePaneKey];
}

- (void)setDefaultVisiblePackageProjectPane:(PKGPreferencesGeneralPackageProjectPaneTag)inTag
{
	_defaultVisiblePackageProjectPane=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesGeneralDefaultVisiblePackageProjectPaneKey];
}

- (void)setDefaultFilePathReferenceStyle:(PKGFilePathType)inTag
{
	_defaultFilePathReferenceStyle=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesGeneralDefaultFilePathReferenceStyleKey];
}

#pragma mark - Files

- (void)setShowAllFilesInOpenDialog:(BOOL)inBool
{
	_showAllFilesInOpenDialog=inBool;
	
	[_defaults setInteger:inBool forKey:PKGPreferencesFilesShowAllFilesInOpenDialogKey];
}

- (void)setShowOwnershipAndReferenceStyleCustomizationDialog:(BOOL)inBool
{
	_showOwnershipAndReferenceStyleCustomizationDialog=inBool;
	
	[_defaults setInteger:inBool forKey:PKGPreferencesFilesShowOwnershipAndReferenceStyleCustomizationDialogKey];
}

- (void)setKeepOwnership:(BOOL)inBool
{
	_keepOwnership=inBool;
	
	[_defaults setInteger:inBool forKey:PKGPreferencesFilesKeepOwnershipKey];
}

- (void)setHighlightExcludedFiles:(BOOL)inBool
{
	_highlightExcludedFiles=inBool;
	
	[_defaults setInteger:inBool forKey:PKGPreferencesFilesHighlightExcludedFilesKey];
}

#pragma mark - Build

- (void)setUnsavedProjectSaveBehavior:(PKGPreferencesBuildUnsavedProjectSaveBehavior)inTag
{
	_unsavedProjectSaveBehavior=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesBuildUnsavedProjectSaveBehaviorKey];
}

- (void)setShowBuildWindowBehavior:(PKGPreferencesBuildShowBuildWindowBehavior)inTag
{
	_showBuildWindowBehavior=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesBuildShowBuildWindowBehaviorKey];
}

- (void)setHideBuildWindowBehavior:(PKGPreferencesBuildHideBuildWindowBehavior)inTag
{
	_hideBuildWindowBehavior=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesBuildHideBuildWindowBehaviorKey];
}

- (void)setPlayedSoundForSuccessfulBuild:(NSString *)inSoundName
{
	if ([inSoundName length]==0 || [_playedSoundForSuccessfulBuild caseInsensitiveCompare:inSoundName]!=NSOrderedSame)
	{
		_playedSoundForSuccessfulBuild=[inSoundName copy];
	
		[_defaults setObject:[inSoundName copy] forKey:PKGPreferencesBuildPlayedSoundForSuccessfulBuildKey];
	}
}

- (void)setPlayedSoundForFailedBuild:(NSString *)inSoundName
{
	if ([inSoundName length]==0 || [_playedSoundForFailedBuild caseInsensitiveCompare:inSoundName]!=NSOrderedSame)
	{
		_playedSoundForFailedBuild=[inSoundName copy];
	
		[_defaults setObject:[inSoundName copy] forKey:PKGPreferencesBuildPlayedSoundForFailedBuildKey];
	}
}

- (void)setUseBundleVersionForQuickBuild:(BOOL)inBool
{
	_useBundleVersionForQuickBuild=inBool;
	
	[_defaults setBool:inBool forKey:PKGPreferencesQuickBuildUseBundleVersionKey];
}

- (void)setFailOverFolderForQuickBuild:(NSString *)inPath
{
	_failOverFolderForQuickBuild=[inPath copy];
	
	if (inPath==nil)
		[_defaults removeObjectForKey:PKGPreferencesQuickBuildFailOverFolderKey];
	else
		[_defaults setObject:[inPath copy] forKey:PKGPreferencesQuickBuildFailOverFolderKey];
}

- (void)setTemporaryBuildLocation:(NSString *)inPath
{
	_temporaryBuildLocation=[inPath copy];
	
	[_defaults setObject:[inPath copy] forKey:PKGPreferencesBuildTemporaryBuildLocationKey];
}

#pragma mark - Templates

#pragma mark - Advanced

- (void)setAdvancedMode:(BOOL)inBool
{
	_advancedMode=inBool;
	
	[_defaults setBool:inBool forKey:PKGPreferencesAdvancedAdvancedModeStateKey];
}

- (void)setAppleMode:(BOOL)inBool
{
	_appleMode=inBool;
	
	[_defaults setBool:inBool forKey:PKGPreferencesAdvancedAppleModeStateKey];
}

#pragma mark - Project Assistant

- (void)setDontShowProjectAssistantOnLaunch:(BOOL)inBool
{
	_dontShowProjectAssistantOnLaunch=inBool;
	
	[_defaults setBool:inBool forKey:PKGPreferencesProjectAssistantDontShowOnLaunchKey];
}

@end
