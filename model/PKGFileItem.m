/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFileItem.h"

#import "PKGPackagesError.h"

NSString * const PKGFileItemPayloadFileNameKey=@"PAYLOAD_FILENAME";

NSString * const PKGFileItemTypeKey=@"TYPE";

NSString * const PKGFileItemUserIDKey=@"UID";

NSString * const PKGFileItemGroupIDKey=@"GID";

NSString * const PKGFileItemPermissionsKey=@"PERMISSIONS";

NSString * const PKGFileItemExpandedKey=@"EXPANDED";	// Let us know when the contents of a real folder has been disclosed in the hierarchy


@interface PKGFileItem ()

	@property (readwrite) PKGFileItemType type;

	@property (readwrite) PKGFilePath * filePath;


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
		nFileItem.payloadFileName=nil;
		
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

+ (instancetype)newElasticFolderWithName:(NSString *)inName uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions
{
    return [PKGFileItem fileItemWithName:inName type:PKGFileItemTypeNewElasticFolder uid:inUid gid:inGid permissions:inPermissions];
}

+ (instancetype)folderTemplateWithName:(NSString *)inName uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions;
{
	return [PKGFileItem fileItemWithName:inName type:PKGFileItemTypeFolderTemplate uid:inUid gid:inGid permissions:inPermissions];
}

+ (instancetype)fileSystemItemWithFilePath:(PKGFilePath *)inFilePath uid:(uid_t)inUid gid:(gid_t)inGid permissions:(mode_t)inPermissions
{
	if (inFilePath==nil)
		return nil;
	
	return [[PKGFileItem alloc] initWithFilePath:inFilePath uid:inUid gid:inGid permissions:inPermissions];
}

- (instancetype)initWithFileItem:(PKGFileItem *)inFileItem
{
	if (inFileItem==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_payloadFileName=[inFileItem.payloadFileName copy];
		
		_type=inFileItem.type;
		
		_filePath=[inFileItem.filePath copy];
		
		_uid=inFileItem.uid;
		_gid=inFileItem.gid;
		_permissions=inFileItem.permissions;
		
		_contentsDisclosed=inFileItem.contentsDisclosed;
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
		_payloadFileName=nil;
		
		_type=PKGFileItemTypeFileSystemItem;
		
		_filePath=inFilePath;
		
		_uid=inUid;
		_gid=inGid;
		_permissions=inPermissions;
	}
	
	return self;
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
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
		_payloadFileName=[inRepresentation[PKGFileItemPayloadFileNameKey] copy];
		
		if (_payloadFileName!=nil && [_payloadFileName isKindOfClass:NSString.class]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGFileItemPayloadFileNameKey}];
			
			return nil;
		}
		
		_type=[inRepresentation[PKGFileItemTypeKey] integerValue];
		
		if (_type>PKGFileItemTypeNewElasticFolder)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValueError
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
			case PKGFileItemTypeHiddenFolderTemplate:
			case PKGFileItemTypeRoot:
			case PKGFileItemTypeFolderTemplate:
			case PKGFileItemTypeNewFolder:
            case PKGFileItemTypeNewElasticFolder:
				
				_contentsDisclosed=NO;
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
	NSMutableDictionary * tRepresentation=[self.filePath representation];
	
	if (self.payloadFileName!=nil)
		tRepresentation[PKGFileItemPayloadFileNameKey]=self.payloadFileName;
	
	tRepresentation[PKGFileItemTypeKey]=@(self.type);
	
	tRepresentation[PKGFileItemUserIDKey]=@(self.uid);
	tRepresentation[PKGFileItemGroupIDKey]=@(self.gid);
	
	tRepresentation[PKGFileItemPermissionsKey]=@(self.permissions);
	
	if (self.type==PKGFileItemTypeFileSystemItem && self.contentsDisclosed==YES)
		tRepresentation[PKGFileItemExpandedKey]=@(YES);
	
	return tRepresentation;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGFileItem * nFileItem=[[[self class] allocWithZone:inZone] init];
	
	if (nFileItem!=nil)
	{
		nFileItem->_fileItemAuxiliary=[(id)_fileItemAuxiliary copyWithZone:inZone];
	
		nFileItem.payloadFileName=[self.payloadFileName copyWithZone:inZone];
		
		nFileItem.type=self.type;
	
		nFileItem.filePath=[self.filePath copyWithZone:inZone];
	
		nFileItem.uid=self.uid;
	
		nFileItem.gid=self.gid;
	
		nFileItem.permissions=self.permissions;
	
		nFileItem.contentsDisclosed=self.isContentsDisclosed;
	}
	
	return nFileItem;
}

#pragma mark -

- (NSString *)fileName
{
	switch(self.type)
	{
		case PKGFileItemTypeHiddenFolderTemplate:
		case PKGFileItemTypeFolderTemplate:
		case PKGFileItemTypeNewFolder:
        case PKGFileItemTypeNewElasticFolder:
			return self.filePath.string;
			
		case PKGFileItemTypeFileSystemItem:
			
			if (self.payloadFileName!=nil)
				return self.payloadFileName;
			
			return self.filePath.string.lastPathComponent;
			
		default:
			
			return nil;
	}
	
	return nil;
}

#pragma mark -

- (void)resetAuxiliaryData
{
	if (_fileItemAuxiliary!=nil)
		_fileItemAuxiliary=nil;
}

@end

