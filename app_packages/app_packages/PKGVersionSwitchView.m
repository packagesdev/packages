/*
Copyright (c) 2004-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGVersionSwitchView.h"

@interface PKGVersionSwitchView ()
{
	NSDictionary * _attributes;
	
	BOOL _isPushed;
	BOOL _state;
}

@end

@implementation PKGVersionSwitchView

- (instancetype)initWithFrame:(NSRect) aFrame
{
    self=[super initWithFrame:aFrame];
    
    if (self!=nil)
    {
		_attributes=@{NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:0.498f alpha:1.0f],
					  NSFontAttributeName:[NSFont systemFontOfSize:13.0f]};
    }
    
    return self;
}

#pragma mark -

- (void)drawRect:(NSRect)rect
{
    NSString * tString=self.title;
	
    if ((_state==YES && _isPushed==NO) ||
        (_state==NO && _isPushed==YES))
    {
        tString=self.alternateTitle;
    }
    
    if (tString!=nil)
    {
        NSSize tSize=[tString sizeWithAttributes:_attributes];
        
        if (tSize.width>0 && tSize.height>0)
        {
            NSPoint tPoint;
            
            tPoint.x=0.0f;
            tPoint.y=(NSHeight([self bounds])-tSize.height)*0.5f;
            
            // Draw String
            
            [tString drawAtPoint:tPoint withAttributes:_attributes];
        }
    }
}

#pragma mark -

- (void)mouseDown:(NSEvent *)theEvent
{
    _isPushed=YES;
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint tMouseLoc=[self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect tBounds=[self bounds];
    
    if (NSMouseInRect(tMouseLoc,tBounds,[self isFlipped])==YES)
    {
        if (_isPushed==NO)
        {
            _isPushed=YES;
            
            [self setNeedsDisplay:YES];
        }
    }
    else
    {
        if (_isPushed==YES)
        {
            _isPushed=NO;
            
            [self setNeedsDisplay:YES];
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint tMouseLoc=[self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect tBounds=[self bounds];
    
    _isPushed=NO;
    
    if (NSMouseInRect(tMouseLoc,tBounds,[self isFlipped])==YES)
    {
        _state=!_state;
        
        [self setNeedsDisplay:YES];
    }
}

@end
