/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WBVersionPicker.h"

@interface WBVersionPickerCell (WB_Private)

- (void)endEditingSelectedElement;

- (void)selectFirstElement;
- (void)selectLastElement;

@end

@interface NSView (AppKit_Non_Public_APIs)

- (BOOL)_automaticFocusRingDisabled;

@end

@implementation WBVersionPicker

+ (void)initialize
{
	if (self==WBVersionPicker.class)
		[self setCellClass:WBVersionPickerCell.class];
}

- (instancetype)initWithFrame:(NSRect)inFrame
{
	self=[super initWithFrame:inFrame];
	
	if (self!=nil)
	{
		[[self cell] setBezeled:YES];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)inCoder
{
	self=[super initWithCoder:inCoder];
	
	if (self!=nil)
	{
		[[self cell] setBezeled:YES];
	}
	
	return self;
}

#pragma mark -

- (WBVersionsHistory *)versionsHistory
{
	return [[self cell] versionsHistory];
}

- (void)setVersionsHistory:(WBVersionsHistory *)inVersionsHistory
{
	[[self cell] setVersionsHistory:inVersionsHistory];
}

- (WBVersion *)minVersion
{
	return [[self cell] minVersion];
}

- (void)setMinVersion:(WBVersion *)inMinVersion
{
	[[self cell] setMinVersion:inMinVersion];
}

- (WBVersion *)maxVersion
{
	return [[self cell] maxVersion];
}

- (void)setMaxVersion:(WBVersion *)inMaxVersion
{
	[[self cell] setMaxVersion:inMaxVersion];
}

- (WBVersion *)versionValue
{
	return [[self cell] versionValue];
}

- (void)setVersionValue:(WBVersion *)inVersionValue
{
	[[self cell] setVersionValue:inVersionValue];
}


- (BOOL)isOpaque
{
	return NO;
}

- (BOOL)isBezeled
{
	return [[self cell] isBezeled];
}

- (void)setBezeled:(BOOL)inBezeled
{
	[[self cell] setBezeled:inBezeled];
}

- (BOOL)isBordered
{
	return [[self cell] isBordered];
}

- (void)setBordered:(BOOL)inBordered
{
	[[self cell] setBordered:inBordered];
}

- (NSColor *)textColor
{
	return [[self cell] textColor];
}

- (void)setTextColor:(NSColor *)inTextColor
{
	[[self cell] setTextColor:inTextColor];
}

- (NSColor *)backgroundColor
{
	return [[self cell] backgroundColor];
}

- (void)setBackgroundColor:(NSColor *)inBackgroundColor
{
	[[self cell] setBackgroundColor:inBackgroundColor];
}

- (BOOL)drawsBackground
{
	return [[self cell] drawsBackground];
}

- (void)setDrawsBackground:(BOOL)inDrawsBackground
{
	[[self cell] setDrawsBackground:inDrawsBackground];
}

- (WBVersionPickerStyle)versionPickerStyle
{
	return [[self cell] versionPickerStyle];
}

- (void)setVersionPickerStyle:(WBVersionPickerStyle)inVersionPickerStyle
{
	[[self cell] setVersionPickerStyle:inVersionPickerStyle];
}

- (id<WBVersionPickerCellDelegate>)delegate
{
	return ((id<WBVersionPickerCellDelegate>)[[self cell] delegate]);
}

- (void)setDelegate:(id<WBVersionPickerCellDelegate>)inDelegate
{
	[[self cell] setDelegate:inDelegate];
}

#pragma mark - First Responder

- (BOOL)needsPanelToBecomeKey
{
	return [self acceptsFirstResponder];	// Follow NSView behavior (NSControl behavior checks whether the cell is selectable)
}

- (BOOL)acceptsFirstResponder
{
	return [self isEnabled];
}

- (BOOL)becomeFirstResponder
{
	if ([self _automaticFocusRingDisabled]==YES)
		[self setKeyboardFocusRingNeedsDisplayInRect:self.bounds];
	else
		[self setNeedsDisplay:YES];

	NSEvent * tCurrentEvent=[NSApp currentEvent];
	if (tCurrentEvent.type!=WBEventTypeKeyDown)
		return YES;
    
	NSString * tCharacters=tCurrentEvent.characters;
    
	if (tCharacters.length>0)
	{
		unichar tFirstCharacter=[tCharacters characterAtIndex:0];
    
		switch(tFirstCharacter)
		{
			case 0x09:	// Tab
				
				[[self cell] selectFirstElement];
				break;
				
			case 0x19:	// Back Tab
				
				[[self cell] selectLastElement];
				break;
		}
	}
	
    return YES;
}

- (BOOL)resignFirstResponder
{
	[[self cell] endEditingSelectedElement];
    
	if ([self _automaticFocusRingDisabled]==YES)
		[self setKeyboardFocusRingNeedsDisplayInRect:self.bounds];
	else
		[self setNeedsDisplay:YES];
    
	return YES;
}

@end
