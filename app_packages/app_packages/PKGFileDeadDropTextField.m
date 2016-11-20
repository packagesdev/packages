
#import "PKGFileDeadDropTextField.h"

@implementation PKGFileDeadDropTextField

- (instancetype)initWithFrame:(NSRect) inFrame
{
	self=[super initWithFrame:inFrame];
	
	if (self!=nil)
	{
		// Register for Drop
		
		[self registerForDraggedTypes:@[NSFilenamesPboardType]];
	}
	
	return self;
}

#pragma mark -

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	NSPasteboard * tPasteBoard = [sender draggingPasteboard];
	
	if (self.deadDropDelegate!=nil && [[tPasteBoard types] containsObject:NSFilenamesPboardType]==YES)
	{
		if (sourceDragMask & NSDragOperationCopy)
		{
			NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
			
			if (tFiles!=nil)
			{
				if ([self.deadDropDelegate fileDeadDropTextField:self validateDropFiles:tFiles]==YES)
				{
					return NSDragOperationCopy;
				}
			}
		}
	}
	
	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard * tPasteBoard= [sender draggingPasteboard];
	
	if (self.deadDropDelegate!=nil && [[tPasteBoard types] containsObject:NSFilenamesPboardType]==YES)
	{
		NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tFiles!=nil)
			return [self.deadDropDelegate fileDeadDropTextField:self acceptDropFiles:tFiles];
	}
	
	return [super performDragOperation:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	[super prepareForDragOperation:sender];
	
	return YES;
}

@end
