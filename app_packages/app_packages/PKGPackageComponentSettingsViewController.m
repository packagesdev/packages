/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageComponentSettingsViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGPackageSettingsSourceView.h"

#import "PKGFilePathTypeMenu.h"

#import "PKGArchive.h"

#import "PKGFileDeadDropView.h"

#import "PKGLocationTextField.h"

#import "PKGMustCloseApplicationItemsPanel.h"

#import "NSCollection+DeepCopy.h"

@interface PKGPackageComponentSettingsViewController () <PKGFileDeadDropViewDelegate,PKGLocationTextFieldDelegate>
{
	IBOutlet PKGPackageSettingsSourceView * _sourceSectionView;
	
	IBOutlet NSTextField * _sourceTextField;
	
	IBOutlet NSPopUpButton * _sourceReferenceStylePopUpButton;
	
	IBOutlet PKGPackageSettingsSourceView * _referenceSectionView;
	
	
	IBOutlet NSView * _tagSectionView;
	
	IBOutlet NSView * _postInstallationSectionView;
	
	
	IBOutlet NSView * _locationSectionView;
	
	IBOutlet NSTextField * _locationTipLabel;
	
	IBOutlet NSTextField * _locationLabel;
	
	IBOutlet PKGLocationTextField * _locationTextField;
	
	IBOutlet NSPopUpButton * _locationPopUpButton;
	
	
	IBOutlet NSView * _optionsSectionView;
	
	IBOutlet NSButton * _mustCloseApplicationsCheckbox;
}

- (PKGPackageSettings *)_packageSettingsForImportedPackageAtPath:(NSString *)inPath error:(NSError **)outError;

- (void)_updateSectionsLayout;

- (IBAction)switchImportReferenceStyle:(id)sender;

- (IBAction)switchLocationType:(id)sender;

- (IBAction)switchMustCloseApplications:(id)sender;

- (IBAction)editMustBeClosedApplications:(id)sender;

// Notifications

- (void)windowDidBecomeMain:(NSNotification *)inNotification;

@end

@implementation PKGPackageComponentSettingsViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_sourceReferenceStylePopUpButton.menu=[PKGFilePathTypeMenu menuForAction:nil target:self controlSize:NSRegularControlSize];
	
	_sourceSectionView.backgroundColor=[NSColor colorWithDeviceRed:0.7529 green:0.7843 blue:0.8392 alpha:1.0];
	
	_referenceSectionView.backgroundColor=[NSColor colorWithDeviceWhite:0.8392 alpha:1.0];
	
	[_locationTextField registerForDraggedTypes:@[NSFilenamesPboardType,NSStringPboardType]];
}

- (NSUInteger)tag
{
	return PKGPreferencesGeneralDistributionPackageComponentPaneSettings;
}

#pragma mark -

- (void)setPackageComponent:(PKGPackageComponent *)inPackageComponent
{
	if (_packageComponent==inPackageComponent)
		return;

	_packageComponent=inPackageComponent;
	
	if (_packageComponent.type==PKGPackageComponentTypeImported)
	{
		NSString * tArchivePath=[self.filePathConverter absolutePathForFilePath:_packageComponent.importPath];
		
		self.packageSettings=[self _packageSettingsForImportedPackageAtPath:tArchivePath error:NULL];
	}
	else
	{
		self.packageSettings=_packageComponent.packageSettings;
	}
	
	[self refreshUI];
}

#pragma mark -

- (PKGPackageSettings *)_packageSettingsForImportedPackageAtPath:(NSString *)inPath error:(NSError **)outError
{
	PKGArchive * tArchive=[PKGArchive archiveAtPath:inPath];
	
	if ([tArchive isFlatPackage]==NO)
	{
		// Check whether the file exists
		
		// A COMPLETER
		
		if (outError!=NULL)
			*outError=nil;
		
		return nil;
	}
	
	NSData * tData;
	NSError * tError=nil;
	
	if ([tArchive extractFile:@"PackageInfo" intoData:&tData error:&tError]==NO)
	{
		if (outError!=NULL)
			*outError=tError;
		
		return nil;
	}
	
	return [[PKGPackageSettings alloc] initWithXMLData:tData];
}

