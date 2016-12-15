/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGPackagePayloadDataSource.h"

#import "PKGFilesHierarchyViewController.h"

@interface PKGPayloadViewController ()
{
	IBOutlet NSPopUpButton * _payloadTypePopUpButton;
	IBOutlet NSButton * _splitForksCheckbox;
	
	IBOutlet NSTextField * _defaultDestinationLabel;
	IBOutlet NSButton * _defaultDestinationSetButton;
	
	IBOutlet NSView * _hierarchyPlaceHolderView;
	
	PKGFilesHierarchyViewController * _filesHierarchyViewController;
	
	PKGPackagePayloadDataSource * _dataSource;
}

- (void)_updateLayout;

- (IBAction)switchPayloadType:(id)sender;

- (IBAction)setDefaultDestination:(id)sender;

// Notifications

- (void)advancedModeStateDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPayloadViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	_dataSource=[PKGPackagePayloadDataSource new];
	
	return self;
}

- (NSString *)nibName
{
	return @"PKGPayloadViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_filesHierarchyViewController=[PKGFilesHierarchyViewController new];
	
	_filesHierarchyViewController.label=@"Payload";
	_filesHierarchyViewController.hierarchyDatasource=_dataSource;
	
	
	_filesHierarchyViewController.view.frame=_hierarchyPlaceHolderView.bounds;
	
	[_filesHierarchyViewController WB_viewWillAdd];
	
	[_hierarchyPlaceHolderView addSubview:_filesHierarchyViewController.view];
	
	[_filesHierarchyViewController WB_viewDidAdd];
	
    // Do view setup here.
}

#pragma mark -

- (void)WB_viewWillAdd
{
	[self _updateLayout];
	
	[_payloadTypePopUpButton selectItemWithTag:self.payload.type];
	
	_splitForksCheckbox.state=(self.payload.splitForksIfNeeded==YES) ? NSOnState : NSOffState;
	
	_defaultDestinationLabel.stringValue=self.payload.defaultInstallLocation;
	
	_dataSource.rootNodes=self.payload.filesTree.rootNodes;
	_dataSource.filePathConverter=self.filePathConverter;
	_dataSource.delegate=_filesHierarchyViewController;
	
	// A COMPLETER
}

- (void)WB_viewDidAdd
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(advancedModeStateDidChange:) name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];

	[_filesHierarchyViewController refreshHierarchy];
}

- (void)WB_viewWillRemove
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];
}

#pragma mark -

- (void)_updateLayout
{
	BOOL tAdvancedModeEnabled=[PKGApplicationPreferences sharedPreferences].advancedMode;
	
	_splitForksCheckbox.hidden=(tAdvancedModeEnabled==NO);
}

#pragma mark -

- (IBAction)switchPayloadType:(id)sender
{
	// A COMPLETER
}

- (IBAction)setDefaultDestination:(id)sender
{
	// A COMPLETER
}

#pragma mark - Notifications

- (void)advancedModeStateDidChange:(NSNotification *)inNotification
{
	[self _updateLayout];
}

@end
