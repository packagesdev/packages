
#import <Foundation/Foundation.h>

@interface NSFileManager (SortedContents_WB)

- (NSArray *)WB_sortedContentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;

@end
