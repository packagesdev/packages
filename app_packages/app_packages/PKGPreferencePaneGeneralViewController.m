/*
 Copyright (c) 2008-2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPreferencePaneGeneralViewController.h"

#import "PKGApplicationPreferences.h"

@interface PKGPreferencePaneGeneralViewController ()
{
	IBOutlet NSPopUpButton * _visibleDistributionProjectPanePopUpButton;
	
	IBOutlet NSPopUpButton * _visibleDistributionPackagePanePopUpButton;
	
	IBOutlet NSPopUpButton * _visiblePackageProjectPanePopUpButton;
	
	IBOutlet id IBdefaultReferenceStylePopUpButton_;
}

- (IBAction)switchDefaultVisibleDistributionProjectPane:(id) sender;

- (IBAction)switchDefaultVisibleDistributionPackagePane:(id) sender;

- (IBAction)switchDefaultVisiblePackageProjectPane:(id) sender;

- (IBAction)switchDefaultReferenceStyle:(id) sender;

@end

@implementation PKGPreferencePaneGeneralViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
	
	// Reference Style
	
	[IBdefaultReferenceStylePopUpButton_ removeItemAtIndex:0];
}

- (void)WB_viewWillAdd
{
	// Default Visibles Panes
	
	// Project
	
	[_visibleDistributionProjectPanePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].defaultVisibleDistributionProjectPane];
	
	// Package
	
	[_visibleDistributionPackagePanePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].defaultVisibleDistributionPackagePane];
	
	// Package Standalone
	
	[_visiblePackageProjectPanePopUpButton selectItemWithTag:[PKGApplicationPreferences sharedPreferences].defaultVisiblePackageProjectPane];
	
	// Default Reference Style
	
	[IBdefaultReferenceStylePopUpButton_ selectItemWithTag:[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle];
}

#pragma mark -

- (IBAction)switchDefaultVisibleDistributionProjectPane:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].defaultVisibleDistributionProjectPane=[[_visibleDistributionProjectPanePopUpButton selectedItem] tag];
}

- (IBAction)switchDefaultVisibleDistributionPackagePane:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].defaultVisibleDistributionPackagePane=[[_visibleDistributionPackagePanePopUpButton selectedItem] tag];
}

- (IBAction)switchDefaultVisiblePackageProjectPane:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].defaultVisiblePackageProjectPane=[[_visiblePackageProjectPanePopUpButton selectedItem] tag];
}

- (IBAction) switchDefaultReferenceStyle:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle=[[IBdefaultReferenceStylePopUpButton_ selectedItem] tag];
}

@end