#pragma mark -

- (void)_updateSectionsLayout
{
	NSRect tViewBounds=self.view.bounds;
	NSRect tSectionFrame;
	CGFloat tCumulatedHeight=0;
	
	switch(self.packageComponent.type)
	{
		case PKGPackageComponentTypeProject:
			
			// Source Section
			
			_sourceSectionView.hidden=YES;
			
			// Reference Section
			
			_referenceSectionView.hidden=YES;
			
			self.optionsSectionSimplified=NO;
			
			break;
			
		case PKGPackageComponentTypeImported:
			
			// Source Section
			
			tSectionFrame=_sourceSectionView.frame;
			tCumulatedHeight+=NSHeight(tSectionFrame);
			tSectionFrame.origin.y=NSMaxY(tViewBounds)-tCumulatedHeight;
			_sourceSectionView.frame=tSectionFrame;
				
			_sourceSectionView.hidden=NO;
			
			// Reference Section
			
			_referenceSectionView.hidden=YES;
			
			self.optionsSectionSimplified=NO;
			
			break;
			
		case PKGPackageComponentTypeReference:
			
			// Source Section
			
			_sourceSectionView.hidden=YES;
			
			// Reference Section
			
			tSectionFrame=_referenceSectionView.frame;
			tCumulatedHeight+=NSHeight(tSectionFrame);
			tSectionFrame.origin.y=NSMaxY(tViewBounds)-tCumulatedHeight;
			_referenceSectionView.frame=tSectionFrame;
				
			_referenceSectionView.hidden=NO;
			
			self.optionsSectionSimplified=YES;
			
			break;
	}
	
	// Tag Section
	
	tSectionFrame=_tagSectionView.frame;
	tCumulatedHeight+=NSHeight(tSectionFrame);
	tSectionFrame.origin.y=NSMaxY(tViewBounds)-tCumulatedHeight;
	_tagSectionView.frame=tSectionFrame;
	
	//  Post-Installation Section
	
	tSectionFrame=_postInstallationSectionView.frame;
	tCumulatedHeight+=NSHeight(tSectionFrame);
	tSectionFrame.origin.y=NSMaxY(tViewBounds)-tCumulatedHeight;
	_postInstallationSectionView.frame=tSectionFrame;
	
	// Location Section
	
	tSectionFrame=_locationSectionView.frame;
	tCumulatedHeight+=NSHeight(tSectionFrame);
	tSectionFrame.origin.y=NSMaxY(tViewBounds)-tCumulatedHeight;
	_locationSectionView.frame=tSectionFrame;
	
	// Options Section
	
	tSectionFrame=_optionsSectionView.frame;
	tCumulatedHeight+=NSHeight(tSectionFrame);
	tSectionFrame.origin.y=NSMaxY(tViewBounds)-tCumulatedHeight;
	_optionsSectionView.frame=tSectionFrame;
}

#pragma mark -

