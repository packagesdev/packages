/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPresentationImageView.h"

@interface PKGPresentationImageView ()
{
    BOOL _highlighted;
}

@end

@implementation PKGPresentationImageView

- (void)drawRect:(NSRect)inRect
{
	[super drawRect:inRect];
	
	if (_highlighted==YES)
	{
		NSBezierPath * tPath=[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds,2.0,2.0) xRadius:8.0 yRadius:8.0];
        tPath.lineWidth=3.0;
        
        [[NSColor alternateSelectedControlColor] setStroke];
        
        [tPath stroke];
	}
}

#pragma mark - NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if (self.presentationDelegate==nil)
		return NSDragOperationNone;
	
	NSDragOperation tOperation=[self.presentationDelegate presentationImageView:self validateDrop:sender];
	
	if (tOperation!=NSDragOperationNone)
	{
		_highlighted=YES;
		
		[self setNeedsDisplay:YES];
	}
	
	return tOperation;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (self.presentationDelegate==nil)
		return NO;
	
	return [self.presentationDelegate presentationImageView:self acceptDrop:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	_highlighted=NO;
	
    [self setNeedsDisplay:YES];
    
    return YES;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    _highlighted=NO;
	
    [self setNeedsDisplay:YES];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}

@end
