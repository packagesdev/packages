/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageSettingsViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGBundleIdentifierFormatter.h"
#import "PKGReplaceableStringFormatter.h"

@interface PKGPackageSettingsViewController () <NSControlTextEditingDelegate>
{
	IBOutlet NSPopUpButton * _conclusionActionPopupButton;
	
	
	IBOutlet NSButton * _authenticationModeCheckbox;
	
	IBOutlet NSButton * _relocatableCheckbox;
	
	IBOutlet NSButton * _overwriteDirectoryPermissionsCheckbox;
	
	IBOutlet NSButton * _followSymbolicLinksCheckbox;
	
	IBOutlet NSButton * _useHFSPlusCompressionCheckbox;
	
	IBOutlet NSTextField * _useHFSPlusCompressionLabel;
}

- (void)_updateAdvancedOptionsVisibility;

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
		
		_optionsSectionSimplified=NO;
	}
	
	return self;
}

- (NSUInteger)tag
{
	return PKGPreferencesGeneralPackageProjectPaneSettings;
}

- (void)setTagSectionEnabled:(BOOL)inEnabled
{
	if (_tagSectionEnabled==inEnabled)
		return;
	
	_tagSectionEnabled=inEnabled;
		
	_identifierTextField.enabled=inEnabled;
		
	_versionTextField.enabled=inEnabled;
}

- (void)setPostInstallationSectionEnabled:(BOOL)inEnabled
{
	if (_postInstallationSectionEnabled==inEnabled)
		return;

	_postInstallationSectionEnabled=inEnabled;
		
	_conclusionActionPopupButton.enabled=inEnabled;
}

- (void)setOptionsSectionEnabled:(BOOL)inEnabled
{
	if (_optionsSectionEnabled==inEnabled)
		return;
	
	_optionsSectionEnabled=inEnabled;
	
	_authenticationModeCheckbox.enabled=inEnabled;
	
	_relocatableCheckbox.enabled=inEnabled;
	
	_overwriteDirectoryPermissionsCheckbox.enabled=inEnabled;
	
	_followSymbolicLinksCheckbox.enabled=inEnabled;
	
	_useHFSPlusCompressionCheckbox.enabled=inEnabled;
}

- (void)setOptionsSectionSimplified:(BOOL)inSimplified
{
	if (_optionsSectionSimplified==inSimplified)
		return;

	_optionsSectionSimplified=inSimplified;
	
	_relocatableCheckbox.hidden=inSimplified;
	
	_overwriteDirectoryPermissionsCheckbox.hidden=inSimplified;
	
	_followSymbolicLinksCheckbox.hidden=inSimplified;
	
	_useHFSPlusCompressionCheckbox.hidden=inSimplified;
	
	NSView * tLowerView=(inSimplified==YES) ? _authenticationModeCheckbox : _followSymbolicLinksCheckbox;
	
	NSRect tOptionsSectionFrame=_followSymbolicLinksCheckbox.superview.frame;
	CGFloat tMaxY=NSMaxY(tOptionsSectionFrame);
	CGFloat tHeight=tMaxY-(NSMinY(tOptionsSectionFrame)+NSMinY(tLowerView.frame)-20.0);
		
	tOptionsSectionFrame.size.height=tHeight;
	tOptionsSectionFrame.origin.y=tMaxY-tHeight;
	
	_followSymbolicLinksCheckbox.superview.frame=tOptionsSectionFrame;
}

#pragma mark -

