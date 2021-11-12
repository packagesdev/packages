/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFileItem+UI.h"

#import "_PKGFileItemAuxiliary.h"

#include <sys/stat.h>

@implementation PKGFileItem (UI)

+ (NSString *)representationOfPOSIXPermissions:(mode_t)inPermissions fileType:(unsigned char)inFileType
{
	char tOwnerExecute;
	
	if ((inPermissions & S_ISUID)==S_ISUID)
		tOwnerExecute=((inPermissions & S_IXUSR)==S_IXUSR) ? 's' : 'S';
	else
		tOwnerExecute=((inPermissions & S_IXUSR)==S_IXUSR) ? 'x' : '-';
	
	char tGroupExecute;
	
	if ((inPermissions & S_ISGID)==S_ISGID)
		tGroupExecute=((inPermissions & S_IXGRP)==S_IXGRP) ? 's' : 'S';
	else
		tGroupExecute=((inPermissions & S_IXGRP)==S_IXGRP) ? 'x' : '-';
	
	char tOtherExecute;
	
	if ((inPermissions & S_ISTXT)==S_ISTXT)
		tOtherExecute=((inPermissions & S_IXOTH)==S_IXOTH) ? 't' : 'T';
	else
		tOtherExecute=((inPermissions & S_IXOTH)==S_IXOTH) ? 'x' : '-';
	
	return [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c", inFileType,
			((inPermissions & S_IRUSR)==S_IRUSR) ? 'r' : '-',
			((inPermissions & S_IWUSR)==S_IWUSR) ? 'w' : '-',
			tOwnerExecute,
			((inPermissions & S_IRGRP)==S_IRGRP) ? 'r' : '-',
			((inPermissions & S_IWGRP)==S_IWGRP) ? 'w' : '-',
			tGroupExecute,
			((inPermissions & S_IROTH)==S_IROTH) ? 'r' : '-',
			((inPermissions & S_IWOTH)==S_IWOTH) ? 'w' : '-',
			tOtherExecute];
}

+ (NSString *)representationOfPOSIXPermissions:(mode_t)inPermissions mixedPermissions:(mode_t)inMixedPermissions fileType:(unsigned char)inFileType
{
	char ownerExecute,groupExecute,otherExecute;
	char tMixedChar='?';
	
	if ((inMixedPermissions & S_ISUID)==S_ISUID || (inMixedPermissions & S_IXUSR)==S_IXUSR)
	{
		ownerExecute=tMixedChar;
	}
	else
	{
		if ((inPermissions & S_ISUID)==S_ISUID)
		{
			ownerExecute=((inPermissions & S_IXUSR)==S_IXUSR) ? 's' : 'S';
		}
		else
		{
			ownerExecute=((inPermissions & S_IXUSR)==S_IXUSR) ? 'x' : '-';
		}
	}
	
	if ((inMixedPermissions & S_ISGID)==S_ISGID || (inMixedPermissions & S_IXGRP)==S_IXGRP)
	{
		groupExecute=tMixedChar;
	}
	else
	{
		if ((inPermissions & S_ISGID)==S_ISGID)
		{
			groupExecute=((inPermissions & S_IXGRP)==S_IXGRP) ? 's' : 'S';
		}
		else
		{
			groupExecute=((inPermissions & S_IXGRP)==S_IXGRP) ? 'x' : '-';
		}
	}
	
	if ((inMixedPermissions & S_ISTXT)==S_ISTXT || (inMixedPermissions & S_IXOTH)==S_IXOTH)
	{
		otherExecute=tMixedChar;
	}
	else
	{
		if ((inPermissions & S_ISTXT)==S_ISTXT)
		{
			otherExecute=((inPermissions & S_IXOTH)==S_IXOTH) ? 't' : 'T';
		}
		else
		{
			otherExecute=((inPermissions & S_IXOTH)==S_IXOTH) ? 'x' : '-';
		}
	}
	
	return [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c",inFileType,
			((inMixedPermissions & S_IRUSR)==S_IRUSR) ? tMixedChar : (((inPermissions & S_IRUSR)==S_IRUSR) ? 'r' : '-'),
			((inMixedPermissions & S_IWUSR)==S_IWUSR) ? tMixedChar : (((inPermissions & S_IWUSR)==S_IWUSR) ? 'w' : '-'),
			ownerExecute,
			((inMixedPermissions & S_IRGRP)==S_IRGRP) ? tMixedChar : (((inPermissions & S_IRGRP)==S_IRGRP) ? 'r' : '-'),
			((inMixedPermissions & S_IWGRP)==S_IWGRP) ? tMixedChar : (((inPermissions & S_IWGRP)==S_IWGRP) ? 'w' : '-'),
			groupExecute,
			((inMixedPermissions & S_IROTH)==S_IROTH) ? tMixedChar : (((inPermissions & S_IROTH)==S_IROTH) ? 'r' : '-'),
			((inMixedPermissions & S_IWOTH)==S_IWOTH) ? tMixedChar : (((inPermissions & S_IWOTH)==S_IWOTH) ? 'w' : '-'),
			otherExecute];
}

