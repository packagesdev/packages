/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGLocalizationUtilities.h"

#import "PKGLanguageConverter.h"

//#import "NSString+Iceberg.h"

@implementation PKGLocalizationUtilities

+ (BOOL)allLanguagesUsedInLocalizations:(NSArray *) inLocalizationsArray
{
	if (inLocalizationsArray==nil)
		return NO;
	
	return ([PKGLocalizationUtilities englishLanguages].count==inLocalizationsArray.count);
}


+ (NSMutableArray *)englishLanguages
{
	static NSMutableArray * sEnglishLanguageNames=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sEnglishLanguageNames=[[NSMutableArray alloc] initWithObjects:@"Arabic",
							   @"Brazilian Portuguese",
							   @"Bulgarian",
							   @"Canadian French",
							   @"Catalan",
							   @"Croatian",
							   @"Czech",
							   @"Danish",
							   @"Dutch",
							   @"English",
							   @"Finnish",
							   @"French",
							   @"German",
							   @"Greek",
							   @"Hebrew",
							   @"Hungarian",
							   @"Icelandic",
							   @"Indonesian",
							   @"Italian",
							   @"Japanese",
							   @"Korean",
							   @"Macedonian",
							   @"Malay",
							   @"Mexican Spanish",
							   @"Norwegian",
							   @"Polish",
							   @"Portuguese",
							   @"Portuguese (Portugal)",
							   @"Romanian",
							   @"Russian",
							   @"Simplified Chinese",
							   @"Slovak",
							   @"Slovenian",
							   @"Spanish",
							   @"Swedish",
							   @"Swiss French",
							   @"Thai",
							   @"Traditional Chinese",
							   @"Turkish",
							   @"Ukrainian",
							   @"Vietnamese",
							   @"Welsh",
							   nil];
		
		[sEnglishLanguageNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
	});
	
	return sEnglishLanguageNames;
}

+ (NSMenu *)languagesMenu
{
	static NSMenu * sMenu=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	
		PKGLanguageConverter * tLanguageConverter=[PKGLanguageConverter sharedConverter];
		
		// Build Menu
		
		sMenu=[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
		
		NSMutableArray * tLocalizedLanguages=[[[PKGLocalizationUtilities englishLanguages] WB_arrayByMappingObjectsUsingBlock:^NSDictionary *(NSString * bEnglishLanguage, NSUInteger bIndex) {
			
			return @{@"Language":bEnglishLanguage,
					 @"Localization":NSLocalizedString(bEnglishLanguage,@""),
					 @"Index":@(bIndex)};
		}] mutableCopy];
		
		[tLocalizedLanguages sortUsingComparator:^NSComparisonResult(NSDictionary * obj1, NSDictionary * obj2) {
			
			return [obj1[@"Localization"] compare:obj2[@"Localization"]];
		}];
		
		[tLocalizedLanguages enumerateObjectsUsingBlock:^(NSDictionary * bDictionary, NSUInteger bIndex, BOOL *bOutStop) {
			
			NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:bDictionary[@"Localization"] action:nil keyEquivalent:@""];
			
			tMenuItem.tag=[bDictionary[@"Index"] integerValue];
			
			NSString * tISOName=[tLanguageConverter ISOFromEnglish:bDictionary[@"Language"]];
			
			if (tISOName!=nil)
				tMenuItem.image=[NSImage imageNamed:[NSString stringWithFormat:@"flag_%@",tISOName]];
			
			[sMenu addItem:tMenuItem];
		}];
	});
	
	return [sMenu copyWithZone:[NSMenu menuZone]];
}

