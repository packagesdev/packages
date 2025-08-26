/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "_PKGFileItemAuxiliary.h"

#include <sys/stat.h>

#import "PKGFileFilter.h"

@interface _PKGFileItemAuxiliary ()

	@property (readwrite) double refreshTimeMark;

	@property (readwrite,copy) NSString * referencedItemPath;

	@property (readwrite) NSImage * icon;

	@property (readwrite,getter=isExcluded) BOOL excluded;

	@property (readwrite,getter=isSymbolicLink) BOOL symbolicLink;

	@property (readwrite,getter=isReferencedItemMissing) BOOL referencedItemMissing;

	@property (readwrite) unsigned char fileType;

+ (NSImage *)cachedUnknownFSObjectIcon;

+ (NSImage *)cachedGenericFolderIcon;

+ (NSImage *)cachedIconForFileType:(NSString *)inType directory:(BOOL)inDirectory;

@end

@implementation _PKGFileItemAuxiliary

+ (NSImage *)cachedIconForTemplateFolderAtPath:(NSString *)inPath
{
	static dispatch_once_t onceToken;
	static NSMutableDictionary * sIconTemplatesRepository=nil;
	
	dispatch_once(&onceToken, ^{
	
		NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
		
		sIconTemplatesRepository=[NSMutableDictionary dictionary];
		
		// Hard Drive
		
		NSImage * tIcon=[tSharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(kGenericHardDiskIcon)];
		
		sIconTemplatesRepository[@"/"]=tIcon;
		
		// Applications
		
		tIcon=[tSharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(kApplicationsFolderIcon)];
		
		sIconTemplatesRepository[@"/Applications"]=tIcon;
		
		// Library
		
		tIcon=[tSharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(kSharedLibrariesFolderIcon)];
		
		sIconTemplatesRepository[@"/Library"]=tIcon;
		sIconTemplatesRepository[@"/System/Library"]=tIcon;
		
		// System
		
		tIcon=[tSharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(kSystemFolderIcon)];
		
		sIconTemplatesRepository[@"/System"]=tIcon;
		
		// Users
		
		tIcon=[tSharedWorkspace iconForFile:@"/Users"];
		
		sIconTemplatesRepository[@"/Users"]=tIcon;
		
	});
	
	return sIconTemplatesRepository[inPath];
}

+ (NSImage *)cachedUnknownFSObjectIcon
{
	static dispatch_once_t onceToken;
	static NSImage * sCachedUnknownFSObjectIcon=nil;
	
	dispatch_once(&onceToken, ^{
		
		sCachedUnknownFSObjectIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kUnknownFSObjectIcon)];
	});
	
	return sCachedUnknownFSObjectIcon;
}

+ (NSImage *)cachedGenericFolderIcon
{
	static dispatch_once_t onceToken;
	static NSImage * sCachedGenericFolderIcon=nil;
	
	dispatch_once(&onceToken, ^{
		
		sCachedGenericFolderIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
	});
	
	return sCachedGenericFolderIcon;
}

+ (NSImage *)cachedIconForFileType:(NSString *)inType directory:(BOOL)inDirectory
{
	if (inType==nil)
		return nil;
	
	static dispatch_once_t onceToken;
	static NSMutableDictionary * sIconTypesRespository=nil;
	
	dispatch_once(&onceToken, ^{
	
		NSArray * tWellKnownTypes=@[@"nib",@"png",@"tiff",@"tif",@"icns",@"rtd",@"plugin",@"rtfd",@"strings",@"plist",@"txt",@"strings"];
		NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
		
		sIconTypesRespository=[NSMutableDictionary dictionary];
		
		for(NSString * tType in tWellKnownTypes)
		{
			NSImage * tIcon=[tSharedWorkspace iconForFileType:tType];
			
			if (tIcon!=nil)
				sIconTypesRespository[tType]=tIcon;
		}
		
		// Application
		
		NSImage * tIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
		
		if (tIcon!=nil)
			sIconTypesRespository[@"app"]=tIcon;
		
		// Framework & lproj folders
		
		tIcon=[_PKGFileItemAuxiliary cachedGenericFolderIcon];
		
		if (tIcon!=nil)
		{
			sIconTypesRespository[@"lproj"]=tIcon;
			sIconTypesRespository[@"framework"]=tIcon;
		}
	});
	
	NSImage * tIcon=sIconTypesRespository[inType];
	
	if (tIcon!=nil)
		return tIcon;
	
	if (inDirectory==YES)
		return nil;
	
	tIcon=[[NSWorkspace sharedWorkspace] iconForFileType:inType];
	
	if (tIcon!=nil)
		sIconTypesRespository[inType]=tIcon;
	
	return tIcon;
}

