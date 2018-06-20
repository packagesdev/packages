
#import "WBWhiteView.h"

@implementation WBWhiteView

- (BOOL)isOpaque
{
	return YES;
}

#pragma mark -

- (void)drawRect:(NSRect)rect
{
	[[NSColor textBackgroundColor] set];
	
	NSRectFill(rect);
}

@end