/*+ (NSArray *)localizationsFromLocalizationsArray:(NSArray *)inLocalizationsArray
{
	if (inLocalizationsArray.count==0)
		return nil;
	
	NSMutableArray * tLocalizations=[NSMutableArray array];
	
	for(NSDictionary * tItemDictionary in inLocalizationsArray)
	{
		NSString * tLanguage=tItemDictionary[ICDOCUMENT_LANGUAGE];
		
		[tLocalizations addObject:(tLanguage==nil) ? @"" : tLanguage];
	}
	
	return [tLocalizations copy];
}

+ (id) localizedValueForLanguage:(NSString *) inLanguage inLocalizations:(NSArray *) inLocalizationsArray lookForBestMatch:(BOOL) inLookForBestMatch
{
	if (inLanguage==nil || inLocalizationsArray==nil)
		return nil;
	
	id tLocalizedValue=nil;
	
	NSArray * tAvailableLocalizations=[PKGLocalizationUtilities localizationsFromLocalizationsArray:inLocalizationsArray];
	
	if (tAvailableLocalizations!=nil)
	{
		NSUInteger tIndex=[tAvailableLocalizations indexOfObject:inLanguage];
		
		if (tIndex==NSNotFound && inLookForBestMatch==YES)
		{
			// Try with the ISO name
			
			inLanguage=[[PKGLanguageConverter sharedConverter] ISOFromEnglish:inLanguage];
			
			tIndex=[tAvailableLocalizations indexOfObject:inLanguage];
		
			if (tIndex==NSNotFound)
			{
				NSArray * tPreferedLocalizations=(NSArray *) CFBundleCopyPreferredLocalizationsFromArray((CFArrayRef) tAvailableLocalizations);
			
				if (tPreferedLocalizations!=nil)
				{
					for(NSString * tLanguage in tPreferedLocalizations)
					{
						tIndex=[tAvailableLocalizations indexOfObject:tLanguage];
						
						if (tIndex!=NSNotFound)
						{
							break;
						}
						else
						{
							NSString * tISOLanguage=[[PKGLanguageConverter sharedConverter] ISOFromEnglish:tLanguage];
							
							tIndex=[tAvailableLocalizations indexOfObject:tISOLanguage];
						
							if (tIndex!=NSNotFound)
								break;
						}
					}
				}
			}
		}
		
		if (tIndex!=NSNotFound)
		{
			NSDictionary * tDictionary=[inLocalizationsArray objectAtIndex:tIndex];
			
			if (tDictionary!=nil)
				tLocalizedValue=tDictionary[ICDOCUMENT_VALUE];
		}
	}
	
	return tLocalizedValue;
}

+ (id) localizedValueForLanguage:(NSString *) inLanguage inLocalizations:(NSArray *) inLocalizationsArray
{
	return [PKGLocalizationUtilities localizedValueForLanguage:inLanguage inLocalizations:inLocalizationsArray lookForBestMatch:YES];
}
*/
+ (NSString *)nextPreferredLanguageAfterLanguages:(NSArray *)inLanguagesArray
{
	if (inLanguagesArray==nil)
		return nil;
	
	NSArray * tEnglishLanguageNames=[PKGLocalizationUtilities englishLanguages];
	
	if (tEnglishLanguageNames==nil)
		return nil;
	
	NSArray * tPreferedLocalizations;
		
	if (inLanguagesArray.count==0)
	{
		tPreferedLocalizations=(__bridge_transfer NSArray *) CFBundleCopyPreferredLocalizationsFromArray((__bridge CFArrayRef) tEnglishLanguageNames);
		
		if (tPreferedLocalizations!=nil && [tPreferedLocalizations count]>0)
			return [[PKGLanguageConverter sharedConverter] englishFromISO:[tPreferedLocalizations objectAtIndex:0]];
		
		return nil;
	}
	
	NSString * tLanguageName=nil;
	
	NSMutableArray * tMutableEnglishLanguageNames=[tEnglishLanguageNames mutableCopy];

	[tMutableEnglishLanguageNames removeObjectsInArray:inLanguagesArray];

	if (tEnglishLanguageNames.count==0)
		return nil;
	
	if (tEnglishLanguageNames.count==1)
		return tEnglishLanguageNames.lastObject;
	
	tPreferedLocalizations=(__bridge_transfer NSArray *) CFBundleCopyPreferredLocalizationsFromArray((__bridge CFArrayRef) tMutableEnglishLanguageNames);
		
	if (tPreferedLocalizations.count==0)
		return nil;
	
	tLanguageName=[[PKGLanguageConverter sharedConverter] englishFromISO:tPreferedLocalizations[0]];
		
	if ([tEnglishLanguageNames containsObject:tLanguageName]==NO)	// Workaround for bug in Cocoa
		tLanguageName=tEnglishLanguageNames[0];
	
	return tLanguageName;
}

