/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGInstallationTypeCheckBox.h"

@implementation PKGInstallationTypeCheckBox

- (NSView *)hitTest:(NSPoint)aPoint
{
	return nil;
}

@end

@implementation PKGInstallationTypeCheckBoxCell

/*- (BOOL)trackMouse:(NSEvent *)inEvent inRect:(NSRect)inCellFrame ofView:(NSView *)inControlView untilMouseUp:(BOOL)flag
{
	return YES;
}*/

/*- (NSCellHitResult)hitTestForEvent:(NSEvent *)inEvent inRect:(NSRect)inFrame ofView:(NSView *)inView
{
	return NSCellHitContentArea;
}*/

#pragma mark -

- (void)drawImage:(NSImage *)inImage withFrame:(NSRect) inFrame inView:(NSView *)inView
{
	if (inImage==nil)
	{
		[super drawImage:inImage withFrame:inFrame inView:inView];
		
		return;
	}
	
	if (self.isInvisible==YES)
	{
		NSImage * tStrippedImage=[NSImage imageWithSize:inImage.size flipped:NO drawingHandler:^BOOL(NSRect bRect){
		
			NSImage * tImage=[NSImage imageNamed:@"Strip32Composite"];
			
			[tImage drawInRect:NSMakeRect(0.0,0.0,13.0,17.0) fromRect:NSMakeRect(0.0,0.0,13.0,17.0) operation:WBCompositingOperationSourceOver fraction:1.0];
			
			[inImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:WBCompositingOperationSourceIn fraction:1.0];
			
			if (self.isDependent==YES)
			{
				// Draw the small gear
				
				tImage=[NSImage imageNamed:@"NSSmartBadgeTemplate"];
				
				[tImage drawInRect:NSMakeRect(1.5,3,10,10) fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
			}
			
			return YES;
		}];
								  
		[super drawImage:tStrippedImage withFrame:inFrame inView:inView];
		
		return;
	}
	
	[super drawImage:inImage withFrame:inFrame inView:inView];
	
	if (self.isDependent==YES)
	{
		// Draw the small gear
		
		NSImage * tImage=[NSImage imageNamed:@"NSSmartBadgeTemplate"];
				
		NSSize tSize=tImage.size;
		
		[tImage drawInRect:NSMakeRect(NSMinX(inFrame)+3.5,round(NSMidY(inFrame)-tSize.height*0.5)+2,10,10) fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
	}
}

- (NSRect)drawTitle:(NSAttributedString *)inAttributedString withFrame:(NSRect)inFrame inView:(NSView*)inView
{
	//inFrame.origin.y-=1.0;
	
	if (self.invisible==NO)
		return [super drawTitle:inAttributedString withFrame:inFrame inView:inView];
	
	NSMutableAttributedString * tMutableAttributedString=[[NSMutableAttributedString alloc] initWithAttributedString:inAttributedString];
	
	NSImage * tImage=(self.isEnabled==YES) ? [NSImage imageNamed:@"Strip32"] : [NSImage imageNamed:@"Strip32Disabled"];

	if (tImage==nil)
	{
		NSLog(@"Missing resources");
		
		return [super drawTitle:inAttributedString withFrame:inFrame inView:inView];
	}
	
	NSGraphicsContext * tGraphicContext= [NSGraphicsContext currentContext];
	
	[NSGraphicsContext saveGraphicsState];
	
	[tMutableAttributedString addAttribute:NSForegroundColorAttributeName 
									 value:[NSColor colorWithPatternImage:tImage] 
									 range:NSMakeRange(0,tMutableAttributedString.length)];
	
	[tGraphicContext setPatternPhase:NSMakePoint(0.0,[inView convertPoint:NSZeroPoint toView:nil].y)];
	
	NSRect tRect=[super drawTitle:tMutableAttributedString withFrame:inFrame inView:inView];

	[NSGraphicsContext restoreGraphicsState];

	return tRect;
}

@end
