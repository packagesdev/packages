/*
Copyright (c) 2009-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*

Gutter code

Copyright (c) 2009, Todd Ditchendorf
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the Todd Ditchendorf nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ICSourceTextView.h"
#import "ICGutterView.h"

#import "ICLineJumperWindowController.h"

#import "NSRangeUtilities.h"

/*

<string>if</string>
                <string>else</string>
                <string>for</string>
                <string>in</string>
                <string>while</string>
                <string>do</string>
                <string>continue</string>
                <string>break</string>
                <string>with</string>
                <string>try</string>
                <string>catch</string>
                <string>switch</string>
                <string>case</string>
                <string>new</string>
                <string>var</string>
                <string>function</string>
                <string>return</string>
                <string>this</string>
                <string>delete</string>
                <string>true</string>
                <string>false</string>
                <string>void</string>
                <string>throw</string>
                <string>typeof</string>
                <string>const</string>
                <string>default</string>
*/

@interface ICSourceTextView ()
{
	IBOutlet ICGutterView * _gutterView;
	
	NSScrollView * _scrollView;
	
	// Data
	
	float sourceTextViewOffset;
	
	NSUInteger _numberOfSpaceForTab;
}

- (void) updateTabStyle;

- (void) renderGutter;

- (void) getRectsOfVisibleLines:(out NSArray **) outRects startingLineNumber:(out NSUInteger *) outStart;

- (NSUInteger) lineNumberForIndex:(NSUInteger) inIndex;

// Notification

- (void) viewBoundsDidChange:(NSNotification *) inNotification;

@end

@implementation ICSourceTextView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
	_numberOfSpaceForTab=4;
	
	_scrollView=[self enclosingScrollView];
	
	[_scrollView setHasHorizontalScroller:YES];
	
	[[self textContainer] setContainerSize:NSMakeSize(1.0e7, 1.0e7)];
	[[self textContainer] setWidthTracksTextView:NO];
    [[self textContainer] setHeightTracksTextView:NO];
	
	[self setMinSize:[self frame].size];
	
	[self setMaxSize:NSMakeSize(1.0e7, 1.0e7)];
	
	[self setHorizontallyResizable:YES];
	[self setHorizontallyResizable:YES];
    [self setVerticallyResizable:YES];
    [self setAutoresizingMask:NSViewNotSizable];
	
	[self setTextContainerInset:NSMakeSize(5.0f,0.0f)];
	
	self.automaticQuoteSubstitutionEnabled=NO;	// To avoid getting the very annoying typographic quotes
	
	[self renderGutter];
	
	[self updateTabStyle];
    
    [[_scrollView contentView] setPostsBoundsChangedNotifications:YES];
}

#pragma mark -

- (void)viewWillMoveToWindow:(NSWindow *)inWindow
{
	if (inWindow==nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(IC_textDidChange:)
													 name:NSTextDidChangeNotification
												   object:self];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(viewBoundsDidChange:)
													 name:NSViewBoundsDidChangeNotification
												   object:[_scrollView contentView]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(viewBoundsDidChange:)
													 name:NSWindowDidResizeNotification
												   object:[self window]];
	}
}

