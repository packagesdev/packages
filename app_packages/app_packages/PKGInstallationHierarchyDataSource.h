
#import <Foundation/Foundation.h>

#import "PKGInstallationHierarchy.h"

extern NSString * const PKGInstallationHierarchyChoicesUUIDsPboardType;

@class PKGInstallationHierarchyDataSource;

@protocol PKGInstallationHierarchyDataSourceDelegate <NSObject>

- (NSMutableDictionary *)disclosedDictionary;

- (void)installationHierarchyDataDidChange:(PKGInstallationHierarchyDataSource *)inInstallationHierarchyDataSource;

@end

@interface PKGInstallationHierarchyDataSource : NSObject <NSOutlineViewDataSource>

	@property (nonatomic) PKGInstallationHierarchy * installationHierarchy;

	@property (nonatomic,weak) id<PKGInstallationHierarchyDataSourceDelegate> delegate;

+ (NSArray *)supportedDraggedTypes;

- (id)itemWithChoiceUUID:(NSString *)inChoiceUUID;

- (void)outlineView:(NSOutlineView *)inOutlineView removeItems:(NSArray *)inItems;

- (void)outlineView:(NSOutlineView *)inOutlineView groupItems:(NSArray *)inItems;

- (void)outlineView:(NSOutlineView *)inOutlineView ungroupItemsInGroup:(id)inItem;

- (void)outlineView:(NSOutlineView *)inOutlineView mergeItems:(NSArray *)inItems;

- (void)outlineView:(NSOutlineView *)inOutlineView separateItemsMergedAsItem:(id)inItem;



@end
