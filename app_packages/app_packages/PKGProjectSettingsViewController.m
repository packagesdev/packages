/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGProjectSettingsViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGPayloadExclusionsViewController.h"

#import "PKGFileFiltersDataSource.h"

#import "PKGFilePathTextField.h"

@interface PKGProjectSettingsViewController () <PKGFilePathTextFieldDelegate>
{
	IBOutlet NSTextField * _buildNameTextField;
	
	IBOutlet PKGFilePathTextField * _buildPathTextField;
	
	IBOutlet NSPopUpButton * _buildReferenceFolderPopUpButton;
	
	IBOutlet NSView * _exclusionsPlaceHolderView;
	
	IBOutlet NSButton * _filterPayloadOnlyCheckbox;
	
	PKGPayloadExclusionsViewController * _exclusionsViewController;
}

- (IBAction)setProjectName:(id)sender;

- (IBAction)setBuildPath:(id)sender;
- (IBAction)selectBuildPath:(id)sender;
- (IBAction)showBuildPathInFinder:(id)sender;

- (IBAction)setReferenceFolder:(id)sender;
- (IBAction)resetReferenceFolder:(id)sender;

@end

@implementation PKGProjectSettingsViewController

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Exclusions
	
	_exclusionsViewController=[PKGPayloadExclusionsViewController new];
	
	_exclusionsViewController.view.frame=_exclusionsPlaceHolderView.bounds;
	
	[_exclusionsPlaceHolderView addSubview:_exclusionsViewController.view];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	// Build Name
	
	_buildNameTextField.stringValue=(self.projectSettings.name==nil) ? @"" : self.projectSettings.name;
	
	// Build Path
	
	_buildPathTextField.filePath=self.projectSettings.buildPath;
	
	// Reference Folder
	
	NSMenuItem * tMenuItem=[_buildReferenceFolderPopUpButton itemAtIndex:0];
	
	if (tMenuItem!=nil)
	{
		NSImage * tImage=nil;
		
		NSString * tReferenceFolderPath=self.projectSettings.referenceFolderPath;
		
		if (tReferenceFolderPath==nil)
		{
			tMenuItem.title=NSLocalizedStringFromTable(@"Project Folder",@"Project",@"");
			
			_buildReferenceFolderPopUpButton.toolTip=nil;
			
			tImage=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		}
		else
		{
			tMenuItem.title=([tReferenceFolderPath isEqualToString:@"/"]==NO) ? [tReferenceFolderPath lastPathComponent] : @"/";
			
			_buildReferenceFolderPopUpButton.toolTip=tReferenceFolderPath;
			
			tImage=[[NSWorkspace sharedWorkspace] iconForFile:tReferenceFolderPath];
		}
		
		if (tImage!=nil)
		{
			tImage.size=NSMakeSize(16.0f,16.0);
			
			tMenuItem.image=tImage;
		}
	}
	
	// Exclusions
	
	PKGFileFiltersDataSource * tDataSource=[[PKGFileFiltersDataSource alloc] initWithFileFilters:self.projectSettings.filesFilters];
	
	_exclusionsViewController.fileFiltersDataSource=tDataSource;
	
	_filterPayloadOnlyCheckbox.state=(self.projectSettings.filterPayloadOnly==YES) ? NSOnState : NSOffState;
	
	[_exclusionsViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[_exclusionsViewController WB_viewDidAppear];
	
	[self.view.window makeFirstResponder:_buildNameTextField];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_exclusionsViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_exclusionsViewController WB_viewDidDisappear];
}

#pragma mark -

- (IBAction)setProjectName:(NSTextField *)sender
{
	NSString * tOldProjectName=(self.projectSettings.name==nil) ? @"" : self.projectSettings.name;
	
	if ([tOldProjectName isEqualToString:sender.stringValue]==YES)
		return;
	
	self.projectSettings.name=sender.stringValue;
	
	[self noteDocumentHasChanged];
}

- (IBAction)setBuildPath:(PKGFilePathTextField *)sender
{
	PKGFilePath * tFilePath=[sender filePath];
	
	if (tFilePath==nil)
		return;
	
	if ([self.projectSettings.buildPath isEqualToFilePath:tFilePath]==NO)
	{
		self.projectSettings.buildPath=tFilePath;
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)selectBuildPath:(id)sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.canChooseFiles=NO;
	tOpenPanel.canChooseDirectories=YES;
	tOpenPanel.canCreateDirectories=YES;
	
	tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
	
	NSString * tOldBuildPath=[self.filePathConverter absolutePathForFilePath:self.projectSettings.buildPath];
	
	if (tOldBuildPath!=nil)
		tOpenPanel.directoryURL=[NSURL fileURLWithPath:tOldBuildPath];
	
	dispatch_async(dispatch_get_main_queue(), ^{	// Dispatched to avoid the lack of animation for the sheet because of the dumb popupbutton animation
		[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
			
			if (bResult==NSFileHandlingPanelOKButton)
			{
				NSString * tNewBuildPath=tOpenPanel.URL.path;
				
				if ([tNewBuildPath isEqualToString:tOldBuildPath]==YES)
					return;
				
				PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:tNewBuildPath type:self.projectSettings.buildPath.type];
				
				if (tFilePath==nil)
				{
					NSBeep();
					
					return;
				}
				
				self.projectSettings.buildPath=tFilePath;
				
				[_buildPathTextField setFilePath:self.projectSettings.buildPath];
				
				[self noteDocumentHasChanged];
			}
		}];
	});
}

- (IBAction)showBuildPathInFinder:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:[self.filePathConverter absolutePathForFilePath:self.projectSettings.buildPath] inFileViewerRootedAtPath:@""];
}