- (void)updateTabStyle
{
	NSMutableAttributedString * tMutableAttributedString=[self textStorage];
	
	if (tMutableAttributedString!=nil)
	{
		NSRange tRange;
		double tColumnWidth=0.;
		NSParagraphStyle * tParagraphStyle;
		
		NSDictionary * tAttributesDictionary=[NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName,nil];
		
		NSMutableString * tMutableString=[NSMutableString stringWithCapacity:_numberOfSpaceForTab];
		
		if (tMutableString!=nil)
		{
			for(NSUInteger i=0;i<_numberOfSpaceForTab;i++)
				[tMutableString appendString:@" "];
			
			tColumnWidth=[tMutableString sizeWithAttributes:tAttributesDictionary].width;
		}
		
		if ([tMutableAttributedString length]>0)
		{
			tParagraphStyle=[tMutableAttributedString attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:&tRange];
		}
		else
		{
			tParagraphStyle=[NSParagraphStyle defaultParagraphStyle];
		}
		
		if (tParagraphStyle!=nil)
		{
			NSMutableParagraphStyle * tMutableParagraphStyle=[tParagraphStyle mutableCopy];
			
			if (tMutableParagraphStyle!=nil)
			{
				NSUInteger tNumberOfTabs=500;
				
				NSMutableArray * tMutableArray=[[NSMutableArray alloc] initWithCapacity:tNumberOfTabs];
				
				if (tMutableArray!=nil)
				{
					for(NSUInteger tIndex=0;tIndex<tNumberOfTabs;tIndex++)
					{
						NSTextTab * tTextTab=[[NSTextTab alloc] initWithType:NSLeftTabStopType location:((double)tIndex+1) * tColumnWidth];
						
						[tMutableArray addObject:tTextTab];
					}
					
					[tMutableParagraphStyle setTabStops:tMutableArray];
				
					[self setDefaultParagraphStyle:tMutableParagraphStyle];
					
					if ([tMutableAttributedString length]>0)
						[tMutableAttributedString addAttribute:NSParagraphStyleAttributeName value:tMutableParagraphStyle
														 range:NSMakeRange(0,[tMutableString length])];
				}
			}
		}
	}
	
	[self didChangeText];
}

- (void) renderGutter
{
    NSArray * tArray;
	NSUInteger tStart;
    
    [self getRectsOfVisibleLines:&tArray startingLineNumber:&tStart];
	
    _gutterView.lineNumberRects=tArray;
	_gutterView.startLineNumber=tStart;
    
	[_gutterView setNeedsDisplay:YES];
}

- (void) getRectsOfVisibleLines:(out NSArray **) outRects startingLineNumber:(out NSUInteger *) outStart
{
	NSString * tString=[self string];
	NSLayoutManager * tLayoutManager=[[self textContainer] layoutManager];
	
	*outRects=nil;
	
	NSRect tBoundingRect = [[_scrollView contentView] documentVisibleRect];
	
    NSRange tVisibleGlyphRange = [tLayoutManager glyphRangeForBoundingRect:tBoundingRect inTextContainer:[self textContainer]];
	
	float tScrollY = NSMinY(tBoundingRect);
        
    NSUInteger tIndex = tVisibleGlyphRange.location;
    NSUInteger tLength = tIndex + tVisibleGlyphRange.length;

    (*outStart) = [self lineNumberForIndex:tIndex + 1];
	
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
    while (tIndex < tLength)
	{
        NSRange tRange=[tString lineRangeForRange:NSMakeRange(tIndex, 0)];
		
        tIndex = NSMaxRange(tRange);
        
		NSRect tRect = [tLayoutManager lineFragmentRectForGlyphAtIndex:tRange.location effectiveRange:NULL withoutAdditionalLayout:YES];
        
		tRect.origin.y -= tScrollY;
        
		[tMutableArray addObject:[NSValue valueWithRect:tRect]];
    }
    
    (*outRects) = [tMutableArray copy];
}


- (NSUInteger) lineNumberForIndex:(NSUInteger) inIndex
{
    NSString * tString=[self string];
	NSUInteger tLength=[tString length];
	
	NSUInteger tNumberOfLines=0;
    
    for (NSUInteger tIndex = 0; tIndex < tLength; tNumberOfLines++)
	{
        NSRange tRange= [tString lineRangeForRange:NSMakeRange(tIndex, 0)];
		
        tIndex = NSMaxRange(tRange);
        
		if (inIndex <= tIndex)
			break;
    }
    
    return tNumberOfLines;
}

