
#import "WBWhiteView.h"

@implementation WBWhiteView

- (BOOL)isOpaque
{
	return YES;
}

#pragma mark -

- (void)drawRect:(NSRect)rect
{
	[[NSColor whiteColor] set];
	
	NSRectFill(rect);
}

@end
