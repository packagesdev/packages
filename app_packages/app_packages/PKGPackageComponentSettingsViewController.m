/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageComponentSettingsViewController.h"

#import "PKGDistributionProject.h"
#import "PKGPackageComponent+UI.h"

#import "PKGApplicationPreferences.h"

#import "PKGPackageSettingsSourceView.h"

#import "PKGFilePathTypeMenu.h"

#import "PKGArchive.h"

#import "PKGLocationDropView.h"

#import "PKGFileDeadDropView.h"

#import "PKGMustCloseApplicationItemsPanel.h"

#import "NSCollection+DeepCopy.h"

#import "NSObject+Conformance.h"

#import "PKGReplaceableStringFormatter.h"

@interface PKGPackageComponentSettingsViewController () <PKGFileDeadDropViewDelegate,PKGLocationDropViewDelegate>
{
	IBOutlet PKGPackageSettingsSourceView * _sourceSectionView;
	
	IBOutlet NSTextField * _sourceTextField;
	
	IBOutlet NSPopUpButton * _sourceReferenceStylePopUpButton;
	
	IBOutlet PKGPackageSettingsSourceView * _referenceSectionView;
	
	
	IBOutlet NSView * _tagSectionView;
	
	IBOutlet NSView * _postInstallationSectionView;
	
	
	IBOutlet PKGLocationDropView * _locationSectionView;
	
	IBOutlet NSTextField * _locationTipLabel;
	
	IBOutlet NSTextField * _locationLabel;
	
	IBOutlet NSTextField * _locationTextField;
	
	IBOutlet NSPopUpButton * _locationPopUpButton;
	
	
	IBOutlet NSView * _optionsSectionView;
	
	IBOutlet NSButton * _mustCloseApplicationsCheckbox;
}

- (PKGPackageSettings *)_packageSettingsForImportedPackageAtPath:(NSString *)inPath error:(NSError **)outError;

- (void)_updateSectionsLayout;

- (void)refreshLocationSectionWithPath:(NSString *)inPath;

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
    
	_sourceReferenceStylePopUpButton.menu=[PKGFilePathTypeMenu menuForAction:nil target:self controlSize:WBControlSizeRegular];
	
	_sourceSectionView.backgroundColor=[NSColor colorWithDeviceRed:0.7529 green:0.7843 blue:0.8392 alpha:1.0];
	
	_referenceSectionView.backgroundColor=[NSColor colorWithDeviceWhite:0.8392 alpha:1.0];
	
	if ([self WB_doesReallyConformToProtocol:@protocol(PKGFileDeadDropViewDelegate)]==YES)
		_locationSectionView.delegate=(id<PKGLocationDropViewDelegate>)self;
	
	[_locationSectionView registerForDraggedTypes:@[NSFilenamesPboardType,WBPasteboardTypeString]];
    
    PKGReplaceableStringFormatter * tFormatter=[PKGReplaceableStringFormatter new];
    tFormatter.keysReplacer=self;
    
    _locationTextField.formatter=tFormatter;
}

- (NSUInteger)tag
{
	return PKGPreferencesGeneralDistributionPackageComponentPaneSettings;
}

