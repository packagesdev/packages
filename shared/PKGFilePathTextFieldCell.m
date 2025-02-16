/*
Copyright (c) 2004-2016, StŽphane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGFilePathTextFieldCell.h"

#import "PKGFilePathTypeMenu.h"

@interface PKGFilePathTextFieldCell ()

- (void)convertCellFrame:(NSRect)inCellFrame toImageFrame:(NSRect *)outImageFrame textFrame:(NSRect *)outTextFrame;

@end

@implementation PKGFilePathTextFieldCell

- (void)convertCellFrame:(NSRect)inCellFrame toImageFrame:(NSRect *)outImageFrame textFrame:(NSRect *)outTextFrame
{
	NSRect tTextFrame, tImageFrame;
	
	NSDivideRect (inCellFrame, &tImageFrame, &tTextFrame, [PKGFilePathTypeMenu sizeOfPullDownImageForControlSize:self.controlSize].width, NSMinXEdge);
	
	if (outImageFrame!=NULL)
		*outImageFrame=tImageFrame;
	
	if (outTextFrame!=NULL)
		*outTextFrame=tTextFrame;
}

- (NSSize) cellSize
{
	NSSize cellSize = [super cellSize];
	
	cellSize.width += [PKGFilePathTypeMenu sizeOfPullDownImageForControlSize:self.controlSize].width;
	
	return cellSize;
}

#pragma mark -

- (void)editWithFrame:(NSRect) inCellFrame inView:(NSView *) inControlView editor:(NSText *) inEditor delegate:(id) inDelegate event:(NSEvent *) inEvent
{
    NSRect tTextFrame;
    
	[self convertCellFrame:inCellFrame toImageFrame:NULL textFrame:&tTextFrame];
	
    [super editWithFrame: tTextFrame
                  inView: inControlView
                  editor: inEditor
                delegate: inDelegate
                   event: inEvent];
}

- (void)selectWithFrame:(NSRect) inCellFrame inView:(NSView *) inControlView editor:(NSText *) inEditor delegate:(id) inDelegate start:(NSInteger) inStart length:(NSInteger) inLength
{
	NSRect tTextFrame;
	
	[self convertCellFrame:inCellFrame toImageFrame:NULL textFrame:&tTextFrame];
	
    [super selectWithFrame: tTextFrame
                    inView: inControlView
                    editor: inEditor
                  delegate: inDelegate
                     start: inStart
                    length: inLength];
}

- (BOOL)trackMouse:(NSEvent *)inEvent inRect:(NSRect)inCellFrame ofView:(NSView *)inControlView untilMouseUp:(BOOL)flag
{
	if (inEvent.type==WBEventTypeLeftMouseDown)
	{
		// Check where the even occur
	
		NSRect tImageFrame;
		
		[self convertCellFrame:inCellFrame toImageFrame:&tImageFrame textFrame:NULL];
		
		if (NSPointInRect([inControlView convertPoint:inEvent.locationInWindow fromView:nil], tImageFrame)==YES)
		{
			// Pop up the menu
		
			NSMenu * tMenu=[PKGFilePathTypeMenu menuForAction:@selector(switchPathType:) target:inControlView controlSize:self.controlSize];
		
			tMenu.font=self.font;
		
			NSMenuItem * tMenuItem=[tMenu itemWithTag:self.pathType];
		
			tMenuItem.state=WBControlStateValueOn;
		
			[tMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0., NSMaxY(inCellFrame)+4.) inView:inControlView];
			
			return NO;
		}
	}
	
	return [super trackMouse:inEvent inRect:inCellFrame ofView:inControlView untilMouseUp:flag];
}

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10)
- (NSCellHitResult)hitTestForEvent:(NSEvent *)inEvent inRect:(NSRect)inCellFrame ofView:(NSView *)inControlView
#else
- (NSUInteger)hitTestForEvent:(NSEvent *)inEvent inRect:(NSRect)inCellFrame ofView:(NSView *)inControlView
#endif
{
    NSRect tTextFrame;
    
    [self convertCellFrame:inCellFrame toImageFrame:NULL textFrame:&tTextFrame];
    
    return [super hitTestForEvent:inEvent inRect:inCellFrame ofView:inControlView];
}

#pragma mark -

- (void)drawInteriorWithFrame:(NSRect) inCellFrame inView:(NSView *) inControlView
{
	NSRect tTextFrame,tImageFrame;
	
	[self convertCellFrame:inCellFrame toImageFrame:&tImageFrame textFrame:&tTextFrame];
	
	// Draw the text
	
    NSColor * savedColor=self.textColor;
    
	if (self.fileNotFound==YES)
	{
        self.textColor=[NSColor redColor];
	}
	
	[super drawInteriorWithFrame:tTextFrame inView: inControlView];
	
	if (self.fileNotFound==YES)
	{
        self.textColor=savedColor;
	}
	
	// Draw the popup menu icon
	
	NSImage * tImage=[PKGFilePathTypeMenu pullDownImageForPathType:self.pathType controlSize:self.controlSize];
	
	switch(self.controlSize)
	{
		case WBControlSizeRegular:
			
			tImageFrame.size=tImage.size;
			tImageFrame.origin.x+=1.;
			tImageFrame.origin.y=round(NSMidY(tImageFrame)-NSHeight(tImageFrame)*0.5)+1.;
			
			[tImage drawInRect:tImageFrame fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1 respectFlipped:YES hints:nil];
			
			break;
		
		case WBControlSizeSmall:
		case WBControlSizeMini:
			
			NSLog(@"Control Size not supported");
			
			break;
			
		default:
			
			break;
	}
}

- (void)resetCursorRect:(NSRect)inCellFrame inView:(NSView *)inControlView
{
	NSRect tTextFrame,tImageFrame;
	
	[self convertCellFrame:inCellFrame toImageFrame:&tImageFrame textFrame:&tTextFrame];
	
	[inControlView addCursorRect:tImageFrame
						  cursor:[NSCursor arrowCursor]];
	
	[inControlView addCursorRect:tTextFrame
						  cursor:[NSCursor IBeamCursor]];
}

@end
