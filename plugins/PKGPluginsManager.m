/*
Copyright (c) 2008-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPluginsManager.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGPluginNameKey=@"NAME";

//NSString * const PKGPluginVersionKey=@"VERSION";

NSString * const PKGPluginsParentFolderPath=@"/Library/PrivilegedHelperTools/fr.whitebox.packages";

@interface PKGConverter ()

	@property (weak,readwrite)PKGDistributionProject * project;

@end

@interface PKGPlugin ()

	@property (copy,readwrite) NSString * displayName;

	@property (readwrite) NSBundle * UIBundle;

	@property (readwrite) NSBundle * converterBundle;

@end

@implementation PKGPlugin

- (NSUInteger)hash
{
	return [self.displayName hash];
}

@end


@interface PKGPluginsManager ()
{
	NSMutableDictionary * _dictionary;
	
	NSMutableDictionary * _reverseDictionary;
}

- (NSMutableDictionary *)dictionary;
- (NSMutableDictionary *)reverseDictionary;

- (void)_lazyInit;

@end

@implementation PKGPluginsManager

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
		// Find the Requirements plugin folder
	
		NSString * tFolderName=[self folderName];
	
		if (tFolderName==nil)
		{
			NSLog(@"[PKGPluginsManager init] Missing folder name");
			return nil;
		}
	}
	
	return self;
}

#pragma mark -

- (void)_lazyInit
{
	NSString * tFolderPath=[PKGPluginsParentFolderPath stringByAppendingPathComponent:[self folderName]];
	NSArray * tPluginsList=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:tFolderPath error:NULL];
	
	// Only keeps the .plugin bundles
	
	NSArray * tBundlesArray=[tPluginsList WB_arrayByMappingObjectsLenientlyUsingBlock:^NSBundle *(NSString *bPathComponent,NSUInteger bIndex){
		
		if ([[bPathComponent pathExtension] isEqualToString:@"plugin"]==YES)
			return [NSBundle bundleWithPath:[tFolderPath stringByAppendingPathComponent:bPathComponent]];
		
		return nil;
	}];
	
	_reverseDictionary=[NSMutableDictionary  dictionary];
	_dictionary=[NSMutableDictionary dictionary];
	
	
	[tBundlesArray enumerateObjectsUsingBlock:^(NSBundle * bBundle,NSUInteger bIndex,BOOL * bOutStop){
		
		NSDictionary * tInfoDictionary=[bBundle infoDictionary];
		
		if (tInfoDictionary==nil)
			return;
		
		NSString * tBundleIdentifier=tInfoDictionary[@"CFBundleIdentifier"];
		
		if (tBundleIdentifier==nil)
		{
			NSLog(@"[PKGPluginsManager init] Missing CFBundleIdentifier in \'%@\'",bBundle.bundlePath);
			return;
		}
		
		NSString * tUIPluginPath=[bBundle pathForAuxiliaryExecutable:@"ui.bundle"];
		NSString * tConverterPluginPath=[bBundle pathForAuxiliaryExecutable:@"converter.bundle"];
		
		if (tUIPluginPath==nil || tConverterPluginPath==nil)
		{
			if (tUIPluginPath==nil)
				NSLog(@"[PKGPluginsManager init] Missing UI plugin (%@)",bBundle.bundlePath);
			
			if (tConverterPluginPath==nil)
				NSLog(@"[PKGPluginsManager init] Missing Converter plugin (%@)",bBundle.bundlePath);
			
			return;
		}
		
		PKGPlugin * tPlugin=[[PKGPlugin alloc] init];
		
		if (tPlugin==nil)
		{
			NSLog(@"[PKGPluginsManager init] Low Memory");
			return;
		}
		
		tPlugin.UIBundle=[NSBundle bundleWithPath:tUIPluginPath];
		
		if (tPlugin.UIBundle==nil)
		{
			NSLog(@"[PKGPluginsManager init] Error when creating bundle at \'%@\'",tUIPluginPath);
			return;
		}
		
		tPlugin.displayName=[tPlugin.UIBundle objectForInfoDictionaryKey:PKGPluginNameKey];
		
		if (tPlugin.displayName!=nil)
			_reverseDictionary[tPlugin.displayName]=tBundleIdentifier;
		
		tPlugin.converterBundle=[NSBundle bundleWithPath:tConverterPluginPath];
		
		if (tPlugin.converterBundle==nil)
		{
			NSLog(@"[PKGPluginsManager init] Error when creating bundle at \'%@\'",tConverterPluginPath);
			return;
		}
		
		_dictionary[tBundleIdentifier]=tPlugin;
	}];
}

#pragma mark -

- (NSMutableDictionary *)dictionary
{
	if (_dictionary==nil)
		[self _lazyInit];
	
	return _dictionary;
}

- (NSMutableDictionary *)reverseDictionary
{
	if (_reverseDictionary==nil)
		[self _lazyInit];
	
	return _reverseDictionary;
}

#pragma mark -

- (NSString *)folderName
{
	return nil;
}

- (NSArray *)allPluginsIdentifier
{
	return [[self dictionary] allKeys];
}

- (NSArray *)allPluginsNameSorted
{
	return [[[self reverseDictionary] allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *bString1,NSString *bString2){
	
		return [bString1 caseInsensitiveCompare:bString2];
	}];
}

- (NSString *)localizedPluginNameForIdentifier:(NSString *) inIdentifier
{
	if (inIdentifier!=nil)
		return ((PKGPlugin *)[self dictionary][inIdentifier]).displayName;
	
	return nil;
}

- (NSString *)identifierForLocalizedPluginName:(NSString *) inLocalizedName
{
	if (inLocalizedName!=nil)
		return [self reverseDictionary][inLocalizedName];

	return nil;
}

- (PKGPlugin *)pluginForIdentifier:(NSString *)inIdentifier
{
	if (inIdentifier==nil)
		return nil;
	
	return [self dictionary][inIdentifier];
}

#pragma mark -

- (PKGConverter *)createConverterForIdentifier:(NSString *) inIdentifier
{
	return [self createConverterForIdentifier:inIdentifier project:nil];
}

- (PKGConverter *)createConverterForIdentifier:(NSString *) inIdentifier project:(PKGDistributionProject *) inProject
{
	PKGPlugin * tPlugin=[self pluginForIdentifier:inIdentifier];
	
	if (tPlugin==nil)
	{
		NSLog(@"[ICPluginsManager createPluginConverterForIdentifier:] No plugin found for identifier %@",inIdentifier);
		return nil;
	}
	
	NSBundle * tBundle=tPlugin.converterBundle;
		
	if (tBundle!=nil)
	{
		Class tPrincipalClass=[tBundle principalClass];
		
		if (tPrincipalClass==nil)
		{
			NSLog(@"[ICPluginsManager createPluginConverterForIdentifier:] Principal Class not found");
			return nil;
		}
		
		PKGConverter * tConverter=[[tPrincipalClass alloc] initWithProject:inProject];
			
		return tConverter;
	}
	
	return nil;
}

@end
