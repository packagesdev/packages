/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "PKGReferencePopupButtonCell.h"

#import "PKGFilePathTypeMenu.h"

#import "PKGFilePath.h"

#define PKGReferencePopupButtonCellLeftOffset		20.0

@interface PKGReferencePopupButtonCell ()

+ (NSImage *)leftCapForReferenceStyle:(PKGFilePathType)inPathType controlSize:(NSControlSize)inControlSize;

@end

@implementation PKGReferencePopupButtonCell

+ (NSImage *)leftCapForReferenceStyle:(PKGFilePathType)inPathType controlSize:(NSControlSize)inControlSize
{
	if (inControlSize==WBControlSizeRegular)
	{
		switch(inPathType)
		{
			case PKGFilePathTypeAbsolute:
				
				return [NSImage imageNamed:@"AbsoluteRegularUbuntu"];
				
			case PKGFilePathTypeRelativeToProject:
				
				return [NSImage imageNamed:@"RelativeRegularUbuntu"];
				
			case PKGFilePathTypeRelativeToReferenceFolder:
				
				return [NSImage imageNamed:@"ReferenceFolderRegularUbuntu"];
				
			case PKGFilePathTypeMixed:
				
				return [NSImage imageNamed:@"MixedRegularUbuntu"];
				
			default:
				
				return nil;
		}
	}
	
	if (inControlSize==WBControlSizeSmall)
	{
		switch(inPathType)
		{
			case PKGFilePathTypeAbsolute:
				
				return [NSImage imageNamed:@"AbsoluteSmallUbuntu"];
				
			case PKGFilePathTypeRelativeToProject:
				
				return [NSImage imageNamed:@"RelativeSmallUbuntu"];
				
			case PKGFilePathTypeRelativeToReferenceFolder:
				
				return [NSImage imageNamed:@"ReferenceFolderSmallUbuntu"];
				
			case PKGFilePathTypeMixed:
				
				return [NSImage imageNamed:@"MixedSmallUbuntu"];
				
			default:
				
				return nil;
		}
	}
	
	return nil;
}

- (id)initWithCoder:(NSCoder *)inCoder
{
	self=[super initWithCoder:inCoder];
	
	if (self!=nil)
	{
		self.menu=[PKGFilePathTypeMenu menuForAction:self.action target:self.target controlSize:self.controlSize];
	}
	
	return self;
}

- (void)drawWithFrame:(NSRect)inFrame inView:(NSControl *)inControlView
{
	[self drawBorderAndBackgroundWithFrame:inFrame inView:inControlView];
	
	NSMenuItem * tMenuItem=[self selectedItem];
	
	if (tMenuItem==nil)
		return;
	
	// Draw the Path Type icon

	NSImage * tReferenceIcon=[PKGReferencePopupButtonCell leftCapForReferenceStyle:[tMenuItem tag] controlSize:self.controlSize];
	NSRect tRect;
	tRect.origin=NSMakePoint(NSMinX(inFrame)+2.0,NSMinY(inFrame)+((self.controlSize==WBControlSizeRegular) ? 2.0 : 1.0));   // A VOIR (Big Sur issue)
	tRect.size=tReferenceIcon.size;
	
	[tReferenceIcon drawInRect:tRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:(self.isEnabled==YES) ? 1.0 : 0.5 respectFlipped:YES hints:nil];

	// Draw the menu item
	
	CGFloat tOffset=PKGReferencePopupButtonCellLeftOffset+8.0;
	
	tRect=[self titleRectForBounds:inFrame];
	
	tRect.origin.x=tOffset;
	
	[tMenuItem.title drawInRect:tRect withAttributes:@{NSFontAttributeName:self.font,
													   NSForegroundColorAttributeName:([tMenuItem isEnabled]==YES) ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]}];
}

@end
