/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageSettingsViewController.h"

#import "PKGApplicationPreferences.h"


@interface PKGPackageSettingsViewController () <NSControlTextEditingDelegate>
{
	IBOutlet NSTextField * _identifierTextField;
	
	IBOutlet NSTextField * _versionTextField;
	
	
	IBOutlet NSPopUpButton * _conclusionActionPopupButton;
	
	
	IBOutlet NSButton * _authenticationModeCheckbox;
	
	IBOutlet NSButton * _relocatableCheckbox;
	
	IBOutlet NSButton * _overwriteDirectoryPermissionsCheckbox;
	
	IBOutlet NSButton * _followSymbolicLinksCheckbox;
	
	IBOutlet NSButton * _useHFSPlusCompressionCheckbox;
	
	IBOutlet NSTextField * _useHFSPlusCompressionLabel;
}

- (void)_updateLayout;

- (void)refreshUI;

- (IBAction)switchConclusionAction:(id)sender;

- (IBAction)switchAuthenticationMode:(id)sender;
- (IBAction)switchRelocatable:(id)sender;
- (IBAction)switchOverwriteDirectoryPermissions:(id)sender;
- (IBAction)switchFollowSymbolicLinks:(id)sender;
- (IBAction)switchuseHFSPlusCompression:(id)sender;

- (void)advancedModeStateDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPackageSettingsViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		_tagSectionEnabled=YES;
		_postInstallationSectionEnabled=YES;
		_optionsSectionEnabled=YES;
	}
	
	return self;
}

- (NSUInteger)tag
{
	return PKGPreferencesGeneralPackageProjectPaneSettings;
}

- (void)setTagSectionEnabled:(BOOL)inEnabled
{
	if (_tagSectionEnabled!=inEnabled)
	{
		_tagSectionEnabled=inEnabled;
		
		_identifierTextField.enabled=inEnabled;
		
		_versionTextField.enabled=inEnabled;
	}
}

- (void)setPostInstallationSectionEnabled:(BOOL)inEnabled
{
	if (_postInstallationSectionEnabled!=inEnabled)
	{
		_postInstallationSectionEnabled=inEnabled;
		
		_conclusionActionPopupButton.enabled=inEnabled;
	}
}

- (void)setOptionsSectionEnabled:(BOOL)inEnabled
{
	if (_optionsSectionEnabled!=inEnabled)
	{
		_optionsSectionEnabled=inEnabled;
		
		_authenticationModeCheckbox.enabled=inEnabled;
		
		_relocatableCheckbox.enabled=inEnabled;
		
		_overwriteDirectoryPermissionsCheckbox.enabled=inEnabled;
		
		_followSymbolicLinksCheckbox.enabled=inEnabled;
		
		_useHFSPlusCompressionCheckbox.enabled=inEnabled;
	}
}

#pragma mark -

- (void)refreshUI
{
	if (_identifierTextField==nil)
		return;
	
	// Tag Section
	
	_identifierTextField.stringValue=self.packageSettings.identifier;
	
	_versionTextField.stringValue=self.packageSettings.version;
	
	// Post Installation Section
	
	[_conclusionActionPopupButton selectItemWithTag:self.packageSettings.conclusionAction];
	
	// Options Section
	
	_authenticationModeCheckbox.state=(self.packageSettings.authenticationMode==PKGPackageAuthenticationRoot)? NSOnState : NSOffState;
	
	_relocatableCheckbox.state=(self.packageSettings.relocatable==YES)? NSOnState : NSOffState;
	
	_overwriteDirectoryPermissionsCheckbox.state=(self.packageSettings.overwriteDirectoryPermissions==YES)? NSOnState : NSOffState;
	
	_followSymbolicLinksCheckbox.state=(self.packageSettings.followSymbolicLinks==YES)? NSOnState : NSOffState;
	
	_useHFSPlusCompressionCheckbox.state=(self.packageSettings.useHFSPlusCompression==YES)? NSOnState : NSOffState;
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self _updateLayout];
	
	[self refreshUI];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	//[self.view.window makeFirstResponder:_identifierTextField];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(advancedModeStateDidChange:) name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];
}

