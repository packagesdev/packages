/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFileItem.h"

#import "PKGPackagesError.h"

NSString * const PKGFileItemTypeKey=@"TYPE";

NSString * const PKGFileItemUserIDKey=@"UID";

NSString * const PKGFileItemGroupIDKey=@"GID";

NSString * const PKGFileItemPermissionsKey=@"PERMISSIONS";

NSString * const PKGFileItemExpandedKey=@"EXPANDED";	// Let us know when the contents of a real folder has been disclosed in the hierarchy


@interface PKGFileItem ()

	@property (readwrite) PKGFileItemType type;

	@property (readwrite) PKGFilePath * filePath;

- (instancetype)initWithFilePath:(PKGFilePath *)inFilePath uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions;

+ (instancetype)fileItemWithName:(NSString *)inName type:(PKGFileItemType)inType uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions;

@end


@implementation PKGFileItem

+ (instancetype)fileItemWithName:(NSString *)inName type:(PKGFileItemType)inType uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions
{
	if (inName==nil)
		return nil;
	
	PKGFileItem * nFileItem=[[PKGFileItem alloc] init];
	
	if (nFileItem!=nil)
	{
		nFileItem.type=inType;
		
		nFileItem.filePath=[PKGFilePath filePathWithName:inName];
		
		nFileItem.uid=inUid;
		nFileItem.gid=inGid;
		nFileItem.permissions=inPermissions;
	}
	
	return nFileItem;
}

+ (instancetype)newFolderWithName:(NSString *)inName uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions
{
	return [PKGFileItem fileItemWithName:inName type:PKGFileItemTypeNewFolder uid:inUid gid:inGid permissions:inPermissions];
}

+ (instancetype)folderTemplateWithName:(NSString *)inName uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions;
{
	return [PKGFileItem fileItemWithName:inName type:PKGFileItemTypeFolderTemplate uid:inUid gid:inGid permissions:inPermissions];
}

+ (instancetype)fileSystemItemWithFilePath:(PKGFilePath *)inFilePath uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions
{
	if (inFilePath==nil)
		return nil;
	
	PKGFileItem * nFileItem=[[PKGFileItem alloc] init];
	
	if (nFileItem!=nil)
	{
		nFileItem.type=PKGFileItemTypeFileSystemItem;
		
		nFileItem.filePath=inFilePath;
		
		nFileItem.uid=inUid;
		nFileItem.gid=inGid;
		nFileItem.permissions=inPermissions;
	}
	
	return nFileItem;
}

- (instancetype)initWithFileItem:(PKGFileItem *)inFileItem
{
	if (inFileItem==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_type=inFileItem.type;
		
		_filePath=[inFileItem.filePath copy];
		
		_uid=inFileItem.uid;
		_gid=inFileItem.gid;
		_permissions=inFileItem.permissions;
	}
	
	return self;
}

- (instancetype)initWithFilePath:(PKGFilePath *)inFilePath uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions
{
	if (inFilePath==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_type=PKGFileItemTypeFileSystemItem;
		
		_filePath=inFilePath;
		
		_uid=inUid;
		_gid=inGid;
		_permissions=inPermissions;
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		_type=[inRepresentation[PKGFileItemTypeKey] integerValue];
		
		if (_type>PKGFileItemTypeFileSystemItem)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGFileItemTypeKey}];
			
			return nil;
		}
		
		NSError * tError=nil;
		
		_filePath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation error:&tError];
		
		if (_filePath==nil)
		{
			if (outError!=nil)
				*outError=tError;
			
			return nil;
		}
		
		_uid=(uid_t) [inRepresentation[PKGFileItemUserIDKey] unsignedIntValue];
		_gid=(gid_t) [inRepresentation[PKGFileItemGroupIDKey] unsignedIntValue];
		
		_permissions=(mode_t)[inRepresentation[PKGFileItemPermissionsKey] unsignedShortValue];
		
		switch(_type)
		{
			case PKGFileItemTypeInvisible:
			case PKGFileItemTypeRoot:
			case PKGFileItemTypeFolderTemplate:
			case PKGFileItemTypeNewFolder:
				
				_contentsDisclosed=NO;	// A VERIFIER
				break;
				
			case PKGFileItemTypeFileSystemItem:
				
				_contentsDisclosed=[inRepresentation[PKGFileItemExpandedKey] boolValue];
				break;
		}
	}
	
	return self;
}

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGFileItemTypeKey]=@(self.type);
	
	[tRepresentation addEntriesFromDictionary:[self.filePath representation]];
	
	tRepresentation[PKGFileItemUserIDKey]=@(self.uid);
	tRepresentation[PKGFileItemGroupIDKey]=@(self.gid);
	
	tRepresentation[PKGFileItemPermissionsKey]=@(self.permissions);
	
	if (self.type==PKGFileItemTypeFileSystemItem && self.contentsDisclosed==YES)
		tRepresentation[PKGFileItemExpandedKey]=@(YES);
	
	return tRepresentation;
}

@end

