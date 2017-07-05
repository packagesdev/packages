/*
 Copyright (c) 2008-2017, Stephane Sudre
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



@interface PKGPreferencePaneBuildViewController () <PKGFileDeadDropViewDelegate>
{
	IBOutlet NSPopUpButton * _unsavedProjectBehaviorPopUpButton;
	
	
	IBOutlet NSPopUpButton * _showBuildWindowBehaviorPopUpButton;
	
	IBOutlet NSPopUpButton * _hideBuildWindowBehaviorPopUpButton;
	
	
	IBOutlet NSPopUpButton * _playSoundOnSuccessPopUpButton;
	
	IBOutlet NSPopUpButton * _playSoundOnErrorsPopUpButton;
	
	
	IBOutlet NSButton * _quickBuildUseBundleVersionCheckBox;
	
	IBOutlet NSPopUpButton * _quickBuildFailoverFolderPopUpButton;
	
	
	IBOutlet PKGTemporaryBuildLocationView * _temporaryBuildLocationView;
	
	IBOutlet NSImageView * _temporaryBuildLocationIconImageView;
	
	IBOutlet PKGVerticallyCenteredTextField * _temporaryBuildLocationTextField;
}

+ (NSMenu *)soundMenu;

- (void)refreshTemporaryBuildLocationUI;

- (void)setFailoverFolder:(NSString *) inFolderPath;


- (IBAction)switchUnsavedProjectBehavior:(id) sender;


- (IBAction)switchShowBuildWindowBehavior:(id) sender;

- (IBAction)switchHideBuildWindowBehavior:(id) sender;


- (IBAction)switchPlaySoundOnSuccess:(id) sender;

- (IBAction)switchPlaySoundOnErrors:(id) sender;


- (IBAction)setQuickBuildUseBundleVersion:(id) sender;

- (IBAction)switchQuickBuildFailoverFolder:(id) sender;


- (IBAction)setTemporaryBuildLocation:(id) sender;

@end

@implementation PKGPreferencePaneBuildViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	[_temporaryBuildLocationView setDelegate:self];
	
	[_playSoundOnSuccessPopUpButton setMenu:[PKGPreferencePaneBuildViewController soundMenu]];
	
	[_playSoundOnErrorsPopUpButton setMenu:[PKGPreferencePaneBuildViewController soundMenu]];
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self refreshUI];
}

#pragma mark -

- (void)refreshTemporaryBuildLocationUI
{
	NSString * tPath=[PKGApplicationPreferences sharedPreferences].temporaryBuildLocation;
	
	_temporaryBuildLocationTextField.stringValue=tPath;
	
	NSImage * tImage;
	BOOL isDirectory;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:tPath isDirectory:&isDirectory]==YES)
	{
		tImage=[[NSWorkspace sharedWorkspace] iconForFile:tPath];
		
		if (isDirectory==NO)
			_temporaryBuildLocationTextField.textColor=[NSColor redColor];
	}
	else
	{
		tImage=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kQuestionMarkIcon)];
		
		_temporaryBuildLocationTextField.textColor=[NSColor redColor];
	}
	
	tImage.size=NSMakeSize(32.0f,32.0f);
	
	_temporaryBuildLocationIconImageView.image=tImage;
}

- (void)refreshUI
{
	[_unsavedProjectBehaviorPopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].unsavedProjectSaveBehavior];
	
	// Build Window
	
	[_showBuildWindowBehaviorPopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].showBuildWindowBehavior];
	
	[_hideBuildWindowBehaviorPopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].hideBuildWindowBehavior];
	
	// Build Result
	
	NSString * tSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForSuccessfulBuild;
	
	[_playSoundOnSuccessPopUpButton selectItemAtIndex:(tSoundName.length==0) ? 0 : [_playSoundOnSuccessPopUpButton indexOfItemWithTitle:tSoundName]];
	
	tSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForFailedBuild;
	
	[_playSoundOnErrorsPopUpButton selectItemAtIndex:(tSoundName.length==0) ? 0 : [_playSoundOnErrorsPopUpButton indexOfItemWithTitle:tSoundName]];
	
	// Quick Build
	
	[_quickBuildUseBundleVersionCheckBox setState:([PKGApplicationPreferences sharedPreferences].useBundleVersionForQuickBuild==YES) ? NSOnState : NSOffState];
	
	[self setFailoverFolder:[PKGApplicationPreferences sharedPreferences].failOverFolderForQuickBuild];
	
	// Temporary Build Location
	
	[self refreshTemporaryBuildLocationUI];
}

#pragma mark -

+ (NSMenu *)soundMenu
{
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
		
	NSMenu * tMenu=[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
	
	if (tMenu==nil)
		return nil;
	
	if (tMutableSet.count==0)
		return tMenu;
	
	// Sort by Names
	
	NSArray * tSortedArray=[tMutableSet.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Mute",@"No comment")
													  action:nil
											   keyEquivalent:@""];
	
	if (tMenuItem!=nil)
	{
		tMenuItem.tag=-1;
		
		[tMenu addItem:tMenuItem];
	}
	
	tMenuItem=[NSMenuItem separatorItem];
	
	if (tMenuItem!=nil)
		[tMenu addItem:tMenuItem];
	
	for(NSString * tTitle in tSortedArray)
	{
		tMenuItem=[[NSMenuItem alloc] initWithTitle:tTitle
											 action:nil
									  keyEquivalent:@""];

		if (tMenuItem!=nil)
			[tMenu addItem:tMenuItem];
	}
	
	return tMenu;
}

- (void)setFailoverFolder:(NSString *) inFolderPath
{
	if (inFolderPath!=nil)
	{
		BOOL isDirectory=YES;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:inFolderPath isDirectory:&isDirectory]==NO)
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
			
			tMenuItem.title=inFolderPath.lastPathComponent;
		}
	}
	
	[_quickBuildFailoverFolderPopUpButton selectItemWithTag:0];
}

#pragma mark -

- (IBAction)switchUnsavedProjectBehavior:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].unsavedProjectSaveBehavior=_unsavedProjectBehaviorPopUpButton.selectedItem.tag;
}

- (IBAction)switchShowBuildWindowBehavior:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].showBuildWindowBehavior=_showBuildWindowBehaviorPopUpButton.selectedItem.tag;
}

- (IBAction)switchHideBuildWindowBehavior:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].hideBuildWindowBehavior=_hideBuildWindowBehaviorPopUpButton.selectedItem.tag;
}

- (IBAction)switchPlaySoundOnSuccess:(NSPopUpButton *) sender
{
	NSString * tOldSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForSuccessfulBuild;
	NSMenuItem * tMenuItem=sender.selectedItem;
	NSInteger tTag=tMenuItem.tag;
	
	if (tTag==-1)
	{
		if (tOldSoundName.length>0)
			[PKGApplicationPreferences sharedPreferences].playedSoundForSuccessfulBuild=@"";
		
		return;
	}
	
	NSString * tSoundName=tMenuItem.title;
		
	[PKGApplicationPreferences sharedPreferences].playedSoundForSuccessfulBuild=tSoundName;
	
	[[NSSound soundNamed:tSoundName] play];
}

- (IBAction)switchPlaySoundOnErrors:(NSPopUpButton *) sender
{
	NSString * tOldSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForFailedBuild;
	NSMenuItem * tMenuItem=sender.selectedItem;
	NSInteger tTag=tMenuItem.tag;
	
	if (tTag==-1)
	{
		if (tOldSoundName.length>0)
			[PKGApplicationPreferences sharedPreferences].playedSoundForFailedBuild=@"";
		
		return;
	}

	NSString * tSoundName=tMenuItem.title;
	
	[PKGApplicationPreferences sharedPreferences].playedSoundForFailedBuild=tSoundName;
	
	[[NSSound soundNamed:tSoundName] play];
}

- (IBAction)setQuickBuildUseBundleVersion:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].useBundleVersionForQuickBuild=(_quickBuildUseBundleVersionCheckBox.state==NSOnState);
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
			
			if (bResult==NSFileHandlingPanelOKButton)
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
		
		if (bResult!=NSFileHandlingPanelOKButton)
			return;
		
		[PKGApplicationPreferences sharedPreferences].temporaryBuildLocation=tOpenPanel.URL.path;
		
		[self refreshTemporaryBuildLocationUI];
	}];
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
