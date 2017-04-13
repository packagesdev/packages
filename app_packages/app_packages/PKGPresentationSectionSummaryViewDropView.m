
#import "PKGPresentationSectionSummaryViewDropView.h"

@implementation PKGPresentationSectionSummaryViewDropView

- (void)drawRect:(NSRect)inRect
{
	if (self.isHighlighted==YES)
	{
		NSBezierPath * tPath=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds],2.0,2.0) xRadius:8.0 yRadius:8.0];
		
		tPath.lineWidth=3.0;
		
		[[NSColor alternateSelectedControlColor] setStroke];
		
		[tPath stroke];
	}
}

@end
