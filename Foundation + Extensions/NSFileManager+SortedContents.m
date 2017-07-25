
#import "NSFileManager+SortedContents.h"

@implementation NSFileManager (SortedContents_WB)

- (NSArray *)WB_sortedContentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error
{
	NSArray * tArray=[self contentsOfDirectoryAtPath:path error:error];
	
	if (tArray.count==0)
		return tArray;
	
	return [tArray sortedArrayUsingComparator:^NSComparisonResult(NSString * bFileName1, NSString * bFileName2) {
		
		return [bFileName1 compare:bFileName2 options:NSNumericSearch];
	}];
}

@end
