/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

#import <Collaboration/Collaboration.h>

#include <sys/stat.h>

@implementation PKGPayloadTreeNode (UI)

+ (PKGPayloadTreeNode *)newFolderNodeWithParentNode:(PKGPayloadTreeNode *)inParentNode siblings:(NSArray *)inSiblings
{
	if (inSiblings==nil)
		return nil;
	
	uid_t tUid=0;
	uid_t tGid=0;
	
	if (inParentNode!=nil)
	{
		PKGFileItem * tParentFileItem=inParentNode.representedObject;
		
		if (tParentFileItem==nil)
			return nil;
		
		tUid=tParentFileItem.uid;
		tGid=tParentFileItem.gid;
	}
	
	PKGFileItem * nFileItem=[PKGFileItem newFolderWithName:[PKGPayloadTreeNode uniqueFileNameAmongSiblings:inSiblings] uid:tUid gid:tGid permissions:0775];
	
	if (nFileItem==nil)
		return nil;
	
	return [PKGPayloadTreeNode treeNodeWithRepresentedObject:nFileItem children:nil];
}

#pragma mark -

+ (NSString *)uniqueFileNameAmongSiblings:(NSArray *)inSiblingsNodes
{
	NSString * tBaseName=NSLocalizedString(@"untitled folder",@"No comment");
	
	NSString * tFileName=tBaseName;
	NSUInteger tIndex=1;
	
	do
	{
		BOOL tFound=NO;
		
		for(PKGPayloadTreeNode * tPayloadTreeNiode in inSiblingsNodes)
		{
			PKGFileItem * tFileItem=tPayloadTreeNiode.representedObject;
			
			if ([tFileItem.fileName caseInsensitiveCompare:tFileName]==NSOrderedSame)
			{
				tFound=YES;
				break;
			}
		}
		
		if (tFound==NO)
			return tFileName;
		
		tFileName=[NSString stringWithFormat:@"%@ %lu",tBaseName,(unsigned long)tIndex];
		
		tIndex++;
	}
	while (tIndex<65535);
	
	return nil;
}

+ (BOOL)validateFolderName:(NSString *)inFolderName
{
	if (inFolderName==nil)
		return NO;
	
	NSUInteger tLength=inFolderName.length;
	
	if (tLength==0 || tLength>256)
		return NO;
	
	if ([inFolderName isEqualToString:@".."]==YES ||
		[inFolderName isEqualToString:@"."]==YES ||
		[inFolderName rangeOfString:@"/"].location!=NSNotFound)
		return NO;
	
	return YES;
}

- (NSComparisonResult)compareName:(PKGPayloadTreeNode *)inPayloadTreeNode
{
	if (inPayloadTreeNode==nil)
		return NSOrderedDescending;
	
	return [((PKGFileItem *)self.representedObject).fileName compare:((PKGFileItem *)inPayloadTreeNode.representedObject).fileName options:NSCaseInsensitiveSearch|NSNumericSearch];
}

- (void)setNewFolderName:(NSString *)inFolderName
{
	if (inFolderName==nil)
		return;
	
	PKGFileItem * tFileItem=self.representedObject;
	
	if (tFileItem.type!=PKGFileItemTypeNewFolder)
		return;
	
	tFileItem.filePath.string=inFolderName;
}

#pragma mark -

- (NSString *)fileName
{
	return ((PKGFileItem *)self.representedObject).fileName;
}

- (NSString *)filePath
{
	if (self.parent==nil)
		return @"/";
	
	PKGPayloadTreeNode * tPayloadTreeNode=self;
	NSMutableString * tMutableString=[NSMutableString string];
	
	do
	{
		PKGFileItem * tFileItem=tPayloadTreeNode.representedObject;
		
		NSString * tFileName=tFileItem.fileName;
		
		if (tFileName==nil)
			break;
		
		if ([tFileName isEqualToString:@"/"]==YES)
			break;
		
		[tMutableString insertString:tFileName atIndex:0];
		[tMutableString insertString:@"/" atIndex:0];
		
		tPayloadTreeNode=(PKGPayloadTreeNode *) tPayloadTreeNode.parent;
	}
	while (tPayloadTreeNode!=nil);
	
	return [tMutableString copy];
}


- (BOOL)isHiddenTemplateNode
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeHiddenFolderTemplate);
}

- (BOOL)isTemplateNode
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeHiddenFolderTemplate || tFileItem.type==PKGFileItemTypeFolderTemplate);
}

- (BOOL)isFileSystemItemNode
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeFileSystemItem);
}

