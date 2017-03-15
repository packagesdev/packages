
#import "PKGImportReferencePopUpButtonCell.h"

@implementation PKGImportReferencePopUpButtonCell

- (id)initWithCoder:(NSCoder *)inCoder
{
	self=[super initWithCoder:inCoder];
	
	if (self!=nil)
	{
		self.bordered=NO;
	}
	
	return self;
}

#pragma mark -

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSImage * tImage=self.selectedItem.image;
	
	if (tImage==nil)
		return;
	
	CGFloat tMinX=NSMinX(cellFrame);
	CGFloat tMiddleY=NSMidY(cellFrame);
	
	NSRect tDestinationRect;
	tDestinationRect.size=tImage.size;
	
	tDestinationRect.origin.x=round(tMinX+10.0);
	tDestinationRect.origin.y=round(tMiddleY-tImage.size.height*0.5+1.0);
	
	[tImage drawInRect:tDestinationRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:(self.isEnabled==YES) ? 1.0 : 0.5 respectFlipped:YES hints:@{}];
}

@end
