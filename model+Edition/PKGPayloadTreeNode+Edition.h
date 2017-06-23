
#import "PKGPayloadTreeNode.h"

@interface PKGPayloadTreeNode (Edition)

- (void)switchPathsToType:(PKGFilePathType)inType recursively:(BOOL)inRecursively usingPathConverter:(id<PKGFilePathConverter>)inFilePathConverter;

@end
