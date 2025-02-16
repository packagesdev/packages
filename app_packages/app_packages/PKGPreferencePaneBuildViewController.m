/*
 Copyright (c) 2008-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPreferencePaneBuildViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGTemporaryBuildLocationView.h"
#import "PKGVerticallyCenteredTextField.h"

#import "PKGChooseIdentityPanel.h"

#import "NSArray+WBExtensions.h"

@interface PKGPreferencePaneBuildViewController () <PKGFileDeadDropViewDelegate>
{
	IBOutlet NSPopUpButton * _unsavedProjectBehaviorPopUpButton;
	
	
	IBOutlet NSPopUpButton * _showBuildWindowBehaviorPopUpButton;
	
	IBOutlet NSPopUpButton * _hideBuildWindowBehaviorPopUpButton;
	
	
	IBOutlet NSView * _buildResultBehaviorsTabHeaderView;
	
	IBOutlet NSButton * _playSoundCheckBox;
	
	IBOutlet NSPopUpButton * _soundNamePopUpButton;
	
	IBOutlet NSButton * _speakAnnouncementCheckBox;
	
	IBOutlet NSPopUpButton * _announcementVoicePopUpButton;
	
	IBOutlet NSButton * _notifyUsingSystemNotificationCheckBox;
	
	IBOutlet NSButton * _bounceIconInDockCheckBox;
	
	
	IBOutlet NSButton * _embedTrustedTimestampCheckBox;
	
	
	IBOutlet NSPopUpButton * _quickBuildSigningCertificatePopUpButton;
	
	IBOutlet NSButton * _quickBuildUseBundleVersionCheckBox;
	
	IBOutlet NSPopUpButton * _quickBuildFailoverFolderPopUpButton;
	
	
	IBOutlet PKGTemporaryBuildLocationView * _temporaryBuildLocationView;
	
	IBOutlet NSImageView * _temporaryBuildLocationIconImageView;
	
	IBOutlet PKGVerticallyCenteredTextField * _temporaryBuildLocationTextField;
	
	
	PKGPreferencesBuildResultBehaviorType _selectedBehaviorType;
	
	NSDictionary * _voiceDisplayNamesDictionary;
	
	NSDictionary * _voiceIdentifiersDictionary;
}

- (NSMenu *)soundsMenu;

- (NSMenu *)voicesMenu;

- (void)refreshBuildResultBehaviorUI;

- (void)refreshTemporaryBuildLocationUI;

- (void)setFailoverFolder:(NSString *)inFolderPath;


- (IBAction)switchUnsavedProjectBehavior:(id)sender;


- (IBAction)switchShowBuildWindowBehavior:(id)sender;

- (IBAction)switchHideBuildWindowBehavior:(id)sender;


- (IBAction)switchBuildResultBehavior:(id)sender;


- (IBAction)switchPlaySound:(id)sender;

- (IBAction)switchSoundName:(id)sender;

- (IBAction)switchSpeakAnnouncement:(id)sender;

- (IBAction)switchAnnouncementVoice:(id)sender;

- (IBAction)switchNotifyUsingSystemNotification:(id)sender;

- (IBAction)switchBounceIconInDock:(id)sender;


- (IBAction)switchEmbedTrustedTimestamp:(id)sender;


- (IBAction)switchQuickBuildSigningCertificate:(id)sender;

- (IBAction)setQuickBuildUseBundleVersion:(id)sender;

- (IBAction)switchQuickBuildFailoverFolder:(id)sender;


- (IBAction)setTemporaryBuildLocation:(id)sender;

@end

@implementation PKGPreferencePaneBuildViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	[_temporaryBuildLocationView setDelegate:self];
	
	_selectedBehaviorType=PKGPreferencesBuildResultBehaviorSuccess;
	
	[((NSButton *)[_buildResultBehaviorsTabHeaderView viewWithTag:_selectedBehaviorType]) setState:WBControlStateValueOn];
	
	
	[_soundNamePopUpButton setMenu:[self soundsMenu]];
	
	[_announcementVoicePopUpButton setMenu:[self voicesMenu]];
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self refreshUI];
}

#pragma mark -

- (void)refreshBuildResultBehaviorUI
{
	PKGApplicationBuildResultBehavior * tResultBehavior=[PKGApplicationPreferences sharedPreferences].buildResultBehaviors[_selectedBehaviorType];
	
	_playSoundCheckBox.state=tResultBehavior.playSound;
	
	_soundNamePopUpButton.enabled=tResultBehavior.playSound;
	
	NSString * tSoundName=tResultBehavior.soundName;
	
	[_soundNamePopUpButton selectItemAtIndex:(tSoundName.length==0) ? 0 : [_soundNamePopUpButton indexOfItemWithTitle:tSoundName]];
	
	
	_speakAnnouncementCheckBox.state=tResultBehavior.speakAnnouncement;
	
	_announcementVoicePopUpButton.enabled=tResultBehavior.speakAnnouncement;
	
	NSString * tAnnouncementVoice=tResultBehavior.announcementVoice;
	
	if (tAnnouncementVoice.length==0)
		tAnnouncementVoice=[NSSpeechSynthesizer defaultVoice];
	
	NSString * tVoiceDisplayName=_voiceDisplayNamesDictionary[tAnnouncementVoice];
	
	if (tVoiceDisplayName==nil)
		tVoiceDisplayName=_voiceDisplayNamesDictionary[[NSSpeechSynthesizer defaultVoice]];
	
	[_announcementVoicePopUpButton selectItemAtIndex:(tVoiceDisplayName.length==0) ? 0 : [_announcementVoicePopUpButton indexOfItemWithTitle:tVoiceDisplayName]];
	
	
	_notifyUsingSystemNotificationCheckBox.state=tResultBehavior.notifyUsingSystemNotification;
	
	_bounceIconInDockCheckBox.state=tResultBehavior.bounceIconInDock;
}

- (void)refreshTemporaryBuildLocationUI
{
	NSString * tPath=[PKGApplicationPreferences sharedPreferences].temporaryBuildLocation;
	
	_temporaryBuildLocationTextField.stringValue=tPath;
	
	NSImage * tImage;
	BOOL isDirectory;
    BOOL tEverythingIsFine=YES;
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:tPath isDirectory:&isDirectory]==YES)
	{
		tImage=[[NSWorkspace sharedWorkspace] iconForFile:tPath];
		
        tEverythingIsFine=isDirectory;
	}
	else
	{
		tImage=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kQuestionMarkIcon)];
		
        tEverythingIsFine=NO;
	}
	
	tImage.size=NSMakeSize(32.0,32.0);
	
	_temporaryBuildLocationIconImageView.image=tImage;
    
	if (tEverythingIsFine==NO)
	{
		_temporaryBuildLocationTextField.textColor=[NSColor redColor];
	}
	else
	{
		_temporaryBuildLocationTextField.textColor=[NSColor labelColor];
	}
}

- (void)refreshUI
{
	[_unsavedProjectBehaviorPopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].unsavedProjectSaveBehavior];
	
	// Build Window
	
	[_showBuildWindowBehaviorPopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].showBuildWindowBehavior];
	
	[_hideBuildWindowBehaviorPopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].hideBuildWindowBehavior];
	
	// Build Result
	
	[self refreshBuildResultBehaviorUI];
	
	//Signing
	
	_embedTrustedTimestampCheckBox.state=([PKGApplicationPreferences sharedPreferences].embedTimestampInSignature==YES) ? WBControlStateValueOn : WBControlStateValueOff;
	
	// Quick Build
	
	[_quickBuildSigningCertificatePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].quickBuildSigningAction];
	
	NSMenuItem * tMenuItem=[_quickBuildSigningCertificatePopUpButton itemAtIndex:[_quickBuildSigningCertificatePopUpButton indexOfItemWithTag:PKGPreferencesQuickBuildSigningSign]];
	
	NSString * tSigningIdentity=[PKGApplicationPreferences sharedPreferences].quickBuildSigningIdentity;
	
	if ([tSigningIdentity length]==0)
		tSigningIdentity=@"-";
	else
		tMenuItem.enabled=YES;
		
	tMenuItem.title=tSigningIdentity;
	
	[_quickBuildUseBundleVersionCheckBox setState:([PKGApplicationPreferences sharedPreferences].useBundleVersionForQuickBuild==YES) ? WBControlStateValueOn : WBControlStateValueOff];
	
	[self setFailoverFolder:[PKGApplicationPreferences sharedPreferences].failOverFolderForQuickBuild];
	
	// Temporary Build Location
	
	[self refreshTemporaryBuildLocationUI];
}

#pragma mark -

- (NSMenu *)soundsMenu
{
	static NSMenu * _sSoundsMenu=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSArray * tLibraryArray=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSSystemDomainMask+NSLocalDomainMask,NO);
		NSFileManager * tFileManager=[NSFileManager defaultManager];
		NSMutableSet * tMutableSet=[NSMutableSet set];
		
		for(NSString * tLibraryPath in tLibraryArray)
		{
			NSArray * tSoundsArray=[tFileManager contentsOfDirectoryAtPath:[tLibraryPath stringByAppendingPathComponent:@"Sounds"] error:NULL];
			
			for(NSString * tSoundFile in tSoundsArray)
			{
				if ([tSoundFile.pathExtension caseInsensitiveCompare:@"aiff"]==NSOrderedSame)
					[tMutableSet addObject:tSoundFile.stringByDeletingPathExtension];
			}
		}
		
		_sSoundsMenu=[[NSMenu alloc] initWithTitle:@""];
		
		if (tMutableSet.count>0)
		{
			// Sort by Names
			
			NSArray * tSortedArray=[tMutableSet.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
			
			NSMenuItem * tMenuItem;
			
			for(NSString * tTitle in tSortedArray)
			{
				tMenuItem=[[NSMenuItem alloc] initWithTitle:tTitle
													 action:nil
											  keyEquivalent:@""];
				
				if (tMenuItem!=nil)
					[_sSoundsMenu addItem:tMenuItem];
			}
		}
	});
	
	return [_sSoundsMenu copy];
}

- (NSMenu *)voicesMenu
{
	static NSMenu * _sVoicesMenu=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		NSArray * tAvailableVoiceIdentifiers=[NSSpeechSynthesizer availableVoices];
		
		NSMutableDictionary * tMutableVoiceDisplayNamesDictionary=[NSMutableDictionary dictionary];
		NSMutableDictionary * tMutableVoiceIdentifiersDictionary=[NSMutableDictionary dictionary];
		
		NSArray * tDisplayVoiceNames=[tAvailableVoiceIdentifiers WB_arrayByMappingObjectsLenientlyUsingBlock:^NSString *(NSString * bVoiceIdentifier, NSUInteger bIndex) {
			NSString * tVoiceDisplayName=[[NSSpeechSynthesizer attributesForVoice:bVoiceIdentifier] objectForKey:NSVoiceName];
			
			if (tVoiceDisplayName==nil)
				return nil;
			
			tMutableVoiceDisplayNamesDictionary[bVoiceIdentifier]=tVoiceDisplayName;
			tMutableVoiceIdentifiersDictionary[tVoiceDisplayName]=bVoiceIdentifier;
			
			return tVoiceDisplayName;
		}];
		
		_voiceDisplayNamesDictionary=[tMutableVoiceDisplayNamesDictionary copy];
		_voiceIdentifiersDictionary=[tMutableVoiceIdentifiersDictionary copy];
		
		NSMutableSet * tMutableSet=[NSMutableSet setWithArray:tDisplayVoiceNames];
		
		_sVoicesMenu=[[NSMenu alloc] initWithTitle:@""];
		
		if (tMutableSet.count>0)
		{
			// Sort by Names
		
			NSArray * tSortedArray=[tMutableSet.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
			
			NSMenuItem * tMenuItem;
			
			for(NSString * tTitle in tSortedArray)
			{
				tMenuItem=[[NSMenuItem alloc] initWithTitle:tTitle
													 action:nil
											  keyEquivalent:@""];
				
				if (tMenuItem!=nil)
					[_sVoicesMenu addItem:tMenuItem];
			}
		}
	});
	
	return [_sVoicesMenu copy];
}

- (void)setFailoverFolder:(NSString *)inFolderPath
{
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	if (inFolderPath!=nil)
	{
		BOOL isDirectory=YES;
		
		if ([tFileManager fileExistsAtPath:inFolderPath isDirectory:&isDirectory]==NO)
		{
			inFolderPath=nil;
			
			NSLog(@"QuickBuild failover path does not exist");
		}
		else
		{
			if (isDirectory==NO)
			{
				inFolderPath=nil;
				
				NSLog(@"QuickBuild failover path is not a directory");
			}
		}
	}
	
	if (inFolderPath==nil)
		inFolderPath=NSHomeDirectory();
	
	if (inFolderPath!=nil)
	{
		NSMenuItem * tMenuItem=[[_quickBuildFailoverFolderPopUpButton menu] itemAtIndex:0];
		
		if (tMenuItem!=nil)
		{
			// Image
			
			NSImage * tImage=[[NSWorkspace sharedWorkspace] iconForFile:inFolderPath];
			
			if (tImage!=nil)
				tImage.size=NSMakeSize(16.0,16.0);
			
			tMenuItem.image=tImage;
			
			// Title
			
			tMenuItem.title=[tFileManager displayNameAtPath:inFolderPath];
		}
	}
	
	[_quickBuildFailoverFolderPopUpButton selectItemWithTag:0];
}

#pragma mark -

- (IBAction)switchUnsavedProjectBehavior:(id)sender
{
	[PKGApplicationPreferences sharedPreferences].unsavedProjectSaveBehavior=_unsavedProjectBehaviorPopUpButton.selectedItem.tag;
}

- (IBAction)switchShowBuildWindowBehavior:(id)sender
{
	[PKGApplicationPreferences sharedPreferences].showBuildWindowBehavior=_showBuildWindowBehaviorPopUpButton.selectedItem.tag;
}

- (IBAction)switchHideBuildWindowBehavior:(id)sender
{
	[PKGApplicationPreferences sharedPreferences].hideBuildWindowBehavior=_hideBuildWindowBehaviorPopUpButton.selectedItem.tag;
}


- (IBAction)switchBuildResultBehavior:(NSButton *)sender
{
	_selectedBehaviorType=sender.tag;
	
	[self refreshBuildResultBehaviorUI];
}

- (IBAction)switchPlaySound:(NSButton *)sender
{
	PKGApplicationBuildResultBehavior * tResultBehavior=[PKGApplicationPreferences sharedPreferences].buildResultBehaviors[_selectedBehaviorType];
	
	tResultBehavior.playSound=([sender state]==WBControlStateValueOn);
	
	_soundNamePopUpButton.enabled=tResultBehavior.playSound;
}

- (IBAction)switchSoundName:(NSPopUpButton *)sender
{
	PKGApplicationBuildResultBehavior * tResultBehavior=[PKGApplicationPreferences sharedPreferences].buildResultBehaviors[_selectedBehaviorType];
	
	NSMenuItem * tMenuItem=sender.selectedItem;
	
	NSString * tSoundName=tMenuItem.title;
	
	tResultBehavior.soundName=tSoundName;
	
	[[NSSound soundNamed:tSoundName] play];
}

- (IBAction)switchSpeakAnnouncement:(NSButton *)sender
{
	PKGApplicationBuildResultBehavior * tResultBehavior=[PKGApplicationPreferences sharedPreferences].buildResultBehaviors[_selectedBehaviorType];
	
	tResultBehavior.speakAnnouncement=([sender state]==WBControlStateValueOn);
	
	_announcementVoicePopUpButton.enabled=tResultBehavior.speakAnnouncement;
}

- (IBAction)switchAnnouncementVoice:(NSPopUpButton *)sender
{
	PKGApplicationBuildResultBehavior * tResultBehavior=[PKGApplicationPreferences sharedPreferences].buildResultBehaviors[_selectedBehaviorType];
	
	NSMenuItem * tMenuItem=sender.selectedItem;
	
	NSString * tAnnouncementVoiceDisplayName=tMenuItem.title;
	
	tResultBehavior.announcementVoice=_voiceIdentifiersDictionary[tAnnouncementVoiceDisplayName];
}

- (IBAction)switchNotifyUsingSystemNotification:(NSButton *)sender
{
	PKGApplicationBuildResultBehavior * tResultBehavior=[PKGApplicationPreferences sharedPreferences].buildResultBehaviors[_selectedBehaviorType];
	
	tResultBehavior.notifyUsingSystemNotification=([sender state]==WBControlStateValueOn);
}

- (IBAction)switchBounceIconInDock:(NSButton *)sender
{
	PKGApplicationBuildResultBehavior * tResultBehavior=[PKGApplicationPreferences sharedPreferences].buildResultBehaviors[_selectedBehaviorType];
	
	tResultBehavior.bounceIconInDock=([sender state]==WBControlStateValueOn);
}

- (IBAction)switchEmbedTrustedTimestamp:(NSButton *)sender
{
	[PKGApplicationPreferences sharedPreferences].embedTimestampInSignature=([sender state]==WBControlStateValueOn);
}



- (IBAction)switchQuickBuildSigningCertificate:(NSPopUpButton *)sender
{
	NSInteger tTag=[sender selectedItem].tag;
	
	if (tTag==-1)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			
			PKGChooseIdentityPanel * tChooseIdentityPanel=[PKGChooseIdentityPanel new];
			
			tChooseIdentityPanel.messageText=NSLocalizedString(@"Choose the certificate to be used for signing Quick Builds.",@"");
			tChooseIdentityPanel.informativeText=NSLocalizedString(@"Certificate Chooser Informative Text",@"");
			
			if ([tChooseIdentityPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bReturnCode) {
				
				if (bReturnCode==WBModalResponseCancel)
				{
					[_quickBuildSigningCertificatePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].quickBuildSigningAction];
					
					return;
				}
				
				[PKGApplicationPreferences sharedPreferences].quickBuildSigningIdentity=tChooseIdentityPanel.identity;
				
				[PKGApplicationPreferences sharedPreferences].quickBuildSigningAction=PKGPreferencesQuickBuildSigningSign;
				
				// Update the PopUpButton first menu item
				
				NSMenuItem * tMenuItem=[_quickBuildSigningCertificatePopUpButton itemAtIndex:[_quickBuildSigningCertificatePopUpButton indexOfItemWithTag:PKGPreferencesQuickBuildSigningSign]];
				
				tMenuItem.title=[PKGApplicationPreferences sharedPreferences].quickBuildSigningIdentity;
				tMenuItem.enabled=YES;
				
				[_quickBuildSigningCertificatePopUpButton selectItemWithTag:PKGPreferencesQuickBuildSigningSign];
			}]==NO)
			{
				// Revert to previously selected menu item
				
				[_quickBuildSigningCertificatePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].quickBuildSigningAction];
			}
		});
		
		return;
	}
	
	if (tTag!=[PKGApplicationPreferences sharedPreferences].quickBuildSigningAction)
	{
		[PKGApplicationPreferences sharedPreferences].quickBuildSigningAction=(PKGPreferencesQuickBuildSigningAction)tTag;
	}
}

- (IBAction)setQuickBuildUseBundleVersion:(id)sender
{
	[PKGApplicationPreferences sharedPreferences].useBundleVersionForQuickBuild=(_quickBuildUseBundleVersionCheckBox.state==WBControlStateValueOn);
}

- (IBAction)switchQuickBuildFailoverFolder:(id)sender
{
	// Use dispatch_async to fluidify the animation (because of NSPopUpButton stupidity)
	
	dispatch_async(dispatch_get_main_queue(), ^{
		NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
		
		tOpenPanel.canChooseFiles=NO;
		tOpenPanel.canChooseDirectories=YES;
		tOpenPanel.canCreateDirectories=YES;
		tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
		
		NSString * tPath=[[PKGApplicationPreferences sharedPreferences].failOverFolderForQuickBuild stringByExpandingTildeInPath];
		
		tOpenPanel.directoryURL=[NSURL fileURLWithPath:(tPath==nil) ? NSHomeDirectory() : tPath];
		
		[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
			
			if (bResult==WBFileHandlingPanelOKButton)
			{
				NSString * tPath=tOpenPanel.URL.path;
				
				[PKGApplicationPreferences sharedPreferences].failOverFolderForQuickBuild=tPath;
				
				[self setFailoverFolder:tPath];
			}
			else
			{
				[_quickBuildFailoverFolderPopUpButton selectItemWithTag:0];
			}
		}];
	});
}

- (IBAction)setTemporaryBuildLocation:(id)sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.canChooseFiles=NO;
	tOpenPanel.canChooseDirectories=YES;
	tOpenPanel.canCreateDirectories=YES;
	tOpenPanel.showsHiddenFiles=YES;
	tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
	
	NSString * tPath=[_temporaryBuildLocationTextField stringValue].stringByExpandingTildeInPath;
	
	if(tPath!=nil)
		tOpenPanel.directoryURL=[NSURL fileURLWithPath:tPath];
	
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult!=WBFileHandlingPanelOKButton)
			return;
		
		[PKGApplicationPreferences sharedPreferences].temporaryBuildLocation=tOpenPanel.URL.path;
		
		[self refreshTemporaryBuildLocationUI];
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchQuickBuildSigningCertificate:))
	{
		if (inMenuItem.tag==PKGPreferencesQuickBuildSigningSign)
		{
			NSString * tString=[PKGApplicationPreferences sharedPreferences].quickBuildSigningIdentity;
		
			if ([tString length]==0)
				return NO;
		}
	}
	
	return YES;
}

#pragma mark - PKGFileDeadDropViewDelegate

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView validateDropFiles:(NSArray *)inFilenames
{
	if (inFilenames.count!=1)
		return NO;
	
	BOOL isDirectory;
	
	return ([[NSFileManager defaultManager] fileExistsAtPath:[inFilenames objectAtIndex:0] isDirectory:&isDirectory]==YES && isDirectory==YES);
}

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView acceptDropFiles:(NSArray *)inFilenames
{
	if (inFilenames.count!=1)
		return NO;
	
	[PKGApplicationPreferences sharedPreferences].temporaryBuildLocation=[inFilenames firstObject];
	
	[self refreshTemporaryBuildLocationUI];
	
	return YES;
}

@end