- (void)refreshUI
{
	if (_sourceReferenceStylePopUpButton==nil)
		return;
	
	PKGPackageSettings * tPackageSettings=self.packageSettings;
	
	// Source Section
	
	switch(self.packageComponent.type)
	{
		case PKGPackageComponentTypeProject:
			
			break;
			
		case PKGPackageComponentTypeImported:
		{
			[_sourceReferenceStylePopUpButton selectItemWithTag:self.packageComponent.importPath.type];
			
			_sourceTextField.stringValue=self.packageComponent.importPath.string;
			
			if (tPackageSettings==nil)
				_sourceSectionView.backgroundColor=[NSColor colorWithDeviceRed:243.0/255.0 green:83.0/255.0 blue:93.0/255.0 alpha:1.0];
			else
				_sourceSectionView.backgroundColor=[NSColor colorWithDeviceRed:0.7529 green:0.7843 blue:0.8392 alpha:1.0];

			break;
		}
		case PKGPackageComponentTypeReference:
			
			break;
	}
	
	[super refreshUI];
	
	// Location Section
	
	PKGPackageLocationType tLocationType=PKGPackageLocationEmbedded;
	
	if (tPackageSettings==nil)
	{
		_locationPopUpButton.enabled=NO;
	}
	else
	{
		tLocationType=tPackageSettings.locationType;
		
		_locationPopUpButton.enabled=YES;
	}
	
	if (self.packageComponent.type==PKGPackageComponentTypeReference && (tLocationType==PKGPackageLocationEmbedded || tLocationType==PKGPackageLocationCustomPath))
		tLocationType=PKGPackageLocationHTTPURL;
	
	
	[_locationPopUpButton selectItemWithTag:tLocationType];
	
	_locationLabel.hidden=_locationTextField.hidden=(tLocationType==PKGPackageLocationEmbedded);
	
	if (tLocationType==PKGPackageLocationEmbedded)
	{
		_versionTextField.nextKeyView=_identifierTextField;
	}
	else
	{
		_versionTextField.nextKeyView=_locationTextField;
		
		_locationTextField.nextKeyView=_identifierTextField;
	}
	
	NSString * tLocationPath=tPackageSettings.locationURL;
	
	switch(tLocationType)
	{
		case PKGPackageLocationEmbedded:
			
			_locationTipLabel.stringValue=@"";
			
			_locationTextField.stringValue=@"";
			
			break;
			
		case PKGPackageLocationCustomPath:
			
			_locationTipLabel.stringValue=NSLocalizedString(@"( './' represents the parent folder of the distribution bundle )",@"");
			
			_locationLabel.stringValue=NSLocalizedString(@"Path:",@"");
			
			_locationTextField.stringValue=(tLocationPath.length==0) ? @"" : tLocationPath;
			
			break;
			
		case PKGPackageLocationHTTPURL:
			
			_locationTipLabel.stringValue=NSLocalizedString(@"( URL of the folder containing the package on the HTTP server )",@"");
			
			_locationLabel.stringValue=NSLocalizedString(@"URL:",@"");
			
			_locationTextField.stringValue=(tLocationPath.length==0) ? @"" : tLocationPath;
			
			break;
			
		case PKGPackageLocationRemovableMedia:
			
			_locationTipLabel.stringValue=@"";
			
			_locationLabel.stringValue=NSLocalizedString(@"Path:",@"");
			
			_locationTextField.stringValue=(tLocationPath.length==0) ? @"x-disc://" : tLocationPath;
			
			break;
	}
	
	// Options Section
	
	_mustCloseApplicationsCheckbox.state=(self.packageComponent.mustCloseApplications==YES)? NSOnState : NSOffState;
	
	switch(self.packageComponent.type)
	{
		case PKGPackageComponentTypeProject:
			
			self.tagSectionEnabled=YES;
			self.postInstallationSectionEnabled=YES;
			self.optionsSectionEnabled=YES;
			
			break;
			
		case PKGPackageComponentTypeImported:
			
			self.tagSectionEnabled=NO;
			self.postInstallationSectionEnabled=NO;
			self.optionsSectionEnabled=NO;
			
			break;
			
		case PKGPackageComponentTypeReference:
			
			self.tagSectionEnabled=YES;
			self.postInstallationSectionEnabled=YES;
			self.optionsSectionEnabled=YES;
			
			break;
	}
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self _updateSectionsLayout];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:self.view.window];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.view.window];
}

#pragma mark -

