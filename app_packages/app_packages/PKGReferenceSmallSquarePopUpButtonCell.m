
#import "PKGReferenceSmallSquarePopUpButtonCell.h"

#import "PKGFilePathTypeMenu.h"

#import "PKGFilePath.h"

@interface PKGReferenceSmallSquarePopUpButtonCell ()

+ (NSImage *)imageForReferenceStyle:(PKGFilePathType)inPathType;

@end

@implementation PKGReferenceSmallSquarePopUpButtonCell

+ (NSImage *)imageForReferenceStyle:(PKGFilePathType)inPathType
{
	switch(inPathType)
	{
		case PKGFilePathTypeAbsolute:
			
			return [NSImage imageNamed:@"AbsoluteSquareSmallUbuntu"];
			
		case PKGFilePathTypeRelativeToProject:
			
			return [NSImage imageNamed:@"RelativeSquareSmallUbuntu"];
			
		case PKGFilePathTypeRelativeToReferenceFolder:
			
			return [NSImage imageNamed:@"ReferenceFolderSquareSmallUbuntu"];
			
		case PKGFilePathTypeMixed:
			
		default:
			
			return nil;
	}
	
	return nil;
}

- (id)initWithCoder:(NSCoder *)inCoder
{
	self=[super initWithCoder:inCoder];
	
	if (self!=nil)
	{
		self.bordered=NO;
		
		self.menu=[PKGFilePathTypeMenu menuForAction:self.action target:self.target controlSize:self.controlSize];
	}
	
	return self;
}

- (void)drawWithFrame:(NSRect) inFrame inView:(NSView *) inControlView
{
	NSMenuItem * tMenuItem=[self selectedItem];
	
	if (tMenuItem==nil)
		return;
	
	// Draw the Path Type icon
	
	NSImage * tReferenceIcon=[PKGReferenceSmallSquarePopUpButtonCell imageForReferenceStyle:[tMenuItem tag]];
	NSRect tRect={
		.origin=NSZeroPoint,
		.size=tReferenceIcon.size
	};
	
	[tReferenceIcon drawInRect:tRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:(self.isEnabled==YES) ? 1.0 : 0.5 respectFlipped:YES hints:nil];
}

@end