- (BOOL)isContentsDisclosed
{
	PKGFileItem * tFileItem=self.representedObject;
	
	if (tFileItem.type!=PKGFileItemTypeFileSystemItem)
		return YES;
	
	return tFileItem.isContentsDisclosed;
}

- (BOOL)isReferencedItemMissing
{
	PKGFileItem * tFileItem=self.representedObject;
	
	if (tFileItem.type!=PKGFileItemTypeFileSystemItem)
		return NO;
	
	return tFileItem.isReferencedItemMissing;
}

- (BOOL)isSelectableAsInstallationLocation
{
	PKGFileItem * tFileItem=self.representedObject;
	
	switch(tFileItem.type)
	{
		case PKGFileItemTypeHiddenFolderTemplate:
		case PKGFileItemTypeFolderTemplate:
		case PKGFileItemTypeNewFolder:
			
			return YES;
			
		case PKGFileItemTypeFileSystemItem:
			
			break;	// It's a bit more complicated
			
		default:
			
			break;
	}
	
	return NO;
}

@end

@implementation PKGPayloadTreeNodeAttributedImage

- (id)copy
{
	PKGPayloadTreeNodeAttributedImage * tAttributedImage=[PKGPayloadTreeNodeAttributedImage new];
	
	tAttributedImage.image=self.image;
	tAttributedImage.alpha=self.alpha;
	
	return tAttributedImage;
}

@end


@implementation PKGPayloadTreeNode (PKGFileHierarchy)

- (PKGPayloadTreeNodeAttributedImage *)nameAttributedIcon
{
	PKGFileItem * tFileItem=self.representedObject;
	
	if (tFileItem==nil)
		return nil;
	
	PKGPayloadTreeNodeAttributedImage * tAttribuedImage=[PKGPayloadTreeNodeAttributedImage new];
	
	tAttribuedImage.image=tFileItem.icon;
	tAttribuedImage.alpha=(tFileItem.type<PKGFileItemTypeNewFolder && [self containsNoTemplateDescendantNodes]==NO) ? 0.5 : 1.0;
	
	return tAttribuedImage;
}

- (NSAttributedString *)nameAttributedTitle
{
	PKGFileItem * tFileItem=self.representedObject;
	
	NSMutableDictionary * tAttributesDictionary=[NSMutableDictionary dictionaryWithObject:(tFileItem.isReferencedItemMissing==YES) ? [NSColor redColor] : [NSColor blackColor]
																				   forKey:NSForegroundColorAttributeName];
	
	if (tFileItem.isExcluded==YES)
		tAttributesDictionary[NSStrikethroughStyleAttributeName]=@(NSUnderlineStyleSingle);
	
	return [[NSAttributedString alloc] initWithString:tFileItem.fileName
										   attributes:tAttributesDictionary];
}

- (BOOL)isNameTitleEditable
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeNewFolder);
}

- (NSString *)ownerTitle
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return [[CBUserIdentity userIdentityWithPosixUID:tFileItem.uid authority:[CBIdentityAuthority localIdentityAuthority]] posixName];
	
	// A COMPLETER
}

- (NSString *)groupTitle
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return [[CBGroupIdentity groupIdentityWithPosixGID:tFileItem.gid authority:[CBIdentityAuthority localIdentityAuthority]] posixName];
}

- (NSString *)posixPermissionsTitle
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return tFileItem.posixPermissionsRepresentation;
}

#pragma mark -

- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter
{
	PKGFileItem * tFileItem=self.representedObject;
	
	switch(tFileItem.type)
	{
		case PKGFileItemTypeHiddenFolderTemplate:
		case PKGFileItemTypeRoot:
		case PKGFileItemTypeFolderTemplate:
		case PKGFileItemTypeNewFolder:
			
			return [self filePath];
			
		case PKGFileItemTypeFileSystemItem:
			
			return [inPathConverter absolutePathForFilePath:tFileItem.filePath];
	}
	
	return nil;
}

#pragma mark -

- (BOOL)needsRefresh:(NSTimeInterval)inTimeMark
{
	PKGFileItem * tFileItem=self.representedObject;
	
	return (tFileItem.refreshTimeMark<inTimeMark);
}

- (void)refreshWithAbsolutePath:(NSString *)inAbsolutePath fileFilters:(NSArray *)inFileFilters
{
	PKGFileItem * tFileItem=self.representedObject;
	
	[tFileItem refreshAuxiliaryWithAbsolutePath:inAbsolutePath fileFilters:inFileFilters];
}

@end