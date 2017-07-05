
#import "PKGChoicesForest.h"

@interface PKGChoiceDependencyRecord : NSObject

	@property PKGChoiceTreeNode * choiceTreeNode;
	@property (getter=isGroup) BOOL group;
	@property BOOL enabledDependencySupported;
	@property BOOL selectedDependencySupported;
	@property NSSet * selectedDependencies;
	@property NSSet * enabledDependencies;

@end

@interface PKGChoicesForest (Dependencies_Edition)

- (NSDictionary *)allDependencyRecords;

- (NSMutableDictionary *)availableDependenciesDictionaryForEnabledStateOfGroupNode:(PKGChoiceTreeNode *)inTreeNode;

- (NSMutableDictionary *)availableDependenciesDictionaryForEnabledStateOfLeafNode:(PKGChoiceTreeNode *)inTreeNode skipEnabledIfConstant:(BOOL)inSkipEnabled;
- (NSMutableDictionary *)availableDependenciesDictionaryForEnabledStateOfLeafNode:(PKGChoiceTreeNode *)inTreeNode;
- (NSMutableDictionary *)availableDependenciesDictionaryForSelectedStateOfLeafNode:(PKGChoiceTreeNode *)inTreeNode;

@end