- (NSTimeInterval)refreshTimeMark
{
	if (_fileItemAuxiliary==nil)
		return -1.0;
	
	if (self.type<PKGFileItemTypeNewFolder)
		return DBL_MAX;
	
	return _fileItemAuxiliary.refreshTimeMark;
}

- (NSString *)referencedItemPath
{
	if (_fileItemAuxiliary==nil)
		return nil;
	
	return _fileItemAuxiliary.referencedItemPath;
}

- (unsigned char)fileType
{
	if (_fileItemAuxiliary==nil)
		return 'd';
	
	return _fileItemAuxiliary.fileType;
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
		NSImage * tIcon=[_PKGFileItemAuxiliary cachedIconForTemplateFolderAtPath:_fileItemAuxiliary.referencedItemPath];
		
		if (tIcon!=nil)
			return tIcon;
		
		return [_PKGFileItemAuxiliary cachedGenericFolderIcon];
	}
	
	if (_fileItemAuxiliary==nil)
		return nil;
	
	return _fileItemAuxiliary.icon;
}

- (NSString *)posixPermissionsRepresentation
{
	unsigned char tFileType='d';
	
	if (_fileItemAuxiliary!=nil)
		tFileType=_fileItemAuxiliary.fileType;
	
	return [PKGFileItem representationOfPOSIXPermissions:self.permissions fileType:tFileType];
}

- (BOOL)isNameEditable
{
    return (self.type==PKGFileItemTypeNewFolder ||
            self.type==PKGFileItemTypeNewElasticFolder ||
            self.payloadFileName!=nil);
}

#pragma mark -

- (void)refreshAuxiliaryAsMissingFileItem
{
	if (_fileItemAuxiliary!=nil && self.type<PKGFileItemTypeNewFolder)
		return;
	
	_fileItemAuxiliary=[_PKGFileItemAuxiliary itemMissingAuxiliary];
}

- (void)refreshAuxiliaryWithAbsolutePath:(NSString *)inAbsolutePath fileFilters:(NSArray *)inFileFilters
{
	if (_fileItemAuxiliary!=nil && self.type<PKGFileItemTypeNewFolder)
		return;
	
	if (_fileItemAuxiliary==nil)
		_fileItemAuxiliary=[_PKGFileItemAuxiliary new];
	
	[_fileItemAuxiliary updateWithReferencedItemPath:inAbsolutePath type:self.type fileFilters:inFileFilters];
}

- (void)createTemporaryAuxiliaryIfNeededWithAbsolutePath:(NSString *)inAbsolutePath
{
	if (_fileItemAuxiliary!=nil || self.type<PKGFileItemTypeNewFolder)
		return;
	
	_fileItemAuxiliary=[_PKGFileItemAuxiliary new];
	
	[_fileItemAuxiliary updateWithReferencedItemPath:inAbsolutePath type:self.type fileFilters:nil obsolete:YES];
}

@end
