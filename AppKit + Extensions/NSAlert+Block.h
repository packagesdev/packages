
#import <Cocoa/Cocoa.h>

@interface NSAlert (Block_WB)

- (void)WB_beginSheetModalForWindow:(NSWindow *)sheetWindow completionHandler:(void (^)(NSModalResponse returnCode))handler;

@end
