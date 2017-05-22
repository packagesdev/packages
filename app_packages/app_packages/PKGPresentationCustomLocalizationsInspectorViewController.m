/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationCustomLocalizationsInspectorViewController.h"

#import "PKGPresentationLocalizationsFilePathViewController.h"

#import "PKGPresentationLocalizationsFilePathDataSource.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGApplicationPreferences.h"

@interface PKGPresentationCustomLocalizationsInspectorViewController () <PKGPresentationLocalizationsDataSourceDelegate>
{
	IBOutlet NSTextField * _titleLabel;
	
	IBOutlet NSView * _contentsHolderView;
	
	PKGPresentationLocalizationsFilePathViewController * _localizationsControllerView;
}

@end

@implementation PKGPresentationCustomLocalizationsInspectorViewController

- (NSString *)nibName
{
	return @"PKGPresentationCustomLocalizationsInspectorViewController";
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_localizationsControllerView=[[PKGPresentationLocalizationsFilePathViewController alloc] initWithDocument:self.document];
	
	PKGPresentationLocalizationsFilePathDataSource * tLocalizationsDataSource=[[PKGPresentationLocalizationsFilePathDataSource alloc] init];
	tLocalizationsDataSource.localizations=((PKGPresentationLocalizableStepSettings *) self.settings).localizations;
	tLocalizationsDataSource.delegate=self;
	
	_localizationsControllerView.dataSource=tLocalizationsDataSource;
	
	NSRect tBounds=_contentsHolderView.bounds;
	
	_localizationsControllerView.view.frame=tBounds;
	
	[_contentsHolderView addSubview:_localizationsControllerView.view];
}

#pragma mark -

- (void)setTitle:(NSString *)inTitle
{
	[super setTitle:inTitle];
	
	_titleLabel.stringValue=(inTitle==nil) ? @"" : inTitle;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[_localizationsControllerView WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[[NSNotificationCenter defaultCenter] addObserver:_localizationsControllerView selector:@selector(localizationsDidChange:) name:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
	
	[_localizationsControllerView WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:_localizationsControllerView name:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
	
	[_localizationsControllerView WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_localizationsControllerView WB_viewDidDisappear];
}

#pragma mark - PKGPresentationLocalizationsDataSourceDelegate

- (id)defaultValue
{
	PKGFilePath * tFilePath=[PKGFilePath filePath];
	tFilePath.type=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	return tFilePath;
}

- (void)localizationsDidChange:(PKGPresentationLocalizationsDataSource *)inDataSource
{
	[self noteDocumentHasChanged];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings userInfo:nil];
}

#pragma mark -

- (void)settingsDidChange:(NSNotification *)inNotification
{
	if (inNotification.userInfo==nil)
		return;
	
	_localizationsControllerView.dataSource.localizations=((PKGPresentationLocalizableStepSettings *) self.settings).localizations;
	
	[_localizationsControllerView refreshUI];
}

@end
