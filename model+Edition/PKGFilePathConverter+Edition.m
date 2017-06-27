
#import "PKGFilePathConverter+Edition.h"

#import "PKGPayloadBundleItem.h"

@implementation PKGFilePathConverter (Edition)

- (void)switchPathsOfPayloadTreeNode:(PKGPayloadTreeNode *)inTreeNode toType:(PKGFilePathType)inType
{
	[self switchPathsOfPayloadTreeNode:inTreeNode toType:inType recursively:NO];
}

- (void)switchPathsOfPayloadTreeNode:(PKGPayloadTreeNode *)inTreeNode toType:(PKGFilePathType)inType recursively:(BOOL)inRecursively
{
	PKGFileItem * tFileItem=[inTreeNode representedObject];
	
	if (tFileItem==nil)
		return;
	
	if (tFileItem.type==PKGFileItemTypeFileSystemItem)
	{
		[self shiftTypeOfFilePath:tFileItem.filePath toType:inType];
		
		if ([tFileItem isKindOfClass:PKGPayloadBundleItem.class]==YES)
		{
			PKGPayloadBundleItem * tBundleItem=(PKGPayloadBundleItem *)tFileItem;
			
			[self shiftTypeOfFilePath:tBundleItem.preInstallationScriptPath toType:inType];
			
			[self shiftTypeOfFilePath:tBundleItem.postInstallationScriptPath toType:inType];
		}
	}
	
	if (inRecursively==NO)
		return;
	
	[inTreeNode enumerateChildrenUsingBlock:^(PKGPayloadTreeNode * bChild, BOOL *stop) {
		
		[self switchPathsOfPayloadTreeNode:bChild toType:inType recursively:YES];
	}];
}

@end
