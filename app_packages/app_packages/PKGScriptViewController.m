/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGScriptViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGOwnershipAndReferenceStyleViewController.h"
#import "PKGScriptDeadDropView.h"

#import "PKGTellerView.h"

@interface PKGScriptOpenPanelDelegate : NSObject<NSOpenSavePanelDelegate>

@property (copy) NSString * currentPath;

@end

@implementation PKGScriptOpenPanelDelegate

- (BOOL)panel:(NSOpenPanel *)inPanel shouldEnableURL:(NSURL *)inURL
{
	if (inURL.isFileURL==NO)
		return NO;
	
	return ([self.currentPath isEqualToString:inURL.path]==NO);
}

@end

@interface PKGScriptViewController () <PKGFileDeadDropViewDelegate,PKGScriptDeadDropViewDataSource>
{
	IBOutlet NSTextField * _viewLabel;
	
	IBOutlet PKGScriptDeadDropView * _scriptsDeadDropView;
	
	IBOutlet NSTextField * _scriptNameTextField;
	
	IBOutlet NSTextField * _lastModificationTextField;
	
	IBOutlet NSPopUpButton * _referenceStylePopUpButton;
	
	IBOutlet NSButton * _setButton;
	IBOutlet NSButton * _removeButton;
	
	PKGScriptOpenPanelDelegate * _openPanelDelegate;
	
	NSDateFormatter * _lastModifiedDateFormatter;
}

- (IBAction)showInFinder:(id)sender;
- (IBAction)openWithFinder:(id)sender;

- (IBAction)switchPathType:(NSPopUpButton *)sender;
- (IBAction)selectPath:(id)sender;
- (IBAction)removePath:(id)sender;

// Notification

- (void)windowDidChangeMain:(NSNotification *)inNotification;

@end

@implementation PKGScriptViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		_label=@"";
		
		_lastModifiedDateFormatter=[NSDateFormatter new];
		
		_lastModifiedDateFormatter.formatterBehavior=NSDateFormatterBehavior10_4;
		_lastModifiedDateFormatter.dateStyle=NSDateFormatterMediumStyle;
		_lastModifiedDateFormatter.timeStyle=NSDateFormatterShortStyle;
	}
	
	return self;
}

- (NSString *)nibName
{
	return NSStringFromClass([self class]);
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_scriptsDeadDropView.delegate=self;
	_scriptsDeadDropView.dataSource=self;
}

#pragma mark -

- (void)refreshUI
{
	BOOL tIsPathSet=(_installationScriptPath!=nil && _installationScriptPath.isSet==YES);
	
	// Type PullDown
	
	[_referenceStylePopUpButton selectItemWithTag:(_installationScriptPath==nil) ? [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle : _installationScriptPath.type];
	
	// Remove button
	
	_removeButton.hidden=(tIsPathSet==NO);
	
	// Icon
	
	[_scriptsDeadDropView reloadData];
	
	// File Name & Last Modified
	
	if (tIsPathSet==NO)
	{
		_scriptNameTextField.textColor=[NSColor tertiaryLabelColor];
		_scriptNameTextField.stringValue=NSLocalizedString(@"No Script Set",@"");
		_scriptNameTextField.toolTip=@"";
		
		_lastModificationTextField.stringValue=@"-";
		
		return;
	}
	
	_scriptNameTextField.stringValue=_installationScriptPath.lastPathComponent;
	
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:self.installationScriptPath];
	
	if (tAbsolutePath==nil)
	{
		_scriptNameTextField.toolTip=@"";
		_lastModificationTextField.stringValue=@"-";
		
		return;
	}
	
	_scriptNameTextField.toolTip=self.installationScriptPath.string;
	
	NSError * tError=nil;
	NSDictionary * tAttributes=[[NSFileManager defaultManager] attributesOfItemAtPath:tAbsolutePath error:&tError];
	
	if (tAttributes==nil)
	{
		if (tError!=nil)
		{
			if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES && tError.code==NSFileReadNoSuchFileError)
				_scriptNameTextField.textColor=[NSColor redColor];
		}
		
		_lastModificationTextField.stringValue=@"-";
		
		return;
	}
	
	_scriptNameTextField.textColor=[NSColor labelColor];
	
	_lastModificationTextField.stringValue=[_lastModifiedDateFormatter stringForObjectValue:tAttributes[NSFileModificationDate]];
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_viewLabel.stringValue=_label;
	
	[self refreshUI];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// This will allow us to display a question mark if the file can not be found following some user actions in another application
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeMain:) name:PKGWindowDidBecomeMainNotification object:self.view];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeMain:) name:PKGWindowDidResignMainNotification object:self.view];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGWindowDidBecomeMainNotification object:self.view];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGWindowDidResignMainNotification object:self.view];
}

#pragma mark -

- (void)setLabel:(NSString *)inLabel
{
	_label=(inLabel!=nil) ? [inLabel copy] : @"";
	
	if (_viewLabel!=nil)
		_viewLabel.stringValue=_label;
}

- (void)setInstallationScriptPath:(PKGFilePath *)inFilePath
{
	if (_installationScriptPath!=inFilePath)
		_installationScriptPath=inFilePath;
	
	[self refreshUI];
}

#pragma mark -

- (IBAction)showInFinder:(id)sender
{
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:self.installationScriptPath];
	
	if (tAbsolutePath==nil)
		return;
	
	[[NSWorkspace sharedWorkspace] selectFile:tAbsolutePath inFileViewerRootedAtPath:@""];
}

