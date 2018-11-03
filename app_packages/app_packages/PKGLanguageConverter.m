/*
Copyright (c) 2004-2018, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
 
 Where to find the data:
 
 English <-> ISO : /System/Library/PrivateFrameworks/International.framework/Versions/A/Resources/SALanguage.plist
 
 Native Name : /System/Library/PrivateFrameworks/IntlPreferences.framework/Versions/A/Resources/Language.strings
 
*/

#import "PKGLanguageConverter.h"

@interface PKGLanguageConverter ()
{
	NSDictionary * _ISOToEnglishDictionary;
	NSDictionary * _englishToISODictionary;

	NSDictionary * _ISOFailover;
	
	NSDictionary * _englishToNativeDictionary;
	NSDictionary * _nativeToEnglishDictionary;
}

	@property (readwrite) NSArray * allEnglishNames;

@end

@implementation PKGLanguageConverter

+ (PKGLanguageConverter *)sharedConverter
{
    static PKGLanguageConverter * sLanguageConverter=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		 sLanguageConverter=[PKGLanguageConverter new];
	});
    
    return sLanguageConverter;
}

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _englishToNativeDictionary=[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NativeLanguages" ofType:@"plist"]];
		
		NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
		
		[_englishToNativeDictionary enumerateKeysAndObjectsUsingBlock:^(id bKey, id bObject, BOOL *bOutStop) {
			
			tMutableDictionary[bObject]=bKey;
			
		}];
		
		_nativeToEnglishDictionary=[tMutableDictionary copy];
		
		_allEnglishNames=@[@"Arabic",
						   @"Bulgarian",
						   @"Canadian French",
						   @"Catalan",
						   @"Croatian",
						   @"Czech",
						   @"Danish",
						   @"Dutch",
						   @"English",
						   @"English (Australia)",
						   @"English (Great Britain)",
						   @"Farsi",
						   @"Finnish",
						   @"French",
						   @"German",
						   @"Greek",
						   @"Hebrew",
						   @"Hindi",
						   @"Hungarian",
						   @"Icelandic",
						   @"Indonesian",
						   @"Italian",
						   @"Japanese",
						   @"Korean",
						   @"Latvian",
						   @"Macedonian",
						   @"Malay",
						   @"Mexican Spanish",
						   @"Norwegian",
						   @"Polish",
						   @"Portuguese",
						   @"Portuguese (Brazil)",
						   @"Portuguese (Portugal)",
						   @"Romanian",
						   @"Russian",
						   @"Simplified Chinese",
						   @"Slovak",
						   @"Slovenian",
						   @"Spanish",
						   @"Spanish (Latin America)",
						   @"Swedish",
						   @"Swiss French",
						   @"Thai",
						   @"Traditional Chinese",
						   @"Traditional Chinese (Hong Kong)",
						   @"Turkish",
						   @"Ukrainian",
						   @"Vietnamese",
						   @"Welsh"];
		
		
		_englishToISODictionary=@{@"Arabic":@"ar",
								  @"Bulgarian":@"bg",
								  @"Canadian French":@"fr_CA",
								  @"Catalan":@"ca",
								  @"Czech":@"cs",
								  @"Danish":@"da",
								  @"Dutch":@"nl",
								  @"English":@"en",
								  @"English (Australia)":@"en_AU",
								  @"English (Great Britain)":@"en_GB",
								  @"Farsi":@"fa",
								  @"Finnish":@"fi",
								  @"French":@"fr",
								  @"German":@"de",
								  @"Greek":@"el",
								  @"Hebrew":@"he",
								  @"Hindi":@"hi",
								  @"Croatian":@"hr",
								  @"Hungarian":@"hu",
								  @"Icelandic":@"is",
								  @"Indonesian":@"id",
								  @"Italian":@"it",
								  @"Japanese":@"ja",
								  @"Korean":@"ko",
								  @"Latvian":@"lv",
								  @"Macedonian":@"mk",
								  @"Malay":@"ms",
								  @"Spanish (Latin America)":@"es_419",
								  @"Mexican Spanish":@"es_MX",
								  @"Norwegian":@"no",
								  @"Polish":@"pl",
								  @"Portuguese":@"pt",
								  @"Portuguese (Brazil)":@"pt_BR",
								  @"Portuguese (Portugal)":@"pt_PT",
								  @"Romanian":@"ro",
								  @"Russian":@"ru",
								  @"Spanish":@"es",
								  @"Simplified Chinese":@"zh_CN",
								  @"Slovak":@"sk",
								  @"Slovenian":@"sl",
								  @"Swedish":@"sv",
								  @"Swiss French":@"fr_CH",
								  @"Thai":@"th",
								  @"Traditional Chinese":@"zh_TW",
								  @"Traditional Chinese (Hong Kong)":@"zh_HK",
								  @"Turkish":@"tr",
								  @"Ukrainian":@"uk",
								  @"Vietnamese":@"vi",
								  @"Welsh":@"cy"};
		
		_ISOToEnglishDictionary=@{@"ar":@"Arabic",
								  @"bg":@"Bulgarian",
								  @"fr_CA":@"Canadian French",
								  @"ca":@"Catalan",
								  @"hr":@"Croatian",
								  @"cs":@"Czech",
								  @"da":@"Danish",
								  @"nl":@"Dutch",
								  @"en":@"English",
								  @"en_AU":@"English (Australia)",
								  @"en_GB":@"English (Great Britain)",
								  @"fa":@"Farsi",
								  @"fi":@"Finnish",
								  @"fr":@"French",
								  @"de":@"German",
								  @"el":@"Greek",
								  @"he":@"Hebrew",
								  @"hi":@"Hindi",
								  @"hu":@"Hungarian",
								  @"is":@"Icelandic",
								  @"id":@"Indonesian",
								  @"it":@"Italian",
								  @"ja":@"Japanese",
								  @"ko":@"Korean",
								  @"lv":@"Latvian",
								  @"mk":@"Macedonian",
								  @"ms":@"Malay",
								  @"es_419":@"Spanish (Latin America)",
								  @"es_MX":@"Mexican Spanish",
								  @"no":@"Norwegian",
								  @"pl":@"Polish",
								  @"pt":@"Portuguese",
								  @"pt_BR":@"Portuguese (Brazil)",
								  @"pt_PT":@"Portuguese (Portugal)",
								  @"ro":@"Romanian",
								  @"ru":@"Russian",
								  @"zh_CN":@"Simplified Chinese",
								  @"sk":@"Slovak",
								  @"sl":@"Slovenian",
								  @"es":@"Spanish",
								  @"sv":@"Swedish",
								  @"fr_CH":@"Swiss French",
								  @"th":@"Thai",
								  @"zh_HK":@"Traditional Chinese (Hong Kong)",
								  @"zh_TW":@"Traditional Chinese",
								  @"tr":@"Turkish",
								  @"uk":@"Ukrainian",
								  @"vi":@"Vietnamese",
								  @"cy":@"Welsh"};
		
		_ISOFailover=@{@"en_AU":@"en",
					   @"en_GB":@"en",
					   @"fr_CA":@"fr",
					   @"pt_BR":@"pt",
					   @"zh_HK":@"zh_TW"
					   };
	}
    
    return self;
}

