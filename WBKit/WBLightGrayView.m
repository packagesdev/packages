
#import "WBLightGrayView.h"

@implementation WBLightGrayView

- (BOOL) isOpaque
{
	return YES;
	
}

- (void)drawRect:(NSRect) inFrame
{
	[[NSColor colorWithDeviceWhite:0.94f alpha:1.0f] set];
	
	NSRectFill(inFrame);
}

@end
