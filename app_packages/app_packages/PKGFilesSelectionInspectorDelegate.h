
#import <Foundation/Foundation.h>

@protocol PKGFilesSelectionInspectorDelegate <NSObject>

- (void)viewController:(NSViewController *)inViewController didUpdateSelectedItems:(NSArray *)inArray;

- (BOOL)viewController:(NSViewController *)inViewController shouldRenameItem:(id)inItem to:(NSString *)inName;

- (void)viewController:(NSViewController *)inViewController didRenameItem:(id)inItem to:(NSString *)inName;

@end
