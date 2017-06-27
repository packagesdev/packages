
#import "PKGFilePathConverter.h"

#import "PKGPayloadTreeNode.h"

@interface PKGFilePathConverter (Edition)

- (void)switchPathsOfPayloadTreeNode:(PKGPayloadTreeNode *)inTreeNode toType:(PKGFilePathType)inType;

- (void)switchPathsOfPayloadTreeNode:(PKGPayloadTreeNode *)inTreeNode toType:(PKGFilePathType)inType recursively:(BOOL)inRecursively;

@end
