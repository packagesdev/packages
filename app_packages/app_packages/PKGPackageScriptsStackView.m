#import "PKGPackageScriptsStackView.h"

@implementation PKGPackageScriptsStackView

- (instancetype)initWithFrame:(NSRect)inRect
{
	self=[super initWithFrame:inRect];
	
	if (self!=nil)
	{
		self.orientation=PKGUserInterfaceLayoutOrientationHorizontal;
	}
	
	return self;
}

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor whiteColor] set];
	
	NSRectFill(dirtyRect);
}

@end
