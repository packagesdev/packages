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

//#import "NSFileManager+fileTypes.h"

//#import "ICBackgroundUtilities.h"

#import <ApplicationServices/ApplicationServices.h>


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

#pragma mark -

/*- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard * tPasteBoard = [sender draggingPasteboard];

    if ([[tPasteBoard types] containsObject:NSFilenamesPboardType]==YES)
        return NSDragOperationNone;
    
    NSDragOperation sourceDragMask= [sender draggingSourceOperationMask];
    
    if ((sourceDragMask & NSDragOperationCopy)==0)
        return NSDragOperationNone;
    
    NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];

    if (tFiles.count!=1)
        return NSDragOperationNone;
    
    NSString * tFilePath=tFiles.lastObject;
    
    BOOL tImageFormatSupported=[[NSFileManager defaultManager] IC_fileAtPath:tFilePath matchesTypes:[ICBackgroundUtilities backgroundImageTypes]];
    
    if (tImageFormatSupported==NO)
    {
        NSURL * tURL = [NSURL fileURLWithPath:tFilePath];
        
        CGImageSourceRef tSourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef) tURL, NULL);
        
        if (tSourceRef!=NULL)
        {
            NSString * tImageUTI=(__bridge NSString *) CGImageSourceGetType(tSourceRef);
            
            if (tImageUTI!=nil)
                tImageFormatSupported=[[ICBackgroundUtilities backgroundImageUTIs] containsObject:tImageUTI];
            
            // Release Memory
            
            CFRelease(tSourceRef);
        }
    }
    
    if (tImageFormatSupported==NO)
        return NSDragOperationNone;
    
    _highlighted=YES;

    [self setNeedsDisplay:YES];

    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard * tPasteBoard= [sender draggingPasteboard];

    if ([[tPasteBoard types] containsObject:NSFilenamesPboardType]==NO)
        return NO;
    
    NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
    
    if (tFiles.count!=1)
        return NO;
    
    NSString * tFilePath=tFiles.lastObject;
    
    NSImage * tImage=[[NSImage alloc] initWithContentsOfFile:tFilePath];
    
    if (tImage!=nil)
    {
        [self.presentationDelegate presentationImageView:self imagePathDidChange:tFilePath];
        
        self.image=tImage;
        
        return YES;
    }
	
    return NO;
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
}*/

@end
