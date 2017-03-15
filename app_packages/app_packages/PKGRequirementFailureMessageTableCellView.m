
#import "PKGRequirementFailureMessageTableCellView.h"

@implementation PKGRequirementFailureMessageTableCellView

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    
	const CGFloat tPattern[2]={1.0,1.0};
	
	NSBezierPath * tBezierPath=[NSBezierPath bezierPath];
	NSRect tBounds=self.bounds;
	
	[tBezierPath setLineDash:tPattern count:2 phase:0];
	
	[tBezierPath moveToPoint:NSMakePoint(NSMinX(tBounds),round(NSMidY(tBounds))+0.5)];
	[tBezierPath lineToPoint:NSMakePoint(NSMaxX(tBounds),round(NSMidY(tBounds))+0.5)];
	
	[self.gridColor setStroke];
	[tBezierPath stroke];
}

@end
