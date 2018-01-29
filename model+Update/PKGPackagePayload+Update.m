
#import "PKGPackagePayload+Update.h"

@interface PKGPackagePayload (Default)

+ (PKGPackagePayload *)sharedDefaultPackagePayload;

@end

@implementation PKGPackagePayload (Default)

+ (PKGPackagePayload *)sharedDefaultPackagePayload
{
	static dispatch_once_t onceToken;
	static PKGPackagePayload * sDefaultPackagePayload=nil;
	
	
	dispatch_once(&onceToken, ^{
		
		NSString * tPath=[[NSBundle mainBundle] pathForResource:@"DefaultFileHierarchy" ofType:@"plist"];
		
		if (tPath==nil)
		{
			NSLog(@"DefaultFileHierachy.plist file not found");
			
			return;
		}
		
		NSError * tError=nil;
		NSData * tData=[NSData dataWithContentsOfFile:tPath options:0 error:&tError];
		
		if (tData==nil)
		{
			// A COMPLETER
		}
		
		id tPropertyList=[NSPropertyListSerialization propertyListWithData:tData options:0 format:NULL error:&tError];
		
		if (tPropertyList==nil)
		{
			// A COMPLETER
		}
		
		sDefaultPackagePayload=[[PKGPackagePayload alloc] initWithDefaultHierarchy:tPropertyList error:&tError];
		
		if (sDefaultPackagePayload==nil)
		{
			// A COMPLETER
		}
		
	});
	
	return sDefaultPackagePayload;
}

@end

@implementation PKGPackagePayload (Update)

- (void)updateProjectAttributes:(PKGProjectAttribute)inProjectUpdateAttributes completionHandler:(void (^)(PKGProjectAttribute bUpdatedAttributes))handler
{
	__block PKGProjectAttribute tUpdatedAttributes=PKGProjectAttributeNone;
	
	if ((inProjectUpdateAttributes & PKGProjectAttributeDefaultPayloadHierarchy)==PKGProjectAttributeDefaultPayloadHierarchy)
	{
		if ([PKGPackagePayload sharedDefaultPackagePayload].templateVersion>self.templateVersion)
		{
			NSLog(@"We need to update the permissions");
			
			// We need to fix/update the permissions
			
			if ([self.filesTree.rootNodes.array[0] mergeDescendantsOfNode:[PKGPackagePayload sharedDefaultPackagePayload].filesTree.rootNodes.array[0]
														  usingComparator:^NSComparisonResult(PKGPayloadTreeNode * bPayloadTreeNode1, PKGPayloadTreeNode * bPayloadTreeNode2) {
															  
															  if (bPayloadTreeNode2==nil)
																  return NSOrderedDescending;
															  
															  return [((PKGFileItem *)bPayloadTreeNode1.representedObject).fileName compare:((PKGFileItem *)bPayloadTreeNode2.representedObject).fileName options:NSCaseInsensitiveSearch|NSNumericSearch|NSForcedOrderingSearch];
				
			}
											representedObjectMergeHandler:^BOOL(PKGPayloadTreeNode *bOriginalTreeNode, PKGPayloadTreeNode *bModifiedTreeNode) {
												
												PKGFileItem * tOriginalFileItem=bOriginalTreeNode.representedObject;
												
												if (tOriginalFileItem.type!=PKGFileItemTypeFolderTemplate && tOriginalFileItem.type!=PKGFileItemTypeHiddenFolderTemplate)
													return NO;
												
												PKGFileItem * tModifiedTreeNode=bModifiedTreeNode.representedObject;
												
												if (tOriginalFileItem.type!=tModifiedTreeNode.type)
													return NO;
												
												BOOL tMerged=NO;
												
												if (tOriginalFileItem.uid!=tModifiedTreeNode.uid)
												{
													tOriginalFileItem.uid=tModifiedTreeNode.uid;
													tMerged=YES;
												}
												
												if (tOriginalFileItem.gid!=tModifiedTreeNode.gid)
												{
													tOriginalFileItem.gid=tModifiedTreeNode.gid;
													tMerged=YES;
												}
												
												if (tOriginalFileItem.permissions!=tModifiedTreeNode.permissions)
												{
													tOriginalFileItem.permissions=tModifiedTreeNode.permissions;
													tMerged=YES;
												}
												
												if (tMerged==YES)
													[tOriginalFileItem resetAuxiliaryData];
												
												return tMerged;
				
			}]==YES)
			{
				tUpdatedAttributes|=PKGProjectAttributeDefaultPayloadHierarchy;
			}
		
			self.templateVersion=[PKGPackagePayload sharedDefaultPackagePayload].templateVersion;									
		}
	}
	
	if (handler!=nil)
		handler(tUpdatedAttributes);
}

@end
