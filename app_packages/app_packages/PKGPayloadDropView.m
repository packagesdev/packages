
#import "PKGPayloadDropView.h"

@implementation PKGPayloadDropView

- (void)drawRect:(NSRect)inRect
{
	if (self.isHighlighted==YES)
	{
		NSBezierPath * tPath=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds],2.0,2.0) xRadius:8.0 yRadius:8.0];
		
		if (tPath!=nil)
		{
			[tPath setLineWidth:3.0f];
			
			[[NSColor alternateSelectedControlColor] set];
			
			[tPath stroke];
		}
	}
}

@end
