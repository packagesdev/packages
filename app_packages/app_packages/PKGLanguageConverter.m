/*
Copyright (c) 2004-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGLanguageConverter.h"

@interface PKGLanguageConverter ()
{
	NSDictionary * _ISOToEnglishDictionary;
	NSDictionary * _englishToISODictionary;

	NSDictionary * _conversionDictionary;
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
        _conversionDictionary=[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NativeLanguages" ofType:@"plist"]];
		
		_allEnglishNames=@[@"Arabic",
						   @"Brazilian Portuguese",
						   @"Bulgarian",
						   @"Canadian French",
						   @"Catalan",
						   @"Croatian",
						   @"Czech",
						   @"Danish",
						   @"Dutch",
						   @"English",
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
						   @"Welsh"];
		
		
		_englishToISODictionary=@{@"Arabic":@"ar",
								  @"Brazilian Portuguese":@"pt_BR",
								  @"Bulgarian":@"bg",
								  @"Canadian French":@"fr_CA",
								  @"Catalan":@"ca",
								  @"Czech":@"cs",
								  @"Danish":@"da",
								  @"Dutch":@"nl",
								  @"English":@"en",
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
								  @"Macedonian":@"mk",
								  @"Malay":@"ms",
								  @"Mexican Spanish":@"es_MX",
								  @"Norwegian":@"no",
								  @"Polish":@"pl",
								  @"Portuguese":@"pt",
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
								  @"Turkish":@"tr",
								  @"Ukrainian":@"uk",
								  @"Vietnamese":@"vi",
								  @"Welsh":@"cy"};
		
		_ISOToEnglishDictionary=@{@"ar":@"Arabic",
								  @"pt_BR":@"Brazilian Portuguese",
								  @"bg":@"Bulgarian",
								  @"fr_CA":@"Canadian French",
								  @"ca":@"Catalan",
								  @"hr":@"Croatian",
								  @"cs":@"Czech",
								  @"da":@"Danish",
								  @"nl":@"Dutch",
								  @"en":@"English",
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
								  @"mk":@"Macedonian",
								  @"ms":@"Malay",
								  @"es_MX":@"Mexican Spanish",
								  @"no":@"Norwegian",
								  @"pl":@"Polish",
								  @"pt":@"Portuguese",
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
								  @"zh_TW":@"Traditional Chinese",
								  @"tr":@"Turkish",
								  @"uk":@"Ukrainian",
								  @"vi":@"Vietnamese",
								  @"cy":@"Welsh"};
	}
    
    return self;
}

#pragma mark -

- (NSString *)englishFromISO:(NSString *)inISOName
{
    if (_ISOToEnglishDictionary==nil)
		return inISOName;

	NSString * tEnglishName=_ISOToEnglishDictionary[inISOName];
	
	if (tEnglishName==nil)
		tEnglishName=inISOName;
	
    return tEnglishName;
}

- (NSString *)ISOFromEnglish:(NSString *)inEnglishName
{
	if (_englishToISODictionary==nil)
		return inEnglishName;
    
     NSString * tISOName=_englishToISODictionary[inEnglishName];
	
	if (tISOName==nil)
		tISOName=inEnglishName;
	
    return tISOName;
}

- (NSString *)nativeForEnglish:(NSString *)inEnglishName
{
	NSString * tNative=_conversionDictionary[inEnglishName];

	if (tNative==nil)
		tNative=inEnglishName;

	return tNative;
}

@end
