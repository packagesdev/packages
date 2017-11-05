/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLocationTextField.h"

@implementation PKGLocationTextField

- (id)initWithCoder:(NSCoder *)coder
{
	self=[super initWithCoder:coder];
	
	if (self!=nil)
	{
		[self registerForDraggedTypes:@[NSFilenamesPboardType,NSStringPboardType]];
	}
	
	return self;
}

#pragma mark - Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if (self.delegate==nil || [self.delegate conformsToProtocol:@protocol(PKGLocationTextFieldDelegate)]==NO)
		return [super draggingEntered:sender];
	
	id<PKGLocationTextFieldDelegate> tDelegate=(id<PKGLocationTextFieldDelegate>)self.delegate;
	
	if ([tDelegate locationTextField:self validateDrop:sender]==YES)
		return NSDragOperationCopy;
	
	return [super draggingEntered:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (self.delegate==nil)
		return [super performDragOperation:sender];
	
	id<PKGLocationTextFieldDelegate> tDelegate=(id<PKGLocationTextFieldDelegate>)self.delegate;
	
	if ([tDelegate locationTextField:self acceptDrop:sender]==YES)
		return YES;
	
	return [super performDragOperation:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	[super prepareForDragOperation:sender];
	
	return YES;
}

@end
