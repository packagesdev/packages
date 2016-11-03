/*
Copyright (c) 2004-2016, Stéphane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGFilePathTextField.h"

#import "PKGFilePathTextFieldCell.h"

@interface PKGFilePathTextField ()

-(IBAction)switchPathType:(id)sender;

-(void)_setCellStringValue:(NSString *)inString;

@end

@implementation PKGFilePathTextField

+ (Class) cellClass
{
    return [PKGFilePathTextFieldCell class];
}

+ (void) setCellClass:(Class) inClass
{
}

- (id)initWithCoder:(NSCoder *)coder
{
    self=[super initWithCoder:coder];
    
    if (self!=nil)
    {
        _filePath=[PKGFilePath filePath];
		
		[self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
	
    return self;
}

#pragma mark -

- (BOOL) isOpaque
{
	return NO;
}

#pragma mark -

- (void)setFilePath:(PKGFilePath *)inFilePath
{
	_filePath=[inFilePath copy];
	
	[self.cell setPathType:_filePath.type];
	
	[self _setCellStringValue:_filePath.string];
}

- (void)setStringValue:(NSString *)inStringValue
{
	NSLog(@"Use setFilePath: instead");
}

- (void)setAttributedStringValue:(NSAttributedString *)inAttributedStringValue
{
	NSLog(@"Use setFilePath: instead");
}

- (void)_setCellStringValue:(NSString *)inString
{
	((PKGFilePathTextFieldCell *)self.cell).fileNotFound=NO;
	
	NSString * tStringValue=self.filePath.string;
	
	[self.cell setStringValue:(tStringValue!=nil)? tStringValue :@""];
	
	if (self.skipExistenceCheck==NO)
	{
		if (self.pathConverter==nil)
		{
			NSLog(@"The Path converter has not been set");
			return;
		}
		
		NSFileManager * tFileManager=[NSFileManager defaultManager];
		
		NSString * tAbsolutePath=[self.pathConverter absolutePathForFilePath:self.filePath];
		
		if ([tFileManager fileExistsAtPath:tAbsolutePath]==NO)
		{
			((PKGFilePathTextFieldCell *)self.cell).fileNotFound=YES;
			
			[self updateCell:self.cell];
		}
	}
}

#pragma mark -

-(IBAction)switchPathType:(id)sender
{
	PKGFilePathType tPathType=[sender tag];
	
	if (tPathType!=self.filePath.type)
	{
		if (self.pathConverter==nil)
		{
			NSLog(@"The Path converter has not been set");
			return;
		}
		
		PKGFilePath * tPathToConvert=self.filePath;
		
		if ([self.pathConverter shiftTypeOfFilePath:tPathToConvert toType:tPathType]==YES)
		{
			self.filePath=tPathToConvert;
			
			[[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidChangeNotification
																object:self
															  userInfo:nil];
			
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			
			[[self target] performSelector:[self action]
								withObject:self];
			
#pragma clang diagnostic pop
		}
		else
		{
			// A COMPLETER
		}
	}
}

#pragma mark - Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if (self.delegate==nil)
		return [super draggingEntered:sender];
	
	if ([self.delegate conformsToProtocol:@protocol(PKGFilePathTextFieldDelegate)]==YES)
	{
		NSPasteboard *tPasteBoard=[sender draggingPasteboard];
		
		if ([tPasteBoard.types containsObject:NSFilenamesPboardType]==YES)
		{
			NSDragOperation sourceDragMask= [sender draggingSourceOperationMask];
			
			if ((sourceDragMask & NSDragOperationCopy)==NSDragOperationCopy)
			{
				NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
				
				if ([tFiles count]==1)
				{
					id<PKGFilePathTextFieldDelegate> tDelegate=(id<PKGFilePathTextFieldDelegate>)self.delegate;
						
					if ([tDelegate filePathTextField:self shouldAcceptFile:tFiles[0]]==YES)
						return NSDragOperationCopy;
				}
			}
		}
	}
	
	return [super draggingEntered:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (self.delegate==nil)
		return [super performDragOperation:sender];
	
	NSPasteboard *tPasteBoard= [sender draggingPasteboard];
	
	if ([tPasteBoard.types containsObject:NSFilenamesPboardType]==YES)
	{
		NSArray *tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if ([tFiles count]==1)
		{
			if (self.pathConverter==nil)
			{
				NSLog(@"The Path converter has not been set");
				return NO;
			}
			
			PKGFilePath * tFilePath=[self.pathConverter filePathForAbsolutePath:tFiles[0] type:self.filePath.type];
			
			if (tFilePath!=nil)
			{
				self.filePath=tFilePath;
				
				[[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidChangeNotification
																	object:self
																  userInfo:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				
				[[self target] performSelector:[self action]
									withObject:self];
				
#pragma clang diagnostic pop
				
				return YES;
			}
		}
	}
	
	return [super performDragOperation:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	[super prepareForDragOperation:sender];
	
	return YES;
}

#pragma mark - Notifications

- (void)textDidEndEditing:(NSNotification *)notification
{
	self.filePath.string=[[self cell] stringValue];
	
	[self _setCellStringValue:self.filePath.string];
	
    [super textDidEndEditing:notification];
}

@end
