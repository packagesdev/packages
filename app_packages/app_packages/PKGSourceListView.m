/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGSourceListView.h"

#import "PKGHighlightWindow.h"

@interface PKGSourceListView ()
{
	PKGHighlightWindow * _highlightWindow;
}

- (void)setHighlighted:(BOOL)inHighlighted;

@end

@implementation PKGSourceListView

- (NSMenu *)menuForEvent:(NSEvent *)inEvent
{
	if (inEvent.type==WBEventTypeRightMouseDown)
	{
		NSPoint tPoint=[self convertPoint:inEvent.locationInWindow fromView:nil];
		
		NSInteger tClickedRow=[self rowAtPoint:tPoint];
		
		if (tClickedRow==-1)
			return nil;
		
		id tItem=[self itemAtRow:tClickedRow];
			
		if ([self.delegate outlineView:self isGroupItem:tItem]==YES)
			return nil;
	}
	
	return [super menuForEvent:inEvent];
}

#pragma mark -

- (void)setHighlighted:(BOOL)inHighlighted
{
	if (inHighlighted==YES && _highlightWindow==nil)
	{
		_highlightWindow=[[PKGHighlightWindow alloc] initForView:self];
		
		if (_highlightWindow!=nil)
		{
			[self.window addChildWindow:_highlightWindow ordered:NSWindowAbove];
			
			[_highlightWindow orderFront:self];
		}
		
		return;
	}
	
	if (inHighlighted==NO && _highlightWindow!=nil)
	{
		[self.window removeChildWindow:_highlightWindow];
		
		[_highlightWindow orderOut:self];
		
		_highlightWindow=nil;
	}
}

#pragma mark - Overridden Private Method

- (BOOL)_shouldDoDragUpdateOfViewBasedRowData
{
	return NO;
}

#pragma mark -

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSDragOperation tDragOperation=[super draggingEntered:sender];
	
	if (tDragOperation!=NSDragOperationNone)
		[self setHighlighted:YES];
	
	return tDragOperation;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	[self setHighlighted:NO];
	
	return [super performDragOperation:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[self setHighlighted:NO];
	
	[super draggingExited:sender];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	[self setHighlighted:NO];
}

@end
