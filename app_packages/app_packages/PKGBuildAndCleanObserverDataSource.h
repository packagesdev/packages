
#import <Foundation/Foundation.h>

#import "PKGDocument.h"

@class PKGBuildAndCleanObserverDataSource;

@protocol PKGBuildAndCleanObserverDataSourceDelegate <NSObject>

- (void)buildAndCleanObserverDataSource:(PKGBuildAndCleanObserverDataSource *)inBuildAndCleanObserverDataSource shouldReloadDataAndExpandItem:(id)inItem;
- (void)buildAndCleanObserverDataSource:(PKGBuildAndCleanObserverDataSource *)inBuildAndCleanObserverDataSource shouldReloadDataAndCollapseItem:(id)inItem;

@end

@interface PKGBuildAndCleanObserverDataSource : NSObject <NSOutlineViewDataSource>

	@property (nonatomic,weak) id<PKGBuildAndCleanObserverDataSourceDelegate> delegate;

	@property (nonatomic,readonly,copy) NSString * statusDescription;


+ (PKGBuildAndCleanObserverDataSource *)buildObserverDataSourceForDocument:(PKGDocument *)inDocument;

- (void)processBuildEventNotification:(NSNotification *)inNotification;

@end