- (IBAction)setReferenceFolder:(id)sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.resolvesAliases=NO;
	
	tOpenPanel.canChooseFiles=NO;
	tOpenPanel.canChooseDirectories=YES;
	tOpenPanel.canCreateDirectories=NO;
	
	tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
	
	if (self.projectSettings.referenceFolderPath!=nil)
		tOpenPanel.directoryURL=[NSURL fileURLWithPath:self.projectSettings.referenceFolderPath];
	
	dispatch_async(dispatch_get_main_queue(), ^{	// Dispatched to avoid the lack of animation for the sheet because of the dumb popupbutton animation
		[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
			
			if (bResult==NSFileHandlingPanelOKButton)
			{
				NSString * tReferenceFolderPath=tOpenPanel.URL.path;
				
				if ([self.projectSettings.referenceFolderPath isEqualToString:tReferenceFolderPath]==NO)
				{
					self.projectSettings.referenceFolderPath=tReferenceFolderPath;
					
					NSMenuItem * tMenuItem=[_buildReferenceFolderPopUpButton itemAtIndex:0];
					
					if (tMenuItem!=nil)
					{
						[tMenuItem setTitle:([tReferenceFolderPath isEqualToString:@"/"]==NO) ? [tReferenceFolderPath lastPathComponent] : @"/"];
							
						_buildReferenceFolderPopUpButton.toolTip=tReferenceFolderPath;
							
						NSImage * tImage=[[NSWorkspace sharedWorkspace] iconForFile:tReferenceFolderPath];
						
						if (tImage!=nil)
						{
							tImage.size=NSMakeSize(16.0f,16.0);
							
							tMenuItem.image=tImage;
						}
					}
					
					[self noteDocumentHasChanged];
				}
			}
			
			[_buildReferenceFolderPopUpButton selectItemAtIndex:0];
		}];
	});
}

- (IBAction)resetReferenceFolder:(id)sender
{
	if (self.projectSettings.referenceFolderPath!=nil)
	{
		self.projectSettings.referenceFolderPath=nil;
		
		NSMenuItem * tMenuItem=[_buildReferenceFolderPopUpButton itemAtIndex:0];
		
		if (tMenuItem!=nil)
		{
			tMenuItem.title=NSLocalizedStringFromTable(@"Project Folder",@"Project",@"");
				
			_buildReferenceFolderPopUpButton.toolTip=nil;
				
			NSImage * tImage=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
			
			if (tImage!=nil)
			{
				tImage.size=NSMakeSize(16.0f,16.0);
				
				tMenuItem.image=tImage;
			}
		}
		
		[self noteDocumentHasChanged];
	}
	
	[_buildReferenceFolderPopUpButton selectItemAtIndex:0];
}


- (BOOL) validateMenuItem:(NSMenuItem *) inMenuItem
{
	SEL tAction=[inMenuItem action];
	
	/*if (tAction==@selector(changeCertificate:))
	{
		if (cachedBuildFormat_==ICDOCUMENT_PROJECT_SETTINGS_BUILD_FORMAT_FLAT)
		{
			if (cachedCertificateDictionary_==nil || [cachedCertificateDictionary_ count]==0)
			{
				[inMenuItem setTitle:NSLocalizedStringFromTable(@"Set Certificate...",@"Project",@"")];
			}
			else
			{
				[inMenuItem setTitle:NSLocalizedStringFromTable(@"Change Certificate...",@"Project",@"")];
			}
			
			return YES;
		}
		
		return NO;
	}
	
	 if (tAction==@selector(removeCertificate:))
	{
		if (cachedBuildFormat_!=ICDOCUMENT_PROJECT_SETTINGS_BUILD_FORMAT_FLAT || cachedCertificateDictionary_==nil || [cachedCertificateDictionary_ count]==0)
		{
			return NO;
		}
	}
	*/
	if (tAction==@selector(showBuildPathInFinder:))
	{
		NSString * tPath=[self.filePathConverter absolutePathForFilePath:self.projectSettings.buildPath];
		
		if (tPath==nil)
			return NO;
		
		return [[NSFileManager defaultManager] fileExistsAtPath:tPath];
	}
	
	if (tAction==@selector(setReferenceFolder:))
	{
		if (self.projectSettings.referenceFolderPath!=nil && ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)==NSAlternateKeyMask)
		{
			inMenuItem.title=NSLocalizedStringFromTable(@"Revert to Default",@"Project",@"");
			inMenuItem.action=@selector(resetReferenceFolder:);
		}
		
		return YES;
	}
	
	if (tAction==@selector(resetReferenceFolder:))
	{
		if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)!=NSAlternateKeyMask)
		{
			inMenuItem.title=NSLocalizedStringFromTable(@"Other...",@"Project",@"");
			inMenuItem.action=@selector(setReferenceFolder:);
		}
		
		return YES;
	}
	
	return YES;
}

#pragma mark -

- (void)control:(NSControl *)inControl didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)inErrorDescription
{
	if ([inErrorDescription isEqualToString:@"Error"]==YES)
		NSBeep();
}

#pragma mark - PKGFilePathTextFieldDelegate

- (BOOL)filePathTextField:(PKGFilePathTextField *)inFilePathTextField shouldAcceptFile:(NSString *)inPath
{
	if (inFilePathTextField==_buildPathTextField)
	{
		BOOL isDirectory;
		
		return ([[NSFileManager defaultManager] fileExistsAtPath:inPath isDirectory:&isDirectory]==YES && isDirectory==YES);
	}
	
	return NO;
}

@end
