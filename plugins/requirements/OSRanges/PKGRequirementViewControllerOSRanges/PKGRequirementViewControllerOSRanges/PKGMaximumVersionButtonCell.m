
#import "PKGMaximumVersionButtonCell.h"

@implementation PKGMaximumVersionButtonCell

- (NSRect)drawTitle:(NSAttributedString *)inAttributedString withFrame:(NSRect)inFrame inView:(NSView*)inView
{
	if ([self isEnabled]==YES)
		return [super drawTitle:inAttributedString withFrame:inFrame inView:inView];
	
	[self setEnabled:YES];
	
	NSRect tRect=[super drawTitle:inAttributedString withFrame:inFrame inView:inView];
	
	[self setEnabled:NO];
	
	return tRect;
}

@end
