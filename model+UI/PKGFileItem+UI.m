
#import "PKGFileItem+UI.h"

#import "_PKGFileItemAuxiliary.h"

#include <sys/stat.h>

@implementation PKGFileItem (UI)

- (NSTimeInterval)refreshTimeMark
{
	if (_fileItemAuxiliary==nil)
		return -1.0;
	
	if (self.type!=PKGFileItemTypeFileSystemItem)
		return DBL_MAX;
	
	return _fileItemAuxiliary.refreshTimeMark;
}

- (NSString *)fileName
{
	switch(self.type)
	{
		case PKGFileItemTypeInvisible:
		case PKGFileItemTypeFolderTemplate:
		case PKGFileItemTypeNewFolder:
			
			return self.filePath.string;
			
		case PKGFileItemTypeFileSystemItem:
			
			return [self.filePath.string lastPathComponent];
			
		default:
			
			return nil;
	}
	
	return nil;
}

- (BOOL)isExcluded
{
	if (_fileItemAuxiliary==nil)
		return NO;
	
	return _fileItemAuxiliary.isExcluded;
}

- (BOOL)isSymbolicLink
{
	if (self.type!=PKGFileItemTypeFileSystemItem)
		return NO;
	
	if (_fileItemAuxiliary==nil)
		return NO;
	
	return _fileItemAuxiliary.isSymbolicLink;
}

- (BOOL)isReferencedItemMissing
{
	if (self.type!=PKGFileItemTypeFileSystemItem)
		return NO;
	
	if (_fileItemAuxiliary==nil)
		return NO;
	
	return _fileItemAuxiliary.isReferencedItemMissing;
}

- (NSImage *)icon
{
	if (self.type<PKGFileItemTypeNewFolder)
	{
		NSImage * tIcon=[_PKGFileItemAuxiliary cachedIconForTemplateFolderAtPath:_fileItemAuxiliary.referencedItemPath enabled:YES];
		
		if (tIcon!=nil)
			return tIcon;
		
		return [_PKGFileItemAuxiliary cachedGenericFolderIcon];
	}
	
	if (_fileItemAuxiliary==nil)
		return nil;
	
	return _fileItemAuxiliary.icon;
}

- (NSImage *)disabledIcon
{
	if (self.type>=PKGFileItemTypeNewFolder)
		return nil;
	
	NSImage * tIcon=[_PKGFileItemAuxiliary cachedIconForTemplateFolderAtPath:_fileItemAuxiliary.referencedItemPath enabled:NO];
		
	if (tIcon!=nil)
		return tIcon;
	
	return [_PKGFileItemAuxiliary cachedGenericFolderIcon];
}

- (NSString *)referencedItemPath
{
	if (_fileItemAuxiliary==nil)
		return nil;
	
	return _fileItemAuxiliary.referencedItemPath;
}

- (NSString *)posixPermissionsRepresentation
{
	char tFileMode='d';
	
	if (_fileItemAuxiliary!=nil)
		tFileMode=_fileItemAuxiliary.fileMode;
	
	mode_t tPermissions=self.permissions;
	
	char tOwnerExecute;
	
	if ((tPermissions & S_ISUID)==S_ISUID)
		tOwnerExecute=((tPermissions & S_IXUSR)==S_IXUSR) ? 's' : 'S';
	else
		tOwnerExecute=((tPermissions & S_IXUSR)==S_IXUSR) ? 'x' : '-';
	
	char tGroupExecute;
	
	if ((tPermissions & S_ISGID)==S_ISGID)
		tGroupExecute=((tPermissions & S_IXGRP)==S_IXGRP) ? 's' : 'S';
	else
		tGroupExecute=((tPermissions & S_IXGRP)==S_IXGRP) ? 'x' : '-';
	
	char tOtherExecute;
	
	if ((tPermissions & S_ISTXT)==S_ISTXT)
		tOtherExecute=((tPermissions & S_IXOTH)==S_IXOTH) ? 't' : 'T';
	else
		tOtherExecute=((tPermissions & S_IXOTH)==S_IXOTH) ? 'x' : '-';
	
	return [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c", tFileMode,
			((tPermissions & S_IRUSR)==S_IRUSR) ? 'r' : '-',
			((tPermissions & S_IWUSR)==S_IWUSR) ? 'w' : '-',
			tOwnerExecute,
			((tPermissions & S_IRGRP)==S_IRGRP) ? 'r' : '-',
			((tPermissions & S_IWGRP)==S_IWGRP) ? 'w' : '-',
			tGroupExecute,
			((tPermissions & S_IROTH)==S_IROTH) ? 'r' : '-',
			((tPermissions & S_IWOTH)==S_IWOTH) ? 'w' : '-',
			tOtherExecute];
}

#pragma mark -

- (void)refreshAuxiliaryWithAbsolutePath:(NSString *)inAbsolutePath fileFilters:(NSArray *)inFileFilters
{
	if (_fileItemAuxiliary!=nil && (self.type!=PKGFileItemTypeFileSystemItem))
		return;
	
	if (_fileItemAuxiliary==nil)
		_fileItemAuxiliary=[_PKGFileItemAuxiliary new];
	
	[_fileItemAuxiliary updateWithReferencedItemPath:inAbsolutePath type:self.type fileFilters:inFileFilters];
}

@end
