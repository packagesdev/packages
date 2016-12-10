
#import "PKGPayloadTreeNode.h"

#import "PKGPayloadBundleItem.h"

@implementation PKGPayloadTreeNode

- (Class)representedObjectClassForRepresentation:(NSDictionary *)inRepresentation;
{
	if (inRepresentation!=nil)
	{
		if ([PKGPayloadBundleItem isRepresentationOfBundleItem:inRepresentation])
			return PKGPayloadBundleItem.class;
	}
	
	return PKGFileItem.class;
}

#pragma mark -

- (BOOL)isLeaf
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	if (tFileItem.type!=PKGFileItemTypeFileSystemItem)
		return NO;
	
	return ([tFileItem isContentsDisclosed]==NO);
}

#pragma mark -

- (void)insertSortedChild:(PKGPayloadTreeNode *)inPayloadTreeNode
{
	// A COMPLETER
}

- (PKGPayloadTreeNode *)descendantNodeAtPath:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	PKGPayloadTreeNode * tPayloadTreeNode=self;
	
	NSArray * tPathComponents=[inPath componentsSeparatedByString:@"/"];
	
	for(NSString * tComponent in tPathComponents)
	{
		if (tComponent.length==0)
			continue;
		
		for(PKGPayloadTreeNode * tChildTreeNode in tPayloadTreeNode.children)
		{
			PKGFileItem * tFileItem=(PKGFileItem *)tChildTreeNode.representedObject;
			
			if ([[tFileItem.filePath lastPathComponent] isEqualToString:tComponent]==YES)
			{
				tPayloadTreeNode=tChildTreeNode;
				break;
			}
		}
	}
	
	return tPayloadTreeNode;
}

- (NSUInteger)optimizePayloadHierarchy
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	if (tFileItem.type==PKGFileItemTypeFileSystemItem ||
		tFileItem.type==PKGFileItemTypeNewFolder)
		return 1;
	
	NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
	
	[[self children] enumerateObjectsUsingBlock:^(PKGPayloadTreeNode * bChildNode,NSUInteger bIndex,__attribute__((unused))BOOL * bOutStop){
		
		if ([bChildNode optimizePayloadHierarchy]==0)
			[tIndexSet addIndex:bIndex];
	}];
	
	[self removeChildrenAtIndexes:tIndexSet];
	
	NSUInteger tNumberOfChildren=[self numberOfChildren];
	
	if (tNumberOfChildren>0)
		return tNumberOfChildren;
	
	if (tFileItem.type!=PKGFileItemTypeRoot)
		return 0;
	
	return 1;
}

- (BOOL)containsNotTemplateNodeDescendants;
{
	PKGFileItem * tFileItem=(PKGFileItem *)self.representedObject;
	
	if (tFileItem.type>=PKGFileItemTypeNewFolder)
		return YES;
	
	NSUInteger tCount=[self numberOfChildren];
	
	for(NSUInteger tIndex=0;tIndex<tCount;tIndex++)
	{
		if ([((PKGPayloadTreeNode *)[self descendantNodeAtIndex:tIndex]) containsNotTemplateNodeDescendants]==YES)
			return YES;
	}
	
	return NO;
}

@end