- (void)setOptionsSectionSimplified:(BOOL)inSimplified
{
	if (self.isOptionsSectionSimplified==inSimplified)
		return;
	
	[super setOptionsSectionSimplified:inSimplified];
	
	if (inSimplified==YES)
	{
		NSView * tLowerView=_mustCloseApplicationsCheckbox;
		
		NSRect tOptionsSectionFrame=_mustCloseApplicationsCheckbox.superview.frame;
		CGFloat tMaxY=NSMaxY(tOptionsSectionFrame);
		CGFloat tHeight=tMaxY-(NSMinY(tOptionsSectionFrame)+NSMinY(tLowerView.frame)-20.0);
		
		tOptionsSectionFrame.size.height=tHeight;
		tOptionsSectionFrame.origin.y=tMaxY-tHeight;
		
		_mustCloseApplicationsCheckbox.superview.frame=tOptionsSectionFrame;
	}
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

- (void)refreshLocationSectionWithPath:(NSString *)inPath
{
	PKGPackageSettings * tPackageSettings=self.packageSettings;
	PKGPackageLocationType tLocationType=PKGPackageLocationEmbedded;
	
	if (tPackageSettings==nil)
	{
		_locationPopUpButton.enabled=NO;
	}
	else
	{
		tLocationType=self.packageComponent.packageSettings.locationType;
		
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
	
	switch(tLocationType)
	{
		case PKGPackageLocationEmbedded:
			
			_locationTipLabel.stringValue=@"";
			
			_locationTextField.objectValue=@"";
			
			break;
			
		case PKGPackageLocationCustomPath:
			
			_locationTipLabel.stringValue=NSLocalizedString(@"( './' represents the parent folder of the distribution bundle )",@"");
			
			_locationLabel.stringValue=NSLocalizedString(@"Path:",@"");
			
			_locationTextField.objectValue=(inPath.length==0) ? @"" : inPath;
			
			break;
			
		case PKGPackageLocationHTTPURL:
			
			_locationTipLabel.stringValue=NSLocalizedString(@"( URL of the folder containing the package on the HTTP server )",@"");
			
			_locationLabel.stringValue=NSLocalizedString(@"URL:",@"");
			
			_locationTextField.objectValue=(inPath.length==0) ? @"" : inPath;
			
			break;
			
		case PKGPackageLocationHTTPSURL:
			
			_locationTipLabel.stringValue=NSLocalizedString(@"( URL of the folder containing the package on the HTTPS server )",@"");
			
			_locationLabel.stringValue=NSLocalizedString(@"URL:",@"");
			
			_locationTextField.objectValue=(inPath.length==0) ? @"" : inPath;
			
			break;
			
		case PKGPackageLocationRemovableMedia:
			
			_locationTipLabel.stringValue=@"";
			
			_locationLabel.stringValue=NSLocalizedString(@"Path:",@"");
			
			_locationTextField.objectValue=(inPath.length==0) ? PKGLocationURLPrefixRemovableMedia : inPath;
			
			break;
	}
}

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
		tLocationType=self.packageComponent.packageSettings.locationType;
		
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
	
	
	NSString * tLocationPath=self.packageComponent.packageSettings.locationURL;
	
	[self refreshLocationSectionWithPath:tLocationPath];
	
	// Options Section
	
	_mustCloseApplicationsCheckbox.state=(self.packageComponent.mustCloseApplications==YES)? WBControlStateValueOn : WBControlStateValueOff;
	
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
	
	__block NSString * tLocationPath=self.packageComponent.packageSettings.locationURL;
	
	BOOL (^removePrefixFromLocationPathIfNeeded)(NSArray *) = ^BOOL(NSArray * bPrefixes)
	{
		for(NSString * tPrefix in bPrefixes)
		{
			if ([tLocationPath rangeOfString:tPrefix options:NSCaseInsensitiveSearch].location==0)
			{
				tLocationPath=[tLocationPath substringFromIndex:[tPrefix length]];
				
				self.packageComponent.packageSettings.locationURL=tLocationPath;
				
				return YES;
			}
		}
		
		return NO;
	};
	
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
				removePrefixFromLocationPathIfNeeded(@[PKGLocationURLPrefixHTTP,PKGLocationURLPrefixHTTPS,PKGLocationURLPrefixRemovableMedia]);
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
				if (removePrefixFromLocationPathIfNeeded(@[PKGLocationURLPrefixFile,PKGLocationURLPrefixHTTPS,PKGLocationURLPrefixRemovableMedia])==YES)
				{
					if ([tLocationPath rangeOfString:PKGLocationURLPrefixHTTP options:NSCaseInsensitiveSearch].location!=0)
						tLocationPath=[PKGLocationURLPrefixHTTP stringByAppendingString:tLocationPath];
				}
				
				self.packageComponent.packageSettings.locationURL=tLocationPath;
			}
			
			break;
			
		case PKGPackageLocationHTTPSURL:
			
			_locationTipLabel.stringValue=NSLocalizedString(@"( URL of the folder containing the package on the HTTPS server )",@"");
			
			_locationLabel.stringValue=NSLocalizedString(@"URL:","");
			
			if (tLocationPath==nil)
			{
				tLocationPath=@"";
			}
			else
			{
				if (removePrefixFromLocationPathIfNeeded(@[PKGLocationURLPrefixFile,PKGLocationURLPrefixHTTP,PKGLocationURLPrefixRemovableMedia])==YES)
				{
					if ([tLocationPath rangeOfString:PKGLocationURLPrefixHTTPS options:NSCaseInsensitiveSearch].location!=0)
						tLocationPath=[PKGLocationURLPrefixHTTPS stringByAppendingString:tLocationPath];
				}
				
				self.packageComponent.packageSettings.locationURL=tLocationPath;
			}
			
			break;
			
		case PKGPackageLocationRemovableMedia:
			
			_locationTipLabel.stringValue=@"";
			
			_locationLabel.stringValue=NSLocalizedString(@"Path:","");
			
			if (tLocationPath==nil)
			{
				tLocationPath=PKGLocationURLPrefixRemovableMedia;
			}
			else
			{
				if (removePrefixFromLocationPathIfNeeded(@[PKGLocationURLPrefixFile,PKGLocationURLPrefixHTTP,PKGLocationURLPrefixHTTPS])==YES)
				{
					if ([tLocationPath rangeOfString:PKGLocationURLPrefixRemovableMedia options:NSCaseInsensitiveSearch].location!=0)
						tLocationPath=[PKGLocationURLPrefixRemovableMedia stringByAppendingString:tLocationPath];
				}
				
				self.packageComponent.packageSettings.locationURL=tLocationPath;
			}
			
			break;
		
		default:
			break;
	}
	
	_locationTextField.objectValue=tLocationPath;
	
	// Notify Document Change
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchMustCloseApplications:(id)sender
{
	BOOL tMustCloseApplications=(_mustCloseApplicationsCheckbox.state==WBControlStateValueOn)? YES : NO;
	
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
    tPanel.stringReplacer=self.document;
    
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

#pragma mark - PKGLocationDropViewDelegate

- (BOOL)locationDropView:(PKGLocationDropView *)inView validateDrop:(id <NSDraggingInfo>)inInfo
{
	if (inView==nil || inInfo==nil)
		return NO;
	
	NSPasteboard * tPasteBoard=[inInfo draggingPasteboard];
	
	NSString * tString=nil;
	
	if ([tPasteBoard availableTypeFromArray:@[(__bridge NSString *)kUTTypeURL]]!=nil)
	{
		tString=[tPasteBoard stringForType:(__bridge NSString *)kUTTypeURL];
		
		// If tString!=nil then it's probably a webloc (it's not an alias).
	}
	
	if (tString==nil)
	{
		if ([tPasteBoard availableTypeFromArray:@[WBPasteboardTypeString]]!=nil)
		{
			tString=[tPasteBoard stringForType:WBPasteboardTypeString];
		}
		else if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
		{
			NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
			
			if (tArray.count!=1)
				return NO;
			
			tString=tArray.lastObject;
			
			BOOL isDirectory=NO;
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:tString isDirectory:&isDirectory]==YES && isDirectory==YES)
				return YES;
			
			PKGArchive * tArchive=[PKGArchive archiveAtPath:tString];
			
			if ([tArchive isFlatPackage]==NO)
				return NO;
		}
	}
	
	if (tString==nil)
		return NO;
		
	NSString * tLastComponent=tString.lastPathComponent;
	NSString * tName=nil;
	
	if ([tLastComponent length]>0 && [tLastComponent.pathExtension caseInsensitiveCompare:@"pkg"]==NSOrderedSame)
		tName=[tLastComponent stringByDeletingPathExtension];
	
	if (tName==nil)
		return YES;
	
	switch(self.packageComponent.type)
	{
		case PKGPackageComponentTypeProject:
		case PKGPackageComponentTypeImported:
			
			return ([self.packageComponent.packageSettings.name caseInsensitiveCompare:tName]==NSOrderedSame);	// The lastComponent will be removed
			
		case PKGPackageComponentTypeReference:
		{
			if ([self.packageComponent.packageSettings.name caseInsensitiveCompare:tName]==NSOrderedSame)
				return YES;
			
			// Check whether the name is not already being used by another component
		
			NSUInteger tLength=[tName length];
			
			if (tLength>=256)
				return NO;
			
			PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)self.document.project;
			
			if ([tDistributionProject.packageComponents indexesOfObjectsPassingTest:^BOOL(PKGPackageComponent * bPackageComponent,NSUInteger bIndex,BOOL * bOutStop){
				
				return ([bPackageComponent.packageSettings.name caseInsensitiveCompare:tName]==NSOrderedSame);
				
			}].count>0)
			{
				return NO;
			}
			
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)locationDropView:(PKGLocationDropView *)inView acceptDrop:(id <NSDraggingInfo>)inInfo
{
	if (inView==nil || inInfo==nil)
		return NO;
	
	NSPasteboard * tPasteBoard=[inInfo draggingPasteboard];
	
	NSString * tString=nil;
	BOOL tMayNeedToChangeType=NO;
	PKGPackageLocationType tLocationType=PKGPackageLocationCustomPath;
	
	if ([tPasteBoard availableTypeFromArray:@[(__bridge NSString *)kUTTypeURL]]!=nil)
	{
		tString=[tPasteBoard stringForType:(__bridge NSString *)kUTTypeURL];
		
		if (tString!=nil)
			tLocationType=PKGPackageLocationHTTPURL;
	}
	
	BOOL isLocalFlatPackage=NO;
	BOOL isDirectory=NO;
	
	if (tString==nil)
	{
		if ([tPasteBoard availableTypeFromArray:@[WBPasteboardTypeString]]!=nil)
		{
			tString=[tPasteBoard stringForType:WBPasteboardTypeString];
		}
		else if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
		{
			NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
			
			if (tArray.count!=1)
				return NO;
			
			tString=tArray.lastObject;
			
			tMayNeedToChangeType=YES;
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:tString isDirectory:&isDirectory]==NO)
				return NO;
			
			if (isDirectory==NO)
				isLocalFlatPackage=YES;
			
			if (self.packageComponent.type==PKGPackageComponentTypeReference)
			{
				tLocationType=PKGPackageLocationRemovableMedia;
			}
			else
			{
				tLocationType=PKGPackageLocationCustomPath;
			}
		}
	}
	
	if (tString==nil)
		return NO;
	
	// Check whether the current Location URL has a prefix or not
	
	NSString * tOldLocationURL=self.packageComponent.packageSettings.locationURL;
	BOOL tOldURLHasPrefix=NO;
	
	for(NSString * tPrefix in @[PKGLocationURLPrefixHTTP,PKGLocationURLPrefixHTTPS,PKGLocationURLPrefixRemovableMedia])
	{
		if ([tOldLocationURL rangeOfString:tPrefix options:NSCaseInsensitiveSearch].location==0)
		{
			tOldURLHasPrefix=YES;
			break;
		}
	}
	
	
	BOOL tHTTPURL=NO;
	NSString * tPrefix=nil;
	
	if ([tString rangeOfString:PKGLocationURLPrefixHTTP options:NSCaseInsensitiveSearch].location==0)
	{
		tHTTPURL=YES;
		tPrefix=PKGLocationURLPrefixHTTP;
		tMayNeedToChangeType=YES;
		tLocationType=PKGPackageLocationHTTPURL;
	}
	else if ([tString rangeOfString:PKGLocationURLPrefixHTTPS options:NSCaseInsensitiveSearch].location==0)
	{
		tHTTPURL=YES;
		tPrefix=PKGLocationURLPrefixHTTPS;
		tMayNeedToChangeType=YES;
		tLocationType=PKGPackageLocationHTTPSURL;
	}
	else if ([tString rangeOfString:PKGLocationURLPrefixRemovableMedia options:NSCaseInsensitiveSearch].location==0)
	{
		tPrefix=PKGLocationURLPrefixRemovableMedia;
		tMayNeedToChangeType=YES;
		tLocationType=PKGPackageLocationRemovableMedia;
	}
	
	if (tPrefix!=nil)
		tString=[tString substringFromIndex:[tPrefix length]];
	
	if (tHTTPURL==YES)
		tString=[tString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSString * tLastComponent=tString.lastPathComponent;
		
	if (tLastComponent==nil)
		return NO;
	
	NSString * tName=nil;
	
	if (isDirectory==NO &&
		(isLocalFlatPackage==YES ||
		([tLastComponent length]>0 && [tLastComponent.pathExtension caseInsensitiveCompare:@"pkg"]==NSOrderedSame)))
	{
		tName=[tLastComponent stringByDeletingPathExtension];
	}
	
	if (tName!=nil)
		tString=[tString stringByDeletingLastPathComponent];
	
	if (tPrefix!=nil && tOldURLHasPrefix==YES)
		tString=[tPrefix stringByAppendingString:tString];
	
	// Set the new location URL
	
	self.packageComponent.packageSettings.locationURL=tString;
	
	// Change the location type if needed
	
	if (tMayNeedToChangeType==YES && self.packageComponent.packageSettings.locationType!=tLocationType)
	{
		self.packageComponent.packageSettings.locationType=tLocationType;
		
		// Update UI
		
		[self refreshLocationSectionWithPath:tString];
	}
	else
	{
		_locationTextField.objectValue=tString;
	}
	
	if (tName!=nil && self.packageComponent.type==PKGPackageComponentTypeReference)
	{
		if ([self.packageComponent.packageSettings.name caseInsensitiveCompare:tName]!=NSOrderedSame)
			[[NSNotificationCenter defaultCenter] postNotificationName:PKGPackageComponentDidRequestNameChangeNotitication object:self.packageComponent userInfo:@{@"Name":tName}];
	}
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	
	[_locationTextField.target performSelector:_locationTextField.action withObject:_locationTextField];
	
	// Notify Document Change
	
	[self noteDocumentHasChanged];
	
	return YES;
}

#pragma mark - Notifications

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
    
    [_locationTextField setNeedsDisplay:YES];
}

- (void)windowDidBecomeMain:(NSNotification *)inNotification
{
	if (self.packageComponent.type==PKGPackageComponentTypeImported)
	{
		NSString * tArchivePath=[self.filePathConverter absolutePathForFilePath:_packageComponent.importPath];
		
		self.packageSettings=[self _packageSettingsForImportedPackageAtPath:tArchivePath error:NULL];
		
		[self refreshUI];
	}
}

- (void)controlTextDidChange:(NSNotification *)inNotification
{
	NSString * tValue=[inNotification.userInfo[@"NSFieldEditor"] string];
	
	if (tValue==nil)
		return;
	
	if (inNotification.object!=_locationTextField)
	{
		[super controlTextDidChange:inNotification];
		
		return;
	}
	
	if ([self.packageComponent.packageSettings.locationURL isEqualToString:tValue]==YES)
		return;
		
	self.packageComponent.packageSettings.locationURL=tValue;
	
	// Note change
	
	[self noteDocumentHasChanged];
}

@end
