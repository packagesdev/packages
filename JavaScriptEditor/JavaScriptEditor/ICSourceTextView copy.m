/*
Copyright (c) 2009, Stephane Sudre
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

@implementation ICSourceTextView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

#pragma mark -

- (void) awakeFromNib
{
	numberOfSpaceForTab_=4;
	
	[IBscrollView_ setHasHorizontalScroller:YES];
	
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
	
	[self setFont:[NSFont fontWithName:@"Monaco" size:10.0f]];
	
	[self renderGutter];
	
	[self updateTabStyle];

	// Register for Notifications
    
    [[IBscrollView_ contentView] setPostsBoundsChangedNotifications:YES];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(textDidChange:)
													 name:NSTextDidChangeNotification
												   object:self];
												   
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewBoundsChanged:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:[IBscrollView_ contentView]];
											   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewBoundsChanged:)
                                                 name:NSWindowDidResizeNotification
                                               object:[self window]];
}

- (void) updateTabStyle
{
	NSMutableAttributedString * tMutableAttributedString;
	
	tMutableAttributedString=[self textStorage];
	
	if (tMutableAttributedString!=nil)
	{
		NSDictionary * tAttributesDictionary;
		NSRange tRange;
		NSMutableString * tMutableString;
		double tColumnWidth;
		NSParagraphStyle * tParagraphStyle;
		
		tAttributesDictionary=[NSDictionary dictionaryWithObjectsAndKeys:[self font],NSFontAttributeName,nil];
		
		tMutableString=[NSMutableString stringWithCapacity:numberOfSpaceForTab_];
		
		if (tMutableString!=nil)
		{
			NSUInteger i;
			
			for(i=0;i<numberOfSpaceForTab_;i++)
			{
				[tMutableString appendString:@" "];
			}
			
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
			NSMutableParagraphStyle * tMutableParagraphStyle;
			
			tMutableParagraphStyle=[tParagraphStyle mutableCopy];
			
			if (tMutableParagraphStyle!=nil)
			{
				NSMutableArray * tMutableArray;
				NSUInteger tNumberOfTabs;
				
				tNumberOfTabs=500;
				
				tMutableArray=[[NSMutableArray alloc] initWithCapacity:tNumberOfTabs];
				
				if (tMutableArray!=nil)
				{
					NSUInteger tIndex;
					
					for(tIndex=0;tIndex<tNumberOfTabs;tIndex++)
					{
						NSTextTab * tTextTab;
					
						tTextTab=[[NSTextTab alloc] initWithType:NSLeftTabStopType location:((double)tIndex+1) * tColumnWidth];
						
						if (tTextTab!=nil)
						{
							[tMutableArray addObject:tTextTab];
								
							[tTextTab release];
						}
						else
						{
							// A COMPLETER
							
							break;
						}
					}
					
					[tMutableParagraphStyle setTabStops:tMutableArray];
					
					[tMutableArray release];
				
					[self setDefaultParagraphStyle:tMutableParagraphStyle];
					
					if ([tMutableAttributedString length]>0)
					{
						[tMutableAttributedString addAttribute:NSParagraphStyleAttributeName value:tMutableParagraphStyle range:NSMakeRange(0,[tMutableString length])];
					}
				}
				
				[tMutableParagraphStyle release];
			}
		}
	}
	
	[self didChangeText];
}

- (void) renderGutter
{
    NSArray * tArray;
	NSUInteger tStart;
	
	if (![[self window] isVisible]) return;
    
    [self getRectsOfVisibleLines:&tArray startingLineNumber:&tStart];
	
    [IBgutterView_ setLineNumberRects:tArray];
    
	[IBgutterView_ setStartLineNumber: tStart];
    
	[IBgutterView_ setNeedsDisplay:YES];        
}

- (void) getRectsOfVisibleLines:(NSArray **) outRects startingLineNumber:(NSUInteger *) outStart
{
    NSMutableArray * tMutableArray;
    NSString * tString;
	NSLayoutManager * tLayoutManager;
    NSRect tBoundingRect; 
    float tScrollY;
    NSRange tVisibleGlyphRange;
	NSUInteger tIndex,tLength;
	
	*outRects=nil;
	
	tMutableArray = [NSMutableArray array];
	
	tString = [self string];
    
	tLayoutManager = [[self textContainer] layoutManager];
	
	tBoundingRect = [[ IBscrollView_ contentView] documentVisibleRect];
	
    tVisibleGlyphRange = [tLayoutManager glyphRangeForBoundingRect:tBoundingRect inTextContainer:[self textContainer]];
	
	tScrollY = NSMinY(tBoundingRect);
        
    tIndex = tVisibleGlyphRange.location;
    tLength = tIndex + tVisibleGlyphRange.length;

    (*outStart) = [self lineNumberForIndex:tIndex + 1];
    
    while (tIndex < tLength)
	{
        NSRange tRange;
		NSRect tRect;
		
		tRange = [tString lineRangeForRange:NSMakeRange(tIndex, 0)];
		
        tIndex = NSMaxRange(tRange);
        
		tRect = [tLayoutManager lineFragmentRectForGlyphAtIndex:tRange.location effectiveRange:NULL withoutAdditionalLayout:YES];
        
		tRect.origin.y -= tScrollY;
        
		[tMutableArray addObject:[NSValue valueWithRect:tRect]];
    }
    
    (*outRects) = tMutableArray;
}


- (NSUInteger) lineNumberForIndex:(NSUInteger) inIndex
{
    NSString * tString;
    NSUInteger tNumberOfLines, tIndex, tLength;
	
	tString=[self string];
	
	tLength = [tString length];
    
    for (tIndex = 0, tNumberOfLines = 0; tIndex < tLength; tNumberOfLines++)
	{
        NSRange tRange;
		
		tRange = [tString lineRangeForRange:NSMakeRange(tIndex, 0)];
		
        tIndex = NSMaxRange(tRange);
        
		if (inIndex <= tIndex)
		{
            break;
        }
    }
    
    return tNumberOfLines;
}

- (NSIndexSet *) indexesOfLineStartsForRanges:(NSArray *) inRangesArray
{
	NSMutableIndexSet * tIndexSet;
	
	tIndexSet=[NSMutableIndexSet indexSet]; 
	
	if (tIndexSet!=nil && inRangesArray!=nil)
	{
		NSString * tString;
	
		tString=[[self textStorage] string];
	
		if (tString!=nil)
		{
			if ([tString length]>0)
			{
				NSEnumerator * tEnumerator;
				
				tEnumerator=[inRangesArray objectEnumerator];
				
				if (tEnumerator!=nil)
				{
					NSValue * tValue;
					
					while (tValue=[tEnumerator nextObject])
					{
						NSRange tRange;
						unsigned int tIndex;
						
						tRange=[tValue rangeValue];
						
						tIndex=tRange.location+tRange.length;
						
						if (tIndex>0)
						{
							tIndex=tIndex-1;
							
							while (1)
							{
								if ([tString characterAtIndex:tIndex]=='\n')
								{
									[tIndexSet addIndex:tIndex];
									
									if ((tIndex<tRange.location) || (tIndex==tRange.location && [tString characterAtIndex:tRange.location]!='\n'))
									{
										break;
									}
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
			}
			else
			{
				[tIndexSet addIndex:0];
			}
		}
	}
	
	return tIndexSet;
}

#pragma mark -

- (BOOL) performKeyEquivalent:(NSEvent *) inEvent
{
	unichar tChar;
	
	tChar=[[inEvent charactersIgnoringModifiers] characterAtIndex:0];
	
	if (NSCommandKeyMask & [inEvent modifierFlags])
	{
		if (tChar==']')
		{
			[self shiftRight:nil];
				
			return YES;
		}
		else if (tChar=='[')
		{
			[self shiftLeft:nil];
				
			return YES;
		}
	}
	
	return [super performKeyEquivalent:inEvent];
}

- (IBAction) _shiftRight:(NSArray *) inSelectionRanges
{
	if (inSelectionRanges!=nil)
	{
		NSIndexSet * tIndexSet;
		
		tIndexSet=[self indexesOfLineStartsForRanges:inSelectionRanges];
		
		if (tIndexSet!=nil && [tIndexSet count]>0)
		{
			NSMutableString * tMutableString;
			
			tMutableString=[[self textStorage] mutableString];
			
			if (tMutableString!=nil)
			{
				unsigned int tIndex;
				NSMutableArray * tNewSelectionArray;
				NSUInteger i,tCount;
				NSMutableArray * tRangesList;
				NSMutableArray * tStringsList;
				
				tRangesList=[NSMutableArray array];
				
				tStringsList=[NSMutableArray array];
				
				tIndex=[tIndexSet lastIndex];
				
				tNewSelectionArray=[inSelectionRanges mutableCopy];
				
				tCount=[tNewSelectionArray count];
				
				while (tIndex!=NSNotFound)
				{
					unsigned int tWorkIndex;
					
					tWorkIndex=tIndex;
					
					if (tWorkIndex!=0)
					{
						tWorkIndex++;
					}
					
					[tRangesList addObject:[NSValue valueWithRange:NSMakeRange(tWorkIndex,0)]];
					
					[tStringsList addObject:@"\t"];
					
					// Update text (replace spaces by tab when possible)
					
					// A COMPLETER
					
					// Update Selection
					
					for(i=tCount;i>0;i--)
					{
						NSValue * tValue;
						NSRange tRange;
						
						
						tValue=[tNewSelectionArray objectAtIndex:i-1];
						
						tRange=[tValue rangeValue];
						
						if (tWorkIndex<=(tRange.location+tRange.length))
						{
							if (tWorkIndex>=tRange.location && tRange.length>0)
							{
								tRange.length++;
							}
							else
							{
								tRange.location++;
							}
						}
						
						tValue=[NSValue valueWithRange:tRange];
						
						[tNewSelectionArray replaceObjectAtIndex:i-1 withObject:tValue];
					}
					
					tIndex=[tIndexSet indexLessThanIndex:tIndex];
				}
				
				//if ([tRangesList count]>0)
				{
					if ([self shouldChangeTextInRanges:tRangesList replacementStrings:tStringsList]==YES)
					{
						NSUInteger tRangeCount,tRangeIndex;
						
						tRangeCount=[tRangesList count];
						
						for(tRangeIndex=0;tRangeIndex<tRangeCount;tRangeIndex++)
						{
							[self replaceCharactersInRange:[[tRangesList objectAtIndex:tRangeIndex] rangeValue] withString:@"\t"];
						}
						
						
						
						[self setSelectedRanges: tNewSelectionArray];
						
						[self didChangeText];
					}
					
					
				}
				
				[tNewSelectionArray release];
			}
		}
	}
}

- (IBAction) shiftRight:(id) sender
{
	[self _shiftRight:[self selectedRanges]];
}

- (IBAction) _shiftLeft:(NSArray *) inSelectionRanges
{
	if (inSelectionRanges!=nil)
	{
		NSIndexSet * tIndexSet;
		
		tIndexSet=[self indexesOfLineStartsForRanges:inSelectionRanges];
		
		if (tIndexSet!=nil && [tIndexSet count]>0)
		{
			NSMutableString * tMutableString;
			
			tMutableString=[[self textStorage] mutableString];
			
			if (tMutableString!=nil)
			{
				unsigned int tIndex;
				NSMutableArray * tNewSelectionArray;
				NSUInteger i,tCount;
				NSUInteger tLength;
				NSMutableArray * tRangesList;
				NSMutableArray * tStringsList;
				
				tRangesList=[NSMutableArray array];
				tStringsList=[NSMutableArray array];
				
				tIndex=[tIndexSet lastIndex];
				
				tNewSelectionArray=[inSelectionRanges mutableCopy];
				
				tCount=[tNewSelectionArray count];
				
				tLength=[tMutableString length];
				
				while (tIndex!=NSNotFound)
				{
					unsigned int tWorkIndex;
					unsigned int tSearchIndex;
					unsigned int tRemovedLength=0;
					BOOL tRemoved=NO;
					
					tWorkIndex=tIndex;
					
					if (tWorkIndex!=0)
					{
						tWorkIndex++;
					}
					
					tSearchIndex=tWorkIndex;
					
					// Find the first tab or series of space
					
					for(;tSearchIndex<tLength;tSearchIndex++)
					{
						if ([tMutableString characterAtIndex:tSearchIndex]=='\t')
						{
							tRemoved=YES;
							
							tRemovedLength=1;
							
							break;
						}
						else if ([tMutableString characterAtIndex:tSearchIndex]==' ')
						{
							continue;
						}
						else
						{
							break;
						}
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
								{
									break;
								}
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
						NSLog(@"%d,%d",tSearchIndex,tRemovedLength);
						
						//[tMutableString deleteCharactersInRange:NSMakeRange(tSearchIndex,tRemovedLength)];
						
						[tRangesList insertObject:[NSValue valueWithRange:NSMakeRange(tSearchIndex,tRemovedLength)] atIndex:0];
					
						[tStringsList insertObject:@"" atIndex:0];

						// Update Selection
						
						for(i=tCount;i>0;i--)
						{
							NSValue * tValue;
							NSRange tRange;
							
							
							tValue=[tNewSelectionArray objectAtIndex:i-1];
							
							tRange=[tValue rangeValue];
							
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
										NSUInteger tOffsetLength;
										
										tOffsetLength=tRemovedLength-(tRange.location-tSearchIndex);
										
										tRange.location=tSearchIndex;
										
										if (tRange.length>tOffsetLength)
										{
											tRange.length-=tOffsetLength;
										}
										else
										{
											tRange.length=0;
										}
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
										NSUInteger tOffsetLength;
									
										tOffsetLength=tRange.location+tRange.length-tSearchIndex;
									
										tRange.length-=tOffsetLength;
									}
								}
								
								
								
								
								
								/*if (tRange.length>0 && (tSearchIndex+tRemovedLength)>=tRange.location)
								{
									NSUInteger tOffsetLength;
									
									tOffsetLength=tRange.location-tSearchIndex;
									
									tRange.location-=tOffsetLength;
									
									tRange.length-=(tRemovedLength-tOffsetLength);
								}
								else
								{
									if (tRange.location>(tSearchIndex+tRemovedLength))
									{
										tRange.location-=tRemovedLength;
									}
									else
									{
										tRange.location=tSearchIndex;
									}
								}*/
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
						NSUInteger tRangeCount,tRangeIndex;
						
						tRangeCount=[tRangesList count];
						
						for(tRangeIndex=tRangeCount;tRangeIndex>0;tRangeIndex--)
						{
							[self replaceCharactersInRange:[[tRangesList objectAtIndex:tRangeIndex-1] rangeValue] withString:@""];
						}
						
						if ([tNewSelectionArray count]>0)
						{
							[self setSelectedRanges: tNewSelectionArray];
						}
						else
						{
							[self setSelectedRange:NSMakeRange(0,0)];
						}
						
						[self didChangeText];

						
					}
				}
				
				//[self didChangeText];
				
				
				/**/
				
				//[[self undoManager] registerUndoWithTarget: self selector: @selector(_shiftRight:) object: tNewSelectionArray];
				
				[tNewSelectionArray release];
				
				//
			}
		}
	}
}

- (IBAction) shiftLeft:(id) sender
{
	[self _shiftLeft:[self selectedRanges]];
}

- (void) textDidChange:(NSNotification *) inNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateFunctionPopup:) object:nil];
	
	[self renderGutter];
}

- (void) viewBoundsChanged:(NSNotification *) inNotification
{
    [self renderGutter];
}

@end
