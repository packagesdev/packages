
#import "WBLightGrayView.h"

@implementation WBLightGrayView

- (BOOL)isOpaque
{
	return YES;
}

#pragma mark -

- (void)drawRect:(NSRect)inRect
{
	[[NSColor colorWithDeviceWhite:0.94 alpha:1.0] set];
	
	NSRectFill(inRect);
}

@end
