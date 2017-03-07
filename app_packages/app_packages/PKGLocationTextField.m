
#import "PKGLocationTextField.h"

@implementation PKGLocationTextField

- (id)initWithCoder:(NSCoder *)coder
{
	self=[super initWithCoder:coder];
	
	if (self!=nil)
	{
		[self registerForDraggedTypes:@[NSFilenamesPboardType,NSStringPboardType]];
	}
	
	return self;
}

#pragma mark - Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if (self.delegate==nil || [self.delegate conformsToProtocol:@protocol(PKGLocationTextFieldDelegate)]==NO)
		return [super draggingEntered:sender];
	
	id<PKGLocationTextFieldDelegate> tDelegate=(id<PKGLocationTextFieldDelegate>)self.delegate;
	
	if ([tDelegate locationTextField:self validateDrop:sender]==YES)
		return NSDragOperationCopy;
	
	return [super draggingEntered:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (self.delegate==nil)
		return [super performDragOperation:sender];
	
	id<PKGLocationTextFieldDelegate> tDelegate=(id<PKGLocationTextFieldDelegate>)self.delegate;
	
	if ([tDelegate locationTextField:self acceptDrop:sender]==YES)
		return YES;
	
	return [super performDragOperation:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	[super prepareForDragOperation:sender];
	
	return YES;
}

@end
