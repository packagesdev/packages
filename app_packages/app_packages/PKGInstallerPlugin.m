/*
 Copyright (c) 2017-2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGInstallerPlugin.h"

#import "PKGLanguageConverter.h"

NSString * const PKGInstallerPluginSectionTitleKey=@"InstallerSectionTitle";

NSString * const PKGInstallerPluginPageTitleKey=@"PageTitle";

@interface PKGInstallerPlugin ()
{
	NSMutableDictionary * _localizations;
}

- (NSDictionary *)localizedStringsForResourceNamed:(NSString *)inResourceName forLocalization:(NSString *)inLocalization;
- (NSDictionary *)localizedStringsForLocalization:(NSString *)inLocalization;

@end

@implementation PKGInstallerPlugin

- (instancetype)initWithBundleAtURL:(NSURL *)inURL
{
	NSBundle * tBundle=[NSBundle bundleWithURL:inURL];
	
	return [self initWithBundle:tBundle];
}

- (instancetype)initWithBundleAtPath:(NSString *)inPath
{
	NSBundle * tBundle=[NSBundle bundleWithPath:inPath];
	
	return [self initWithBundle:tBundle];
}

- (instancetype)initWithBundle:(NSBundle *)inBundle
{
	if (inBundle==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_bundle=inBundle;
		
		_localizations=[NSMutableDictionary dictionary];
	}
	
	return self;
}

#pragma mark -

- (NSDictionary *)localizedStringsForResourceNamed:(NSString *)inResourceName forLocalization:(NSString *)inLocalization
{
    if (inResourceName== nil || inLocalization==nil)
        return nil;
    
    NSString * tEnglishLanguage=[[PKGLanguageConverter sharedConverter] englishFromISO:inLocalization];
    NSString * tISOLanguage=[[PKGLanguageConverter sharedConverter] ISOFromEnglish:inLocalization];
    
    NSString * tPath=[_bundle pathForResource:inResourceName ofType:@"strings" inDirectory:nil forLocalization:tEnglishLanguage];
    
    if (tPath==nil)
        tPath=[_bundle pathForResource:inResourceName ofType:@"strings" inDirectory:nil forLocalization:tISOLanguage];
    
    if (tPath!=nil)
        return [[NSDictionary alloc] initWithContentsOfFile:tPath];
    
    // Starting with macOS l'Aventura, there is a .loctable file (it does not make sense so far).
    tPath=[_bundle pathForResource:inResourceName ofType:@"loctable"];
    
    if (tPath==nil)
        return nil;
    
    NSDictionary * tLocalizableDictionary=[[NSDictionary alloc] initWithContentsOfFile:tPath];
        
    if (tLocalizableDictionary==nil)
        return nil;
    
    NSDictionary * tLocalizedStringsDictionary=tLocalizableDictionary[tISOLanguage];
    
    if (tLocalizedStringsDictionary==nil)
        tLocalizedStringsDictionary=tLocalizableDictionary[tEnglishLanguage];
    
    return tLocalizedStringsDictionary;
}

- (NSDictionary *)localizedStringsForLocalization:(NSString *)inLocalization
{
	if (inLocalization==nil)
		return nil;
	
	NSMutableDictionary * tLocalizedStringsDictionary=[NSMutableDictionary dictionary];
	
    NSDictionary * tLocalizableDictionary=[self localizedStringsForResourceNamed:@"Localizable" forLocalization:inLocalization];
    
    if (tLocalizableDictionary!=nil)
        [tLocalizedStringsDictionary addEntriesFromDictionary:tLocalizableDictionary];
    
    NSDictionary * tInfoPlistDictionary=[self localizedStringsForResourceNamed:@"InfoPlist" forLocalization:inLocalization];
    
    if (tInfoPlistDictionary!=nil)
        [tLocalizedStringsDictionary addEntriesFromDictionary:tInfoPlistDictionary];
	
	return [tLocalizedStringsDictionary copy];
}

#pragma mark -

- (NSString *)sectionTitleForLocalization:(NSString *)inLocalization
{
	return [self stringForKey:PKGInstallerPluginSectionTitleKey localization:inLocalization];
}

- (NSString *)pageTitleForLocalization:(NSString *)inLocalization
{
	return [self stringForKey:PKGInstallerPluginPageTitleKey localization:inLocalization];
}

- (NSString *)stringForKey:(NSString *)inKey localization:(NSString *)inLocalization
{
	if (inLocalization==nil)
		return nil;
	
	NSDictionary * tLocalizedStrings=_localizations[inLocalization];
	
	if (tLocalizedStrings!=nil)
		return tLocalizedStrings[inKey];
	
	tLocalizedStrings=[self localizedStringsForLocalization:inLocalization];
	
	if (tLocalizedStrings.count>0)
	{
		_localizations[inLocalization]=tLocalizedStrings;
		
		return tLocalizedStrings[inKey];
	}
	
	NSArray * tPreferedLocalizations=(__bridge_transfer NSArray *) CFBundleCopyPreferredLocalizationsFromArray((__bridge CFArrayRef) _localizations.allKeys);
	
	if (tPreferedLocalizations==nil)
		return nil;
	
	for(NSString * tLocalization in tPreferedLocalizations)
	{
		tLocalizedStrings=_localizations[tLocalization];
		
		if (tLocalizedStrings!=nil)
			return tLocalizedStrings[inKey];
		
		tLocalizedStrings=[self localizedStringsForLocalization:tLocalization];
		
		if (tLocalizedStrings.count>0)
		{
			_localizations[tLocalization]=tLocalizedStrings;
			
			return tLocalizedStrings[inKey];
		}
	}
	
	return nil;
}

@end
