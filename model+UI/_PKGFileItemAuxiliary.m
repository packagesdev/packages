
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

	@property (readwrite) char fileMode;

+ (NSImage *)cachedUnknownFSObjectIcon;

+ (NSImage *)cachedGenericFolderIcon;

+ (NSImage *)cachedIconForFileType:(NSString *)inType;

@end

@implementation _PKGFileItemAuxiliary

+ (NSImage *)cachedIconForTemplateFolderAtPath:(NSString *)inPath enabled:(BOOL)inEnabled
{
	static dispatch_once_t onceToken;
	static NSMutableDictionary * sIconTemplatesRespository=nil;
	
	dispatch_once(&onceToken, ^{
	
		NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
		
		sIconTemplatesRespository=[NSMutableDictionary dictionary];
		
		// Hard Drive
		
		NSImage * tIcon=[tSharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(kGenericHardDiskIcon)];
		
		sIconTemplatesRespository[@"/"]=tIcon;
		
		sIconTemplatesRespository[@"/:Disabled"]=tIcon;
		
		// Applications
		
		tIcon=[tSharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(kApplicationsFolderIcon)];
		
		sIconTemplatesRespository[@"/Applications"]=tIcon;
		
		sIconTemplatesRespository[@"/Applications:Disabled"]=tIcon;
		
		// Library
		
		tIcon=[tSharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(kSharedLibrariesFolderIcon)];
		
		sIconTemplatesRespository[@"/Library"]=tIcon;
		
		sIconTemplatesRespository[@"/Library:Disabled"]=tIcon;
		
		// System
		
		tIcon=[tSharedWorkspace iconForFileType:NSFileTypeForHFSTypeCode(kSystemFolderIcon)];
		
		sIconTemplatesRespository[@"/System"]=tIcon;
		
		sIconTemplatesRespository[@"/System:Disabled"]=tIcon;
		
		// Users
		
		tIcon=[tSharedWorkspace iconForFile:@"/Users"];
		
		sIconTemplatesRespository[@"/Users"]=tIcon;
		
		sIconTemplatesRespository[@"/Users:Disabled"]=tIcon;
	});
	
	if (inEnabled==YES)
		return sIconTemplatesRespository[inPath];
	
	return sIconTemplatesRespository[[inPath stringByAppendingString:@":Disabled"]];
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

+ (NSImage *)cachedGenericFolderIconDisabled
{
	static dispatch_once_t onceToken;
	static NSImage * sCachedGenericFolderIconDisabled=nil;
	
	dispatch_once(&onceToken, ^{
		
		sCachedGenericFolderIconDisabled=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		
		// A COMPLETER
	});
	
	return sCachedGenericFolderIconDisabled;
}

+ (NSImage *)cachedIconForFileType:(NSString *)inType
{
	if (inType==nil)
		return nil;
	
	static dispatch_once_t onceToken;
	static NSMutableDictionary * sIconTypesRespository=nil;
	
	dispatch_once(&onceToken, ^{
	
		NSArray * tWellKnownTypes=@[@"nib",@"png",@"tiff",@"tif",@"icns",@"rtd",@"rtfd",@"strings",@"plist",@"txt",@"strings"];
		NSWorkspace * tSharedWorkspace=[NSWorkspace sharedWorkspace];
		
		sIconTypesRespository=[NSMutableDictionary dictionary];
		
		for(NSString * tType in tWellKnownTypes)
		{
			NSImage * tIcon=[tSharedWorkspace iconForFileType:tType];
			
			if (tIcon!=nil)
				sIconTypesRespository[tType]=tIcon;
		}
	});
	
	NSImage * tIcon=sIconTypesRespository[inType];
	
	if (tIcon!=nil)
		return tIcon;
	
	tIcon=[[NSWorkspace sharedWorkspace] iconForFileType:inType];
	
	if (tIcon!=nil)
		sIconTypesRespository[inType]=tIcon;
	
	return tIcon;
}

#pragma mark -

- (void)updateWithReferencedItemPath:(NSString *)inPath type:(PKGFileItemType)inType fileFilters:(NSArray *)inFileFilters
{
	self.referencedItemPath=inPath;
	
	if (inPath==nil)
		return;
	
	self.fileMode='d';
	self.symbolicLink=NO;
	self.referencedItemMissing=NO;
	
	self.refreshTimeMark=[NSDate timeIntervalSinceReferenceDate];
	
	// File Mode
	
	self.fileMode='d';
	
	struct stat tStat;
	
	if (inType>=PKGFileItemTypeNewFolder)
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
					self.fileMode='-';
					break;
				case S_IFLNK:
					self.fileMode='l';
					self.symbolicLink=YES;
					break;
				case S_IFBLK:
					self.fileMode='b';
					break;
				case S_IFCHR:
					self.fileMode='c';
					break;
				case S_IFSOCK:
					self.fileMode='s';
					break;
				default:
					self.fileMode='-';
					break;
			}
		}
	}
	
	// Excluded
	
	NSString * tFileName=[inPath lastPathComponent];
	PKGFileSystemType tFileSystemType=(self.fileMode=='d') ? PKGFileSystemTypeFolder : PKGFileSystemTypeFile;
	
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
	
	if (inType==PKGFileItemTypeNewFolder)
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
	
	NSString * tPathExtension=[inPath pathExtension];
	
	if ([tPathExtension length]>0)
	{
		tIcon=[_PKGFileItemAuxiliary cachedIconForFileType:tPathExtension];
	}
	else
	{
		if ((tStat.st_mode & S_IFMT)==S_IFDIR)
		{
			tIcon=[_PKGFileItemAuxiliary cachedGenericFolderIcon];
		}
		else
		{
			tIcon=[[NSWorkspace sharedWorkspace] iconForFile:inPath];
			
			// A COMPLETER
		}
	}
	
	if (self.symbolicLink==YES)
	{
		// A COMPLETER
	}
	
	self.icon=tIcon;
}

@end
