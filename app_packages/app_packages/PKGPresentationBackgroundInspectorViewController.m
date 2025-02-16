/*
 Copyright (c) 2017-2018, Stephane Sudre
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
	IBOutlet NSButton * _sharedSettingsCheckBox;
	
	IBOutlet NSPopUpButton * _appearanceModePopUpButton;
	
	IBOutlet NSPopUpButton * _showPopUpButton;
	
	IBOutlet PKGReferencedPopUpButton * _customBackgroundPopUpButton;
	
	IBOutlet NSTextField * _sizeLabel;
	
	IBOutlet NSMatrix * _alignmentMatrix;
	
	IBOutlet NSButton * _layoutDirectionCheckBox;
	
	IBOutlet NSPopUpButton * _scalingPopUpButton;
	
	PKGPresentationBackgroundOpenPanelDelegate * _openPanelDelegate;
	
	PKGPresentationBackgroundSettings * _backgroundSettings;
	
	PKGPresentationAppearanceMode _selectedAppearanceMode;
}

- (IBAction)switchSharedSettingsValue:(id)sender;

- (IBAction)switchAppearanceMode:(id)sender;

- (IBAction)switchBackgroundValue:(id)sender;

- (IBAction)chooseCustomBackground:(id)sender;

- (IBAction)switchAlignment:(id)sender;

- (IBAction)switchLayoutDirection:(id)sender;

- (IBAction)switchScaling:(id)sender;

@end

@implementation PKGPresentationBackgroundInspectorViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	if (self!=nil)
	{
		_backgroundSettings=[inPresentationSettings backgroundSettings];
		
		_selectedAppearanceMode=PKGPresentationAppearanceModeShared;
	}
	
	return self;
}

#pragma mark -

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];

	// AppearanceMode popupbutton
	
	NSMenu * tApperancesModeMenu=_appearanceModePopUpButton.menu;
	
	[tApperancesModeMenu removeAllItems];
	
	[[PKGPresentationBackgroundAppearanceSettings allAppearancesNames] enumerateObjectsUsingBlock:^(NSString * bAppearanceName, NSUInteger bIndex, BOOL *bOutStop) {
		
		PKGPresentationAppearanceMode tAppearanceMode=[PKGPresentationBackgroundAppearanceSettings appearanceModeForAppearanceName:bAppearanceName];
		NSString * tLocalizationKey=[NSString stringWithFormat:@"title.appearance-mode.%d",(int)tAppearanceMode];
		
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(tLocalizationKey,@"Presentation",@"") action:nil keyEquivalent:@""];
		
		tMenuItem.tag=tAppearanceMode;
		
		[tApperancesModeMenu addItem:tMenuItem];
	}];
	
	_appearanceModePopUpButton.menu=tApperancesModeMenu;
	
	_customBackgroundPopUpButton.delegate=self;
	
	[_customBackgroundPopUpButton unregisterDraggedTypes];
	[_customBackgroundPopUpButton registerForDraggedTypes:@[NSFilenamesPboardType]];
}

#pragma mark -

- (PKGPresentationStepSettings *)settings
{
	return _backgroundSettings;
}

- (PKGPresentationBackgroundAppearanceSettings *)selectedAppearanceSettings
{
	BOOL tShareSettings=_backgroundSettings.sharedSettingsForAllAppearances;
	
	if (tShareSettings==YES)
		_selectedAppearanceMode=PKGPresentationAppearanceModeShared;
	
	return [_backgroundSettings appearanceSettingsForAppearanceMode:_selectedAppearanceMode];
}

#pragma mark -

- (void)refreshUI
{
	if (_showPopUpButton==nil)
		return;
	
	BOOL tShareSettings=_backgroundSettings.sharedSettingsForAllAppearances;
	
	_sharedSettingsCheckBox.state=(tShareSettings==YES) ? WBControlStateValueOn : WBControlStateValueOff;
	
	if (tShareSettings==YES)
		_selectedAppearanceMode=PKGPresentationAppearanceModeShared;
	
	NSMenuItem * tMenuItem=[_appearanceModePopUpButton  itemAtIndex:[_appearanceModePopUpButton indexOfItemWithTag:PKGPresentationAppearanceModeShared]];
	NSString * tLocalizationKey=[NSString stringWithFormat:@"title.appearance-mode.%d",(int)PKGPresentationAppearanceModeShared];
	
	tMenuItem.title=(tShareSettings==YES) ? @"-" : NSLocalizedStringFromTable(tLocalizationKey,@"Presentation",@"");
	
	[_appearanceModePopUpButton setEnabled:(tShareSettings==NO)];
	
	[_appearanceModePopUpButton selectItemWithTag:_selectedAppearanceMode];
	
	PKGPresentationBackgroundAppearanceSettings * tAppearanceSettings=[_backgroundSettings appearanceSettingsForAppearanceMode:_selectedAppearanceMode];
	
	
	BOOL tShowCustomImage=tAppearanceSettings.showCustomImage;
	
	[_showPopUpButton selectItemWithTag:(tShowCustomImage==YES) ? PKGPresentationBackgroundSettingsCustomBackground : PKGPresentationBackgroundSettingsDefaultBackground];

	
	
	// Path
	
	_customBackgroundPopUpButton.enabled=tShowCustomImage;
	
	[_customBackgroundPopUpButton setFileNameWithPath:(tShowCustomImage==YES) ? tAppearanceSettings.imagePath.string : nil];
	
	_customBackgroundPopUpButton.pathType=(tAppearanceSettings.imagePath!=nil) ? tAppearanceSettings.imagePath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	_customBackgroundPopUpButton.toolTip=(tShowCustomImage==YES) ? tAppearanceSettings.imagePath.string : nil;
	
	if (tAppearanceSettings.imagePath.isSet==NO)
	{
		[_customBackgroundPopUpButton setFileNotFound:NO];
		_sizeLabel.stringValue=@"";
	}
	else
	{
		NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tAppearanceSettings.imagePath];
		
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
	[_alignmentMatrix selectCellWithTag:tAppearanceSettings.imageAlignment];
	
	_layoutDirectionCheckBox.enabled=tShowCustomImage;
	_layoutDirectionCheckBox.state=(tAppearanceSettings.imageLayoutDirection==PKGImageLayoutDirectionNatural) ? WBControlStateValueOn : WBControlStateValueOff;
	
	// Scaling
	
	_scalingPopUpButton.enabled=tShowCustomImage;
	[_scalingPopUpButton selectItemWithTag:tAppearanceSettings.imageScaling];
}

#pragma mark -

- (IBAction)switchSharedSettingsValue:(id)sender
{
	BOOL tSharedSettings=([sender state]==WBControlStateValueOn);
	
	if (tSharedSettings==_backgroundSettings.sharedSettingsForAllAppearances)
		return;
	
	_backgroundSettings.sharedSettingsForAllAppearances=tSharedSettings;
	
	[self noteDocumentHasChanged];
	
	// Post Notification
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
	
	[self refreshUI];
}

- (IBAction)switchAppearanceMode:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	if (tTag==_selectedAppearanceMode)
		return;
	
	_selectedAppearanceMode=tTag;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:_backgroundSettings];
	
	[self refreshUI];
}

- (IBAction)switchBackgroundValue:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	PKGPresentationBackgroundAppearanceSettings * tSelectedAppearanceSettings=[self selectedAppearanceSettings];
	
	BOOL tCustomBackground=(tTag==PKGPresentationBackgroundSettingsCustomBackground);
	
	if (tCustomBackground==tSelectedAppearanceSettings.showCustomImage)
		return;
	
	tSelectedAppearanceSettings.showCustomImage=tCustomBackground;
	
	[self noteDocumentHasChanged];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:_backgroundSettings];
	
	[self refreshUI];
}

- (IBAction)chooseCustomBackground:(id)sender
{
	// Use dispatch_async to fluidify the animation (because of NSPopUpButton stupidity)
	
	dispatch_async(dispatch_get_main_queue(), ^{
		PKGPresentationBackgroundAppearanceSettings * tSelectedAppearanceSettings=[self selectedAppearanceSettings];
		
		NSString * tAbsoluteImagePath=(tSelectedAppearanceSettings.imagePath.isSet==YES) ? [self.filePathConverter absolutePathForFilePath:tSelectedAppearanceSettings.imagePath] : nil;
	
		NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
		
		tOpenPanel.canChooseFiles=YES;
		tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
		tOpenPanel.treatsFilePackagesAsDirectories=YES;
		if (tAbsoluteImagePath!=nil)
			tOpenPanel.directoryURL=[NSURL fileURLWithPath:[tAbsoluteImagePath stringByDeletingLastPathComponent] isDirectory:YES];
		
		
		_openPanelDelegate=[PKGPresentationBackgroundOpenPanelDelegate new];
		_openPanelDelegate.imagePath=tAbsoluteImagePath;
		
		tOpenPanel.delegate=_openPanelDelegate;
		
		__block PKGFilePathType tReferenceStyle=(tSelectedAppearanceSettings.imagePath!=nil) ? tSelectedAppearanceSettings.imagePath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
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
			
			if (bResult!=WBFileHandlingPanelOKButton)
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
			
			tSelectedAppearanceSettings.imagePath=[self.filePathConverter filePathForAbsolutePath:tPaths[0] type:tReferenceStyle];
				
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
	
	PKGPresentationBackgroundAppearanceSettings * tSelectedAppearanceSettings=[self selectedAppearanceSettings];
	
	if (tTag==tSelectedAppearanceSettings.imageAlignment)
		return;
	
	tSelectedAppearanceSettings.imageAlignment=tTag;
	
	[self noteDocumentHasChanged];
	
	// Post Notification
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
}

- (IBAction)switchLayoutDirection:(NSButton *)sender
{
	PKGImageLayoutDirection tLayoutDirection=([sender state]==WBControlStateValueOn) ? PKGImageLayoutDirectionNatural : PKGImageLayoutDirectionNone;
	
	PKGPresentationBackgroundAppearanceSettings * tSelectedAppearanceSettings=[self selectedAppearanceSettings];
	
	if (tLayoutDirection==tSelectedAppearanceSettings.imageLayoutDirection)
		return;
	
	tSelectedAppearanceSettings.imageLayoutDirection=tLayoutDirection;
	
	[self noteDocumentHasChanged];
	
	// Post Notification
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
}

- (IBAction)switchScaling:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	PKGPresentationBackgroundAppearanceSettings * tSelectedAppearanceSettings=[self selectedAppearanceSettings];
	
	if (tTag==tSelectedAppearanceSettings.imageScaling)
		return;
	
	tSelectedAppearanceSettings.imageScaling=tTag;
	
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
	
	CGImageSourceRef tSourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef) tURL, NULL);
	
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
	
	PKGPresentationBackgroundAppearanceSettings * tSelectedAppearanceSettings=[self selectedAppearanceSettings];
	
	void (^finalizeSetBackgroundImagePath)(PKGFilePath *) = ^(PKGFilePath * bFilePath) {
		
		tSelectedAppearanceSettings.imagePath=bFilePath;
		
		[self refreshUI];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:_backgroundSettings];
		
		[self noteDocumentHasChanged];
	};
	
	if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
	{
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		
		tPanel.canChooseOwnerAndGroupOptions=NO;
		tPanel.keepOwnerAndGroup=NO;
		tPanel.referenceStyle=(tSelectedAppearanceSettings.imagePath!=nil) ? tSelectedAppearanceSettings.imagePath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		[tPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bReturnCode){
			
			if (bReturnCode==PKGPanelCancelButton)
				return;
			
			PKGFilePath * tNewFilePath=[self.filePathConverter filePathForAbsolutePath:inPath type:tPanel.referenceStyle];
			
			finalizeSetBackgroundImagePath(tNewFilePath);
		}];
		
		return YES;
	}
	
	PKGFilePathType tPathType=(tSelectedAppearanceSettings.imagePath!=nil) ? tSelectedAppearanceSettings.imagePath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:inPath type:tPathType];
	
	finalizeSetBackgroundImagePath(tFilePath);
	
	return YES;
}

- (void)referencedPopUpButtonReferenceStyleDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=_customBackgroundPopUpButton)
		return;
	
	PKGPresentationBackgroundAppearanceSettings * tSelectedAppearanceSettings=[self selectedAppearanceSettings];
	
	if (tSelectedAppearanceSettings.imagePath==nil)
		tSelectedAppearanceSettings.imagePath=[PKGFilePath new];
	
	if ([self.filePathConverter shiftTypeOfFilePath:tSelectedAppearanceSettings.imagePath toType:_customBackgroundPopUpButton.pathType]==NO)
	{
		// Oh oh
		
		return;
	}
	
	[self noteDocumentHasChanged];
	
	_customBackgroundPopUpButton.toolTip=tSelectedAppearanceSettings.imagePath.string;
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
