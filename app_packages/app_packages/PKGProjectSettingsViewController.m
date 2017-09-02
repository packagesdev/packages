/*
 Copyright (c) 2017, Stephane Sudre
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

#import "PKGTableViewDataSource.h"

#import "PKGCertificateSealWindowController.h"



#import "PKGCertificatesUtilities.h"

#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <SecurityInterface/SFCertificatePanel.h>

#import "NSAlert+block.h"

@interface PKGProjectSettingsViewController () <PKGFilePathTextFieldDelegate>
{
	IBOutlet NSTextField * _buildNameTextField;
	
	IBOutlet NSPopUpButton * _buildReferenceFolderPopUpButton;
	
	IBOutlet NSView * _exclusionsPlaceHolderView;
	
	IBOutlet NSButton * _filterPayloadOnlyCheckbox;
	
	PKGPayloadExclusionsViewController * _exclusionsViewController;
	
	PKGTableViewDataSource * _fileFiltersDataSource;
	
	PKGCertificateSealWindowController * _certificateSealWindowController;
	
	SFChooseIdentityPanel * _chooseIdentityPanel;
}

	@property (readwrite) IBOutlet PKGFilePathTextField * buildPathTextField;


- (void)selectCertificateDidEnd:(NSWindow *) inSheet returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;



- (void)updateCertificateSeal;

- (IBAction)setProjectName:(id)sender;

- (IBAction)setBuildPath:(id)sender;
- (IBAction)selectBuildPath:(id)sender;
- (IBAction)showBuildPathInFinder:(id)sender;

- (IBAction)setReferenceFolder:(id)sender;
- (IBAction)resetReferenceFolder:(id)sender;

- (IBAction)setFilterPayloadOnly:(id)sender;

// Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation PKGProjectSettingsViewController

#pragma mark -

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
    // Exclusions
	
	_exclusionsViewController=[PKGPayloadExclusionsViewController new];
	
	_exclusionsViewController.view.frame=_exclusionsPlaceHolderView.bounds;
	
	[_exclusionsPlaceHolderView addSubview:_exclusionsViewController.view];
}

#pragma mark -

- (void)setProjectSettings:(PKGProjectSettings *)inProjectSettings
{
	if (_projectSettings!=inProjectSettings)
	{
		_projectSettings=inProjectSettings;
		
		if (_projectSettings!=nil)
			_fileFiltersDataSource=[[PKGTableViewDataSource alloc] initWithItems:_projectSettings.filesFilters];
		else
			_fileFiltersDataSource=nil;
		
		[self refreshUI];
	}
}

#pragma mark -

- (void)refreshUI
{
	if (_buildNameTextField==nil)
		return;
	
	// Certificate Seal
	
	[self updateCertificateSeal];
	
	// Build Name
	
	_buildNameTextField.stringValue=(self.projectSettings.name==nil) ? @"" : self.projectSettings.name;
	
	// Build Path
	
	self.buildPathTextField.filePath=self.projectSettings.buildPath;
	
	// Reference Folder
	
	NSMenuItem * tMenuItem=[_buildReferenceFolderPopUpButton itemAtIndex:0];
	
	if (tMenuItem!=nil)
	{
		NSImage * tImage=nil;
		
		NSString * tReferenceFolderPath=self.projectSettings.referenceFolderPath;
		
		if (tReferenceFolderPath==nil)
		{
			tMenuItem.title=NSLocalizedString(@"Project Folder",@"");
			
			_buildReferenceFolderPopUpButton.toolTip=nil;
			
			tImage=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		}
		else
		{
			tMenuItem.title=([tReferenceFolderPath isEqualToString:@"/"]==NO) ? tReferenceFolderPath.lastPathComponent : @"/";
			
			_buildReferenceFolderPopUpButton.toolTip=tReferenceFolderPath;
			
			tImage=[[NSWorkspace sharedWorkspace] iconForFile:tReferenceFolderPath];
		}
		
		if (tImage!=nil)
		{
			tImage.size=NSMakeSize(16.0,16.0);
			
			tMenuItem.image=tImage;
		}
	}
	
	// Exclusions
	
	_exclusionsViewController.fileFiltersDataSource=_fileFiltersDataSource;
	
	_filterPayloadOnlyCheckbox.state=(self.projectSettings.filterPayloadOnly==YES) ? NSOnState : NSOffState;
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self updateLayout];
	
	[_exclusionsViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self refreshUI];
	
	[_exclusionsViewController WB_viewDidAppear];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
	
	//[self.view.window makeFirstResponder:_buildNameTextField];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
	
	if (_certificateSealWindowController!=nil)
	{
		[self.view.window removeChildWindow:_certificateSealWindowController.window];
		
		[_certificateSealWindowController.window orderOut:self];
		
		_certificateSealWindowController=nil;
	}
	
	[_exclusionsViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_exclusionsViewController WB_viewDidDisappear];
}

- (void)updateLayout
{
	if (_certificateSealWindowController!=nil)
	{
		NSRect tWindowFrame=_certificateSealWindowController.window.frame;
		NSRect tFrame=((NSView *)self.view.window.contentView).frame;
		tWindowFrame.origin=[self.view.window convertRectToScreen:NSMakeRect(NSMaxX(tFrame)-NSWidth(tWindowFrame)+30.0,NSMaxY(tFrame)-48.0,0.0,0.0)].origin;
		
		[_certificateSealWindowController.window setFrameOrigin:tWindowFrame.origin];
	}
}

#pragma mark -

- (BOOL)isSignable
{
	return YES;
}

- (NSString *)certificatePanelMessage
{
	return @"";
}

- (void)updateCertificateSeal
{
	if (self.projectSettings.certificateName!=nil)
	{
		if (_certificateSealWindowController==nil)
		{
			_certificateSealWindowController=[[PKGCertificateSealWindowController alloc] init];
			
			_certificateSealWindowController.nextResponder=self;
		}
		
		SecCertificateRef tCertificateRef=[PKGCertificatesUtilities copyOfCertificateWithName:self.projectSettings.certificateName];
			
		_certificateSealWindowController.certificate=tCertificateRef;
			
		if (tCertificateRef!=NULL)
			CFRelease(tCertificateRef);
			
		if (_certificateSealWindowController.window.parentWindow==nil)
		{
			NSRect tWindowFrame=_certificateSealWindowController.window.frame;
			NSRect tFrame=((NSView *)self.view.window.contentView).frame;
			tWindowFrame.origin=[self.view.window convertRectToScreen:NSMakeRect(NSMaxX(tFrame)-NSWidth(tWindowFrame)+30.0,NSMaxY(tFrame)-48.0,0.0,0.0)].origin;
			
			[_certificateSealWindowController.window setFrame:tWindowFrame display:NO];
			
			[self.view.window addChildWindow:_certificateSealWindowController.window ordered:NSWindowAbove];
		}

		[_certificateSealWindowController.window performSelector:@selector(orderFront:) withObject:self afterDelay:0.21];	// A AMELIORER (the default duration is 0.20 for the apparition of the window)
		
		return;
	}
	
	if (self.projectSettings.certificateName==nil && _certificateSealWindowController!=nil)
	{
		[self.view.window removeChildWindow:_certificateSealWindowController.window];
		
		[_certificateSealWindowController.window orderOut:self];
		
		_certificateSealWindowController=nil;
	}
}

#pragma mark -

- (IBAction)selectCertificate:(id)sender
{
	NSArray * tIdentitiesArray=[PKGCertificatesUtilities availableIdentities];
	
	if (tIdentitiesArray.count==0)
	{
		NSAlert * tAlert=[NSAlert new];
		
		tAlert.messageText=NSLocalizedString(@"No certificates Alert Message Text",@"");
		tAlert.informativeText=NSLocalizedString(@"No certificates Alert Informative Text",@"");
		
		[tAlert addButtonWithTitle:NSLocalizedString(@"OK",@"No Comment")];
		[tAlert addButtonWithTitle:NSLocalizedString(@"Go to Apple Developer website",@"No Comment")];
		
		[tAlert WB_beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bReturnCode){
		
			if (bReturnCode==NSAlertSecondButtonReturn)
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"url.apple.developer.website.certificates",@"")]];
		}];
		
		return;
	}
	
	_chooseIdentityPanel=[SFChooseIdentityPanel new];
	
	[_chooseIdentityPanel setInformativeText:NSLocalizedString(@"Certificate Chooser Informative Text",@"")];
	
	[_chooseIdentityPanel setAlternateButtonTitle:NSLocalizedString(@"Cancel",@"")];
	
	[_chooseIdentityPanel beginSheetForWindow:self.view.window
								modalDelegate:self
							   didEndSelector:@selector(selectCertificateDidEnd:returnCode:contextInfo:)
								  contextInfo:NULL
								   identities:tIdentitiesArray
									  message:self.certificatePanelMessage];
}

- (void)selectCertificateDidEnd:(NSWindow *)inSheet returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	if (inReturnCode!=NSOKButton)
		return;
	
	SecIdentityRef tIdentityRef=[_chooseIdentityPanel identity];
	
	if (tIdentityRef==NULL)
	{
	}
	
	SecCertificateRef tCertificateRef;
	OSStatus tStatus=SecIdentityCopyCertificate(tIdentityRef,&tCertificateRef);
	
	if (tStatus!=noErr)
	{
	}
	
	CFStringRef tCertificateNameRef;
	
	if (SecCertificateCopyCommonName(tCertificateRef, &tCertificateNameRef)!=errSecSuccess)
	{
		NSBeep();
		
		CFRelease(tCertificateRef);
		
		NSAlert * tAlert=[NSAlert new];
		
		tAlert.alertStyle=NSWarningAlertStyle;
		
		tAlert.messageText=NSLocalizedString(@"The Identity of the certificate could not be retrieved.",@"No comment");
		tAlert.informativeText=NSLocalizedString(@"Packages will keep using the previous certificate set.",@"No comment");
		
		[tAlert runModal];
		
		return;
	}
	
	self.projectSettings.certificateName=(__bridge_transfer NSString *)tCertificateNameRef;
	self.projectSettings.certificateKeychainPath=[@"~/Library/Keychains/login.keychain" stringByExpandingTildeInPath];
		
	[self updateCertificateSeal];
		
	// Notify Document Change
		
	[self noteDocumentHasChanged];
	
	// Release Memory
	
	CFRelease(tCertificateRef);
}

- (IBAction)removeCertificate:(id) sender
{
	NSAlert * tAlert=[NSAlert new];
	
	tAlert.messageText=NSLocalizedString(@"Do you really want to remove the certificate?",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove_Certificate",@"No Comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No Comment")];
	
	[tAlert WB_beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bReturnCode){
		
		if (bReturnCode==NSAlertSecondButtonReturn)
			return;
		
		_chooseIdentityPanel=nil;	// Good opportunity to release this panel
		
		self.projectSettings.certificateName=nil;
		self.projectSettings.certificateKeychainPath=nil;
		
		[self updateCertificateSeal];
		
		// Notify Document Change
		
		[self noteDocumentHasChanged];
	}];
}

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
				
				self.buildPathTextField.filePath=self.projectSettings.buildPath;
				
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
						[tMenuItem setTitle:([tReferenceFolderPath isEqualToString:@"/"]==NO) ? tReferenceFolderPath.lastPathComponent : @"/"];
							
						_buildReferenceFolderPopUpButton.toolTip=tReferenceFolderPath;
							
						NSImage * tImage=[[NSWorkspace sharedWorkspace] iconForFile:tReferenceFolderPath];
						
						if (tImage!=nil)
						{
							tImage.size=NSMakeSize(16.0,16.0);
							
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
			tMenuItem.title=NSLocalizedString(@"Project Folder",@"");
				
			_buildReferenceFolderPopUpButton.toolTip=nil;
				
			NSImage * tImage=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
			
			if (tImage!=nil)
			{
				tImage.size=NSMakeSize(16.0,16.0);
				
				tMenuItem.image=tImage;
			}
		}
		
		[self noteDocumentHasChanged];
	}
	
	[_buildReferenceFolderPopUpButton selectItemAtIndex:0];
}

- (IBAction)setFilterPayloadOnly:(NSButton *)sender
{
	BOOL tNewValue=(sender.state==NSOnState);
	
	if (self.projectSettings.filterPayloadOnly!=tNewValue)
	{
		self.projectSettings.filterPayloadOnly=tNewValue;
		
		[self noteDocumentHasChanged];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *) inMenuItem
{
	SEL tAction=[inMenuItem action];
	
	if (tAction==@selector(selectCertificate:))
	{
		if (self.isSignable==NO)
			return NO;
		
		if (self.projectSettings.certificateName==nil)
			[inMenuItem setTitle:NSLocalizedString(@"Set Certificate...",@"")];
		else
			[inMenuItem setTitle:NSLocalizedString(@"Change Certificate...",@"")];
		
		return YES;
	}
	
	if (tAction==@selector(removeCertificate:))
	{
		if (self.isSignable==NO)
			return NO;
		
		return (self.projectSettings.certificateName!=nil);
	}
	
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
			inMenuItem.title=NSLocalizedString(@"Revert to Default",@"");
			inMenuItem.action=@selector(resetReferenceFolder:);
		}
		
		return YES;
	}
	
	if (tAction==@selector(resetReferenceFolder:))
	{
		if (self.projectSettings.referenceFolderPath==nil || ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)!=NSAlternateKeyMask)
		{
			inMenuItem.title=NSLocalizedString(@"Other...",@"");
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
	if (inFilePathTextField==self.buildPathTextField)
	{
		BOOL isDirectory;
		
		return ([[NSFileManager defaultManager] fileExistsAtPath:inPath isDirectory:&isDirectory]==YES && isDirectory==YES);
	}
	
	return NO;
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	[self updateLayout];
}

@end