- (IBAction)openWithFinder:(id)sender
{
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:self.installationScriptPath];
	
	if (tAbsolutePath==nil)
		return;
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:tAbsolutePath]];
}

- (IBAction)switchPathType:(NSPopUpButton *)sender
{
	if (_installationScriptPath==nil)
		return;
	
	NSInteger tTag=[sender selectedTag];
	
	if (tTag!=_installationScriptPath.type)
	{
		if ([self.filePathConverter shiftTypeOfFilePath:_installationScriptPath toType:tTag]==NO)
		{
			NSLog(@"Unable to switch the path type");
			
			NSBeep();
			
			return;
		}
		
		if (_installationScriptPath.isSet==YES)
			_scriptNameTextField.toolTip=self.installationScriptPath.string;
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)selectPath:(id)sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.canChooseFiles=YES;
	tOpenPanel.canChooseDirectories=NO;
	tOpenPanel.canCreateDirectories=NO;
	
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:self.installationScriptPath];
	
	if (tAbsolutePath!=nil)
		tOpenPanel.directoryURL=[NSURL fileURLWithPath:[tAbsolutePath stringByDeletingLastPathComponent]];
	
	_openPanelDelegate=[PKGScriptOpenPanelDelegate new];
	
	_openPanelDelegate.currentPath=tAbsolutePath;
	
	tOpenPanel.delegate=_openPanelDelegate;
	
	tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
	
	__block PKGFilePathType tReferenceStyle=(self.installationScriptPath.isSet==YES) ? self.installationScriptPath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	PKGOwnershipAndReferenceStyleViewController * tOwnershipAndReferenceStyleViewController=nil;
	BOOL tShowOwnershipAndReferenceStyleCustomizationDialog=[PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog;
	
	
	if (tShowOwnershipAndReferenceStyleCustomizationDialog==YES)
	{
		tOwnershipAndReferenceStyleViewController=[PKGOwnershipAndReferenceStyleViewController new];
		
		tOwnershipAndReferenceStyleViewController.canChooseOwnerAndGroupOptions=NO;
		tOwnershipAndReferenceStyleViewController.referenceStyle=tReferenceStyle;
		
		NSView * tAccessoryView=tOwnershipAndReferenceStyleViewController.view;
		
		tOpenPanel.accessoryView=tAccessoryView;
	}
	
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult!=WBFileHandlingPanelOKButton)
			return;
		
		if (tShowOwnershipAndReferenceStyleCustomizationDialog==YES)
		{
			tReferenceStyle=tOwnershipAndReferenceStyleViewController.referenceStyle;
		}
		
		NSString * tNewPath=tOpenPanel.URL.path;
		
		if (tAbsolutePath!=nil && [tAbsolutePath caseInsensitiveCompare:tNewPath]==NSOrderedSame)
			return;
		
		PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:tNewPath type:tReferenceStyle];
		
		if (tFilePath==nil)
		{
			NSLog(@"<PKGScriptViewController> File Path conversion failed.");
			return;
		}
		
		self.installationScriptPath.string=tFilePath.string;
		self.installationScriptPath.type=tFilePath.type;
		
		[self noteDocumentHasChanged];
		
		[self refreshUI];
	}];
}

- (IBAction)removePath:(id)sender
{
	NSAlert * tAlert=[[NSAlert alloc] init];
	tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"Do you really want to remove the %@ script for this package?",@"No comment"),self.label.lowercaseString];
	tAlert.informativeText=NSLocalizedString(@"This cannot be undone.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Remove",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		self.installationScriptPath.string=nil;
		
		[self noteDocumentHasChanged];
		
		[self refreshUI];
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(showInFinder:) ||
		tAction==@selector(openWithFinder:))
		return self.installationScriptPath.isSet;
	
	if (tAction==@selector(switchPathType:))
		return YES;
	
	return YES;
}

#pragma mark - PKGFileDeadDropViewDelegate

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView validateDropFiles:(NSArray *)inFilenames
{
	if (inView==nil || inFilenames.count!=1)
		return NO;
	
	NSString * tPath=inFilenames[0];
	BOOL tIsDirectory=NO;
	
	return ([[NSFileManager defaultManager] fileExistsAtPath:tPath isDirectory:&tIsDirectory]==YES && tIsDirectory==NO);
}

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView acceptDropFiles:(NSArray *)inFilenames
{
	if (inView==nil || inFilenames.count!=1)
		return NO;
	
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:self.installationScriptPath];
	NSString * tNewPath=inFilenames[0];
	
	if (tAbsolutePath!=nil && [tAbsolutePath caseInsensitiveCompare:tNewPath]==NSOrderedSame)
		return NO;
	
	PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:tNewPath type:self.installationScriptPath.type];
	
	self.installationScriptPath.string=tFilePath.string;
	
	[self noteDocumentHasChanged];
	
	[self refreshUI];
	
	return YES;
}

#pragma mark - PKGScriptDeadDropViewDataSource

- (NSString *)pathForScriptDeadDropView:(PKGScriptDeadDropView *)inDeadDropView
{
	return [self.filePathConverter absolutePathForFilePath:self.installationScriptPath];
}

- (void)windowDidChangeMain:(NSNotification *)inNotification
{
	[self refreshUI];
}

@end
