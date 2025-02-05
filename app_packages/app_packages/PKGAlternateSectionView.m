/*
 Copyright (c) 2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGAlternateSectionView.h"

@implementation PKGAlternateSectionView

- (BOOL)isOpaque
{
	return NO;
}

#pragma mark -

- (void)drawRect:(NSRect)inRect
{
	BOOL tIsDark=[self WB_isEffectiveAppearanceDarkAqua];
	
	if (tIsDark==NO)
		[[NSColor colorWithDeviceWhite:0.94 alpha:1.0] setFill];
	else
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.15] set];
	
	NSRectFillUsingOperation(inRect,WBCompositingOperationSourceOver);
	
	if (tIsDark==NO)
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.05] set];
	else
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.03] set];
	
	NSRect tFrameRect= NSInsetRect([self bounds],-1,1.0);
	
	NSFrameRectWithWidthUsingOperation(tFrameRect, 1.0, WBCompositingOperationSourceOver);
}

@end