- (IBAction)switchImportReferenceStyle:(NSPopUpButton *)sender
{
	PKGFilePathType tNewType=sender.selectedItem.tag;
	
	if (tNewType!=self.packageComponent.importPath.type)
	{
		if ([self.filePathConverter shiftTypeOfFilePath:self.packageComponent.importPath toType:tNewType]==NO)
		{
			// A COMPLETER
			
			return;
		}
		
		_sourceTextField.stringValue=self.packageComponent.importPath.string;
		
		// Notify Document Change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchLocationType:(NSPopUpButton *)sender
{
	if (sender==nil)
		return;
	
	PKGPackageLocationType tNewLocationType=sender.selectedItem.tag;
	
	if (tNewLocationType==self.packageComponent.packageSettings.locationType)
		return;

	self.packageComponent.packageSettings.locationType=tNewLocationType;
	
	_locationLabel.hidden=_locationTextField.hidden=(tNewLocationType==PKGPackageLocationEmbedded);
	
	if (tNewLocationType==PKGPackageLocationEmbedded)
	{
		_locationTextField.stringValue=@"";
		
		_locationTipLabel.stringValue=@"";
		
		self.packageComponent.packageSettings.locationURL=@"";
		
		_versionTextField.nextKeyView=_identifierTextField;
		
		[self noteDocumentHasChanged];
		
		return;
	}
	
	_versionTextField.nextKeyView=_locationTextField;
	 
	_locationTextField.nextKeyView=_identifierTextField;
	
	NSString * tLocationPath=self.packageComponent.packageSettings.locationURL;
	
	switch(tNewLocationType)
	{
		case PKGPackageLocationCustomPath:
			
			_locationTipLabel.stringValue=NSLocalizedString(@"( './' represents the parent folder of the distribution bundle )",@"");
			
			_locationLabel.stringValue=NSLocalizedString(@"Path:","");
			
			if (tLocationPath==nil)
			{
				tLocationPath=@"";
			}
			else
			{
				if ([tLocationPath hasPrefix:@"http://"]==YES)
				{
					tLocationPath=[tLocationPath substringFromIndex:7];
					
					self.packageComponent.packageSettings.locationURL=tLocationPath;
				}
				else if ([tLocationPath hasPrefix:@"x-disc://"]==YES)
				{
					tLocationPath=[tLocationPath substringFromIndex:9];
					
					self.packageComponent.packageSettings.locationURL=tLocationPath;
				}
			}
			
			break;
			
		case PKGPackageLocationHTTPURL:
			
			_locationTipLabel.stringValue=NSLocalizedString(@"( URL of the folder containing the package on the HTTP server )",@"");
			
			_locationLabel.stringValue=NSLocalizedString(@"URL:","");
			
			if (tLocationPath==nil)
			{
				tLocationPath=@"";
			}
			else
			{
				if ([tLocationPath hasPrefix:@"file:"]==YES)
				{
					tLocationPath=[tLocationPath substringFromIndex:5];
					
					self.packageComponent.packageSettings.locationURL=tLocationPath;
				}
				else if ([tLocationPath hasPrefix:@"x-disc://"]==YES)
				{
					tLocationPath=[tLocationPath substringFromIndex:9];
					
					self.packageComponent.packageSettings.locationURL=tLocationPath;
				}
			}
			
			break;
			
		case PKGPackageLocationRemovableMedia:
			
			_locationTipLabel.stringValue=@"";
			
			_locationLabel.stringValue=NSLocalizedString(@"Path:","");
			
			if (tLocationPath==nil)
			{
				tLocationPath=@"x-disc://";
			}
			else
			{
				if ([tLocationPath hasPrefix:@"file:"]==YES)
				{
					tLocationPath=[tLocationPath substringFromIndex:5];
					
					self.packageComponent.packageSettings.locationURL=tLocationPath;
				}
				else if ([tLocationPath hasPrefix:@"http://"]==YES)
				{
					tLocationPath=[tLocationPath substringFromIndex:7];
					
					self.packageComponent.packageSettings.locationURL=tLocationPath;
				}
				
				if ([tLocationPath hasPrefix:@"x-disc://"]==NO)
				{
					tLocationPath=[@"x-disc://" stringByAppendingString:tLocationPath];
					
					self.packageComponent.packageSettings.locationURL=tLocationPath;
				}
			}
			
			break;
		
		default:
			break;
	}
	
	_locationTextField.stringValue=tLocationPath;
	
	// Notify Document Change
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchMustCloseApplications:(id)sender
{
	BOOL tMustCloseApplications=(_mustCloseApplicationsCheckbox.state==NSOnState)? YES : NO;
	
	if (self.packageComponent.mustCloseApplications!=tMustCloseApplications)
	{
		self.packageComponent.mustCloseApplications=tMustCloseApplications;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)editMustBeClosedApplications:(id)sender
{
	PKGMustCloseApplicationItemsPanel * tPanel=[PKGMustCloseApplicationItemsPanel mustCloseApplicationItemsPanel];
	
	tPanel.mustCloseApplicationItems=[self.packageComponent.mustCloseApplicationItems deepCopy];
	
	[tPanel beginSheetModalForWindow:self.view.window
				   completionHandler:^(NSInteger bResult) {
					   
					   if (bResult==PKGPanelCancelButton)
						   return;
					   
					   if ([tPanel.mustCloseApplicationItems isEqualTo:self.packageComponent.mustCloseApplicationItems]==YES)
						   return;
					   
					   [self.packageComponent.mustCloseApplicationItems removeAllObjects];
					   [self.packageComponent.mustCloseApplicationItems addObjectsFromArray:tPanel.mustCloseApplicationItems];
					   
					   [self noteDocumentHasChanged];

				   }];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchLocationType:))
	{
		if (self.packageComponent.type==PKGPackageComponentTypeReference)
			return (inMenuItem.tag!=PKGPackageLocationEmbedded && inMenuItem.tag!=PKGPackageLocationCustomPath);
	}
	
	return YES;
}

#pragma mark - PKGFileDeadDropViewDelegate

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView validateDropFiles:(NSArray *)inFilenames
{
	if (self.packageComponent.type!=PKGPackageComponentTypeReference)
		return NO;
	
	if (inView==nil || inFilenames.count!=1)
		return NO;
	
	PKGArchive * tArchive=[PKGArchive archiveAtPath:inFilenames.lastObject];
	
	return [tArchive isFlatPackage];
}

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView acceptDropFiles:(NSArray *)inFilenames
{
	if (self.packageComponent.type!=PKGPackageComponentTypeReference)
		return NO;
	
	if (inView==nil || inFilenames.count==0)
		return NO;
	
	NSString * tArchivePath=inFilenames.lastObject;
	
	PKGArchive * tArchive=[PKGArchive archiveAtPath:tArchivePath];
	
	if (tArchive==nil)
	{
		// A COMPLETER
		
		return NO;
	}
	
	if ([tArchive isFlatPackage]==NO)
	{
		// Check whether the file exists
		
		// A COMPLETER
		
		return NO;
	}
	
	NSData * tData;
	NSError * tError=nil;
	
	if ([tArchive extractFile:@"PackageInfo" intoData:&tData error:&tError]==NO)
	{
		// A COMPLETER
		
		return NO;
	}
	
	NSString * tSavedName=self.packageComponent.packageSettings.name;
	PKGPackageLocationType tSavedLocationType=self.packageComponent.packageSettings.locationType;
	NSString * tSavedLocationURL=self.packageComponent.packageSettings.locationURL;
	
	self.packageComponent.packageSettings=[[PKGPackageSettings alloc] initWithXMLData:tData];
	
	self.packageComponent.packageSettings.name=tSavedName;
	self.packageComponent.packageSettings.locationType=tSavedLocationType;
	self.packageComponent.packageSettings.locationURL=tSavedLocationURL;
	
	self.packageSettings=self.packageComponent.packageSettings;
	
	[self refreshUI];
	
	[self noteDocumentHasChanged];
	
	return YES;
}

#pragma mark - PKGFilePathTextFieldDelegate

- (BOOL)locationTextField:(PKGLocationTextField *)inLocationTextField validateDrop:(id <NSDraggingInfo>)inInfo
{
	if (inLocationTextField==nil || inInfo==nil)
		return NO;
	
	NSPasteboard * tPasteBoard=[inInfo draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[NSStringPboardType]]!=nil)
	{
		NSString * tString=[tPasteBoard stringForType:NSStringPboardType];
		
		if (tString==nil)
			return NO;
		
		switch(self.packageComponent.packageSettings.locationType)
		{
			case PKGPackageLocationCustomPath:
				
				if ([tString hasPrefix:@"http://"]==NO &&
					[tString hasPrefix:@"x-disc://"]==NO)
					return YES;
				
				break;
				
			case PKGPackageLocationHTTPURL:
				
				if ([tString hasPrefix:@"http://"]==YES)
					return YES;
				
				break;
				
			case PKGPackageLocationRemovableMedia:
				
				if ([tString hasPrefix:@"x-disc://"]==YES)
					return YES;
				
				break;
				
			default:
				break;
		}
		
		return NO;
	}
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		if (self.packageComponent.packageSettings.locationType!=PKGPackageLocationCustomPath)
			return NO;
		
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tArray.count!=1)
			return NO;
		
		
		NSString * tFilePath=tArray.lastObject;
		BOOL isDirectory;
				
		return ([[NSFileManager defaultManager] fileExistsAtPath:tFilePath isDirectory:&isDirectory]==YES && isDirectory==YES);
	}
	
	return NO;
}

