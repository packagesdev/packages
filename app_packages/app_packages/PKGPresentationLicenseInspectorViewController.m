/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationLicenseInspectorViewController.h"

#import "PKGPresentationLocalizationsFilePathViewController.h"

#import "PKGPresentationLocalizationsFilePathDataSource.h"

#import "PKGLicenseKeywordsViewController.h"

#import "PKGDistributionProjectPresentationSettings+Safe.h"

#import "PKGApplicationPreferences.h"

#import "PKGLicenseProvider.h"

@interface PKGPresentationLicenseInspectorViewController () <PKGPresentationLocalizationsDataSourceDelegate>
{
	IBOutlet NSPopUpButton * _customLicenseTypePopUpButton;
	
	IBOutlet NSView * _contentsHolderView;
	
	PKGPresentationLocalizationsFilePathViewController * _localizationsViewController;
	
	PKGLicenseKeywordsViewController * _licenseKeywordsViewController;
	
	PKGViewController * _currentViewController;
	
	PKGPresentationLicenseStepSettings * _licenseSettings;
}

- (IBAction)switchLicenseType:(id)sender;

@end

@implementation PKGPresentationLicenseInspectorViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	if (self!=nil)
	{
		_licenseSettings=[inPresentationSettings licenseSettings_safe];
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];

	// Populate the Show popup button
	
	NSMutableArray * tTemplateNames=[[[PKGLicenseProvider defaultProvider] allLicensesNames] mutableCopy];
	
	[tTemplateNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	[_customLicenseTypePopUpButton addItemsWithTitles:tTemplateNames];
	
	NSUInteger tCount=_customLicenseTypePopUpButton.numberOfItems;
	
	for(NSUInteger tIndex=3;tIndex<tCount;tIndex++)
	{
		NSMenuItem * tMenuItem=[_customLicenseTypePopUpButton itemAtIndex:tIndex];
		
		tMenuItem.tag=PKGLicenseTypeTemplate;
	}
	
	// A COMPLETER
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[_currentViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	if (_localizationsViewController!=nil)
		[[NSNotificationCenter defaultCenter] addObserver:_localizationsViewController selector:@selector(localizationsDidChange:) name:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
	
	[_currentViewController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	if (_localizationsViewController!=nil)
		[[NSNotificationCenter defaultCenter] removeObserver:_localizationsViewController name:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
	
	[_currentViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_currentViewController WB_viewDidDisappear];
}

- (void)showContentsView
{
	PKGViewController * tViewController=nil;
	
	if (_licenseSettings.licenseType==PKGLicenseTypeCustom)
	{
		[_customLicenseTypePopUpButton selectItemWithTag:PKGLicenseTypeCustom];
		
		if (_localizationsViewController==nil)
		{
			_localizationsViewController=[[PKGPresentationLocalizationsFilePathViewController alloc] initWithDocument:self.document];
			
			PKGPresentationLocalizationsFilePathDataSource * tLocalizationsDataSource=[[PKGPresentationLocalizationsFilePathDataSource alloc] init];
			tLocalizationsDataSource.localizations=_licenseSettings.localizations;
			tLocalizationsDataSource.delegate=self;
			
			_localizationsViewController.dataSource=tLocalizationsDataSource;
			
			[[NSNotificationCenter defaultCenter] addObserver:_localizationsViewController selector:@selector(localizationsDidChange:) name:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
		}
		
		tViewController=_localizationsViewController;
	}
	else
	{
		NSUInteger tIndex=[_customLicenseTypePopUpButton indexOfItemWithTitle:_licenseSettings.templateName];
		
		[_customLicenseTypePopUpButton selectItemAtIndex:tIndex];
		
		if (_licenseKeywordsViewController==nil)
		{
			_licenseKeywordsViewController=[[PKGLicenseKeywordsViewController alloc] initWithDocument:self.document];
			
			_licenseKeywordsViewController.licenseStepSettings=_licenseSettings;
		}
		
		tViewController=_licenseKeywordsViewController;
	}
	
	if (_currentViewController!=tViewController)
	{
		if (_currentViewController!=nil)
		{
			[_currentViewController WB_viewWillDisappear];
			
			[_currentViewController.view removeFromSuperview];
			
			[_currentViewController WB_viewDidDisappear];
		}
		
		NSRect tBounds=_contentsHolderView.bounds;
		
		tViewController.view.frame=tBounds;
		
		[tViewController WB_viewWillAppear];
		
		[_contentsHolderView addSubview:tViewController.view];
		
		[tViewController WB_viewDidAppear];
		
		_currentViewController=tViewController;
	}
}

- (void)refreshUI
{
	if (_customLicenseTypePopUpButton==nil)
		return;
	
	[self showContentsView];
	
	[_currentViewController refreshUI];
}

#pragma mark -

- (PKGPresentationStepSettings *)settings
{
	return _licenseSettings;
}

#pragma mark -

- (IBAction)switchLicenseType:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	if (tTag==PKGLicenseTypeCustom)
	{
		if (tTag==_licenseSettings.licenseType)
			return;
	
		_licenseSettings.licenseType=PKGLicenseTypeCustom;
		
		dispatch_async(dispatch_get_main_queue(), ^{
		
			[self showContentsView];
			
			//[_currentViewController refreshUI];
			
			[self noteDocumentHasChanged];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings userInfo:nil];
		});
		
		return;
	}
	
	if (tTag==PKGLicenseTypeTemplate)
	{
		NSString * tLicenseTemplateName=sender.selectedItem.title;
		
		if (tTag!=_licenseSettings.licenseType)
		{
			_licenseSettings.licenseType=PKGLicenseTypeTemplate;
			
			_licenseSettings.templateName=tLicenseTemplateName;
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[self showContentsView];
				
				[self noteDocumentHasChanged];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings userInfo:nil];
				
			});
			
			return;
		}
		
		if ([_licenseSettings.templateName caseInsensitiveCompare:tLicenseTemplateName]==NSOrderedSame)
			return;
			
		_licenseSettings.templateName=tLicenseTemplateName;
			
		_licenseKeywordsViewController.licenseStepSettings=_licenseSettings;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[_currentViewController refreshUI];
		
			[self noteDocumentHasChanged];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings userInfo:nil];
		});
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchLicenseType:))
	{
		if (inMenuItem.tag==-1)
		{
			inMenuItem.attributedTitle=[[NSAttributedString alloc] initWithString:inMenuItem.title attributes:@{NSFontAttributeName:[NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]}];
			
			return NO;
		}
		
		return YES;
	}
	
	return YES;
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
	
	_localizationsViewController.dataSource.localizations=((PKGPresentationLocalizableStepSettings *) self.settings).localizations;
	
	[_currentViewController refreshUI];
}

@end
