/*
Copyright (c) 2007-2017, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGReferencedPopUpButton.h"

#import "PKGFilePathTypeMenu.h"

#import "PKGReferencedPopUpButtonCell.h"

#import "NSObject+Conformance.h"

NSString * const PKGReferencedPopUpButtonReferenceStyleDidChangeNotification=@"PKGReferencedPopUpButtonReferenceStyleDidChangeNotification";

@interface PKGReferencedPopUpButton ()
{
	NSPopUpButtonCell * _referencePopUpButtonCell;
}

- (IBAction)takeReferenceStyle:(id)sender;

@end

@implementation PKGReferencedPopUpButton

+ (Class) cellClass
{
    return [PKGReferencedPopUpButtonCell class];
}

+ (void)setCellClass:(Class) inClass
{
}

#pragma mark -

- (void)setDelegate:(id) inDelegate
{
	if (_delegate==inDelegate)
		return;
	
	if ([inDelegate WB_doesReallyConformToProtocol:@protocol(PKGReferencedPopUpButtonDelegate)]==NO)
		return;
	
	_delegate=inDelegate;
}

- (void)setFileNotFound:(BOOL)inFileNotFound
{
	[[self cell] setFileNotFound:inFileNotFound];
	
	[super setNeedsDisplay:YES];
}

- (void)setEnabled:(BOOL)inEnabled
{
	[[self cell] setEnabled:inEnabled];

	_referencePopUpButtonCell.enabled=inEnabled;
}

- (PKGFilePathType)pathType
{
    return [[self cell] pathType];
}

- (void)setPathType:(PKGFilePathType)inPathType
{
	if (inPathType==[self pathType])
		return;
	
	[[self cell] setPathType:inPathType];

	[_referencePopUpButtonCell selectItemWithTag:inPathType];

	[super setNeedsDisplay:YES];
}

- (void)setFileNameWithPath:(NSString *)inFilePath
{
	NSMenuItem * tMenuItem=[self itemAtIndex:0];
		
	tMenuItem.title=(inFilePath==nil) ? @"-" : inFilePath.lastPathComponent;
}

- (void)mouseDown:(NSEvent *)inEvent
{
	NSPoint tMouseLoc=[self convertPoint:[inEvent locationInWindow] fromView:nil];
	
	NSRect tBounds=[self bounds];
	
	tBounds.size.width=PKGReferencedPopUpButtonCellLeftOffset+4.0;
	
	if (NSMouseInRect(tMouseLoc,tBounds,[self isFlipped])==YES)
	{
		tBounds.origin.x-=6.0;
		
		[_referencePopUpButtonCell trackMouse:inEvent inRect:tBounds ofView:self untilMouseUp:YES];
	}
	else
	{
		[super mouseDown:inEvent];
	}
}

#pragma mark -

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if (_delegate==nil)
		return NSDragOperationNone;
	
	if (self.isEnabled==NO)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard = [sender draggingPasteboard];

	if ([tPasteBoard.types containsObject:NSFilenamesPboardType]==NO)
		return NSDragOperationNone;

	NSDragOperation tSourceDragMask = [sender draggingSourceOperationMask];
	
	if ((tSourceDragMask & NSDragOperationCopy) == 0)
		return NSDragOperationNone;

	NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];

	if (tFiles.count!=1)
		return NSDragOperationNone;

	NSString * tFilePath=tFiles[0];
	
	if ([self.delegate referencedPopUpButton:self validateDropFile:tFilePath]==NO)
		return NSDragOperationNone;

	[self setNeedsDisplay:YES];

	return NSDragOperationCopy;
}

- (BOOL)wantsPeriodicDraggingUpdates
{
	return NO;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [self draggingEntered:sender];
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
    if (self.delegate==nil)
		return NO;
	
	NSPasteboard * tPasteBoard = [sender draggingPasteboard];

	if ( [tPasteBoard.types containsObject:NSFilenamesPboardType]==NO)
		return NO;
	
	NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
	
	if (tFiles.count!=1)
		return NO;
	
	[self.delegate referencedPopUpButton:self acceptDropFile:tFiles[0]];
	
	return YES;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	[self setNeedsDisplay:YES];
    
    return YES;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    [self setNeedsDisplay:YES];
}

#pragma mark -

- (IBAction)takeReferenceStyle:(NSMenuItem *)sender
{
	NSInteger tTag=sender.tag;
	
    if (self.pathType==tTag)
		return;

	self.pathType=tTag;
	
	if (self.delegate!=nil)
		[self.delegate referencedPopUpButtonReferenceStyleDidChange:[NSNotification notificationWithName:PKGReferencedPopUpButtonReferenceStyleDidChangeNotification object:self]];
}

#pragma mark -

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];
	
	if (self==nil)
		return nil;
	
	PKGReferencedPopUpButtonCell * tCell=self.cell;
		
	tCell.pathType=PKGFilePathTypeAbsolute;

	
	_referencePopUpButtonCell=[[NSPopUpButtonCell alloc] initTextCell:@""];
	
	_referencePopUpButtonCell.controlSize=tCell.controlSize;
	
	_referencePopUpButtonCell.font=tCell.font;
	
	_referencePopUpButtonCell.bordered=NO;
	
	_referencePopUpButtonCell.menu=[PKGFilePathTypeMenu menuForAction:@selector(takeReferenceStyle:) target:self controlSize:tCell.controlSize];
	
	[_referencePopUpButtonCell selectItemWithTag:PKGFilePathTypeAbsolute];
	
    return self;
}

@end
