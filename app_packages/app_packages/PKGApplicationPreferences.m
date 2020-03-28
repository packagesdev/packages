/*
 Copyright (c) 2016-2020, Stephane Sudre
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

NSString * const PKGPreferencesGeneralDefaultVisibleDistributionPackageComponentPaneKey=@"general.package.pane.default";

NSString * const PKGPreferencesGeneralDefaultVisiblePackageProjectPaneKey=@"general.package.standalone.pane.default";

NSString * const PKGPreferencesGeneralDefaultFilePathReferenceStyleKey=@"general.file.defaultReferenceStyle";

// Files

NSString * const PKGPreferencesFilesShowAllFilesInOpenDialogKey=@"file.opensavedialog.showAllFiles";

NSString * const PKGPreferencesFilesHighlightExcludedFilesKey=@"file.list.highlight.excluded";

NSString * const PKGPreferencesFilesKeepOwnershipKey=@"file.customizationdialog.keepPermission";

NSString * const PKGPreferencesFilesShowOwnershipAndReferenceStyleCustomizationDialogKey=@"file.customizationdialog.ui.showCustomizationDialog";

NSString * const PKGPreferencesFilesShowServicesUsersAndGroupsKey=@"files.usersandgroups.services.show";

// Build

NSString * const PKGPreferencesBuildUnsavedProjectSaveBehaviorKey=@"build.project.unsaved.behavior";

NSString * const PKGPreferencesBuildShowBuildWindowBehaviorKey=@"build.window.event.show";

NSString * const PKGPreferencesBuildHideBuildWindowBehaviorKey=@"build.window.event.hide";


NSString * const PKGPreferencesBuildPlayedSoundForSuccessfulBuildKey=@"build.sound.play.success";	// Deprecated

NSString * const PKGPreferencesBuildPlayedSoundForFailedBuildKey=@"build.sound.play.errors";		// Deprecated


NSString * const PKGPreferencesBuildSuccessKey=@"success";

NSString * const PKGPreferencesBuildFailureKey=@"failure";

NSString * const PKGPreferencesBuildResultBehaviorPlaySoundFormatKey=@"build.result.behavior.%@.playSound";

NSString * const PKGPreferencesBuildResultBehaviorSoundNameFormatKey=@"build.result.behavior.%@.soundName";

NSString * const PKGPreferencesBuildResultBehaviorSpeakAnnouncementFormatKey=@"build.result.behavior.%@.speakAnnouncement";

NSString * const PKGPreferencesBuildResultBehaviorAnnouncementVoiceFormatKey=@"build.result.behavior.%@.announcementVoice";

NSString * const PKGPreferencesBuildResultBehaviorNotifyUsingSystemNotificationFormatKey=@"build.result.behavior.%@.notifyUsingSystemNotification";

NSString * const PKGPreferencesBuildResultBehaviorBounceIconInDockFormatKey=@"build.result.behavior.%@.bounceIconInDock";


NSString * const PKGPreferencesBuildEmbedTrustedTimestampInSignatureKey=@"build.signing.embed-timestamp";


NSString * const PKGPreferencesQuickBuildSigningActionKey=@"quickbuild.signing.action";

NSString * const PKGPreferencesQuickBuildSigningIdentityKey=@"quickbuild.signing.identity";

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

NSString * const  PKGPreferencesProjectAssistantDefaultNewProjectLocationKey=@"projectassistant.project.default.location";

NSString * const  PKGPreferencesProjectAssistantDefaultNewProjectLocation=@"~/";

// Notifications

NSString * const PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification=@"PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification";

NSString * const PKGPreferencesFilesShowServicesUsersAndGroupsDidChangeNotification=@"PKGPreferencesFilesShowServicesUsersAndGroupsDidChangeNotification";

NSString * const PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification=@"PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification";

NSString * const PKGPreferencesAdvancedAppleModeStateDidChangeNotification=@"PKGPreferencesAdvancedAppleModeStateDidChangeNotification";


@interface PKGApplicationBuildResultBehavior ()
{
	NSUserDefaults * _defaults;
	
	NSString * _buildResultTypeName;
}

+ (NSArray *)buildResultBehaviors;

- (instancetype)initWithBehaviorType:(PKGPreferencesBuildResultBehaviorType)inType;

@end


@implementation PKGApplicationBuildResultBehavior

+ (void)initialize
{
	NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
	
	NSArray * tResultTypeNames=@[PKGPreferencesBuildSuccessKey,PKGPreferencesBuildFailureKey];
	
	for(NSString * tResultTypeName in tResultTypeNames)
	{
		[tUserDefaults registerDefaults:@{
								  
										  [NSString stringWithFormat:PKGPreferencesBuildResultBehaviorSpeakAnnouncementFormatKey,tResultTypeName]:@(NO),
										  [NSString stringWithFormat:PKGPreferencesBuildResultBehaviorNotifyUsingSystemNotificationFormatKey,tResultTypeName]:@(YES),
										  [NSString stringWithFormat:PKGPreferencesBuildResultBehaviorBounceIconInDockFormatKey,tResultTypeName]:@(YES),
									  
									  }];
	}

}

+ (NSArray *)buildResultBehaviors
{
	static NSMutableArray * sBuildResultBehaviors=nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		
		NSMutableArray * tMutableArray=[NSMutableArray array];
		
		// Success
		
		PKGApplicationBuildResultBehavior * tBuildResultBehavior=[[PKGApplicationBuildResultBehavior alloc] initWithBehaviorType:PKGPreferencesBuildResultBehaviorSuccess];
		
		[tMutableArray addObject:tBuildResultBehavior];
		
		tBuildResultBehavior=[[PKGApplicationBuildResultBehavior alloc] initWithBehaviorType:PKGPreferencesBuildResultBehaviorFailure];
		
		[tMutableArray addObject:tBuildResultBehavior];
		
		sBuildResultBehaviors=[tMutableArray copy];
		
	});
	
	return sBuildResultBehaviors;
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_defaults=[NSUserDefaults standardUserDefaults];
	}
	
	return self;
}

- (instancetype)initWithBehaviorType:(PKGPreferencesBuildResultBehaviorType)inType
{
	self=[super init];
	
	if (self!=nil)
	{
		_type=inType;
		
		switch(_type)
		{
			case PKGPreferencesBuildResultBehaviorSuccess:
				
				_buildResultTypeName=PKGPreferencesBuildSuccessKey;
				break;
				
			case PKGPreferencesBuildResultBehaviorFailure:
				
				_buildResultTypeName=PKGPreferencesBuildFailureKey;
				break;
				
			default:
				
				return nil;
		}
		
		_defaults=[NSUserDefaults standardUserDefaults];
		
		NSString * tPlaySoundKey=[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorPlaySoundFormatKey,_buildResultTypeName];
		NSString * tSoundNameKey=[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorSoundNameFormatKey,_buildResultTypeName];
		
		if ([_defaults objectForKey:tPlaySoundKey]==nil &&
			[_defaults objectForKey:tSoundNameKey]==nil)
		{
			NSString * tSpareKey=(_type==PKGPreferencesBuildResultBehaviorSuccess) ? PKGPreferencesBuildPlayedSoundForSuccessfulBuildKey: PKGPreferencesBuildPlayedSoundForFailedBuildKey;
			
			NSString * tPlayedSoundName=[_defaults stringForKey:tSpareKey];
			
			if (tPlayedSoundName.length==0)
			{
				_playSound=NO;
				_soundName=nil;
			}
			else
			{
				_playSound=YES;
				_soundName=[tPlayedSoundName copy];
				
				[_defaults setBool:_playSound forKey:tPlaySoundKey];
				[_defaults setObject:_soundName forKey:tSoundNameKey];
			}
		}
		else
		{
			_playSound=[_defaults boolForKey:tPlaySoundKey];
			_soundName=[_defaults stringForKey:tSoundNameKey];
		}
		
		_soundName=[_defaults stringForKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorSoundNameFormatKey,_buildResultTypeName]];
		
		_speakAnnouncement=[_defaults boolForKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorSpeakAnnouncementFormatKey,_buildResultTypeName]];
		
		_announcementVoice=[_defaults stringForKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorAnnouncementVoiceFormatKey,_buildResultTypeName]];
		
		_notifyUsingSystemNotification=[_defaults boolForKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorNotifyUsingSystemNotificationFormatKey,_buildResultTypeName]];
		
		_bounceIconInDock=[_defaults boolForKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorBounceIconInDockFormatKey,_buildResultTypeName]];
	}
	
	return self;
}

#pragma mark -

- (void)setPlaySound:(BOOL)inBool
{
	_playSound=inBool;
	
	[_defaults setInteger:inBool forKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorPlaySoundFormatKey,_buildResultTypeName]];
}

- (void)setSoundName:(NSString *)inSoundName
{
	if (inSoundName.length==0 || _soundName==nil || [_soundName caseInsensitiveCompare:inSoundName]!=NSOrderedSame)
	{
		_soundName=[inSoundName copy];
		
		[_defaults setObject:[inSoundName copy] forKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorSoundNameFormatKey,_buildResultTypeName]];
	}
}

- (void)setSpeakAnnouncement:(BOOL)inBool
{
	_speakAnnouncement=inBool;
	
	[_defaults setBool:inBool forKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorSpeakAnnouncementFormatKey,_buildResultTypeName]];
}

- (void)setAnnouncementVoice:(NSString *)inAnnouncementVoice
{
	if (inAnnouncementVoice.length==0 || _announcementVoice==nil || [_announcementVoice caseInsensitiveCompare:inAnnouncementVoice]!=NSOrderedSame)
	{
		_announcementVoice=[inAnnouncementVoice copy];
		
		[_defaults setObject:[inAnnouncementVoice copy] forKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorAnnouncementVoiceFormatKey,_buildResultTypeName]];
	}
}

- (void)setNotifyUsingSystemNotification:(BOOL)inBool
{
	_notifyUsingSystemNotification=inBool;
	
	[_defaults setBool:inBool forKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorNotifyUsingSystemNotificationFormatKey,_buildResultTypeName]];
}

- (void)setBounceIconInDock:(BOOL)inBool
{
	_bounceIconInDock=inBool;
	
	[_defaults setBool:inBool forKey:[NSString stringWithFormat:PKGPreferencesBuildResultBehaviorBounceIconInDockFormatKey,_buildResultTypeName]];
}

@end



@interface PKGApplicationPreferences ()
{
	NSUserDefaults * _defaults;
}

	@property (readwrite) NSArray * buildResultBehaviors;

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
									  PKGPreferencesGeneralDefaultVisibleDistributionPackageComponentPaneKey:@(PKGPreferencesGeneralDistributionPackageComponentPaneSettings),
									  PKGPreferencesGeneralDefaultVisiblePackageProjectPaneKey:@(PKGPreferencesGeneralPackageProjectPaneProject),
									  PKGPreferencesGeneralDefaultFilePathReferenceStyleKey:@(PKGFilePathTypeAbsolute),
									  
									  PKGPreferencesFilesShowAllFilesInOpenDialogKey:@(NO),
									  PKGPreferencesFilesHighlightExcludedFilesKey:@(NO),
									  PKGPreferencesFilesKeepOwnershipKey:@(NO),
									  PKGPreferencesFilesShowOwnershipAndReferenceStyleCustomizationDialogKey:@(YES),
									  PKGPreferencesFilesShowServicesUsersAndGroupsKey:@(NO),
									  
									  PKGPreferencesBuildUnsavedProjectSaveBehaviorKey:@(PKGPreferencesBuildUnsavedProjectSaveAskBeforeBuild),
									  PKGPreferencesBuildShowBuildWindowBehaviorKey:@(PKGPreferencesBuildShowBuildWindowAlways),
									  PKGPreferencesBuildHideBuildWindowBehaviorKey:@(PKGPreferencesBuildHideBuildWindowNever),
									  
									  PKGPreferencesBuildEmbedTrustedTimestampInSignatureKey:@(YES),
									  
									  PKGPreferencesQuickBuildSigningActionKey:@(PKGPreferencesQuickBuildSigningDontSign),
									  PKGPreferencesQuickBuildUseBundleVersionKey:@(NO),
									  //PKGPreferencesQuickBuildFailOverFolderKey = nil <=> NSHomeDirectory()
									  PKGPreferencesBuildTemporaryBuildLocationKey:PKGPreferencesBuildDefautTemporationLocation,
									  
									  
									  PKGPreferencesAdvancedAdvancedModeStateKey:@(NO),
									  
									  PKGPreferencesAdvancedAppleModeStateKey:@(NO),
									  
									  PKGPreferencesProjectAssistantDontShowOnLaunchKey:@(NO),
									  PKGPreferencesProjectAssistantDefaultNewProjectLocationKey:PKGPreferencesProjectAssistantDefaultNewProjectLocation
									  
									  }];
		
		// General
		
		_defaultVisibleDistributionProjectPane=[_defaults integerForKey:PKGPreferencesGeneralDefaultVisibleDistributionProjectPaneKey];
		
		_defaultVisibleDistributionPackageComponentPane=[_defaults integerForKey:PKGPreferencesGeneralDefaultVisibleDistributionPackageComponentPaneKey];
		
		_defaultVisiblePackageProjectPane=[_defaults integerForKey:PKGPreferencesGeneralDefaultVisiblePackageProjectPaneKey];
		
		_defaultFilePathReferenceStyle=[_defaults integerForKey:PKGPreferencesGeneralDefaultFilePathReferenceStyleKey];
		
		// Files
		
		_showAllFilesInOpenDialog=[_defaults boolForKey:PKGPreferencesFilesShowAllFilesInOpenDialogKey];
		
		_highlightExcludedFiles=[_defaults boolForKey:PKGPreferencesFilesHighlightExcludedFilesKey];
		
		_keepOwnership=[_defaults boolForKey:PKGPreferencesFilesKeepOwnershipKey];
		
		_showOwnershipAndReferenceStyleCustomizationDialog=[_defaults boolForKey:PKGPreferencesFilesShowOwnershipAndReferenceStyleCustomizationDialogKey];
		
		_showServicesUsersAndGroups=[_defaults boolForKey:PKGPreferencesFilesShowServicesUsersAndGroupsKey];
		
		// Build
		
		_unsavedProjectSaveBehavior=[_defaults integerForKey:PKGPreferencesBuildUnsavedProjectSaveBehaviorKey];
		
		_showBuildWindowBehavior=[_defaults integerForKey:PKGPreferencesBuildShowBuildWindowBehaviorKey];
		
		_hideBuildWindowBehavior=[_defaults integerForKey:PKGPreferencesBuildHideBuildWindowBehaviorKey];
		
		
		_embedTimestampInSignature=[_defaults boolForKey:PKGPreferencesBuildEmbedTrustedTimestampInSignatureKey];
		
		
		_buildResultBehaviors=[PKGApplicationBuildResultBehavior buildResultBehaviors];
		
		_quickBuildSigningAction=[_defaults integerForKey:PKGPreferencesQuickBuildSigningActionKey];
		
		_quickBuildSigningIdentity=[_defaults stringForKey:PKGPreferencesQuickBuildSigningIdentityKey];
		
		_useBundleVersionForQuickBuild=[_defaults boolForKey:PKGPreferencesQuickBuildUseBundleVersionKey];
		
		_failOverFolderForQuickBuild=[_defaults stringForKey:PKGPreferencesQuickBuildFailOverFolderKey];
		
		_temporaryBuildLocation=[_defaults stringForKey:PKGPreferencesBuildTemporaryBuildLocationKey];
		
		// Templates
		
		// Advanced
		
		_advancedMode=[_defaults boolForKey:PKGPreferencesAdvancedAdvancedModeStateKey];
		
		_appleMode=[_defaults boolForKey:PKGPreferencesAdvancedAppleModeStateKey];
		
		// Project Assistant
		
		_dontShowProjectAssistantOnLaunch=[_defaults boolForKey:PKGPreferencesProjectAssistantDontShowOnLaunchKey];
		
		_defaultLocationOfNewProjects=[_defaults stringForKey:PKGPreferencesProjectAssistantDefaultNewProjectLocationKey];
	}
	
	return self;
}

#pragma mark - General

- (void)setDefaultVisibleDistributionProjectPane:(PKGPreferencesGeneralDistributionProjectPaneTag)inTag
{
	_defaultVisibleDistributionProjectPane=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesGeneralDefaultVisibleDistributionProjectPaneKey];
}

- (void)setDefaultVisibleDistributionPackageComponentPane:(PKGPreferencesGeneralDistributionPackageComponentPaneTag)inTag
{
	_defaultVisibleDistributionPackageComponentPane=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesGeneralDefaultVisibleDistributionPackageComponentPaneKey];
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
	
	[_defaults setBool:inBool forKey:PKGPreferencesFilesShowAllFilesInOpenDialogKey];
}

- (void)setShowOwnershipAndReferenceStyleCustomizationDialog:(BOOL)inBool
{
	_showOwnershipAndReferenceStyleCustomizationDialog=inBool;
	
	[_defaults setBool:inBool forKey:PKGPreferencesFilesShowOwnershipAndReferenceStyleCustomizationDialogKey];
}

- (void)setKeepOwnership:(BOOL)inBool
{
	_keepOwnership=inBool;
	
	[_defaults setBool:inBool forKey:PKGPreferencesFilesKeepOwnershipKey];
}

- (void)setHighlightExcludedFiles:(BOOL)inBool
{
	_highlightExcludedFiles=inBool;
	
	[_defaults setBool:inBool forKey:PKGPreferencesFilesHighlightExcludedFilesKey];
}

- (void)setShowServicesUsersAndGroups:(BOOL)inBool
{
	_showServicesUsersAndGroups=inBool;
	
	[_defaults setBool:inBool forKey:PKGPreferencesFilesShowServicesUsersAndGroupsKey];
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

- (void)setQuickBuildSigningAction:(PKGPreferencesQuickBuildSigningAction)inTag
{
	_quickBuildSigningAction=inTag;
	
	[_defaults setInteger:inTag forKey:PKGPreferencesQuickBuildSigningActionKey];
}

- (void)setQuickBuildSigningIdentity:(NSString *)inQuickBuildSigningIdentity
{
	_quickBuildSigningIdentity=[inQuickBuildSigningIdentity copy];
	
	[_defaults setObject:_quickBuildSigningIdentity forKey:PKGPreferencesQuickBuildSigningIdentityKey];
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

- (void)setIncludeTimestampInSignature:(BOOL)inBool
{
	_embedTimestampInSignature=inBool;
	
	[_defaults setBool:inBool forKey:PKGPreferencesBuildEmbedTrustedTimestampInSignatureKey];
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

- (void)setDefaultLocationOfNewProjects:(NSString *)inPath
{
	_defaultLocationOfNewProjects=[inPath copy];
	
	[_defaults setObject:[inPath copy] forKey:PKGPreferencesProjectAssistantDefaultNewProjectLocationKey];
}

@end
