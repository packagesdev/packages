/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


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
	
	[tReferenceIcon drawInRect:tRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:(self.isEnabled==YES) ? 1.0 : 0.5 respectFlipped:YES hints:nil];
}

@end
