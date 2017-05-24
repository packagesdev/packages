/*
Copyright (c) 2004-2017, Stéphane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGLicenseProvider.h"
#import "NSString+Karelia.h"

#import "PKGPackages.h"

#import "PKGLicenseTemplate.h"

NSString * const ICLicenseTemplatesRelativeFolderPath=@"Application Support/fr.whitebox.packages/Licenses Templates";

@interface PKGLicenseProvider ()
{
	NSMutableDictionary * _licensesTemplates;
}

@end

@implementation PKGLicenseProvider

+ (PKGLicenseProvider *) defaultProvider
{
	static PKGLicenseProvider * sLicenseProvider=nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sLicenseProvider=[[PKGLicenseProvider alloc] init];
	});
	
	return sLicenseProvider;
}

- (id)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _licensesTemplates=[NSMutableDictionary dictionary];
		
		// Find the Template licenses folder
        
        NSFileManager * tFileManager=[NSFileManager defaultManager];
		
        NSArray * tLibraryArray=NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSLocalDomainMask,NO);
        
        for(NSString * tLibraryPath in tLibraryArray)
        {
            NSString * tFolderPath=[tLibraryPath stringByAppendingPathComponent:ICLicenseTemplatesRelativeFolderPath];
            NSArray * tComponents=[tFileManager contentsOfDirectoryAtPath:tFolderPath error:NULL];
			
			if (tComponents==nil)
				continue;
			
			for(NSString * tLicenseName in tComponents)
			{
				NSString * tLicenseTemplatePath=[tFolderPath stringByAppendingPathComponent:tLicenseName];
				BOOL isDirectory;
				
                if ([tFileManager fileExistsAtPath:tLicenseTemplatePath isDirectory:&isDirectory]==YES && isDirectory==NO)
					continue;
				
				PKGLicenseTemplate * tLicenseTemplate=[[PKGLicenseTemplate alloc] initWithContentsOfDirectory:tLicenseTemplatePath];
				
				if (tLicenseTemplate!=nil)
					_licensesTemplates[tLicenseName]=tLicenseTemplate;
            }
        }
    }
    
    return self;
}

#pragma mark -

- (NSArray *)allLicensesNames
{
    return [_licensesTemplates allKeys];
}

- (PKGLicenseTemplate *)licenseTemplateNamed:(NSString *) inName
{
	if (inName==nil)
		return nil;
	
	return _licensesTemplates[inName];
}

#pragma mark -

+ (void)replaceKeywords:(NSDictionary *)inDictionary inAttributedString:(NSMutableAttributedString *)inMutableAttributedString
{
	if (inDictionary==nil || inMutableAttributedString==nil)
		return;
	
    NSString * tString=inMutableAttributedString.string;
	NSRange tFoundRange={.location=0,.length=0};
	
    while (1)
    {
        tFoundRange = [tString rangeFromString:@"%%" toString:@"%%" options:0 range:NSMakeRange(NSMaxRange(tFoundRange),tString.length-NSMaxRange(tFoundRange))];
        
        if (tFoundRange.location==NSNotFound)
			return;
		
		NSString * tKey=[tString substringWithRange:NSMakeRange(tFoundRange.location+2,tFoundRange.length-4)];
		NSString * tValue=inDictionary[tKey];
		
		if (tValue!=nil)
		{
			[inMutableAttributedString replaceCharactersInRange:tFoundRange
													 withString:tValue];
		
			tString=inMutableAttributedString.string;
			
			tFoundRange.length=tValue.length;
		}
    }
}

+ (void)replaceKeywords:(NSDictionary *)inDictionary inString:(NSMutableString *)inMutableString
{
	if (inDictionary==nil || inMutableString==nil)
		return;
	
	NSRange tFoundRange={.location=0,.length=0};
	
    while (1)
    {
        tFoundRange = [inMutableString rangeFromString:@"%%" toString:@"%%" options:0 range:NSMakeRange(NSMaxRange(tFoundRange),inMutableString.length-NSMaxRange(tFoundRange))];
        
        if (tFoundRange.location==NSNotFound)
			return;
		
		NSString * tKey=[inMutableString substringWithRange:NSMakeRange(tFoundRange.location+2,tFoundRange.length-4)];
		NSString * tValue=inDictionary[tKey];
		
		if (tValue!=nil)
		{
			[inMutableString replaceCharactersInRange:tFoundRange
										   withString:tValue];
			
			tFoundRange.length=tValue.length;
		}
    }
}

@end
