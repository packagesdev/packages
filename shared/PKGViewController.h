
#import <Cocoa/Cocoa.h>

@interface PKGViewController : NSViewController

- (BOOL)PKG_viewCanBeRemoved:(id) sender;

- (void)PKG_viewWillBeRemoved:(id) sender;

@end
