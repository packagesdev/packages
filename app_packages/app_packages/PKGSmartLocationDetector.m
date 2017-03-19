/*
 Copyright (c) 2008-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGSmartLocationDetector.h"

@implementation PKGSmartLocationDetector

+ (NSArray *)potentialInstallationDirectoriesForFileAtPath:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	NSError * tError;
	NSDictionary * tAttributes=[[NSFileManager defaultManager] attributesOfItemAtPath:inPath error:&tError];
	
	if (tAttributes==nil)
	{
		if (tError!=nil)
			NSLog(@"Unable to get the attributes of \"%@\" : %@ ",inPath,tError.description);
		
		return nil;
	}
	
	NSString * tParentFolder=[inPath stringByDeletingLastPathComponent];
	
	// Symbolic Link
	
	if ([tAttributes[NSFileType] isEqualToString:NSFileTypeSymbolicLink]==YES)
		return @[tParentFolder,@"/"];
	
	// Not a Folder, a Regular File or a Symbolic Link
	
	if ([tAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]==NO  && [tAttributes[NSFileType] isEqualToString:NSFileTypeRegular]==NO)
		return nil;
	
	NSMutableArray * tPotentialLocations=[NSMutableArray arrayWithObject:tParentFolder];
	NSString * tExtension=[inPath pathExtension];
	
	if (tExtension.length>0)
	{
		if ([tExtension caseInsensitiveCompare:@"pkg"]==NSOrderedSame ||
			[tExtension caseInsensitiveCompare:@"mpkg"]==NSOrderedSame)
			return nil;
		
		if ([tExtension caseInsensitiveCompare:@"plugin"]==NSOrderedSame)
		{
			// Check whether it's an Internet Plugin
			
			NSDictionary * tInfoDictionary=[[NSBundle bundleWithPath:inPath] infoDictionary];
			
			if (tInfoDictionary[@"WebPluginMIMETypes"]!=nil ||
				tInfoDictionary[@"WebPluginName"]!=nil)
			{
				// It is an Interner Plugin
				
				[tPotentialLocations addObject:@"/Library/Internet Plug-Ins/"];
			}
		}
		else if ([tExtension caseInsensitiveCompare:@"bundle"]==NSOrderedSame)
		{
			// Check whether it's an Internet Plugin
			
			NSDictionary * tInfoDictionary=[[NSBundle bundleWithPath:inPath] infoDictionary];
			
			if (tInfoDictionary[@"WebPluginMIMETypes"]!=nil ||
				tInfoDictionary[@"WebPluginName"]!=nil)
			{
				// It is an Interner Plugin
				
				[tPotentialLocations addObject:@"/Library/Internet Plug-Ins/"];
			}
		}
		else if ([tExtension caseInsensitiveCompare:@"app"]==NSOrderedSame)
		{
			// An application
			
			if ([tParentFolder hasPrefix:@"/Applications/Utilities"]==YES)
				[tPotentialLocations addObject:@"/Applications/Utilities/"];
			else
				[tPotentialLocations addObject:@"/Applications/"];
		}
		else
		{
			static NSDictionary * sExtensionLocationsDictionary=nil;
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				
				NSString * tFilePath=[[NSBundle bundleForClass:[self class]] pathForResource:@"ExtensionLocations" ofType:@"plist"];
				
				if (tFilePath==nil)
				{
					NSLog(@"ExtensionLocations.plst file could not be found.");
					
					return;
				}
				
				sExtensionLocationsDictionary=[NSDictionary dictionaryWithContentsOfFile:tFilePath];
			});
			
			id tLocations=sExtensionLocationsDictionary[tExtension];
			
			if (tLocations!=nil)
			{
				if ([tLocations isKindOfClass:NSString.class]==YES)
					[tPotentialLocations addObject:tLocations];
				else if ([tLocations isKindOfClass:NSArray.class]==YES)
					[tPotentialLocations addObjectsFromArray:tLocations];
				else
					NSLog(@"Incorrect value type in ExtensionLocations.plist file");
			}
		}
	}
	
	[tPotentialLocations addObject:@"/"];
	
	return [tPotentialLocations copy];
}

+ (BOOL)canCreateDirectoryPath:(NSString *)inDirectoryPath
{
	return ([inDirectoryPath hasPrefix:@"/Applications"]==YES ||
			[inDirectoryPath hasPrefix:@"/Library"]==YES ||
			[inDirectoryPath hasPrefix:@"/usr/local"]==YES);
}

@end