- (NSIndexSet *) indexesOfLineStartsForRanges:(NSArray *) inRangesArray
{
	NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
	
	if (tIndexSet!=nil && inRangesArray!=nil)
	{
		NSString * tString=[[self textStorage] string];
	
		if (tString!=nil)
		{
			if ([tString length]>0)
			{
				for(NSValue * tValue in inRangesArray)
				{
					NSRange tRange=[tValue rangeValue];
					
					NSUInteger tIndex=tRange.location+tRange.length;
					
					if (tIndex>0)
					{
						tIndex=tIndex-1;
						
						while (1)
						{
							if ([tString characterAtIndex:tIndex]=='\n')
							{
								[tIndexSet addIndex:tIndex];
								
								if ((tIndex<tRange.location) || (tIndex==tRange.location && [tString characterAtIndex:tRange.location]!='\n'))
									break;
							}
							else
							{
								if (tIndex==0)
								{
									[tIndexSet addIndex:tIndex];
									
									break;
								}
							}
							
							tIndex--;
						}
					}
					else
					{
						[tIndexSet addIndex:0];
					}
				}
			}
			else
			{
				[tIndexSet addIndex:0];
			}
		}
	}
	
	return [tIndexSet copy];
}

#pragma mark -

- (void)changeFont:(id) sender
{	
	[super changeFont:sender];
	
	// Post Notification
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ICSourceTextViewFontDidChangeNotification
														object:self
													  userInfo:nil];
}

#pragma mark -

- (void)mouseDown:(NSEvent *) inEvent
{
	[super mouseDown:inEvent];
	
	if (([inEvent clickCount] == 2) && (([inEvent modifierFlags] & WBEventModifierFlagDeviceIndependentFlagsMask) == WBEventModifierFlagOption))
	{
		NSRange tSelectionRange=[self selectedRange];
		
		if (tSelectionRange.length>1)
		{
			NSString * tSelectedText=[[self string] substringWithRange:tSelectionRange];
			
			// Post Notification
			
			[[NSNotificationCenter defaultCenter] postNotificationName:ICSourceTextViewWillShowKeywordDocumentationNotification
																object:self
															  userInfo:@{ICSourceTextViewKeywordKey:tSelectedText}];
		}
	}
}

#pragma mark -

- (void)insertNewline:(id) sender
{
	NSRange tRange=[self rangeForUserTextChange];
	
	if (tRange.location!=NSNotFound)
	{
		NSString * tString=[[self textStorage] string];
		NSUInteger tLength=[tString length];
		
		if (tRange.location>0 && tLength>0)
		{
			NSUInteger tStartOfLine=tRange.location-1;
			
			if (tStartOfLine>0)
			{
				tStartOfLine--;
				
				while (1)
				{
					if ([tString characterAtIndex:tStartOfLine]=='\n')
					{
						tStartOfLine++;
						
						break;
					}
					else
					{
						if (tStartOfLine==0)
							break;
					}
					
					tStartOfLine--;
				}
			}
			
			NSRange tWhiteSpaceRange=[tString rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]
														  options:0
														    range:NSMakeRange(tStartOfLine,tRange.location-tStartOfLine)];
			
			NSUInteger tFirstNonWhiteSpaceCharacter=(tWhiteSpaceRange.location==NSNotFound) ? tRange.location : tWhiteSpaceRange.location;

			if (tFirstNonWhiteSpaceCharacter>tStartOfLine)
				[self insertText:[@"\n" stringByAppendingString:[tString substringWithRange:NSMakeRange(tStartOfLine,tFirstNonWhiteSpaceCharacter-tStartOfLine)]]];
			else
				[super insertNewline:sender];
		}
		else
		{
			[super insertNewline:sender];
		}
	}
}

- (BOOL)performKeyEquivalent:(NSEvent *) inEvent
{
	unichar tChar=[[inEvent charactersIgnoringModifiers] characterAtIndex:0];
	
	if (WBEventModifierFlagCommand & [inEvent modifierFlags])
	{
		if (tChar==']')
		{
			[self shiftRight:nil];
				
			return YES;
		}
		
		if (tChar=='[')
		{
			[self shiftLeft:nil];
				
			return YES;
		}
		
		if (tChar=='l')
		{
			if (NSAppKitVersionNumber>=NSAppKitVersionNumber10_10)
			{
				[[ICLineJumperWindowController sharedLineJumperWindowController] popUpForTextView:self];
			
				return YES;
			}
		}
	}
	
	return [super performKeyEquivalent:inEvent];
}

