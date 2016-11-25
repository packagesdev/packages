
#import "PKGSegmentViewController.h"

@implementation PKGSegmentViewController

- (void)noteDocumentHasChanged
{
	[((NSWindowController *) self.view.window.windowController).document updateChangeCount:NSChangeDone];
}

@end
