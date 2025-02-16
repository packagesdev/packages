/*
 Copyright (c) 2017-2021, Stephane Sudre
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

#import "PKGOwnershipAndReferenceStyleViewController.h"

#define PKGPresentationLicenseInspectorChooseCustomTemplateTag -2

@interface PKGLicenseOpenPanelDelegate : NSObject<NSOpenSavePanelDelegate>

@property (copy) NSString * currentPath;

@end

@implementation PKGLicenseOpenPanelDelegate

- (BOOL)panel:(NSOpenPanel *)inPanel shouldEnableURL:(NSURL *)inURL
{
    if (inURL.isFileURL==NO)
        return NO;
    
    return YES;
}

- (BOOL)panel:(id)inPanel validateURL:(NSURL *)inURL error:(NSError **)outError
{
    if (inURL.isFileURL==NO)
        return NO;
    
    if ([inURL.pathExtension isEqualToString:@"pkglic"]==NO)
    {
        NSBeep();
        
        return NO;
    }
    
    return YES;
}

@end


@interface PKGPresentationLicenseInspectorViewController () <NSMenuItemValidation, PKGPresentationLocalizationsDataSourceDelegate>
{
	IBOutlet NSPopUpButton * _customLicenseTypePopUpButton;
	
	IBOutlet NSView * _contentsHolderView;
	
	PKGPresentationLocalizationsFilePathViewController * _localizationsViewController;
	
	PKGLicenseKeywordsViewController * _licenseKeywordsViewController;
	
	PKGViewController * _currentViewController;
	
	PKGPresentationLicenseStepSettings * _licenseSettings;
    
    PKGLicenseOpenPanelDelegate * _openPanelDelegate;
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

    NSMenu * tMenu=_customLicenseTypePopUpButton.menu;
    
    // Populate the Show popup button with templates
	
	NSMutableArray * tTemplateNames=[[[PKGLicenseProvider defaultProvider] allLicensesNames] mutableCopy];
	
	[tTemplateNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
    NSUInteger tIndex=[tMenu indexOfItemWithTag:PKGPresentationLicenseInspectorChooseCustomTemplateTag]-4;
    
	for(NSString * tTemplateName in tTemplateNames)
    {
        NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:tTemplateName action:nil keyEquivalent:@""];
        tMenuItem.representedObject=[[PKGLicenseProvider defaultProvider] licenseTemplateNamed:tTemplateName];
        tMenuItem.tag=PKGLicenseTypeTemplate;
        
        [tMenu insertItem:tMenuItem atIndex:tIndex];
        
        tIndex++;
    }
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
	
	switch (_licenseSettings.licenseType)
    {
        case PKGLicenseTypeCustom:
	
            [_customLicenseTypePopUpButton selectItemWithTag:PKGLicenseTypeCustom];
            
            if (_localizationsViewController==nil)
            {
                _localizationsViewController=[[PKGPresentationLocalizationsFilePathViewController alloc] initWithDocument:self.document];
                
                PKGPresentationLocalizationsFilePathDataSource * tLocalizationsDataSource=[PKGPresentationLocalizationsFilePathDataSource new];
                tLocalizationsDataSource.localizations=_licenseSettings.localizations;
                tLocalizationsDataSource.delegate=self;
                
                _localizationsViewController.dataSource=tLocalizationsDataSource;
                
                [[NSNotificationCenter defaultCenter] addObserver:_localizationsViewController selector:@selector(localizationsDidChange:) name:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
            }
            
            tViewController=_localizationsViewController;
            
            break;
            
        case PKGLicenseTypeTemplate:
        {
            PKGLicenseTemplate * tTemplate=[[PKGLicenseProvider defaultProvider] licenseTemplateNamed:_licenseSettings.templateName];
            
            if (tTemplate==nil)
            {
                // Template could not be found
                
                // A COMPLETER
            }
            
            [_customLicenseTypePopUpButton selectItemAtIndex:[_customLicenseTypePopUpButton indexOfItemWithRepresentedObject:tTemplate]];
            
            if (_licenseKeywordsViewController==nil)
            {
                _licenseKeywordsViewController=[[PKGLicenseKeywordsViewController alloc] initWithDocument:self.document];
            }
            
            _licenseKeywordsViewController.licenseStepSettings=_licenseSettings;
            
            tViewController=_licenseKeywordsViewController;
            
            break;
        }
            
        case PKGLicenseTypeCustomTemplate:
        {
            PKGFilePath * tFilePath=_licenseSettings.customTemplatePath;
            
            if (tFilePath==nil)
            {
                // A COMPLETER
            }
            
            NSInteger tIndex=[_customLicenseTypePopUpButton indexOfItemWithTag:PKGLicenseTypeCustomTemplate];
            
            NSMenuItem * tMenuItem=[_customLicenseTypePopUpButton itemAtIndex:tIndex];
            tMenuItem.action=@selector(switchLicenseType:);
            
            [self validateMenuItem:tMenuItem];
            
            [_customLicenseTypePopUpButton selectItemAtIndex:tIndex];
            
            if (_licenseKeywordsViewController==nil)
            {
                _licenseKeywordsViewController=[[PKGLicenseKeywordsViewController alloc] initWithDocument:self.document];
            }
            
            _licenseKeywordsViewController.licenseStepSettings=_licenseSettings;
            
            tViewController=_licenseKeywordsViewController;
            
            break;
        }
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

- (IBAction)switchLicenseType:(id)sender
{
    NSInteger tTag=0;
    
    if ([sender isKindOfClass:[NSMenuItem class]]==NO)
    {
        tTag=[sender selectedItem].tag;
    }
    else
    {
        tTag=[sender tag];
    }
	
	if (tTag==PKGLicenseTypeCustom)
	{
		if (tTag==_licenseSettings.licenseType)
			return;
	
		_licenseSettings.licenseType=PKGLicenseTypeCustom;
		_licenseSettings.templateName=nil;
        _licenseSettings.customTemplatePath=nil;
        
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
        NSPopUpButton * tPopUpButton=(NSPopUpButton *)sender;
        
		NSString * tLicenseTemplateName=tPopUpButton.selectedItem.title;
		
		if (tTag!=_licenseSettings.licenseType)
		{
			_licenseSettings.licenseType=PKGLicenseTypeTemplate;
			
			_licenseSettings.templateName=tLicenseTemplateName;
			_licenseSettings.customTemplatePath=nil;
            
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
        
        return;
	}
    
    if (tTag==PKGLicenseTypeCustomTemplate)
    {
        if (tTag!=_licenseSettings.licenseType)
        {
            _licenseSettings.licenseType=PKGLicenseTypeCustomTemplate;
            _licenseSettings.templateName=nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self showContentsView];
                
                [self noteDocumentHasChanged];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings userInfo:nil];
                
            });
            
            return;
        }
        
        return;
    }
    
    if (tTag==-2)
    {
        NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
        
        tOpenPanel.canChooseFiles=NO;
        tOpenPanel.canChooseDirectories=YES;
        tOpenPanel.canCreateDirectories=NO;
        tOpenPanel.allowedFileTypes=@[@".pkglic"];
        
        NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:_licenseSettings.customTemplatePath];
        
        if (tAbsolutePath!=nil)
            tOpenPanel.directoryURL=[NSURL fileURLWithPath:[tAbsolutePath stringByDeletingLastPathComponent]];
        
        _openPanelDelegate=[PKGLicenseOpenPanelDelegate new];
        
        _openPanelDelegate.currentPath=tAbsolutePath;
        
        tOpenPanel.delegate=_openPanelDelegate;
        
        tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
        
        __block PKGFilePathType tReferenceStyle=(_licenseSettings.customTemplatePath.isSet==YES) ? _licenseSettings.customTemplatePath.type : [PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
        
        PKGOwnershipAndReferenceStyleViewController * tOwnershipAndReferenceStyleViewController=nil;
        BOOL tShowOwnershipAndReferenceStyleCustomizationDialog=[PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog;
        
        
        if (tShowOwnershipAndReferenceStyleCustomizationDialog==YES)
        {
            tOwnershipAndReferenceStyleViewController=[PKGOwnershipAndReferenceStyleViewController new];
            
            tOwnershipAndReferenceStyleViewController.canChooseOwnerAndGroupOptions=NO;
            tOwnershipAndReferenceStyleViewController.referenceStyle=tReferenceStyle;
            
            NSView * tAccessoryView=tOwnershipAndReferenceStyleViewController.view;
            
            tOpenPanel.accessoryView=tAccessoryView;
        }
        
        [tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
            
            if (bResult!=WBFileHandlingPanelOKButton)
            {
                switch (_licenseSettings.licenseType)
                {
                    case PKGLicenseTypeCustom:
                        
                        [_customLicenseTypePopUpButton selectItemWithTag:PKGLicenseTypeCustom];
                        break;
                        
                    case PKGLicenseTypeTemplate:
                    {
                        PKGLicenseTemplate * tTemplate=[[PKGLicenseProvider defaultProvider] licenseTemplateNamed:_licenseSettings.templateName];
                        
                        if (tTemplate==nil)
                            break;
                        
                        [_customLicenseTypePopUpButton selectItemAtIndex:[_customLicenseTypePopUpButton indexOfItemWithRepresentedObject:tTemplate]];
                        
                        break;
                    }
                
                    case PKGLicenseTypeCustomTemplate:
                        
                        [_customLicenseTypePopUpButton selectItemAtIndex:[_customLicenseTypePopUpButton indexOfItemWithTag:PKGLicenseTypeCustomTemplate]];
                        break;
                }
                
                return;
            }
            
            if (tShowOwnershipAndReferenceStyleCustomizationDialog==YES)
                tReferenceStyle=tOwnershipAndReferenceStyleViewController.referenceStyle;
            
            NSString * tNewPath=tOpenPanel.URL.path;
            
            if (tAbsolutePath!=nil && [tAbsolutePath caseInsensitiveCompare:tNewPath]==NSOrderedSame)
                return;
            
            PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:tNewPath type:tReferenceStyle];
            
            if (tFilePath==nil)
            {
                NSLog(@"<PKGScriptViewController> File Path conversion failed.");
                return;
            }
            
            _licenseSettings.licenseType=PKGLicenseTypeCustomTemplate;
            
            if (_licenseSettings.customTemplatePath==nil)
                _licenseSettings.customTemplatePath=[PKGFilePath new];
            
            _licenseSettings.customTemplatePath.string=tFilePath.string;
            _licenseSettings.customTemplatePath.type=tFilePath.type;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self noteDocumentHasChanged];
                
                [self refreshUI];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings userInfo:nil];
            });
        }];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchLicenseType:))
	{
		switch (inMenuItem.tag)
        {
            case -4:
                
                inMenuItem.hidden=(_licenseSettings.customTemplatePath==nil);
                break;
                
            case -3:
                
                inMenuItem.hidden=(_licenseSettings.customTemplatePath==nil);
                inMenuItem.attributedTitle=[[NSAttributedString alloc] initWithString:inMenuItem.title attributes:@{NSFontAttributeName:[NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:WBControlSizeSmall]]}];
                
                return NO;
            
            case PKGPresentationLicenseInspectorChooseCustomTemplateTag:
            {
                NSString * tTitle=@"-";
                
                if (_licenseSettings.customTemplatePath==nil)
                {
                    tTitle=NSLocalizedStringFromTable(@"Choose a Custom License Template...", @"Presentation", @"");
                    inMenuItem.hidden=([PKGApplicationPreferences sharedPreferences].advancedMode==NO);
                }
                else
                {
                    tTitle=NSLocalizedStringFromTable(@"Choose Another Custom License Template...", @"Presentation", @"");
                    inMenuItem.hidden=NO;
                }
                    
                inMenuItem.attributedTitle=[[NSAttributedString alloc] initWithString:tTitle attributes:@{NSFontAttributeName:[NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:WBControlSizeSmall]]}];
                
                break;
            }
            case -1:

                inMenuItem.attributedTitle=[[NSAttributedString alloc] initWithString:inMenuItem.title attributes:@{NSFontAttributeName:[NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:WBControlSizeSmall]]}];
			
                return NO;
                
            case PKGLicenseTypeCustomTemplate:
                
                if (_licenseSettings.customTemplatePath==nil)
                {
                    inMenuItem.title=@"-";
                    inMenuItem.hidden=YES;
                }
                else
                {
                    inMenuItem.title=_licenseSettings.customTemplatePath.string.lastPathComponent.stringByDeletingPathExtension;
                    inMenuItem.hidden=NO;
                }
                
                break;
        }
        
		return YES;
	}
	
	return YES;
}

#pragma mark - PKGPresentationLocalizationsDataSourceDelegate

- (id)defaultValueForLocalizationsDataSource:(PKGPresentationLocalizationsDataSource *)inDataSource
{
	PKGFilePath * tFilePath=[PKGFilePath filePath];
	tFilePath.type=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	return tFilePath;
}

- (void)localizationsDataSource:(PKGPresentationLocalizationsDataSource *)inDataSource localizationsDataDidChange:(BOOL)inNumberOfLocalizationsDidChange
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