- (IBAction)_shiftRight:(NSArray *) inSelectionRanges
{
	if (inSelectionRanges!=nil)
	{
		NSIndexSet * tIndexSet=[self indexesOfLineStartsForRanges:inSelectionRanges];
		
		if ([tIndexSet count]>0)
		{
			NSMutableString * tMutableString=[[self textStorage] mutableString];
			
			if (tMutableString!=nil)
			{
				NSMutableArray * tRangesList=[NSMutableArray array];
				NSMutableArray * tStringsList=[NSMutableArray array];
				
				NSUInteger tIndex=[tIndexSet lastIndex];
				
				NSMutableArray * tNewSelectionArray=[inSelectionRanges mutableCopy];
				
				NSUInteger tCount=[tNewSelectionArray count];
				
				while (tIndex!=NSNotFound)
				{
					NSUInteger tWorkIndex=tIndex;
					
					if (tWorkIndex!=0)
						tWorkIndex++;
					
					[tRangesList insertObject:[NSValue valueWithRange:NSMakeRange(tWorkIndex,0)] atIndex:0];
					
					[tStringsList insertObject:@"\t" atIndex:0];
					
					// Update text (replace spaces by tab when possible)
					
					// A COMPLETER
					
					// Update Selection
					
					for(NSUInteger i=tCount;i>0;i--)
					{
						NSValue * tValue=[tNewSelectionArray objectAtIndex:(i-1)];
						
						NSRange tRange=[tValue rangeValue];
						
						if (tWorkIndex<=(tRange.location+tRange.length))
						{
							if (tWorkIndex>=tRange.location && tRange.length>0)
								tRange.length++;
							else
								tRange.location++;
						}
						
						tValue=[NSValue valueWithRange:tRange];
						
						[tNewSelectionArray replaceObjectAtIndex:(i-1) withObject:tValue];
					}
					
					tIndex=[tIndexSet indexLessThanIndex:tIndex];
				}
				
				if ([tRangesList count]>0)
				{
					if ([self shouldChangeTextInRanges:tRangesList replacementStrings:tStringsList]==YES)
					{
						NSUInteger tRangeCount=[tRangesList count];
						
						for(NSUInteger tRangeIndex=tRangeCount;tRangeIndex>0;tRangeIndex--)
							[self replaceCharactersInRange:[[tRangesList objectAtIndex:(tRangeIndex-1)] rangeValue] withString:@"\t"];

						[self setSelectedRanges: tNewSelectionArray];
						
						[self didChangeText];
					}
				}
			}
		}
	}
}

- (IBAction)shiftRight:(id) sender
{
	[self _shiftRight:[self selectedRanges]];
}

