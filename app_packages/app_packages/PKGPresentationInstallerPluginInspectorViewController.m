/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationInstallerPluginInspectorViewController.h"

#import "PKGDistributionPresentationInstallerPluginOpenPanelDelegate.h"

#import "PKGArchitectureUtilities.h"

#import "PKGPresentationSection+UI.h"

@interface PKGPresentationInstallerPluginInspectorViewController ()
{
	IBOutlet NSImageView * _iconView;
	
	IBOutlet NSTextField * _bigNameTextField;
	
	IBOutlet NSTextField * _lastModifiedDateTextField;
	
	IBOutlet NSTextField * _architecturesLabel;
	
	IBOutlet NSTextField * _architecturesTextField;
	
	IBOutlet NSTextField * _versionTextField;
	
	IBOutlet NSTextField * _referenceTypeTextField;
	
	IBOutlet NSPopUpButton * _referenceTypePopUpButton;
	
	IBOutlet NSPopUpButton * _sourcePopUpButton;
	
	IBOutlet NSTextField * _sourcePathTextField;
	
	
	PKGDistributionPresentationInstallerPluginOpenPanelDelegate * _openPanelDelegate;
	
	PKGPresentationSection * _presentationSection;
}

- (IBAction)switchFilePathType:(id)sender;

- (IBAction)showInFinder:(id)sender;

- (IBAction)choosePluginSource:(id)sender;

// Notifications

- (void)pluginPathDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationInstallerPluginInspectorViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSection:(PKGPresentationSection *)inPresentationSection
{
	self=[super initWithDocument:inDocument presentationSection:inPresentationSection];
	
	if (self!=nil)
	{
		_presentationSection=inPresentationSection;
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	NSDateFormatter * tDateFormater=[NSDateFormatter new];
	
	tDateFormater.formatterBehavior=NSDateFormatterBehavior10_4;
	tDateFormater.dateStyle=NSDateFormatterMediumStyle;
	tDateFormater.timeStyle=NSDateFormatterShortStyle;
	
	_lastModifiedDateTextField.formatter=tDateFormater;
}

#pragma mark -

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginPathDidChange:) name:PKGPresentationSectionPluginPathDidChangeNotification object:_presentationSection];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPresentationSectionPluginPathDidChangeNotification object:nil];
}

- (void)refreshUI
{
	if (_iconView==nil)
		return;
	
	// Icon
	
	if (_presentationSection.pluginPath.isSet==NO)
	{
		// Oh oh
		
		return;
	}
	
	// Big Name
	
	_bigNameTextField.stringValue=_presentationSection.pluginPath.string.lastPathComponent;
	
	// Reference
	
	[_referenceTypePopUpButton selectItemWithTag:_presentationSection.pluginPath.type];
	
	// Source
	
	_sourcePathTextField.stringValue=_presentationSection.pluginPath.string;
	
	// Others
	
	NSString * tPath=[self.filePathConverter absolutePathForFilePath:_presentationSection.pluginPath];
	
	if (tPath==nil)
	{
		NSLog(@"Unable to determine absolute path for file path (%@)",_presentationSection.pluginPath);
		
		return;
	}
	
	
	BOOL tPluginExists=[[NSFileManager defaultManager] fileExistsAtPath:tPath];
	
	if (tPluginExists==NO)
	{
		// Last Modification Date
		
		_lastModifiedDateTextField.stringValue=@"-";
		
		// Architectures
		
		_architecturesLabel.stringValue=NSLocalizedString(@"Architectures:",@"");
		_architecturesTextField.stringValue=@"-";
		
		// Version
		
		_versionTextField.stringValue=@"-";
		
		// Reference
		
		_referenceTypePopUpButton.enabled=NO;
		
		// Source
		
		_sourcePathTextField.textColor=[NSColor redColor];
	}
	else
	{
		NSError * tError=nil;
		
		NSDictionary * tAttributesDictionary=[[NSFileManager defaultManager] attributesOfItemAtPath:tPath error:&tError];
		
		if (tAttributesDictionary==nil)
		{
			if ([tError.domain isEqualToString:NSCocoaErrorDomain]==NO || tError.code!=NSFileReadNoSuchFileError)
			{
				NSLog(@"Could not read file attributes");
				
				return;
			}
			
			// Following code works also for a nil attributesDictionary
		}
	
		// Last Modification Date
	
		NSDate * tModificationDate=tAttributesDictionary[NSFileModificationDate];
		
		if (tModificationDate!=nil)
			_lastModifiedDateTextField.objectValue=tModificationDate;
		else
			_lastModifiedDateTextField.stringValue=@"-";
		
		// Architectures
		
		_architecturesLabel.stringValue=NSLocalizedString(@"Architectures:",@"");
		_architecturesTextField.stringValue=@"-";
		

		NSBundle * tBundle=[NSBundle bundleWithPath:tPath];
		NSString * tIdentifier=tBundle.infoDictionary[@"CFBundleIdentifier"];
		NSString * tExecutableFilePath=nil;
		
		if ([tIdentifier isKindOfClass:NSString.class]==YES && tIdentifier.length>0)
			tExecutableFilePath=tBundle.executablePath;
		
		NSArray * tArchitecturesArray=nil;
		
		if (tExecutableFilePath!=nil)
			tArchitecturesArray=[PKGArchitectureUtilities architecturesOfFileAtPath:tExecutableFilePath];
			
		if (tArchitecturesArray.count>0)
		{
			// Label
			
			if (tArchitecturesArray.count==1)
				_architecturesLabel.stringValue=NSLocalizedString(@"Architecture:",@"");
			
			_architecturesTextField.stringValue=[tArchitecturesArray componentsJoinedByString:@" | "];
		}
	
		// Version
	
		NSString * tShortVersionString=tBundle.infoDictionary[@"CFShortVersionString"];
		NSString * tBundleVersionString=tBundle.infoDictionary[@"CFBundleVersion"];
		
		NSString * tFormattedVersionString=@"-";
		
		if (tShortVersionString.length>0)
		{
			if (tBundleVersionString.length>0)
				tFormattedVersionString=[NSString stringWithFormat:@"%@ (%@)",tShortVersionString,tBundleVersionString];
			else
				tFormattedVersionString=tShortVersionString;
		}
		else
		{
			if (tBundleVersionString.length>0)
				tFormattedVersionString=tBundleVersionString;
		}
		
		_versionTextField.stringValue=tFormattedVersionString;
		
		// Reference
		
		_referenceTypePopUpButton.enabled=YES;
		
		// Source
		
		_sourcePathTextField.textColor=[NSColor labelColor];
	}
}

