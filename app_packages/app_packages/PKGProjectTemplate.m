/*
 Copyright (c) 2016-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGProjectTemplate.h"

#import "NSImage+Tint.h"

#import "NSArray+WBExtensions.h"

#import "NSFileManager+SortedContents.h"

NSString * const PKGProjectTemplateNameKey=@"PKGProjectTemplateName";

NSString * const PKGProjectTemplateDescriptionKey=@"PKGProjectTemplateDescription";

NSString * const PKGProjectTemplateEnabledKey=@"PKGProjectTemplateEnabled";

NSString * const PKGProjectTemplateAssistantPluginBundleName=@"Assistant.plugin";

NSString * const PKGProjectOldTemplateKeyPrefix=@"ICPROJECT_TEMPLATE";

NSString * const PKGProjectOldTemplateNameKey=@"ICPROJECT_TEMPLATE_NAME";

NSString * const PKGProjectOldTemplateDescriptionKey=@"ICPROJECT_TEMPLATE_DESCRIPTION";

NSString * const PKGProjectOldTemplateEnabledKey=@"ICPROJECT_TEMPLATE_SUPPORTED";


@interface PKGProjectTemplate ()

	@property NSBundle * bundle;

	@property (readwrite,copy) NSString * templateFilePath;

	@property (readwrite) BOOL enabled;

	@property (readwrite) NSImage * icon;

	@property (readwrite,copy) NSString * name;

	@property (readwrite,copy) NSString * localizedDescription;

	@property (readwrite) PKGAssistantPlugin * assistantPlugin;


- (instancetype)initWithTemplateBundle:(NSBundle *)inBundle;

- (instancetype)initWithOldTemplateBundle:(NSBundle *)inBundle;

@end

@implementation PKGProjectTemplate

+ (NSArray *)allTemplates
{
	NSMutableArray * tMutableProjectTemplatesArray=[NSMutableArray array];
	
	NSArray * tApplicationSupportDirectories=NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask+NSLocalDomainMask, YES);
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	for(NSString * tDirectory in tApplicationSupportDirectories)
	{
		NSString * tPackagesTemplateDirectoryPath=[tDirectory stringByAppendingPathComponent:@"fr.whitebox.packages/Projects Templates"];
		NSArray * tArray=[tFileManager WB_sortedContentsOfDirectoryAtPath:tPackagesTemplateDirectoryPath error:NULL];
		
		NSArray * tTemplatesArray=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^PKGProjectTemplate *(NSString * bLastPathComponent,NSUInteger bIndex){
		
			if ([[bLastPathComponent pathExtension] isEqualToString:@"template"]==NO)
				return nil;
			
			return [[PKGProjectTemplate alloc] initWithTemplateBundle:[NSBundle bundleWithPath:[tPackagesTemplateDirectoryPath stringByAppendingPathComponent:bLastPathComponent]]];
		
		}];
		
		[tMutableProjectTemplatesArray addObjectsFromArray:tTemplatesArray];
	}
	
	return [tMutableProjectTemplatesArray copy];
}

#pragma mark -

- (instancetype)initWithTemplateBundle:(NSBundle *)inBundle
{
	if (inBundle==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		NSDictionary * tLocalizedInfoDictionary=[inBundle localizedInfoDictionary];
		
		for(NSString * tKey in [tLocalizedInfoDictionary allKeys])
		{
			if ([tKey hasPrefix:PKGProjectOldTemplateKeyPrefix]==YES)
				return [self initWithOldTemplateBundle:inBundle];
		}
		
		_bundle=inBundle;
				
		// Template File
		
		_templateFilePath=[_bundle pathForResource:@"Template" ofType:@"pkgproj"];
		
		// Enabled
		
		_enabled=YES;
		
		NSNumber * tNumber=tLocalizedInfoDictionary[PKGProjectTemplateEnabledKey];
		
		if (tNumber!=nil)
			_enabled=tNumber.boolValue;
		
		// Icon
		
		NSImage * tIcon=[_bundle imageForResource:@"Icon"];
		
		if (tIcon!=nil)
			_icon=(_enabled==YES) ? tIcon : [tIcon WB_tintWithColor:[NSColor lightGrayColor]];
		
		// Name
		
		_name=tLocalizedInfoDictionary[PKGProjectTemplateNameKey];
		
		if (_name==nil)
			_name=[_bundle.bundlePath.lastPathComponent stringByDeletingPathExtension];
		
		// Description
		
		_localizedDescription=tLocalizedInfoDictionary[PKGProjectTemplateDescriptionKey];
	}
	
	return self;
}

- (instancetype)initWithOldTemplateBundle:(NSBundle *)inBundle
{
	if (inBundle==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_bundle=inBundle;
		
		// Template File
		
		_templateFilePath=[_bundle pathForResource:@"Template" ofType:@"pkgproj"];
		
		// Enabled
		
		_enabled=YES;
		
		NSNumber * tNumber=[_bundle objectForInfoDictionaryKey:PKGProjectOldTemplateEnabledKey];
		
		if (tNumber!=nil)
			_enabled=tNumber.boolValue;
		
		// Icon
		
		NSImage * tIcon=[_bundle imageForResource:@"Icon"];
		
		if (tIcon!=nil)
			_icon=(_enabled==YES) ? tIcon : [tIcon WB_tintWithColor:[NSColor lightGrayColor]];
		
		// Name
		
		_name=[_bundle objectForInfoDictionaryKey:PKGProjectOldTemplateNameKey];
		
		if (_name==nil)
			_name=[_bundle.bundlePath.lastPathComponent stringByDeletingPathExtension];
		
		// Description
		
		_localizedDescription=[_bundle objectForInfoDictionaryKey:PKGProjectOldTemplateDescriptionKey];
	}
	
	return self;
}

- (PKGAssistantPlugin *)assistantPlugin
{
	if (_assistantPlugin!=nil)
		return _assistantPlugin;
	
	NSString * tPluginsPath=[self.bundle builtInPlugInsPath];
	
	NSBundle * tBundle=[NSBundle bundleWithPath:[tPluginsPath stringByAppendingPathComponent:PKGProjectTemplateAssistantPluginBundleName]];
	
	if (tBundle==nil)
		return nil;
	
	Class tPrincipalClass=tBundle.principalClass;
	
	if (tPrincipalClass==nil)
		return nil;
	
	return [tPrincipalClass alloc];
}

@end
