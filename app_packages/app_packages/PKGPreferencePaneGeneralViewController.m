/*
 Copyright (c) 2008-2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPreferencePaneGeneralViewController.h"

#import "PKGApplicationPreferences.h"

@interface PKGPreferencePaneGeneralViewController ()
{
	IBOutlet NSPopUpButton * _defaultNewProjectLocationPopUpButton;
	
	IBOutlet NSPopUpButton * _defaultReferenceStylePopUpButton;
	
	IBOutlet NSPopUpButton * _visibleDistributionProjectPanePopUpButton;
	
	IBOutlet NSPopUpButton * _visibleDistributionPackagePanePopUpButton;
	
	IBOutlet NSPopUpButton * _visiblePackageProjectPanePopUpButton;
	
	
}

- (void)setDefaultNewProjectLocation:(NSString *)inDefaultNewProjectLocation;


- (IBAction)switchDefaultNewProjectLocation:(id)sender;

- (IBAction)switchDefaultReferenceStyle:(id) sender;

- (IBAction)switchDefaultVisibleDistributionProjectPane:(id) sender;

- (IBAction)switchDefaultVisibleDistributionPackagePane:(id) sender;

- (IBAction)switchDefaultVisiblePackageProjectPane:(id) sender;

@end

@implementation PKGPreferencePaneGeneralViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// Reference Style
	
	[_defaultReferenceStylePopUpButton removeItemAtIndex:0];
}

- (void)WB_viewWillAppear
{
	[self setDefaultNewProjectLocation:[PKGApplicationPreferences sharedPreferences].defaultLocationOfNewProjects];
	
	
	// Default Visibles Panes
	
	// Project
	
	[_visibleDistributionProjectPanePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].defaultVisibleDistributionProjectPane];
	
	// Package
	
	[_visibleDistributionPackagePanePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].defaultVisibleDistributionPackageComponentPane];
	
	// Package Standalone
	
	[_visiblePackageProjectPanePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].defaultVisiblePackageProjectPane];
	
	// Default Reference Style
	
	[_defaultReferenceStylePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle];
}

#pragma mark -

- (void)setDefaultNewProjectLocation:(NSString *)inDefaultNewProjectLocation
{
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	if (inDefaultNewProjectLocation!=nil)
	{
		inDefaultNewProjectLocation=[inDefaultNewProjectLocation stringByExpandingTildeInPath];
		
		BOOL isDirectory=YES;
		
		if ([tFileManager fileExistsAtPath:inDefaultNewProjectLocation isDirectory:&isDirectory]==NO)
		{
			inDefaultNewProjectLocation=nil;
			
			NSLog(@"Default New Project Location path does not exist");
		}
		else
		{
			if (isDirectory==NO)
			{
				inDefaultNewProjectLocation=nil;
				
				NSLog(@"Default New Project Location path is not a directory");
			}
		}
	}
	
	if (inDefaultNewProjectLocation==nil)
		inDefaultNewProjectLocation=NSHomeDirectory();
	
	if (inDefaultNewProjectLocation!=nil)
	{
		NSMenuItem * tMenuItem=[[_defaultNewProjectLocationPopUpButton menu] itemAtIndex:0];
		
		if (tMenuItem!=nil)
		{
			// Image
			
			NSImage * tImage=[[NSWorkspace sharedWorkspace] iconForFile:inDefaultNewProjectLocation];
			
			if (tImage!=nil)
				tImage.size=NSMakeSize(16.0,16.0);
			
			tMenuItem.image=tImage;
			
			// Title
			
			tMenuItem.title=[tFileManager displayNameAtPath:inDefaultNewProjectLocation];
		}
	}
	
	[_defaultNewProjectLocationPopUpButton selectItemWithTag:0];
}

#pragma mark -

- (IBAction)switchDefaultNewProjectLocation:(id)sender
{
	// Use dispatch_async to fluidify the animation (because of NSPopUpButton stupidity)
	
	dispatch_async(dispatch_get_main_queue(), ^{
		NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
		
		tOpenPanel.canChooseFiles=NO;
		tOpenPanel.canChooseDirectories=YES;
		tOpenPanel.canCreateDirectories=YES;
		tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
		
		NSString * tPath=[[PKGApplicationPreferences sharedPreferences].defaultLocationOfNewProjects stringByExpandingTildeInPath];
		
		tOpenPanel.directoryURL=[NSURL fileURLWithPath:(tPath==nil) ? NSHomeDirectory() : tPath];
		
		[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
			
			if (bResult==WBFileHandlingPanelOKButton)
			{
				NSString * tPath=tOpenPanel.URL.path;
				
				[PKGApplicationPreferences sharedPreferences].defaultLocationOfNewProjects=[tPath stringByAbbreviatingWithTildeInPath];
				
				[self setDefaultNewProjectLocation:tPath];
			}
			else
			{
				[_defaultNewProjectLocationPopUpButton selectItemWithTag:0];
			}
		}];
	});
}

- (IBAction) switchDefaultReferenceStyle:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle=_defaultReferenceStylePopUpButton.selectedItem.tag;
}

- (IBAction)switchDefaultVisibleDistributionProjectPane:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].defaultVisibleDistributionProjectPane=_visibleDistributionProjectPanePopUpButton.selectedItem.tag;
}

- (IBAction)switchDefaultVisibleDistributionPackagePane:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].defaultVisibleDistributionPackageComponentPane=_visibleDistributionPackagePanePopUpButton.selectedItem.tag;
}

- (IBAction)switchDefaultVisiblePackageProjectPane:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].defaultVisiblePackageProjectPane=_visiblePackageProjectPanePopUpButton.selectedItem.tag;
}



@end
