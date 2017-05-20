/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationBackgroundInspectorViewController.h"

#import "PKGPresentationBackgroundSettings+UI.h"

#import "PKGApplicationPreferences.h"

#import "PKGOwnershipAndReferenceStyleViewController.h"
#import "PKGOwnershipAndReferenceStylePanel.h"

#import "PKGReferencedPopUpButton.h"

#import "NSFileManager+FileTypes.h"
#import "NSImage+Size.h"

#import "PKGPresentationBackgroundSettings+UI.h"

@interface PKGPresentationBackgroundOpenPanelDelegate : NSObject<NSOpenSavePanelDelegate>
{
	NSFileManager * _fileManager;
}

	@property NSString * imagePath;

@end

@implementation PKGPresentationBackgroundOpenPanelDelegate

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_fileManager=[NSFileManager defaultManager];
	}
	
	return self;
}

#pragma mark -

- (BOOL)panel:(NSOpenPanel *)inPanel shouldEnableURL:(NSURL *)inURL
{
	if (inURL.isFileURL==NO)
		return NO;
	
	NSString * tPath=inURL.path;
	
	BOOL tIsDirectory=NO;
	
	[_fileManager fileExistsAtPath:tPath isDirectory:&tIsDirectory];
	
	if (tIsDirectory==YES)
		return YES;
	
	if (self.imagePath!=nil && [self.imagePath caseInsensitiveCompare:tPath]==NSOrderedSame)
		return NO;
	
	BOOL tImageFormatSupported=[_fileManager WB_fileAtPath:tPath matchesTypes:[PKGPresentationBackgroundSettings backgroundImageTypes]];
	
	if (tImageFormatSupported==YES)
		return YES;
	
	CGImageSourceRef tSourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef) inURL, NULL);
	
	if (tSourceRef==NULL)
		return NO;
	
	NSString * tImageUTI=(__bridge NSString *) CGImageSourceGetType(tSourceRef);
	
	if (tImageUTI!=nil)
		tImageFormatSupported=[[PKGPresentationBackgroundSettings backgroundImageUTIs] containsObject:tImageUTI];
	
	// Release Memory
	
	CFRelease(tSourceRef);
	
	return tImageFormatSupported;
}

@end

@interface PKGPresentationBackgroundInspectorViewController () <PKGReferencedPopUpButtonDelegate>
{
	IBOutlet NSPopUpButton * _showPopUpButton;
	
	IBOutlet PKGReferencedPopUpButton * _customBackgroundPopUpButton;
	
	IBOutlet NSTextField * _sizeLabel;
	
	IBOutlet NSMatrix * _alignmentMatrix;
	
	IBOutlet NSPopUpButton * _scalingPopUpButton;
	
	PKGPresentationBackgroundOpenPanelDelegate * _openPanelDelegate;
	
	PKGPresentationBackgroundSettings * _backgroundSettings;
}

- (IBAction)switchBackgroundValue:(id)sender;

- (IBAction)chooseCustomBackground:(id)sender;

- (IBAction)switchAlignment:(id)sender;
- (IBAction)switchScaling:(id)sender;

@end

@implementation PKGPresentationBackgroundInspectorViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	if (self!=nil)
	{
		_backgroundSettings=[inPresentationSettings backgroundSettings];
	}
	
	return self;
}

#pragma mark -

- (void)WB_viewDidLoad
{
	_customBackgroundPopUpButton.delegate=self;
	
	[_customBackgroundPopUpButton unregisterDraggedTypes];
	[_customBackgroundPopUpButton registerForDraggedTypes:@[NSFilenamesPboardType]];
}

#pragma mark -

- (PKGPresentationStepSettings *)settings
{
	return _backgroundSettings;
}

#pragma mark -

