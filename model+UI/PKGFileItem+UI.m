
#import "PKGFileItem+UI.h"

@implementation PKGFileItem (UI)

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

@end
