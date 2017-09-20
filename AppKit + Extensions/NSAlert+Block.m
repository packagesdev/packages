
#import "NSAlert+Block.h"

@implementation NSAlert (Block_WB)

- (void)WB_alertDidEndSelector:(NSAlert *)alert returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
	
	if (handler!=nil)
		handler(inReturnCode);
}

- (void)WB_beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSModalResponse returnCode))handler
{
	[self beginSheetModalForWindow:inWindow
					 modalDelegate: self
					didEndSelector: @selector(WB_alertDidEndSelector:returnCode:contextInfo:)
					   contextInfo: (__bridge_retained void*)[handler copy] ];
}





@end