- (void)refreshUI
{
	if (_showPopUpButton==nil)
		return;
	
	BOOL tShowCustomImage=_backgroundSettings.showCustomImage;
	
	[_showPopUpButton selectItemWithTag:(tShowCustomImage==YES) ? PKGPresentationBackgroundSettingsCustomBackground : PKGPresentationBackgroundSettingsDefaultBackground];

	// Path
	
	_customBackgroundPopUpButton.enabled=tShowCustomImage;
	
	[_customBackgroundPopUpButton setFileNameWithPath:(tShowCustomImage==YES) ? _backgroundSettings.imagePath.string : nil];
	
	_customBackgroundPopUpButton.pathType=(_backgroundSettings.imagePath!=nil) ? _backgroundSettings.imagePath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	_customBackgroundPopUpButton.toolTip=(tShowCustomImage==YES) ? _backgroundSettings.imagePath.string : nil;
	
	if (_backgroundSettings.imagePath.isSet==NO)
	{
		[_customBackgroundPopUpButton setFileNotFound:NO];
		_sizeLabel.stringValue=@"";
	}
	else
	{
		NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:_backgroundSettings.imagePath];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:tAbsolutePath]==YES)
		{
			[_customBackgroundPopUpButton setFileNotFound:NO];
			
			NSSize tSize=[NSImage WB_sizeOfImageAtPath:tAbsolutePath];
			
			_sizeLabel.stringValue=[NSString stringWithFormat:@"%ldx%ld",lround(tSize.width),lround(tSize.height)];
		}
		else
		{
			[_customBackgroundPopUpButton setFileNotFound:YES];
			_sizeLabel.stringValue=@"";
		}
	}
	
	// Alignment
	
	_alignmentMatrix.enabled=tShowCustomImage;
	[_alignmentMatrix selectCellWithTag:_backgroundSettings.imageAlignment];
	
	// Scaling
	
	_scalingPopUpButton.enabled=tShowCustomImage;
	[_scalingPopUpButton selectItemWithTag:_backgroundSettings.imageScaling];
}

#pragma mark -

- (IBAction)switchBackgroundValue:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	BOOL tCustomBackground=(tTag==PKGPresentationBackgroundSettingsCustomBackground);
	
	if (tCustomBackground==_backgroundSettings.showCustomImage)
		return;
	
	_backgroundSettings.showCustomImage=tCustomBackground;
	
	[self refreshUI];
}

- (IBAction)chooseCustomBackground:(id)sender
{
	// Use dispatch_async to fluidify the animation (because of NSPopUpButton stupidity)
	
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString * tAbsoluteImagePath=(_backgroundSettings.imagePath.isSet==YES) ? [self.filePathConverter absolutePathForFilePath:_backgroundSettings.imagePath] : nil;
	
		NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
		
		tOpenPanel.canChooseFiles=YES;
		tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
		tOpenPanel.treatsFilePackagesAsDirectories=YES;
		if (tAbsoluteImagePath!=nil)
			tOpenPanel.directoryURL=[NSURL fileURLWithPath:[tAbsoluteImagePath stringByDeletingLastPathComponent] isDirectory:YES];
		
		
		_openPanelDelegate=[PKGPresentationBackgroundOpenPanelDelegate new];
		_openPanelDelegate.imagePath=tAbsoluteImagePath;
		
		tOpenPanel.delegate=_openPanelDelegate;
		
		__block PKGFilePathType tReferenceStyle=(_backgroundSettings.imagePath!=nil) ? _backgroundSettings.imagePath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		PKGOwnershipAndReferenceStyleViewController * tOwnershipAndReferenceStyleViewController=nil;
		
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
		{
			tOwnershipAndReferenceStyleViewController=[PKGOwnershipAndReferenceStyleViewController new];
			
			tOwnershipAndReferenceStyleViewController.canChooseOwnerAndGroupOptions=NO;
			tOwnershipAndReferenceStyleViewController.referenceStyle=tReferenceStyle;
			
			NSView * tAccessoryView=tOwnershipAndReferenceStyleViewController.view;
			
			tOpenPanel.accessoryView=tAccessoryView;
		}
		
		[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
			
			if (bResult!=NSFileHandlingPanelOKButton)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
				
					[_customBackgroundPopUpButton selectItemAtIndex:0];
				});
				
				return;
			}
			
			if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
				tReferenceStyle=tOwnershipAndReferenceStyleViewController.referenceStyle;
			
			NSArray * tPaths=[tOpenPanel.URLs WB_arrayByMappingObjectsUsingBlock:^(NSURL * bURL,NSUInteger bIndex){
				
				return bURL.path;
			}];
			
			_backgroundSettings.imagePath=[self.filePathConverter filePathForAbsolutePath:tPaths[0] type:tReferenceStyle];
				
			[self noteDocumentHasChanged];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:_backgroundSettings];
				
				[self refreshUI];
				
				[_customBackgroundPopUpButton selectItemAtIndex:0];
			});
		}];
	});
}

