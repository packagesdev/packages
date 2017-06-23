
#import "PKGPayloadTreeNode+Edition.h"

#import "PKGPayloadBundleItem.h"

@implementation PKGPayloadTreeNode (Edition)

- (void)switchPathsToType:(PKGFilePathType)inType recursively:(BOOL)inRecursively usingPathConverter:(id<PKGFilePathConverter>)inFilePathConverter
{
	PKGFileItem * tFileItem=[self representedObject];
	
	if (tFileItem==nil)
		return;
	
	if (tFileItem.type==PKGFileItemTypeFileSystemItem)
	{
		[inFilePathConverter shiftTypeOfFilePath:tFileItem.filePath toType:inType];
	
		if ([tFileItem isKindOfClass:PKGPayloadBundleItem.class]==YES)
		{
			PKGPayloadBundleItem * tBundleItem=(PKGPayloadBundleItem *)tFileItem;
			
			[inFilePathConverter shiftTypeOfFilePath:tBundleItem.preInstallationScriptPath toType:inType];
			
			[inFilePathConverter shiftTypeOfFilePath:tBundleItem.postInstallationScriptPath toType:inType];
		}
	}
	
	if (inRecursively==NO)
		return;
	
	for(PKGPayloadTreeNode * tChild in [self children])
		[tChild switchPathsToType:inType recursively:inRecursively usingPathConverter:inFilePathConverter];
}

@end
