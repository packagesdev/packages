/*
 Copyright (c) 2017, Stephane Sudre
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

- (NSDictionary *)localizedStringsForLocalization:(NSString *)inLocalization
{
	if (inLocalization==nil)
		return nil;
	
	NSMutableDictionary * tLocalizedDictionary=[NSMutableDictionary dictionary];
	
	NSString * tEnglishLanguage=[[PKGLanguageConverter sharedConverter] englishFromISO:inLocalization];
	NSString * tISOLanguage=[[PKGLanguageConverter sharedConverter] ISOFromEnglish:inLocalization];
	
	NSString * tPath=[_bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:tEnglishLanguage];
	
	if (tPath==nil)
		tPath=[_bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:tISOLanguage];
	
	if (tPath!=nil)
	{
		NSDictionary * tLocalizableDictionary=[[NSDictionary alloc] initWithContentsOfFile:tPath];
		
		if (tLocalizableDictionary!=nil)
			[tLocalizedDictionary addEntriesFromDictionary:tLocalizableDictionary];
	}
	
	tPath=[_bundle pathForResource:@"InfoPlist" ofType:@"strings" inDirectory:nil forLocalization:tEnglishLanguage];
	
	if (tPath==nil)
		tPath=[_bundle pathForResource:@"InfoPlist" ofType:@"strings" inDirectory:nil forLocalization:tISOLanguage];
	
	if (tPath!=nil)
	{
		NSDictionary * tLocalizableDictionary=[[NSDictionary alloc] initWithContentsOfFile:tPath];
		
		if (tLocalizableDictionary!=nil)
			[tLocalizedDictionary addEntriesFromDictionary:tLocalizableDictionary];
	}
	
	return [tLocalizedDictionary copy];
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
