/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationTitleInspectorViewController.h"

#import "PKGPresentationLocalizationsDataSource.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGPresentationLocalizedStringsViewController.h"

@interface PKGPresentationTitleInspectorViewController () <PKGPresentationLocalizationsDataSourceDelegate>
{
	IBOutlet NSView * _placeHolderView;
	
	PKGPresentationTitleSettings * _titleSettings;

	PKGPresentationLocalizedStringsViewController * _localizedTitlesViewController;
}

@end

@implementation PKGPresentationTitleInspectorViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	if (self!=nil)
	{
		_titleSettings=[inPresentationSettings titleSettings_safe];
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_localizedTitlesViewController=[PKGPresentationLocalizedStringsViewController new];
	_localizedTitlesViewController.label=NSLocalizedStringFromTable(@"Distribution Title", @"Presentation", @"");
	_localizedTitlesViewController.informationLabel=NSLocalizedStringFromTable(@"Click + to add a title localization.", @"Presentation", @"");
	
	PKGPresentationLocalizationsDataSource * tDataSource=[PKGPresentationLocalizationsDataSource new];
	
	tDataSource.localizations=_titleSettings.localizations;
	tDataSource.delegate=self;
	
	_localizedTitlesViewController.dataSource=tDataSource;
	
	_localizedTitlesViewController.view.frame=_placeHolderView.bounds;
	
	[_placeHolderView addSubview:_localizedTitlesViewController.view];
}

#pragma mark -

- (PKGPresentationStepSettings *)settings
{
	return _titleSettings;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[_localizedTitlesViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[_localizedTitlesViewController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_localizedTitlesViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_localizedTitlesViewController WB_viewDidDisappear];
}

#pragma mark - PKGPresentationLocalizationsDataSourceDelegate

- (id)defaultValueForLocalizationsDataSource:(PKGPresentationLocalizationsDataSource *)inDataSource
{
	return @"";
}

- (void)localizationsDidChange:(PKGPresentationLocalizationsDataSource *)inDataSource
{
	[self noteDocumentHasChanged];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings userInfo:nil];
}

@end