#pragma mark -

- (IBAction)switchFilePathType:(NSPopUpButton *)sender
{
	PKGFilePathType tType=[sender selectedItem].tag;
	
	if (tType==_presentationSection.pluginPath.type)
		return;
	
	if ([self.filePathConverter shiftTypeOfFilePath:_presentationSection.pluginPath toType:tType]==NO)
	{
		// A COMPLETER
	}
	
	_sourcePathTextField.stringValue=_presentationSection.pluginPath.string;
	
	[self noteDocumentHasChanged];
}

- (IBAction)showInFinder:(id)sender
{
	NSString * tPath=[self.filePathConverter absolutePathForFilePath:_presentationSection.pluginPath];
	
	if (tPath==nil)
		return;
	
	[[NSWorkspace sharedWorkspace] selectFile:tPath inFileViewerRootedAtPath:@""];
}

- (IBAction)choosePluginSource:(id)sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.canChooseFiles=YES;
	tOpenPanel.canChooseDirectories=NO;
	
	_openPanelDelegate=[PKGDistributionPresentationInstallerPluginOpenPanelDelegate new];
	
	NSString * tCurrentPluginPath=[self.filePathConverter absolutePathForFilePath:_presentationSection.pluginPath];
	
	_openPanelDelegate.plugInsPaths=(tCurrentPluginPath==nil) ? @[] : @[tCurrentPluginPath];
	
	tOpenPanel.delegate=_openPanelDelegate;
	
	if (tCurrentPluginPath!=nil && [[NSFileManager defaultManager] fileExistsAtPath:tCurrentPluginPath]==YES)
		tOpenPanel.directoryURL=[NSURL fileURLWithPath:[tCurrentPluginPath stringByDeletingLastPathComponent]];
	
	tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
	
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult!=WBFileHandlingPanelOKButton)
			return;
		
		PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:tOpenPanel.URL.path type:_presentationSection.pluginPath.type];
		
		if (tFilePath==nil)
		{
			return;
		}
		
		_presentationSection.pluginPath.string=tFilePath.string;
		
		// Post Notification
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationSectionPluginPathDidChangeNotification object:_presentationSection];
		
		[self noteDocumentHasChanged];
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(showInFinder:))
	{
		if (_presentationSection.pluginPath.isSet==NO)
			return NO;
		
		NSString * tPath=[self.filePathConverter absolutePathForFilePath:_presentationSection.pluginPath];
		
		if (tPath==nil)
		{
			// Oh oh
			
			NSLog(@"Unable to determine absolute path for file path (%@)",_presentationSection.pluginPath);
			
			return NO;
		}
		
		return [[NSFileManager defaultManager] fileExistsAtPath:tPath];
	}
	
	return YES;
}

#pragma mark -

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	[self refreshUI];
}

- (void)pluginPathDidChange:(NSNotification *)inNotification
{
	[self refreshUI];
}

@end
