
#import "PKGFileFilterKindPopUpButtonCell.h"

@implementation PKGFileFilterKindPopUpButtonCell

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView *) controlView
{
	CGFloat tMinX=NSMinX(cellFrame);
	CGFloat tMiddleY=NSMidY(cellFrame);
	
	NSRect tDestinationRect;
	
	tDestinationRect.origin.x=tMinX+18.0;
	
	NSMenuItem * tMenuItem=[self selectedItem];
	
	if (tMenuItem!=nil)
	{
		NSImage * tImage=[[tMenuItem image] copy];
		
		NSRect tImageRect;
		
		[tImage setSize:NSMakeSize(14.0,14.0)];
		
		tImageRect.origin=NSZeroPoint;
		tImageRect.size=tImage.size;
		
		tDestinationRect.size=tImageRect.size;
		
		tDestinationRect.origin.x=tMinX+8.0;
		tDestinationRect.origin.y=round(tMiddleY-tDestinationRect.size.height*0.5-0.5);
		
		[tImage drawInRect:tDestinationRect fromRect:tImageRect operation:NSCompositeSourceOver fraction:(self.isEnabled==YES) ? 1.0 : 0.5 respectFlipped:YES hints:@{}];
		
		tDestinationRect.origin.x+=tImageRect.size.width+4;
	}
	
	// Draw the Arrow
	
	// Top Arrow
	
	NSBezierPath * tPath=[NSBezierPath bezierPath];
	
	if ([self isEnabled]==YES)
		[[NSColor colorWithDeviceWhite:0.15f alpha:1.0f] setFill];
	else
		[[NSColor colorWithDeviceWhite:0.15f alpha:0.5f] setFill];
	
	if (tPath!=nil)
	{
		[tPath moveToPoint:NSMakePoint(tDestinationRect.origin.x,round(tMiddleY)+1)];
		[tPath lineToPoint:NSMakePoint(tDestinationRect.origin.x+5.0f,round(tMiddleY)+1)];
		[tPath lineToPoint:NSMakePoint(tDestinationRect.origin.x+2.5f,round(tMiddleY+4.5f))];
		[tPath closePath];
		
		[tPath fill];
		
		[tPath removeAllPoints];
	
		[tPath moveToPoint:NSMakePoint(tDestinationRect.origin.x,round(tMiddleY)-1.0f)];
		[tPath lineToPoint:NSMakePoint(tDestinationRect.origin.x+5.0f,round(tMiddleY)-1.0f)];
		[tPath lineToPoint:NSMakePoint(tDestinationRect.origin.x+2.5f,round(tMiddleY)-4.5f)];
		[tPath closePath];
		
		[tPath fill];
	}
}

@end
