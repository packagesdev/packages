
#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

#import <Collaboration/Collaboration.h>

#include <sys/stat.h>

@implementation PKGPayloadTreeNode (UI)

+ (PKGPayloadTreeNode *)newFolderNodeWithParentNode:(PKGPayloadTreeNode *)inParentNode
{
	if (inParentNode==nil)
		return nil;
	
	PKGFileItem * tParentFileItem=(PKGFileItem *)inParentNode.representedObject;
	
	if (tParentFileItem==nil)
		return nil;
	
	PKGFileItem * nFileItem=[PKGFileItem newFolderWithName:[PKGPayloadTreeNode uniqueFileNameAmongSiblings:inParentNode.children] uid:tParentFileItem.uid gid:tParentFileItem.gid permissions:(tParentFileItem.permissions & ACCESSPERMS)];
	
	if (nFileItem==nil)
		return nil;
	
	return [PKGPayloadTreeNode treeNodeWithRepresentedObject:nFileItem children:nil];
}

+ (PKGPayloadTreeNode *)newFolderNodeWithSiblingsNodes:(NSArray *)inSiblingsNodes
{
	if (inSiblingsNodes==nil)
		return nil;
	
	PKGFileItem * nFileItem=[PKGFileItem newFolderWithName:[PKGPayloadTreeNode uniqueFileNameAmongSiblings:inSiblingsNodes] uid:0 gid:0 permissions:0755];
	
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
			PKGFileItem * tFileItem=(PKGFileItem *)tPayloadTreeNiode.representedObject;
			
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

- (NSComparisonResult)compareName:(PKGPayloadTreeNode *)inPayloadTreeNode
{
	if (inPayloadTreeNode==nil)
		return NSOrderedDescending;
	
	return [((PKGFileItem *)self.representedObject).fileName caseInsensitiveCompare:((PKGFileItem *)inPayloadTreeNode.representedObject).fileName];
}

#pragma mark -

- (NSString *)filePath
{
	if (self.parent==nil)
		return @"/";
	
	PKGPayloadTreeNode * tPayloadTreeNode=self;
	NSMutableString * tMutableString=[NSMutableString string];
	
	do
	{
		PKGFileItem * tFileItem=(PKGFileItem *)tPayloadTreeNode.representedObject;
		
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

- (BOOL)isTemplateNode
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeInvisible || tFileItem.type==PKGFileItemTypeFolderTemplate);
}

- (BOOL)isFileSystemItemNode
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeFileSystemItem);
}

@end


@implementation PKGPayloadTreeNode (PKGFileHierarchy)

- (NSImage *)nameIcon
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	if (tFileItem.type<PKGFileItemTypeNewFolder)
		return ([self containsNoTemplateDescendantNodes]==YES)? tFileItem.icon : tFileItem.disabledIcon;
	
	return tFileItem.icon;
}

- (NSAttributedString *)nameTitle
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	NSMutableDictionary * tAttributesDictionary=[NSMutableDictionary dictionaryWithObject:(tFileItem.isReferencedItemMissing==YES) ? [NSColor redColor] : [NSColor blackColor]
																				   forKey:NSForegroundColorAttributeName];
	
	if (tFileItem.isExcluded==YES)
		tAttributesDictionary[NSStrikethroughStyleAttributeName]=@(NSUnderlineStyleSingle);
	
	return [[NSAttributedString alloc] initWithString:tFileItem.fileName
										   attributes:tAttributesDictionary];
}

- (BOOL)isNameTitleEditable
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	return (tFileItem.type==PKGFileItemTypeNewFolder);
}

- (NSString *)ownerTitle
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	return [[CBUserIdentity userIdentityWithPosixUID:tFileItem.uid authority:[CBIdentityAuthority localIdentityAuthority]] posixName];
	
	// A COMPLETER
}

- (NSString *)groupTitle
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	return [[CBGroupIdentity groupIdentityWithPosixGID:tFileItem.gid authority:[CBIdentityAuthority localIdentityAuthority]] posixName];
}

- (NSString *)posixPermissionsTitle
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	return tFileItem.posixPermissionsRepresentation;
}

#pragma mark -

- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	switch(tFileItem.type)
	{
		case PKGFileItemTypeInvisible:
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
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	return (tFileItem.refreshTimeMark<inTimeMark);
}

- (void)refreshWithAbsolutePath:(NSString *)inAbsolutePath fileFilters:(NSArray *)inFileFilters
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	[tFileItem refreshAuxiliaryWithAbsolutePath:inAbsolutePath fileFilters:inFileFilters];
}

@end