/*
 Copyright (c) 2016, Stephane Sudre
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

#import "PKGFileFiltersDataSource.h"

#import "PKGFilePathTextField.h"

@interface PKGProjectSettingsViewController ()
{
	IBOutlet NSTextField * _buildNameTextField;
	
	IBOutlet PKGFilePathTextField * _buildPathTextField;
	
	IBOutlet NSPopUpButton * _buildReferenceFolderPopUpButton;
	
	IBOutlet NSView * _exclusionsPlaceHolderView;
	
	IBOutlet NSButton * _filterPayloadOnlyCheckbox;
	
	PKGPayloadExclusionsViewController * _exclusionsViewController;
}

@end

@implementation PKGProjectSettingsViewController

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Build Path
	
	// Exclusions
	
	_exclusionsViewController=[PKGPayloadExclusionsViewController new];
	
	_exclusionsViewController.view.frame=_exclusionsPlaceHolderView.bounds;
	
	[_exclusionsViewController WB_viewWillAdd];
	
	[_exclusionsPlaceHolderView addSubview:_exclusionsViewController.view];
	
	[_exclusionsViewController WB_viewDidAdd];
}

#pragma mark -

- (void)WB_viewWillAdd
{
	// Build Name
	
	_buildNameTextField.stringValue=(self.projectSettings.name==nil) ? @"" : self.projectSettings.name;
	
	// Build Path
	
	_buildPathTextField.filePath=self.projectSettings.buildPath;
	
	// Reference Folder
	
	// A COMPLETER
	
	// Exclusions
	
	PKGFileFiltersDataSource * tDataSource=[[PKGFileFiltersDataSource alloc] initWithFileFilters:self.projectSettings.filesFilters];
	
	_exclusionsViewController.fileFiltersDataSource=tDataSource;
	
	_filterPayloadOnlyCheckbox.state=(self.projectSettings.filterPayloadOnly==YES) ? NSOnState : NSOffState;
}

- (void)WB_viewDidAdd
{
	// Build Path
	
	// A COMPLETER
}

@end
