/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildInformation.h"

NSString * const PKGBuildDefaultLanguageKey=@"PKGBuildDefaultLanguageKey";

@interface PKGBuildJavaScriptInformation ()
{
	NSMutableSet * _constantsNamesSet;
	
	NSMutableArray * _constants;
	
	NSMutableSet * _functionsNamesSet;
	
	NSMutableArray * _functions;
}

@end

@implementation PKGBuildJavaScriptInformation

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_constantsNamesSet=[NSMutableSet set];
		_constants=[NSMutableArray array];
		
		_functionsNamesSet=[NSMutableSet set];
		_functions=[NSMutableArray array];
	}
	
	return self;
}

#pragma mark -

- (NSArray *)constants
{
	return [_constants copy];
}

- (NSSet *)unknownConstantsNameInSet:(NSSet *)inConstantsNames
{
	NSMutableSet * tUnknownSet=[inConstantsNames mutableCopy];
	
	[tUnknownSet minusSet:_constantsNamesSet];
	
	return [tUnknownSet copy];
}

- (void)addConstantsNamed:(NSSet *)inConstantsNames declaration:(NSString *)inDeclaration
{
	if (inConstantsNames==nil || inDeclaration==nil)
		return;
	
	[_constantsNamesSet unionSet:inConstantsNames];
	
	[_constants addObject:inDeclaration];
}


#pragma mark -

- (NSArray *)functions
{
	return [_functions copy];
}

- (BOOL)containsFunctionNamed:(NSString *)inFunctionName
{
	return [_functionsNamesSet containsObject:inFunctionName];
}

- (void)addFunctionName:(NSString *)inFunctionName implementation:(NSString *)inImplementation
{
	if (inFunctionName==nil || inImplementation==nil)
		return;
	
	[_functionsNamesSet addObject:inFunctionName];
	
	[_functions addObject:inImplementation];
}

@end


@implementation PKGBuildBundleScripts

- (NSUInteger)hash
{
	if (self.preInstallScriptPath!=nil)
		return [self.preInstallScriptPath hash];
	
	if (self.postInstallScriptPath!=nil)
		return [self.postInstallScriptPath hash];
	
	return 0;
}

#pragma mark -

- (BOOL)hasScripts
{
	return (self.preInstallScriptPath!=nil || self.postInstallScriptPath!=nil);
}

@end


@interface PKGBuildPackageAttributes ()

	@property (readwrite) NSMutableArray * downgradableBundles;

	@property (readwrite) NSMutableArray * bundlesVersions;

	@property (readwrite) NSMutableDictionary * bundlesScripts;

	@property (readwrite) NSMutableDictionary * bundlesScriptsTransformedNames;


	@property (readwrite) NSMutableDictionary * bundlesLocators;

@end

@implementation PKGBuildPackageAttributes

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_archiveSize=-1;
		
		_payloadSize=-1;
		
		_downgradableBundles=[NSMutableArray array];
		
		_bundlesVersions=[NSMutableArray array];
		
		_bundlesScripts=[NSMutableDictionary dictionary];
		
		_bundlesScriptsTransformedNames=[NSMutableDictionary dictionary];
		
		
		_bundlesLocators=[NSMutableDictionary dictionary];
	}
	
	return self;
}

#pragma mark -

- (NSUInteger)hash
{
	return [self.identifier hash];
}

@end




@interface PKGBuildInformation ()

	@property (nonatomic,copy,readwrite) NSString * resourcesPath;

	@property (readwrite) NSMutableDictionary * languagesPath;

	@property (readwrite) NSMutableDictionary * requirementsOptions;

	@property (readwrite) NSMutableDictionary * packagesAttributes;

	@property (readwrite) NSMutableDictionary * choicesNames;


	@property (readwrite) PKGBuildJavaScriptInformation * javaScriptInformation;


	@property (readwrite) NSMutableDictionary * localizations;

	@property (readwrite) NSMutableArray * resourcesExtras;

@end

@implementation PKGBuildInformation

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_languagesPath=[NSMutableDictionary dictionary];
		

		
		_requirementsOptions=[NSMutableDictionary dictionary];
		
		_packagesAttributes=[NSMutableDictionary dictionary];
		
		_choicesNames=[NSMutableDictionary dictionary];
		
		
		_javaScriptInformation=[PKGBuildJavaScriptInformation new];
		
		
		_localizations=[NSMutableDictionary dictionary];
		
		_localizations[PKGBuildDefaultLanguageKey]=[NSMutableDictionary dictionary];
		
		
		_resourcesExtras=[NSMutableArray array];
	}
	
	return self;
}

#pragma mark -

- (NSString *)resourcesPath
{
	NSString * tResourcesPath=[self.contentsPath stringByAppendingPathComponent:@"Resources"];
	
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	if ([tFileManager fileExistsAtPath:tResourcesPath]==NO)
	{
		BOOL tResult=[tFileManager createDirectoryAtPath:tResourcesPath
							 withIntermediateDirectories:NO
											  attributes:@{NSFilePosixPermissions:@(S_IRWXU+S_IRGRP+S_IXGRP+S_IROTH+S_IXOTH)}
												   error:NULL];
		
		if (tResult==NO)
		{
			// A COMPLETER
			
			return nil;
		}
	}
	
	return tResourcesPath;
}

@end
