/*
Copyright (c) 2007-2018, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGReferenceFolderPopupButtonCell.h"

@implementation PKGReferenceFolderPopupButtonCell

- (void)drawWithFrame:(NSRect)inFrame inView:(NSView *)inControlView
{
	[self drawBorderAndBackgroundWithFrame:inFrame inView:inControlView];
	
	// Draw the Path Type icon
	
	NSImage * tReferenceIcon=[NSImage imageNamed:@"ReferenceFolderRegularBackgroundUbuntu"];
	NSRect tRect={
		.origin=NSMakePoint(NSMinX(inFrame)+2.0,NSMinY(inFrame)+2.0),
		.size=tReferenceIcon.size
	};
	
	[tReferenceIcon drawInRect:tRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:(self.isEnabled==YES) ? 1.0 : 0.5 respectFlipped:YES hints:nil];
	
	// Draw the menu item
	
	NSMenuItem * tMenuItem=self.selectedItem;
	
	if (tMenuItem==nil)
		return;
	
	NSImage * tIcon=tMenuItem.image;
	
	CGFloat tOffset=8.0;
	
	if (tIcon!=nil)
	{
		NSRect tDestinationRect=NSMakeRect(NSMinX(inFrame)+tOffset,NSMinY(inFrame)+5.0,15.0,15.0);
		
		[tIcon drawInRect:tDestinationRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:(self.isEnabled==YES) ? 1.0 : 0.5 respectFlipped:YES hints:nil];
	}
	
	tRect=[self titleRectForBounds:inFrame];
	
	tRect.origin.x=33.0;

	tRect.size.width=NSMaxX(tRect)-NSMinX(tRect);
	
	[[tMenuItem title] drawInRect:tRect withAttributes:@{NSFontAttributeName:[self font],
														 NSForegroundColorAttributeName:[NSColor controlTextColor]}];
}

@end