- (BOOL)locationTextField:(PKGLocationTextField *)inLocationTextField acceptDrop:(id <NSDraggingInfo>)inInfo
{
	if (inLocationTextField==nil || inInfo==nil)
		return NO;
	
	NSPasteboard * tPasteBoard=[inInfo draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[NSStringPboardType]]!=nil)
	{
		NSString * tString=[tPasteBoard stringForType:NSStringPboardType];
		
		if (tString==nil)
			return NO;
		
		if ([tString hasPrefix:@"http://"]==YES)
		{
			tString=[tString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			tString=[tString substringFromIndex:7];
			
			NSString * tLastComponent=tString.lastPathComponent;
			
			if (tLastComponent==nil)
				return NO;
			
			if ([tLastComponent.pathExtension caseInsensitiveCompare:@"pkg"]==NSOrderedSame)
			{
				tString=[tString stringByDeletingLastPathComponent];
				
				if (self.packageComponent.type==PKGPackageComponentTypeReference)
				{
					tLastComponent=[tLastComponent stringByDeletingPathExtension];
					
					self.packageComponent.packageSettings.name=tLastComponent;	// A COMPLETER (Repercuter le changement sur la source list)
				}
			}
			
			tString=[@"http://" stringByAppendingString:tString];
		}
		
		self.packageComponent.packageSettings.locationURL=tString;
			
		_locationTextField.stringValue=tString;
		
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		
		[_locationTextField.target performSelector:_locationTextField.action withObject:_locationTextField];
		
		// Notify Document Change
		
		[self noteDocumentHasChanged];
		
		return YES;
	}
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tArray.count!=1)
			return NO;
		
		NSString * tString=tArray.lastObject;
		
		BOOL isDirectory;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:tString isDirectory:&isDirectory]==NO || isDirectory==NO)
			return NO;
		
		self.packageComponent.packageSettings.locationURL=tString;
		
		_locationTextField.stringValue=tString;
		
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		
		[_locationTextField.target performSelector:_locationTextField.action withObject:_locationTextField];
		
		// Notify Document Change
		
		[self noteDocumentHasChanged];
		
		return YES;
	}

	return NO;
}

#pragma mark - Notifications

- (void)windowDidBecomeMain:(NSNotification *)inNotification
{
	if (self.packageComponent.type==PKGPackageComponentTypeImported)
	{
		NSString * tArchivePath=[self.filePathConverter absolutePathForFilePath:_packageComponent.importPath];
		
		self.packageSettings=[self _packageSettingsForImportedPackageAtPath:tArchivePath error:NULL];
		
		[self refreshUI];
	}
}

@end
