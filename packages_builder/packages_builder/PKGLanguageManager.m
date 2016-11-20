/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLanguageManager.h"

@implementation PKGLanguageManager

+ (NSString *)shortFolderNameForEnglishLanguage:(NSString *)inEnglishLanguage
{
	if (inEnglishLanguage==nil)
		return nil;
	
	static NSDictionary * sFoldersNamesDictionary=nil;
	static dispatch_once_t onceToken;
	
	// /System/Library/PrivateFrameworks/International.framework/Versions/A/Resources/SALanguage.plist
	
	dispatch_once(&onceToken, ^{
		sFoldersNamesDictionary=@{
								  @"Arabic":@"ar.lproj",
								  @"Brazilian Portuguese":@"pt-BR.lproj",
								  @"Bulgarian":@"bg.lproj",
								  @"Canadian French":@"fr-CA.lproj",
								  @"Catalan":@"ca.lproj",
								  @"Croatian":@"hr.lproj",
								  @"Czech":@"cs.lproj",
								  @"Danish":@"da.lproj",
								  @"Dutch":@"nl.lproj",
								  @"English":@"en.lproj",
								  @"Farsi":@"fa.lproj",
								  @"Finnish":@"fi.lproj",
								  @"French":@"fr.lproj",
								  @"German":@"de.lproj",
								  @"Greek":@"el.lproj",
								  @"Hebrew":@"he.lproj",
								  @"Hindi":@"hi.lproj",
								  @"Hungarian":@"hu.lproj",
								  @"Icelandic":@"is.lproj",
								  @"Indonesian":@"id.lproj",
								  @"Italian":@"it.lproj",
								  @"Japanese":@"ja.lproj",
								  @"Korean":@"ko.lproj",
								  @"Macedonian":@"mk.lproj",
								  @"Malay":@"ms.lproj",
								  @"Mexican Spanish":@"es-MX.lproj",
								  @"Norwegian":@"no.lproj",
								  @"Polish":@"pl.lproj",
								  @"Portuguese":@"pt.lproj",
								  @"Portuguese (Brazil)":@"pt-BR.lproj",
								  @"Portuguese (Portugal)":@"pt-PT.lproj",
								  @"Romanian":@"ro.lproj",
								  @"Russian":@"ru.lproj",
								  @"Simplified Chinese":@"zh_CN.lproj",
								  @"Slovak":@"sk.lproj",
								  @"Slovenian":@"sl.lproj",
								  @"Spanish":@"es.lproj",
								  @"Swedish":@"sv.lproj",
								  @"Swiss French":@"fr-CH.lproj",
								  @"Thai":@"th.lproj",
								  @"Traditional Chinese":@"zh_TW.lproj",
								  @"Turkish":@"tr.lproj",
								  @"Ukrainian":@"uk.lproj",
								  @"Vietnamese":@"vi.lproj",
								  @"Welsh":@"cy.lproj"
								  };
	});
	
	return sFoldersNamesDictionary[inEnglishLanguage];
}

+ (NSString *)folderNameForEnglishLanguage:(NSString *) inEnglishLanguage
{
	if (inEnglishLanguage==nil)
		return nil;
	
	static NSDictionary * sFoldersNamesDictionary=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sFoldersNamesDictionary=@{
								  @"Arabic":@"Arabic.lproj",
								  @"Brazilian Portuguese":@"pt_BR.lproj",
								  @"Bulgarian":@"Bulgarian.lproj",
								  @"Canadian French":@"fr_CA.lproj",
								  @"Catalan":@"Catalan.lproj",
								  @"Croatian":@"Croatian.lproj",
								  @"Czech":@"Czech.lproj",
								  @"Danish":@"Danish.lproj",
								  @"Dutch":@"Dutch.lproj",
								  @"English":@"English.lproj",
								  @"Farsi":@"Farsi.lproj",
								  @"Finnish":@"Finnish.lproj",
								  @"French":@"French.lproj",
								  @"German":@"German.lproj",
								  @"Greek":@"Greek.lproj",
								  @"Hebrew":@"Hebrew.lproj",
								  @"Hindi":@"Hindi.lproj",
								  @"Hungarian":@"Hungarian.lproj",
								  @"Icelandic":@"Icelandic.lproj",
								  @"Indonesian":@"Indonesian.lproj",
								  @"Italian":@"Italian.lproj",
								  @"Japanese":@"Japanese.lproj",
								  @"Korean":@"Korean.lproj",
								  @"Macedonian":@"Macedonian.lproj",
								  @"Malay":@"Malay.lproj",
								  @"Mexican Spanish":@"es_MX.lproj",
								  @"Norwegian":@"Norwegian.lproj",
								  @"Polish":@"Polish.lproj",
								  @"Portuguese":@"pt.lproj",
								  @"Portuguese (Brazil)":@"pt_BR.lproj",
								  @"Portuguese (Portugal)":@"pt_PT.lproj",
								  @"Romanian":@"Romanian.lproj",
								  @"Russian":@"Russian.lproj",
								  @"Simplified Chinese":@"zh_CN.lproj",
								  @"Slovak":@"Slovak.lproj",
								  @"Slovenian":@"Slovenian.lproj",
								  @"Spanish":@"Spanish.lproj",
								  @"Swedish":@"Swedish.lproj",
								  @"Swiss French":@"fr_CH.lproj",
								  @"Thai":@"Thai.lproj",
								  @"Traditional Chinese":@"zh_TW.lproj",
								  @"Turkish":@"Turkish.lproj",
								  @"Ukrainian":@"Ukrainian.lproj",
								  @"Vietnamese":@"Vietnamese.lproj",
								  @"Welsh":@"Welsh.lproj"
								  };
	});
	
	return sFoldersNamesDictionary[inEnglishLanguage];
}

@end