- (IBAction)_shiftLeft:(NSArray *) inSelectionRanges
{
	if (inSelectionRanges!=nil)
	{
		NSIndexSet * tIndexSet=[self indexesOfLineStartsForRanges:inSelectionRanges];
		
		if (tIndexSet!=nil && [tIndexSet count]>0)
		{
			NSMutableString * tMutableString=[[self textStorage] mutableString];
			
			if (tMutableString!=nil)
			{
				//NSUInteger i;
				
				NSMutableArray * tRangesList=[NSMutableArray array];
				NSMutableArray * tStringsList=[NSMutableArray array];
				
				NSUInteger tIndex=[tIndexSet lastIndex];
				
				NSMutableArray *tNewSelectionArray=[inSelectionRanges mutableCopy];
				
				NSUInteger tCount=[tNewSelectionArray count];
				
				NSUInteger tLength=[tMutableString length];
				
				while (tIndex!=NSNotFound)
				{
					NSUInteger tWorkIndex=tIndex;
					
					if (tWorkIndex!=0)
						tWorkIndex++;
					
					NSUInteger tSearchIndex=tWorkIndex;
					
					// Find the first tab or series of space
					
					NSUInteger tRemovedLength=0;
					BOOL tRemoved=NO;
					
					for(;tSearchIndex<tLength;tSearchIndex++)
					{
						if ([tMutableString characterAtIndex:tSearchIndex]=='\t')
						{
							tRemoved=YES;
							
							tRemovedLength=1;
							
							break;
						}
						
						if ([tMutableString characterAtIndex:tSearchIndex]==' ')
							continue;
						
						break;
					}
					
					if (tRemoved==NO)
					{
						tRemovedLength=0;
						
						tSearchIndex=tWorkIndex;
						
						for(;tSearchIndex<tLength;tSearchIndex++)
						{
							if ([tMutableString characterAtIndex:tSearchIndex]==' ')
							{
								tRemoved=YES;
							
								tRemovedLength++;
								
								if (tRemovedLength==4)
									break;
							}
							else
							{
								break;
							}
						}
						
						tSearchIndex=tWorkIndex;
					}
					
					if (tRemoved==YES)
					{
						[tRangesList insertObject:[NSValue valueWithRange:NSMakeRange(tSearchIndex,tRemovedLength)] atIndex:0];
					
						[tStringsList insertObject:@"" atIndex:0];

						// Update Selection
						
						for(NSUInteger i=tCount;i>0;i--)
						{
							NSValue * tValue=[tNewSelectionArray objectAtIndex:i-1];
							
							NSRange tRange=[tValue rangeValue];
							
							if (tSearchIndex<(tRange.location+tRange.length))
							{
								if (tSearchIndex<=tRange.location)
								{
									if ((tSearchIndex+tRemovedLength)<=tRange.location)
									{
										tRange.location-=tRemovedLength;
									}
									else
									{
										NSUInteger tOffsetLength=tRemovedLength-(tRange.location-tSearchIndex);
										
										tRange.location=tSearchIndex;
										
										if (tRange.length>tOffsetLength)
											tRange.length-=tOffsetLength;
										else
											tRange.length=0;
									}
								}
								else 
								{
									if ((tSearchIndex+tRemovedLength)<=(tRange.location+tRange.length))
									{
										tRange.length-=tRemovedLength;
									}
									else
									{
										NSUInteger tOffsetLength=tRange.location+tRange.length-tSearchIndex;
									
										tRange.length-=tOffsetLength;
									}
								}
							}
							
							tValue=[NSValue valueWithRange:tRange];
							
							[tNewSelectionArray replaceObjectAtIndex:i-1 withObject:tValue];
						}
					}
					
					tIndex=[tIndexSet indexLessThanIndex:tIndex];
				}
				
				if ([tRangesList count]>0)
				{
					if ([super shouldChangeTextInRanges:tRangesList replacementStrings:tStringsList]==YES)
					{
						NSUInteger tRangeCount=[tRangesList count];
						
						for(NSUInteger tRangeIndex=tRangeCount;tRangeIndex>0;tRangeIndex--)
						{
							[self replaceCharactersInRange:[[tRangesList objectAtIndex:tRangeIndex-1] rangeValue] withString:@""];
						}
						
						if ([tNewSelectionArray count]>0)
							[self setSelectedRanges: tNewSelectionArray];
						else
							[self setSelectedRange:NSMakeRange(0,0)];
						
						[self didChangeText];
					}
				}
			}
		}
	}
}

- (IBAction)shiftLeft:(id) sender
{
	[self _shiftLeft:[self selectedRanges]];
}

#pragma mark - Notification

- (void)IC_textDidChange:(NSNotification *)inNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateFunctionPopup:) object:nil];
    
	[self renderGutter];
}

- (void)viewBoundsDidChange:(NSNotification *) inNotification
{
    [self renderGutter];
}

- (void)viewDidChangeEffectiveAppearance
{
	[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
}

@end