- (IBAction)switchAlignment:(NSMatrix *)sender
{
	NSInteger tTag=((NSButtonCell *)sender.selectedCell).tag;
	
	if (tTag==_backgroundSettings.imageAlignment)
		return;
	
	_backgroundSettings.imageAlignment=tTag;
	
	[self noteDocumentHasChanged];
	
	// Post Notification
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
}

- (IBAction)switchScaling:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	if (tTag==_backgroundSettings.imageScaling)
		return;
	
	_backgroundSettings.imageScaling=tTag;
	
	[self noteDocumentHasChanged];
	
	// Post Notification
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
}

#pragma mark - PKGReferencedPopUpButtonDelegate

- (BOOL)referencedPopUpButton:(PKGReferencedPopUpButton *)inPopUpButton validateDropFile:(NSString *)inPath
{
	if (inPopUpButton!=_customBackgroundPopUpButton || inPath==nil)
		return NO;

	BOOL tImageFormatSupported=[[NSFileManager defaultManager] WB_fileAtPath:inPath matchesTypes:[PKGPresentationBackgroundSettings backgroundImageTypes]];
	
	if (tImageFormatSupported==YES)
		return YES;

	NSURL * tURL = [NSURL fileURLWithPath:inPath];
	
	CGImageSourceRef tSourceRef = CGImageSourceCreateWithURL((CFURLRef) tURL, NULL);
	
	if (tSourceRef==NULL)
		return NO;

	NSString * tImageUTI=(__bridge NSString *) CGImageSourceGetType(tSourceRef);
	
	if (tImageUTI!=nil)
		tImageFormatSupported=[[PKGPresentationBackgroundSettings backgroundImageUTIs] containsObject:tImageUTI];
	
	// Release Memory
	
	CFRelease(tSourceRef);
	
	return tImageFormatSupported;
}

- (BOOL)referencedPopUpButton:(PKGReferencedPopUpButton *)inPopUpButton acceptDropFile:(NSString *)inPath
{
	if (inPopUpButton!=_customBackgroundPopUpButton || inPath==nil)
		return NO;
	
	void (^finalizeSetBackgroundImagePath)(PKGFilePath *) = ^(PKGFilePath * bFilePath) {
		
		_backgroundSettings.imagePath=bFilePath;
		
		[self refreshUI];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:_backgroundSettings];
		
		[self noteDocumentHasChanged];
	};
	
	if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
	{
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		
		tPanel.canChooseOwnerAndGroupOptions=NO;
		tPanel.keepOwnerAndGroup=NO;
		tPanel.referenceStyle=(_backgroundSettings.imagePath!=nil) ? _backgroundSettings.imagePath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		[tPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bReturnCode){
			
			if (bReturnCode==PKGOwnershipAndReferenceStylePanelCancelButton)
				return;
			
			PKGFilePath * tNewFilePath=[self.filePathConverter filePathForAbsolutePath:inPath type:tPanel.referenceStyle];
			
			finalizeSetBackgroundImagePath(tNewFilePath);
		}];
		
		return YES;
	}
	
	PKGFilePathType tPathType=(_backgroundSettings.imagePath!=nil) ? _backgroundSettings.imagePath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:inPath type:tPathType];
	
	finalizeSetBackgroundImagePath(tFilePath);
	
	return YES;
}

- (void)referencedPopUpButtonReferenceStyleDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=_customBackgroundPopUpButton)
		return;
	
	if (_backgroundSettings.imagePath==nil)
		_backgroundSettings.imagePath=[PKGFilePath new];
	
	if ([self.filePathConverter shiftTypeOfFilePath:_backgroundSettings.imagePath toType:_customBackgroundPopUpButton.pathType]==NO)
	{
		// Oh oh
		
		return;
	}
	
	[self noteDocumentHasChanged];
	
	_customBackgroundPopUpButton.toolTip=_backgroundSettings.imagePath.string;
}

#pragma mark - Notifications

- (void)settingsDidChange:(NSNotification *)inNotification
{
	if (inNotification.userInfo==nil)
		return;
	
	[self refreshUI];
}

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	[self refreshUI];
}

@end
