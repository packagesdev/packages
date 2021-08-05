/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ICLineJumperWindowController.h"

@interface ICLineNumberFormatter : NSFormatter

@end

@implementation ICLineNumberFormatter

- (NSString *)stringForObjectValue:(id) inObject
{
    if ([inObject isKindOfClass:NSString.class]==NO)
        return inObject;
    
    return inObject;
}

- (BOOL)getObjectValue:(id *) outObject forString:(NSString *) inString errorDescription:(NSString **) outError
{
    *outObject=[inString copy];
    
    return YES;
}

#pragma mark -

- (BOOL)isPartialStringValid:(NSString *) inPartialString newEditingString:(NSString **) outNewString errorDescription:(NSString **) outError
{
    if (inPartialString==nil)
        return YES;
    
    NSUInteger tLength=inPartialString.length;
    
    if (tLength==0)
        return YES;
    
    if (tLength>10)
    {
        *outNewString=nil;
        
        *outError=@"NSBeep";
        
        return NO;
    }
    
    static NSCharacterSet * sForbidddenCharacterSet=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sForbidddenCharacterSet=[[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    });
    
    if ([inPartialString rangeOfCharacterFromSet:sForbidddenCharacterSet].location!=NSNotFound)
    {
        *outNewString=nil;
        
        *outError=@"NSBeep";
        
        return NO;
    }
    
    return YES;
}

@end


@interface ICLineJumperWindowController () <NSTextFieldDelegate>
{
    IBOutlet NSTextField * _lineNumberField;
    
    IBOutlet NSButton * _resetButton;
    
    NSTextView * _targetedTextView;
}

- (IBAction)takeLineNumberFrom:(id)sender;

- (IBAction)reset:(id)sender;

@end

@implementation ICLineJumperWindowController

+ (ICLineJumperWindowController *)sharedLineJumperWindowController
{
    static ICLineJumperWindowController * sLineJumperWindowController=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sLineJumperWindowController=[ICLineJumperWindowController new];
        
    });
    
    return sLineJumperWindowController;
}

#pragma mark -

- (NSString *)windowNibName
{
    return @"ICLineJumperWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];


	
    self.window.movableByWindowBackground=YES;
	
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10)
	self.window.titlebarAppearsTransparent=YES;
#endif
    _lineNumberField.formatter=[ICLineNumberFormatter new];
}

#pragma mark -

- (void)popUpForTextView:(NSTextView *)inTextView
{
    if (inTextView==nil)
        return;
    
    _targetedTextView=inTextView;
    
    _lineNumberField.stringValue=@"";
    
    [self showWindow:self];
}

- (void)_abortEditing
{
    [_lineNumberField abortEditing];
    
    _lineNumberField.stringValue=@"";
    
    [self.window close];
}

#pragma mark -

- (IBAction)cancel:(id)sender
{
    [self _abortEditing];
}

- (IBAction)takeLineNumberFrom:(NSTextField *)sender
{
    NSString * tString=sender.stringValue;
    
    if (tString.length==0)
    {
        NSBeep();
        
        return;
    }
    
    NSInteger tLineNumberToJumpTo=tString.integerValue;
    
    if (tLineNumberToJumpTo<=0)
    {
        NSBeep();
        return;
    }
    
    NSLayoutManager * tLayoutManager = _targetedTextView.layoutManager;
    
    NSUInteger tNumberOfGlyphs = tLayoutManager.numberOfGlyphs;
    
    NSUInteger tGlyphIndex = 0;
    
    for (NSUInteger tLineNumber = 1; tGlyphIndex < tNumberOfGlyphs; tLineNumber++)
    {
        NSRange tLineRange;
        
        [tLayoutManager lineFragmentRectForGlyphAtIndex:tGlyphIndex effectiveRange:&tLineRange];
        
        if (tLineNumber == tLineNumberToJumpTo)
        {
            // Scroll to line
            
            NSRect tBounds=[_targetedTextView.layoutManager boundingRectForGlyphRange:tLineRange inTextContainer:_targetedTextView.textContainer];
            
            tBounds.origin.x=0;
            
            [_targetedTextView scrollPoint:tBounds.origin];
            
            // Select line
            
            [_targetedTextView setSelectedRange:tLineRange];
            
            // Hide # Line Number window and set the focus on the text view
            
            [self.window orderOut:nil];
            
            [_targetedTextView.window makeFirstResponder:_targetedTextView];
            
            return;
        }
        
        tGlyphIndex = NSMaxRange(tLineRange);
    }
    
    // Line not found (tLineNumberToJumpTo > number of lines)
    
    NSBeep();
}

- (IBAction)reset:(id)sender
{
    _lineNumberField.currentEditor.string=@"";
    
    _resetButton.hidden=YES;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)inNotification
{
    NSText * tFieldEditor=inNotification.userInfo[@"NSFieldEditor"];
    
    NSString * tString=tFieldEditor.string;
    
    _resetButton.hidden=(tString.length==0);
}

- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(nullable NSString *)error
{
    NSBeep();
}

#pragma mark - NSWindowDelegate

- (void)windowDidResignMain:(NSNotification *)notification
{
    [self _abortEditing];
}

@end