/*+ (NSArray *) allLanguagesFromLocalizations:(NSArray *) inLocalizationsArray
{
	if (inLocalizationsArray==nil)
		return nil;
	
	NSMutableArray * tAllLanguages=[NSMutableArray array];
	
	for(NSDictionary * tDictionary in inLocalizationsArray)
	{
		NSString * tUsedLanguage=[tDictionary objectForKey:ICDOCUMENT_LANGUAGE];
		
		[tAllLanguages addObject:[[PKGLanguageConverter sharedConverter] englishFromISO:tUsedLanguage]];
	}
	
	return tAllLanguages;
}

+ (BOOL) localizations:(NSArray *) inLocalizationsArray containsLanguage:(NSString *) inLanguage
{
	if (inLocalizationsArray!=nil && inLanguage!=nil)
	{
		for(NSDictionary * tDictionary in inLocalizationsArray)
		{
			NSString * tUsedLanguage=[tDictionary objectForKey:ICDOCUMENT_LANGUAGE];
			
			if ([tUsedLanguage isEqualToString:inLanguage]==YES)
				return YES;
		}
	}
	
	return NO;
}

+ (NSUInteger) indexOfLanguage:(NSString *) inLanguage inLocalizations:(NSArray *) inLocalizationsArray
{
	if (inLocalizationsArray!=nil && inLanguage!=nil)
	{
		NSUInteger tCount=[inLocalizationsArray count];
		
		for(NSUInteger i=0;i<tCount;i++)
		{
			NSDictionary * tDictionary=[inLocalizationsArray objectAtIndex:i];
			
			NSString * tUsedLanguage=[tDictionary objectForKey:ICDOCUMENT_LANGUAGE];
				
			if ([tUsedLanguage isEqualToString:inLanguage]==YES)
			{
				return i;
			}
		}
	}
	
	return NSNotFound;
}

+ (NSMutableDictionary *) validLocalizationsPathFromLocalizationsArray:(NSArray *) inLocalizationsArray  projectPath:(NSString *) inProjectPath referencePath:(NSString *) inReferencePath
{
	NSMutableDictionary * tValidLocalizationsPath=nil;
	
	if (inLocalizationsArray!=nil && inProjectPath!=nil && inReferencePath!=nil)
	{
		tValidLocalizationsPath=[NSMutableDictionary dictionary];
		
		if (tValidLocalizationsPath!=nil)
		{
			NSFileManager * tFileManager=[NSFileManager defaultManager];
			
			for(NSDictionary * tDictionary in inLocalizationsArray)
			{
				NSString * tLanguage=[[PKGLanguageConverter sharedConverter] englishFromISO:[tDictionary objectForKey:ICDOCUMENT_LANGUAGE]];
				
				NSDictionary * tPathDictionary=[tDictionary objectForKey:ICDOCUMENT_VALUE];
				
				if (tPathDictionary!=nil)
				{
					NSInteger tPathType=[[tPathDictionary objectForKey:ICDOCUMENT_PATH_TYPE] integerValue];
						
					NSString * tPath=[tPathDictionary objectForKey:ICDOCUMENT_PATH];
					
					if (tPath!=nil && [tPath length]>0)
					{
						if (tPathType==ICDOCUMENT_PATH_TYPE_RELATIVE_TO_PROJECT)
						{
							tPath=[tPath stringByAbsolutingWithPath:inProjectPath];
						}
						else if (tPathType==ICDOCUMENT_PATH_TYPE_RELATIVE_TO_REFERENCE_FOLDER)
						{
							tPath=[tPath stringByAbsolutingWithPath:inReferencePath];
						}
							
						if ([tFileManager fileExistsAtPath:tPath]==YES)
						{
							NSString * tNativeLanguage;
							
							tNativeLanguage=[[PKGLanguageConverter sharedConverter] nativeForEnglish:tLanguage];
							
							[tValidLocalizationsPath setObject:[NSDictionary dictionaryWithObjectsAndKeys:tPath,ICDOCUMENT_PATH,
																										  tLanguage,ICDOCUMENT_LANGUAGE,
																										  nil]
														forKey:tNativeLanguage];
						}
					}
				}
			}
		}
	}
	
	return tValidLocalizationsPath;
}

+ (NSMutableArray *) localizationsArrayWithValue:(id) inValue forLanguage:(NSString *) inLanguage
{
	NSMutableArray * tLocalizationsArray=[NSMutableArray array];

	if (tLocalizationsArray!=nil)
	{
		NSMutableDictionary * tLanguageDictionary=[NSMutableDictionary dictionaryWithObjectsAndKeys:inLanguage,ICDOCUMENT_LANGUAGE,
																				  inValue,ICDOCUMENT_VALUE,
																				  nil];

		if (tLanguageDictionary!=nil)
			[tLocalizationsArray addObject:tLanguageDictionary];
	}
	
	return tLocalizationsArray;
}*/

+ (NSString *)possibleLanguageForFileAtPath:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	NSString * tParentFolder=inPath.stringByDeletingLastPathComponent.lastPathComponent;
	
	NSString * tExtension=tParentFolder.pathExtension;
	
	if (tExtension.length>0 && [tExtension caseInsensitiveCompare:@"lproj"]!=NSOrderedSame)
		return nil;
	
	NSString * tLanguage=tParentFolder.stringByDeletingPathExtension;
	
	if (tLanguage==nil)
		return nil;

	PKGLanguageConverter * tDefaultConverter=[PKGLanguageConverter sharedConverter];
	
	NSString * tEnglishLanguage=[tDefaultConverter englishFromISO:tLanguage];
	
	if ([[tDefaultConverter allEnglishNames] containsObject:tEnglishLanguage]==YES)
		return tEnglishLanguage;
	
	tEnglishLanguage=[tDefaultConverter englishFromISO:[tEnglishLanguage lowercaseString]];
	
	if ([[tDefaultConverter allEnglishNames] containsObject:tEnglishLanguage]==YES)
		return tEnglishLanguage;
		
	tEnglishLanguage=[tDefaultConverter englishFromISO:[tEnglishLanguage capitalizedString]];
	
	if ([[tDefaultConverter allEnglishNames] containsObject:tEnglishLanguage]==YES)
		return tEnglishLanguage;
	
	return nil;
}

@end
