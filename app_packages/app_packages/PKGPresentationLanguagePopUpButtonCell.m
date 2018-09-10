
#import "PKGPresentationLanguagePopUpButtonCell.h"

@implementation PKGPresentationLanguagePopUpButtonCell

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView
{
	NSMutableAttributedString * tMutableTitle=[title mutableCopy];
	
	[tMutableTitle addAttribute:NSForegroundColorAttributeName value:[NSColor labelColor] range:NSMakeRange(0,[title length])];
	
	return [super drawTitle:tMutableTitle withFrame:frame inView:controlView];
}

@end
