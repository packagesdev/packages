
#import "PKGPayloadTreeNodeImageView.h"

@implementation PKGPayloadTreeNodeImageView

- (void)setAttributedImage:(PKGPayloadTreeNodeAttributedImage *)inAttributedImage
{
	if (inAttributedImage!=_attributedImage)
	{
		_attributedImage=[inAttributedImage copy];
		
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -

- (BOOL)isOpaque
{
	return NO;
}

- (void)setDrawsTarget:(BOOL)inDrawsTarget
{
	if (_drawsTarget!=inDrawsTarget)
	{
		_drawsTarget=inDrawsTarget;
		
		[self setNeedsDisplay:YES];
	}
}

- (void)drawRect:(NSRect)inRect
{
	if (_attributedImage==nil)
		return;
	
	NSRect tBounds=self.bounds;
	
	if (_attributedImage.image!=nil)
		[_attributedImage.image drawInRect:tBounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:_attributedImage.alpha];
	
	// Draw the target cross
	
    if (self.drawsTarget==YES)
	{
		[[NSColor redColor] set];
		
		NSRectFill(self.bounds);
		
		// A COMPLETER
	}
}

@end
