
#import <Cocoa/Cocoa.h>

@interface NSViewController (WBExtensions)

- (void)WB_viewWillAdd;

- (void)WB_viewDidAdd;

- (void)WB_viewWillRemove;

- (void)WB_viewDidRemove;

@end