#pragma mark -

- (void)_updateLayout
{
	BOOL tAdvancedModeEnabled=[PKGApplicationPreferences sharedPreferences].advancedMode;
	
	_useHFSPlusCompressionCheckbox.hidden=_useHFSPlusCompressionLabel.hidden=(tAdvancedModeEnabled==NO);
}

#pragma mark -

- (IBAction)switchConclusionAction:(NSPopUpButton *)sender
{
	PKGPackageConclusionAction tConclusionAction=sender.selectedItem.tag;
	
	if (self.packageSettings.conclusionAction!=tConclusionAction)
	{
		self.packageSettings.conclusionAction=tConclusionAction;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchAuthenticationMode:(id)sender
{
	PKGPackageAuthentication tAuthenticationMode=(_authenticationModeCheckbox.state==NSOnState)? PKGPackageAuthenticationRoot : PKGPackageAuthenticationNone;
	
	if (self.packageSettings.authenticationMode!=tAuthenticationMode)
	{
		self.packageSettings.authenticationMode=tAuthenticationMode;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchRelocatable:(id)sender
{
	BOOL tRelocatable=(_relocatableCheckbox.state==NSOnState)? YES : NO;
	
	if (self.packageSettings.relocatable!=tRelocatable)
	{
		self.packageSettings.relocatable=tRelocatable;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchOverwriteDirectoryPermissions:(id)sender
{
	BOOL tOverwriteDirectoryPermissions=(_overwriteDirectoryPermissionsCheckbox.state==NSOnState)? YES : NO;
	
	if (self.packageSettings.overwriteDirectoryPermissions!=tOverwriteDirectoryPermissions)
	{
		self.packageSettings.overwriteDirectoryPermissions=tOverwriteDirectoryPermissions;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchFollowSymbolicLinks:(id)sender
{
	BOOL tFollowSymbolicLinks=(_followSymbolicLinksCheckbox.state==NSOnState)? YES : NO;
	
	if (self.packageSettings.followSymbolicLinks!=tFollowSymbolicLinks)
	{
		self.packageSettings.followSymbolicLinks=tFollowSymbolicLinks;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchuseHFSPlusCompression:(id)sender
{
	BOOL tUseHFSPlusCompression=(_useHFSPlusCompressionCheckbox.state==NSOnState)? YES : NO;
	
	if (self.packageSettings.useHFSPlusCompression!=tUseHFSPlusCompression)
	{
		self.packageSettings.useHFSPlusCompression=tUseHFSPlusCompression;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

#pragma mark - NSControlTextEditingDelegate

- (void)control:(NSControl *)inControl didFailToValidatePartialString:(NSString *)inString errorDescription:(NSString *)inErrorDescription
{
	if ([inErrorDescription isEqualToString:@"Error"]==YES)
		NSBeep();
}

#pragma mark - Notifications

- (void)advancedModeStateDidChange:(NSNotification *)inNotification
{
	[self _updateLayout];
}

- (void)controlTextDidChange:(NSNotification *)inNotification
{
	NSString * tValue=[[[inNotification userInfo] objectForKey:@"NSFieldEditor"] string];
	
	if (tValue==nil)
		return;
	
	if (inNotification.object==_identifierTextField)
	{
		if ([self.packageSettings.identifier isEqualToString:tValue]==YES)
			return;
		
		self.packageSettings.identifier=tValue;
	}
	else if (inNotification.object==_versionTextField)
	{
		if ([self.packageSettings.version isEqualToString:tValue]==YES)
			return;
		
		self.packageSettings.version=tValue;
	}
	
	// Note change
	
	[self noteDocumentHasChanged];
}

@end