- (void)refreshUI
{
	if (_identifierTextField==nil)
		return;
	
	PKGPackageSettings * tPackageSettings=self.packageSettings;
	
	// Tag Section
	
	_identifierTextField.objectValue=(tPackageSettings==nil) ? @"" : tPackageSettings.identifier;
	
	_versionTextField.objectValue=(tPackageSettings==nil) ? @"" : tPackageSettings.version;
	
	// Post Installation Section
	
	[_conclusionActionPopupButton selectItemWithTag:(tPackageSettings==nil) ? PKGPackageConclusionActionNone : tPackageSettings.conclusionAction];
	
	// Options Section
	
	_authenticationModeCheckbox.state=(tPackageSettings==nil) ? WBControlStateValueOff : (tPackageSettings.authenticationMode==PKGPackageAuthenticationRoot)? WBControlStateValueOn : WBControlStateValueOff;
	
	_relocatableCheckbox.state=(tPackageSettings==nil) ? WBControlStateValueOff : (tPackageSettings.relocatable==YES)? WBControlStateValueOn : WBControlStateValueOff;
	
	_overwriteDirectoryPermissionsCheckbox.state=(tPackageSettings==nil) ? WBControlStateValueOff : (tPackageSettings.overwriteDirectoryPermissions==YES)? WBControlStateValueOn : WBControlStateValueOff;
	
	_followSymbolicLinksCheckbox.state=(tPackageSettings==nil) ? WBControlStateValueOff : (tPackageSettings.followSymbolicLinks==YES)? WBControlStateValueOn : WBControlStateValueOff;
	
	_useHFSPlusCompressionCheckbox.state=(tPackageSettings==nil) ? WBControlStateValueOff : (tPackageSettings.useHFSPlusCompression==YES)? WBControlStateValueOn : WBControlStateValueOff;
}

- (void)WB_viewDidLoad
{
    [super WB_viewDidLoad];
    
    PKGReplaceableStringFormatter * tFormatter=[PKGReplaceableStringFormatter new];
    tFormatter.keysReplacer=self;
    
    _versionTextField.formatter=tFormatter;
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
    ((PKGBundleIdentifierFormatter *)_identifierTextField.formatter).keysReplacer=self;
    
    [self _updateAdvancedOptionsVisibility];
	
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

- (void)_updateAdvancedOptionsVisibility
{
	BOOL tAdvancedModeEnabled=[PKGApplicationPreferences sharedPreferences].advancedMode;
	
	_useHFSPlusCompressionCheckbox.hidden=_useHFSPlusCompressionLabel.hidden=(tAdvancedModeEnabled==NO || self.optionsSectionSimplified==YES);
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
	PKGPackageAuthentication tAuthenticationMode=(_authenticationModeCheckbox.state==WBControlStateValueOn)? PKGPackageAuthenticationRoot : PKGPackageAuthenticationNone;
	
	if (self.packageSettings.authenticationMode!=tAuthenticationMode)
	{
		self.packageSettings.authenticationMode=tAuthenticationMode;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchRelocatable:(id)sender
{
	BOOL tRelocatable=(_relocatableCheckbox.state==WBControlStateValueOn)? YES : NO;
	
	if (self.packageSettings.relocatable!=tRelocatable)
	{
		self.packageSettings.relocatable=tRelocatable;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchOverwriteDirectoryPermissions:(id)sender
{
	BOOL tOverwriteDirectoryPermissions=(_overwriteDirectoryPermissionsCheckbox.state==WBControlStateValueOn)? YES : NO;
	
	if (self.packageSettings.overwriteDirectoryPermissions!=tOverwriteDirectoryPermissions)
	{
		self.packageSettings.overwriteDirectoryPermissions=tOverwriteDirectoryPermissions;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchFollowSymbolicLinks:(id)sender
{
	BOOL tFollowSymbolicLinks=(_followSymbolicLinksCheckbox.state==WBControlStateValueOn)? YES : NO;
	
	if (self.packageSettings.followSymbolicLinks!=tFollowSymbolicLinks)
	{
		self.packageSettings.followSymbolicLinks=tFollowSymbolicLinks;
		
		// Note change
		
		[self noteDocumentHasChanged];
	}
}

- (IBAction)switchuseHFSPlusCompression:(id)sender
{
	BOOL tUseHFSPlusCompression=(_useHFSPlusCompressionCheckbox.state==WBControlStateValueOn)? YES : NO;
	
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

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
    
    [_identifierTextField setNeedsDisplay:YES];
    
    [_versionTextField setNeedsDisplay:YES];
}

- (void)advancedModeStateDidChange:(NSNotification *)inNotification
{
	[self _updateAdvancedOptionsVisibility];
}

- (void)controlTextDidChange:(NSNotification *)inNotification
{
	NSString * tValue=[inNotification.userInfo[@"NSFieldEditor"] string];
	
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
