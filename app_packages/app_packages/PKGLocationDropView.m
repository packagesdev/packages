
#import "PKGLocationDropView.h"

@interface PKGLocationDropView ()

	@property (nonatomic,readwrite,getter=isHighlighted) BOOL highlighted;

@end

@implementation PKGLocationDropView

- (BOOL)isOpaque
{
	return NO;
}

#pragma mark -

- (void)setHighlighted:(BOOL)inHighlighted
{
	if (_highlighted!=inHighlighted)
	{
		_highlighted=inHighlighted;
		
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -
	
- (void)drawRect:(NSRect)inRect
{
	//[super drawRect:inRect];
	
	if (self.isHighlighted==YES)
	{
		NSBezierPath * tPath=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds],2.0,2.0) xRadius:8.0 yRadius:8.0];
		
		tPath.lineWidth=3.0;
		
		[NSColor.selectedContentBackgroundColor setStroke];
		
		[tPath stroke];
	}
}

#pragma mark - Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if (self.delegate==nil)
	{
#ifdef DEBUG
		NSLog(@"PKGLocationDropView <0x%p>: drag & drop won't work. delegate is not set",self);
#endif
		return NSDragOperationNone;
	}
	
	id<PKGLocationDropViewDelegate> tDelegate=(id<PKGLocationDropViewDelegate>)self.delegate;
	
	if ([tDelegate locationDropView:self validateDrop:sender]==YES)
	{
		self.highlighted=YES;
		
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (self.delegate==nil)
	{
#ifdef DEBUG
		NSLog(@"PKGLocationDropView <0x%p>: drag & drop won't work. delegate is not set",self);
#endif
		return NO;
	}
	
	id<PKGLocationDropViewDelegate> tDelegate=(id<PKGLocationDropViewDelegate>)self.delegate;
	
	if ([tDelegate locationDropView:self acceptDrop:sender]==YES)
		return YES;
	
	return NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	self.highlighted=NO;
	
	return YES;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	self.highlighted=NO;
}

@end