+ (_PKGFileItemAuxiliary *)itemMissingAuxiliary;
{
	_PKGFileItemAuxiliary * nFileItemAuxiliary=[_PKGFileItemAuxiliary new];
	
	nFileItemAuxiliary.refreshTimeMark=[NSDate timeIntervalSinceReferenceDate];
	
	nFileItemAuxiliary.fileType='f';
	nFileItemAuxiliary.symbolicLink=NO;
	nFileItemAuxiliary.referencedItemMissing=YES;
	nFileItemAuxiliary.excluded=NO;
	nFileItemAuxiliary.icon=[_PKGFileItemAuxiliary cachedUnknownFSObjectIcon];
	
	return nFileItemAuxiliary;
}

#pragma mark -

- (id)copyWithZone:(NSZone *)inZone
{
	_PKGFileItemAuxiliary * nFileItemAuxiliary=[[[self class] allocWithZone:inZone] init];
	
	if (nFileItemAuxiliary!=nil)
	{
		nFileItemAuxiliary.refreshTimeMark=self.refreshTimeMark;
		nFileItemAuxiliary.referencedItemPath=[self.referencedItemPath copy];
		nFileItemAuxiliary.icon=[self.icon copy];
		nFileItemAuxiliary.excluded=self.isExcluded;
		nFileItemAuxiliary.symbolicLink=self.isSymbolicLink;
		nFileItemAuxiliary.referencedItemMissing=self.isReferencedItemMissing;
		nFileItemAuxiliary.fileType=self.fileType;
	}
	
	return nFileItemAuxiliary;
}

#pragma mark -

- (void)updateWithReferencedItemPath:(NSString *)inPath type:(PKGFileItemType)inType fileFilters:(NSArray *)inFileFilters
{
	[self updateWithReferencedItemPath:inPath type:inType fileFilters:inFileFilters obsolete:NO];
}

- (void)updateWithReferencedItemPath:(NSString *)inPath type:(PKGFileItemType)inType fileFilters:(NSArray *)inFileFilters obsolete:(BOOL)inObsolete
{
	self.referencedItemPath=inPath;
	
	if (inPath==nil)
		return;
	
	self.fileType='d';
	self.symbolicLink=NO;
	self.referencedItemMissing=NO;
	self.excluded=NO;
	
	self.refreshTimeMark=(inObsolete==NO) ? [NSDate timeIntervalSinceReferenceDate] : 0.0;
	
	// File Mode
	
	struct stat tStat;
	
	if (inType>=PKGFileItemTypeNewFolder && inType!=PKGFileItemTypeNewElasticFolder)
	{
		if (lstat([inPath fileSystemRepresentation], &tStat)!=0)
		{
			self.symbolicLink=NO;
			
			if (errno==ENOENT ||
				errno==ENOTDIR)
			{
				self.referencedItemMissing=YES;
			}
			else
			{
				NSLog(@"Error (errno: %d) when retrieving file stats for %@",errno,inPath);
			}
		}
		else
		{
			switch((tStat.st_mode & S_IFMT))
			{
				case S_IFDIR:
					break;
				case S_IFREG:
					self.fileType='-';
					break;
				case S_IFLNK:
					self.fileType='l';
					self.symbolicLink=YES;
					break;
				case S_IFBLK:
					self.fileType='b';
					break;
				case S_IFCHR:
					self.fileType='c';
					break;
				case S_IFSOCK:
					self.fileType='s';
					break;
				default:
					self.fileType='-';
					break;
			}
		}
	}
	
	if (inObsolete==YES)
		return;
	
	// Excluded
	
	NSString * tFileName=inPath.lastPathComponent;
	PKGFileSystemType tFileSystemType=(self.fileType=='d') ? PKGFileSystemTypeFolder : PKGFileSystemTypeFile;
	
	for(PKGFileFilter * tFileFilter in inFileFilters)
	{
		if ([tFileFilter matchesFileNamed:tFileName ofType:tFileSystemType]==YES)
		{
			self.excluded=YES;
			break;
		}
	}
	
	// Template
	
	if (inType<PKGFileItemTypeNewFolder)
		return;
	
	// New Folder
	
	if (inType==PKGFileItemTypeNewFolder ||
        inType==PKGFileItemTypeNewElasticFolder)
	{
		self.icon=[_PKGFileItemAuxiliary cachedGenericFolderIcon];
		
		return;
	}
    
	// Icon

	if (self.referencedItemMissing==YES)
	{
		self.icon=[_PKGFileItemAuxiliary cachedUnknownFSObjectIcon];
		return;
	}
	
	NSImage * tIcon=nil;
	
	NSString * tPathExtension=inPath.pathExtension;
	
	if (tPathExtension.length>0)
		tIcon=[_PKGFileItemAuxiliary cachedIconForFileType:tPathExtension directory:((tStat.st_mode & S_IFMT)==S_IFDIR)];
	
	if (tIcon==nil)
	{
		if ((tStat.st_mode & S_IFMT)==S_IFDIR)
			tIcon=[_PKGFileItemAuxiliary cachedGenericFolderIcon];
		else
			tIcon=[[NSWorkspace sharedWorkspace] iconForFile:inPath];
	}
	
	self.icon=tIcon;
}

@end