#pragma mark -

- (NSString *)englishFromISO:(NSString *)inISOName
{
    if (_ISOToEnglishDictionary==nil || inISOName==nil)
		return inISOName;

	NSString * tEnglishName=_ISOToEnglishDictionary[inISOName];
	
	if (tEnglishName==nil)
		tEnglishName=inISOName;
	
    return tEnglishName;
}

- (NSString *)ISOFromEnglish:(NSString *)inEnglishName
{
	if (_englishToISODictionary==nil || inEnglishName==nil)
		return inEnglishName;
    
     NSString * tISOName=_englishToISODictionary[inEnglishName];
	
	if (tISOName==nil)
		tISOName=inEnglishName;
	
    return tISOName;
}

- (NSString *)ISOFailOverForISO:(NSString *)inISOName
{
	if (_ISOFailover==nil || inISOName==nil)
		return inISOName;
	
	NSString * tISOFailOver=_ISOFailover[inISOName];
	
	if (tISOFailOver==nil)
		tISOFailOver=inISOName;
	
	return tISOFailOver;
}

- (NSString *)nativeForEnglish:(NSString *)inEnglishName
{
	if (_englishToNativeDictionary==nil || inEnglishName==nil)
		return nil;
	
	NSString * tNativeName=_englishToNativeDictionary[inEnglishName];

	if (tNativeName==nil)
		tNativeName=inEnglishName;

	return tNativeName;
}

- (NSString *)englishForNative:(NSString *)inNativeName
{
	if (_nativeToEnglishDictionary==nil || inNativeName==nil)
		return inNativeName;
	
	NSString * tEnglishName=_nativeToEnglishDictionary[inNativeName];
	
	if (tEnglishName==nil)
		tEnglishName=inNativeName;
	
	return tEnglishName;
}

@end
