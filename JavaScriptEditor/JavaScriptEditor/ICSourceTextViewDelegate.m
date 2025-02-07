/*
Copyright (c) 2009-2018, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ICSourceTextViewDelegate.h"

#import "NSRangeUtilities.h"

#import "NSString+Ranges.h"

#import "ICSourceTextView+Constants.h"

#import "ICJavaScriptFunctionPopUpButton.h"

#import "NSResponder+Appearance.h"

NSString * ICJavaScriptFunctionsListDidChangeNotification=@"ICJavaScriptFunctionsListDidChangeNotification";

NSString * const ICJavaScriptFunctionNameKey=@"Name";
NSString * const ICJavaScriptFunctionParametersKey=@"Parameters";
NSString * const ICJavaScriptFunctionPrototypeRangeKey=@"PrototypeRange";
NSString * const ICJavaScriptFunctionBlockRangeKey=@"BlockRange";


NSString * const IC_SOURCETEXTVIEW_DELEGATE_EDITOR_FONT=@"javascript.editor.font";

#define IC_SOURCETEXTVIEW_DELEGATE_DELAYED_POPUP_UPDATE	0.1f

@interface ICSourceTextViewDelegate ()
{
	IBOutlet NSTextView * _textView;
	
	IBOutlet ICJavaScriptFunctionPopUpButton * _functionsPopupButton;
	
	// Data
	
	NSCharacterSet * _nonSeparatorsSet;
	NSCharacterSet * _numberPrecedingSeparatorSet;
	
	NSArray * _distributionKeywords;
	NSArray * _keywords;
	
	
	NSMutableArray * _commentsRangesArray;
	NSMutableArray * _stringsRangesArray;
	NSMutableArray * _searchableRangesArray;
	
	NSMutableDictionary * _syntaxLightAttributesDictionary;
	NSMutableDictionary * _syntaxDarkAttributesDictionary;
	
	
	NSMutableArray * _functions;
}

+ (NSMutableDictionary *)functionDictionaryForString:(NSString *) inString;

- (void)delayedParseFunctions;
- (void)updateFunctionsMenuSelectedItem;
- (void)parseSourceCode;

- (void)highlightKeywords:(NSArray *) inKeywordsArray inRange:(NSRange) inRange withAttributes:(NSDictionary *) inAttributes;
- (void)highlightNumbersInRange:(NSRange) inRange withAttributes:(NSDictionary *) inAttributes;

- (NSUInteger)findForwardMatchingCharacter:(unichar) inCharacter inRanges:(NSArray *) inRangesArray startingAt:(NSUInteger) inStartingIndex;
- (NSUInteger)findBackwardMatchingCharacter:(unichar) inCharacter inRanges:(NSArray *) inRangesArray startingAt:(NSUInteger) inStartingIndex;

- (NSArray *)functionsRanges;

@end


@implementation ICSourceTextViewDelegate

- (id) init
{
	self=[super init];
	
	if (self!=nil)
	{
		_nonSeparatorsSet=[NSCharacterSet characterSetWithCharactersInString:@"_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"];
		
		_numberPrecedingSeparatorSet=[NSCharacterSet characterSetWithCharactersInString:@"!^ &*()-+=[{]}:|<,.>/?~ \r\n\t"];
		

		_keywords=[NSArray arrayWithObjects:@"if",
											@"else",
											@"for",
											@"in",
											@"while",
											@"do",
											@"continue",
											@"break",
											@"with",
											@"try",
											@"catch",
											@"switch",
											@"case",
											@"new",
											@"var",
											@"function",
											@"return",
											@"this",
											@"delete",
											@"true",
											@"false",
											@"void",
											@"throw",
											@"typeof",
											@"const",
											@"default",
											nil];
		
		
		_distributionKeywords=[NSArray arrayWithObjects:@"system",
														@"compareVersions",
														@"numericalCompare",
														@"gestalt",
														@"localizedStandardString",
														@"localizedStandardStringWithFormat",
														@"localizedString",
														@"localizedStringWithFormat",
														@"log",
														@"propertiesOf",
														@"run",
														@"runOnce",
														@"sysctl",
														@"all",
														@"fromIdentifier",
														@"fromPID",
														@"fileExistsAtPath",
														@"plistAtPath",
														@"bundleAtPath",
														@"fromPath",
														@"matchingClass",
														@"matchingName",
														@"childrenOf",
														@"parentsOf",
														@"applications",
														@"defaults",
														@"files",
														@"ioregistry",
														@"users.desktopSessionCount",
														@"version",
														@"title",
														@"description",
														@"availableKilobytes",
														@"systemVersion",
														@"ProductName",
														@"ProductVersion",
														@"BuildVersion",
														@"my",
														@"choice",
														@"tooltip",
														@"selected",
														@"packageUpgradeAction",
														@"result",
														@"message",
														@"type",
														@"target",
														@"mountpoint",
														@"isServer",
														@"receiptForIdentifier",
														@"packages",
														@"ignoreContents",
														
														nil];
		
		_commentsRangesArray=[NSMutableArray array];
		_stringsRangesArray=[NSMutableArray array];
		
		
		_syntaxLightAttributesDictionary=[NSMutableDictionary dictionary];
		
		if (_syntaxLightAttributesDictionary!=nil)
		{
			_syntaxLightAttributesDictionary[@"COMMENTS"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:0.0f/255.0f green:116.0f/255.0f blue:0.0f/255.0f alpha:1.0f]};
			_syntaxLightAttributesDictionary[@"STRINGS"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:196.0f/255.0f green:26.0f/255.0f blue:22.0f/255.0f alpha:1.0f]};
			_syntaxLightAttributesDictionary[@"KEYWORDS"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:170.0f/255.0f green:13.0f/255.0f blue:145.0f/255.0f alpha:1.0f]};
			_syntaxLightAttributesDictionary[@"DISTRIBUTION"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:46.0f/255.0f green:13.0f/255.0f blue:110.0f/255.0f alpha:1.0f]};
			_syntaxLightAttributesDictionary[@"NUMBERS"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:0.0f/255.0f green:0.0f/255.0f blue:255.0f/255.0f alpha:1.0f]};
		}
		
		_syntaxDarkAttributesDictionary=[NSMutableDictionary dictionary];
		
		if (_syntaxDarkAttributesDictionary!=nil)
		{
			_syntaxDarkAttributesDictionary[@"COMMENTS"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:108.0f/255.0f green:121.0f/255.0f blue:134.0f/255.0f alpha:1.0f]};
			_syntaxDarkAttributesDictionary[@"STRINGS"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:252.0f/255.0f green:106.0f/255.0f blue:93.0f/255.0f alpha:1.0f]};
			_syntaxDarkAttributesDictionary[@"KEYWORDS"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:252.0/255.0f green:95.0f/255.0f blue:163.0f/255.0f alpha:1.0f]};
			_syntaxDarkAttributesDictionary[@"DISTRIBUTION"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:174.0f/255.0f green:243.0f/255.0f blue:125.0f/255.0f alpha:1.0f]};
			_syntaxDarkAttributesDictionary[@"NUMBERS"]=@{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:150.0f/255.0f green:134.0f/255.0f blue:245.0f/255.0f alpha:1.0f]};
		}
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)awakeFromNib
{
	NSString * tDefaultFontName;
	CGFloat tDefaultFontSize;
	
	NSFont * tFont=[NSFont fontWithName:@"Menlo" size:11.f];
	
	if (tFont!=nil)
	{
		tDefaultFontName=@"Menlo";
		tDefaultFontSize=11.0f;
	}
	else
	{
		tDefaultFontName=@"Monaco";
		tDefaultFontSize=10.0f;
	}
	
	NSString * tFontName=tDefaultFontName;
	CGFloat tFontSize=tDefaultFontSize;
	
	NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
	
	// Text Font
	
	NSString * tString=[tUserDefaults stringForKey:IC_SOURCETEXTVIEW_DELEGATE_EDITOR_FONT];
	
	if (tString!=nil)
	{
		NSArray * tArray=[tString componentsSeparatedByString:@" - "];
		
		if (tArray!=nil && [tArray count]==2)
		{
			tFontName=[tArray objectAtIndex:0];
			
			if ([tFontName length]<3)
				tFontName=tDefaultFontName;
			
			tFontSize=[[tArray objectAtIndex:1] floatValue];
			
			if (tFontSize<2.0f || tFontSize>200.0f)
				tFontSize=tDefaultFontSize;
		}
	}
	
	[_textView setFont:[NSFont fontWithName:tFontName size:tFontSize]];
	
	[_functionsPopupButton removeAllItems];
	
	// Register for Notifications
		
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textViewDidChangeFont:)
												 name:ICSourceTextViewFontDidChangeNotification
											   object:_textView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textViewDidChangeSelection:)
												 name:NSTextViewDidChangeSelectionNotification
											   object:_textView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textDidChange:)
												 name:NSTextDidChangeNotification
											   object:_textView];
}

#pragma mark -

+ (NSMutableDictionary *)functionDictionaryForString:(NSString *) inString
{
	NSMutableDictionary * tFunctionDictionary=nil;
	
	if (inString!=nil)
	{
		NSUInteger tLength=[inString length];
		
		NSRange tFunctionRange=[inString rangeOfString:@"function" options:0 range:NSMakeRange(0,tLength)];
		
		if (tFunctionRange.location!=NSNotFound)
		{
			BOOL notAFunction=NO;
			
			// Check that there is only white space before the keyword
			
			NSUInteger tWhiteSpaceIndex=tFunctionRange.location;
			
			while (tWhiteSpaceIndex>1)
			{
				unichar tChar;

				tChar=[inString characterAtIndex:tWhiteSpaceIndex-1];
				
				if (tChar==' ' ||
					tChar=='\t')
				{
					tWhiteSpaceIndex--;
				}
				else
				{
					notAFunction=YES;
					
					break;
				}
			}
			
			if (notAFunction==NO)
			{
				// Find the function name
				
				NSUInteger tFunctionNameIndex=NSMaxRange(tFunctionRange);
				
				// At least one whitespace before the function name
				
				if (tFunctionNameIndex<tLength)
				{
					unichar tChar=[inString characterAtIndex:tFunctionNameIndex];
				
					if (tChar==' ' || tChar=='\t' || tChar=='\r' || tChar=='\n')
					{
						notAFunction=YES;
						
						// Find the first (
						
						tFunctionNameIndex++;
						
						while (tFunctionNameIndex<tLength)
						{
							tChar=[inString characterAtIndex:tFunctionNameIndex];
							
							if (tChar==' ' ||
								tChar=='\t' || 
								tChar=='\n' ||
								tChar=='\r' ||
								tChar=='_' ||
								(tChar>='A' && tChar<='Z') ||
								(tChar>='a' && tChar<='z') ||
								(tChar>='0' && tChar<='9'))
							{
								tFunctionNameIndex++;
							}
							else if (tChar=='(')
							{
								notAFunction=NO;
								
								tFunctionNameIndex--;
								
								break;
							}
							else
							{
								break;
							}
						}
						
						if (notAFunction==NO && tFunctionNameIndex<(tLength-2))
						{
							NSMutableString * tFunctionName=[NSMutableString stringWithString:[inString substringWithRange:NSMakeRange(NSMaxRange(tFunctionRange),tFunctionNameIndex-NSMaxRange(tFunctionRange)+1)]];
							
							if (tFunctionName!=nil)
							{
								CFStringTrimWhitespace((CFMutableStringRef) tFunctionName);
								
								NSUInteger tNameLength=[tFunctionName length];
								
								if (tNameLength>0)
								{
									tChar=[tFunctionName characterAtIndex:0];
									
									if (tChar<'0' || tChar>'9')
									{
										// Check that we don't have a '\r' or '\n' or '\t' or ' ' in the name
									
										if ([tFunctionName rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\r\n"]].location==NSNotFound)
										{
											NSMutableString * tParametersString=[NSMutableString stringWithString:[inString substringWithRange:NSMakeRange(tFunctionNameIndex+1,tLength-tFunctionNameIndex-1)]];
											
											if (tParametersString!=nil)
											{
												CFStringTrimWhitespace((CFMutableStringRef) tParametersString);
												
												NSUInteger tParametersLength=[tParametersString length];
												
												if (tParametersLength>=2)
												{
													tChar=[tParametersString characterAtIndex:tParametersLength-1];
													
													if (tChar==')')
													{
														NSMutableArray * tParameters=[NSMutableArray array];
														
														if ((tParametersLength-2)>0)
														{
															NSString * tSubString=[tParametersString substringWithRange:NSMakeRange(1,tParametersLength-2)];
														
															if ([tSubString length]>0)
															{
																NSArray * tParametersArray=[tSubString componentsSeparatedByString:@","];
																
																if (tParametersArray!=nil)
																{
																	NSUInteger tParametersCount,tParametersIndex;
																	
																	tParametersCount=[tParametersArray count];
																	
																	for(tParametersIndex=0;tParametersIndex<tParametersCount;tParametersIndex++)
																	{
																		NSMutableString * tSingleParameterString=[NSMutableString stringWithString:[tParametersArray objectAtIndex:tParametersIndex]];
																		
																		if (tSingleParameterString!=nil)
																		{
																			NSUInteger tSingleParameterLength;
																			
																			CFStringTrimWhitespace((CFMutableStringRef) tSingleParameterString);
																			
																			tSingleParameterLength=[tSingleParameterString length];
																			
																			if (tSingleParameterLength==0)
																			{
																				if (tParametersCount!=1)
																					return nil;
																			}
																			else
																			{
																				// Check that a parameter name only contains valid characters
																				
																				for(NSUInteger tCheckIndex=0;tCheckIndex<tSingleParameterLength;tCheckIndex++)
																				{
																					tChar=[tSingleParameterString characterAtIndex:tCheckIndex];
																					
																					if ((tChar>='A' && tChar<='Z') ||
																						(tChar>='a' && tChar<='z') ||
																						 tChar=='_')
																					{
																					}
																					else if (tChar>='0' && tChar<='9')
																					{
																						if (tCheckIndex==0)
																							return nil;
																					}
																					else
																					{
																						return nil;
																					}
																				}
																				
																				[tParameters addObject:tSingleParameterString];
																			}
																		}
																	}
																}
															}
														}
														
														if (tParameters!=nil)
														{
															tFunctionDictionary=[NSMutableDictionary dictionaryWithObjectsAndKeys:tFunctionName,ICJavaScriptFunctionNameKey,
																																  tParameters,ICJavaScriptFunctionParametersKey,
																																  nil];
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
		else
		{
			// Not a function
		}
	}

	return tFunctionDictionary;
}

- (void)delayedParseFunctions
{
	NSUInteger tRangeCount=[_searchableRangesArray count];
	
	_functions=[[NSMutableArray alloc] initWithCapacity:10];
	
	if (tRangeCount>0)
	{
		NSUInteger tRangeIndex=0;
		NSUInteger tRootBlocksCount;
		
		NSString * tSourceCode=[_textView string];
		NSUInteger tLength=[tSourceCode length];
	
		NSMutableArray * tRootBlocksArray=[NSMutableArray array];
		
		NSValue * tValue=[_searchableRangesArray objectAtIndex:0];
			
		NSRange tSearchRange=[tValue rangeValue];
		
		do
		{
			NSRange tFoundRange=[tSourceCode rangeOfString:@"{" options:0 range:tSearchRange];
			
			if (tFoundRange.location==NSNotFound)
			{
				tRangeIndex++;
				
				if (tRangeIndex<tRangeCount)
				{
					tValue=[_searchableRangesArray objectAtIndex:tRangeIndex];
			
					tSearchRange=[tValue rangeValue];
				}
				else
				{
					break;
				}
			}
			else
			{
				NSRange tBlockRange;
				
				tBlockRange.location=tFoundRange.location;
				
				NSUInteger tMatchLocation=[self findForwardMatchingCharacter:'}' inRanges:_searchableRangesArray startingAt:tBlockRange.location];
				
				if (tMatchLocation==NSNotFound)
				{
					tBlockRange.length=tLength-tBlockRange.location;
					
					NSValue * tBlockValue=[NSValue valueWithRange:tBlockRange];
					
					if (tBlockValue!=nil)
						[tRootBlocksArray addObject:tBlockValue];
					
					break;
				}
				else
				{
					tBlockRange.length=tMatchLocation-tBlockRange.location+1;
					
					NSValue * tBlockValue=[NSValue valueWithRange:tBlockRange];
					
					if (tBlockValue!=nil)
						[tRootBlocksArray addObject:tBlockValue];
					
					if ((tMatchLocation+1)<NSMaxRange(tSearchRange))
					{
						tSearchRange.length=NSMaxRange(tSearchRange)-tMatchLocation-1;
						tSearchRange.location=tMatchLocation+1;
					}
					else
					{
						tRangeIndex++;
				
						if (tRangeIndex<tRangeCount)
						{
							tValue=[_searchableRangesArray objectAtIndex:tRangeIndex];
					
							tSearchRange=[tValue rangeValue];
						}
						else
						{
							break;
						}
					}
				}
			}
		}
		while (1);
		
		tRootBlocksCount=[tRootBlocksArray count];
		
		if (tRootBlocksCount>0)
		{
			NSUInteger tRootBlockIndex=0;
			NSRange tPreviousBlockRange=NSMakeRange(0,0);
			
			while (tRootBlockIndex<tRootBlocksCount)
			{
				tValue=[tRootBlocksArray objectAtIndex:tRootBlockIndex];
			
				NSRange tBlockRange=[tValue rangeValue];
				
				if (tBlockRange.location>=(tPreviousBlockRange.location+12))	// Minimum distance required for function X()
				{
					tSearchRange=NSMakeRange(tPreviousBlockRange.location,tBlockRange.location-tPreviousBlockRange.location);
					
					NSRange tFoundRange=[tSourceCode rangeOfString:@"function" options:NSBackwardsSearch range:tSearchRange];
					
					if (tFoundRange.location!=NSNotFound)
					{
						// Find the beginning of the line
						
						NSUInteger tCharIndex=tFoundRange.location;
						
						while (tCharIndex>0)
						{
							unichar tChar=[tSourceCode characterAtIndex:tCharIndex-1];
							
							if (tChar=='\n' || tChar=='\r')
								break;
							
							tCharIndex--;
						}
						
						NSRange tRestrictedRange=NSMakeRange(tCharIndex, tBlockRange.location-tCharIndex);
						
						// Check this does not intersect a string range?
						
						if ([NSRangeUtilities range:tRestrictedRange intersectsSortedRanges:_stringsRangesArray]==NO)
						{
							NSArray * tIntersectedCommentsRange=[NSRangeUtilities sortedRanges:_commentsRangesArray intersectingRange:tRestrictedRange];
							
							// Take the excerpt and remove the comments
							
							NSString * tExcerptString=[tSourceCode substringWithRange:tRestrictedRange excludingSortedRanges:tIntersectedCommentsRange];
							
							if (tExcerptString!=nil)
							{
								NSMutableDictionary * tFunctionDictionary=[ICSourceTextViewDelegate functionDictionaryForString:tExcerptString];
								
								if (tFunctionDictionary!=nil)
								{
									tFunctionDictionary[ICJavaScriptFunctionPrototypeRangeKey]=[NSValue valueWithRange:tRestrictedRange];
									tFunctionDictionary[ICJavaScriptFunctionBlockRangeKey]=[NSValue valueWithRange:NSUnionRange(tRestrictedRange,tBlockRange)];
									
									[_functions addObject:tFunctionDictionary];
								}
							}
						}
					}
				}
				
				tPreviousBlockRange=tBlockRange;
				
				tRootBlockIndex++;
			}
		}
	}
	
	// Update the functions menu
	
	NSMenu * tMenu=[_functionsPopupButton menu];
	
	[tMenu removeAllItems];
	
	for(NSDictionary * tFunctionDictionary in _functions)
	{
		NSString * tTitle=tFunctionDictionary[ICJavaScriptFunctionNameKey];
		
		if (tTitle!=nil)
		{
			NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:tTitle action:nil keyEquivalent:@""];
		
			if (tMenuItem!=nil)
				[tMenu addItem:tMenuItem];
		}
	}

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateFunctionsMenuSelectedItem) object:nil];
			
	[self updateFunctionsMenuSelectedItem];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ICJavaScriptFunctionsListDidChangeNotification object:self];
}

- (void)updateFunctionsMenuSelectedItem
{
	NSUInteger tSelectedFunctionIndex=NSNotFound;
	
	NSArray * tSelectedRanges=[_textView selectedRanges];
	
	if (tSelectedRanges!=nil && [tSelectedRanges count]>0)
	{
		NSValue * tValue=[tSelectedRanges objectAtIndex:0];
		
		NSUInteger tLocation=[tValue rangeValue].location;
		
		tSelectedFunctionIndex=[NSRangeUtilities indexOfRangeIncludingLocation:tLocation withinRanges:[self functionsRanges]];
	}
	
	[_functionsPopupButton selectItemAtIndex:(tSelectedFunctionIndex!=NSNotFound)? tSelectedFunctionIndex : -1];
	
	NSRect tFrame=[_functionsPopupButton frame];
			
	[_functionsPopupButton sizeToFit];
	
	tFrame.size.width=NSWidth([_functionsPopupButton frame])+5.0f;
	
	[_functionsPopupButton setFrame:tFrame];

	[[_functionsPopupButton superview] setNeedsDisplay:YES];
}

- (void)parseSourceCode
{
	NSString * tSourceCode=[_textView string];
	NSUInteger tLength=[tSourceCode length];
	
	[_commentsRangesArray removeAllObjects];
	[_stringsRangesArray removeAllObjects];
	
	_searchableRangesArray=nil;
	
	if (tLength>0 && _commentsRangesArray!=nil && _stringsRangesArray!=nil)
	{
		NSUInteger tIndex=0;
		NSValue * tValue;
	
		while (tIndex<tLength)
		{
			unichar tChar=[tSourceCode characterAtIndex:tIndex];
			
			if (tChar=='/')
			{
				tIndex++;
				
				if (tIndex<tLength)
				{
					tChar=[tSourceCode characterAtIndex:tIndex];
					
					if (tChar=='*')
					{
						NSRange tMultilineCommentRange=NSMakeRange(tIndex-1, 0);
						
						// Look for the first closing */
						
						tIndex++;
						
						if (tIndex<tLength)
						{
							while (tIndex<tLength)
							{
								tChar=[tSourceCode characterAtIndex:tIndex];
								
								if (tChar=='*')
								{
									tIndex++;
									
									if (tIndex<tLength)
									{
										tChar=[tSourceCode characterAtIndex:tIndex];
								
										if (tChar=='/')
										{
											tMultilineCommentRange.length=tIndex-tMultilineCommentRange.location+1;
											
											tValue=[NSValue valueWithRange:tMultilineCommentRange];
											
											[_commentsRangesArray addObject:tValue];
												
											tIndex++;
											
											break;
										}
										else
										{
											if (tChar!='*')
												tIndex++;
										}
									}
									else
									{
										break;
									}
								}
								else
								{
									tIndex++;
								}
							}
						}
						
						if (tIndex>=tLength && tMultilineCommentRange.length==0)
						{
							tMultilineCommentRange.length=tLength-tMultilineCommentRange.location;
											
							tValue=[NSValue valueWithRange:tMultilineCommentRange];
							
							[_commentsRangesArray addObject:tValue];
							
							break;
						}
					}
					else if (tChar=='/')
					{
						NSRange tSinglelineCommentRange=NSMakeRange(tIndex-1, 0);
						
						// We need to look for the first end of line
						
						tIndex++;
						
						if (tIndex<tLength)
						{
							while (tIndex<tLength)
							{
								tChar=[tSourceCode characterAtIndex:tIndex];
								
								if (tChar=='\n' || tChar=='\r')
								{
									tSinglelineCommentRange.length=tIndex-tSinglelineCommentRange.location;
											
									tValue=[NSValue valueWithRange:tSinglelineCommentRange];
									
									[_commentsRangesArray addObject:tValue];

									
									tIndex++;
									
									break;
								}
								else
								{
									tIndex++;
								}
							}
						}
						
						if (tIndex>=tLength && tSinglelineCommentRange.length==0)
						{
							tSinglelineCommentRange.length=tLength-tSinglelineCommentRange.location;
											
							tValue=[NSValue valueWithRange:tSinglelineCommentRange];
							
							[_commentsRangesArray addObject:tValue];
							
							break;
						}
					}
				}
			}
			else if (tChar=='\"')
			{
				NSRange tStringRange=NSMakeRange(tIndex, 0);
				
				// We need to look for the first end of line
				
				tIndex++;
				
				if (tIndex<tLength)
				{
					// Find the first "
					
					while (tIndex<tLength)
					{
						tChar=[tSourceCode characterAtIndex:tIndex];
						
						if (tChar=='\\')
						{
							tIndex+=2;
						}
						else if (tChar=='\"')
						{
							tStringRange.length=tIndex-tStringRange.location+1;
									
							tValue=[NSValue valueWithRange:tStringRange];
							
							[_stringsRangesArray addObject:tValue];
							
							
							tIndex++;
							
							break;
						}
						else
						{
							tIndex++;
						}
					}
				}
				
				if (tIndex>=tLength && tStringRange.length==0)
				{
					tStringRange.length=tLength-tStringRange.location;
									
					tValue=[NSValue valueWithRange:tStringRange];
					
					[_stringsRangesArray addObject:tValue];
					
					break;
				}
			}
			else if (tChar=='\'')
			{
				NSRange tStringRange=NSMakeRange(tIndex, 0);
				
				// We need to look for the first end of line
				
				tIndex++;
				
				if (tIndex<tLength)
				{
					// Find the first '
					
					while (tIndex<tLength)
					{
						tChar=[tSourceCode characterAtIndex:tIndex];
						
						if (tChar=='\\')
						{
							tIndex+=2;
						}
						else if (tChar=='\'')
						{
							tStringRange.length=tIndex-tStringRange.location+1;
									
							tValue=[NSValue valueWithRange:tStringRange];
							
							[_stringsRangesArray addObject:tValue];
							
							
							tIndex++;
							
							break;
						}
						else
						{
							tIndex++;
						}
					}
				}
				
				if (tIndex>=tLength && tStringRange.length==0)
				{
					tStringRange.length=tLength-tStringRange.location;
									
					tValue=[NSValue valueWithRange:tStringRange];
					
					[_stringsRangesArray addObject:tValue];
					
					break;
				}
			}
			else
			{
				tIndex++;
			}
		}
	}
	
	// Colorize code
	
	NSTextStorage * tTextStorage=[_textView textStorage];
	
	NSLayoutManager * tLayoutManager = [[tTextStorage layoutManagers] objectAtIndex: 0];
	
	NSDictionary * tSyntaxAttributesDictionary=([_textView WB_isEffectiveAppearanceDarkAqua]==NO) ? _syntaxLightAttributesDictionary : _syntaxDarkAttributesDictionary;
	
	// Remove all attributes
	
	[tLayoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:NSMakeRange(0,tLength)];
	
	if (tLength>0)
	{
		// Comments
		
		NSDictionary * tAttributeDictionary=tSyntaxAttributesDictionary[@"COMMENTS"];
		
		for(NSValue * tValue in _commentsRangesArray)
			[tLayoutManager addTemporaryAttributes: tAttributeDictionary forCharacterRange:[tValue rangeValue]];
	
		// Strings
		
		tAttributeDictionary=tSyntaxAttributesDictionary[@"STRINGS"];
		
		for(NSValue * tValue in _stringsRangesArray)
			[tLayoutManager addTemporaryAttributes: tAttributeDictionary forCharacterRange:[tValue rangeValue]];
		
		
		NSMutableArray * tExcludedRangesArray=[NSMutableArray arrayWithArray:_commentsRangesArray];
		
		[tExcludedRangesArray addObjectsFromArray:_stringsRangesArray];
		
		
		_searchableRangesArray=[[NSRangeUtilities rangesFromRange:NSMakeRange(0,tLength) excludingRanges:tExcludedRangesArray] mutableCopy];
		
		for(NSValue * tValue in _searchableRangesArray)
		{
			NSRange tRange=[tValue rangeValue];
				
			if (_keywords.count>0)
			{
				tAttributeDictionary=tSyntaxAttributesDictionary[@"KEYWORDS"];
				
				[self highlightKeywords:_keywords inRange:tRange withAttributes:tAttributeDictionary];
			}
			
			if (_distributionKeywords.count>0)
			{
				tAttributeDictionary=tSyntaxAttributesDictionary[@"DISTRIBUTION"];
				
				[self highlightKeywords:_distributionKeywords inRange:tRange withAttributes:tAttributeDictionary];
			}
			
			tAttributeDictionary=tSyntaxAttributesDictionary[@"NUMBERS"];
			
			[self highlightNumbersInRange:tRange withAttributes:tAttributeDictionary];
		}
	}
}

- (void)highlightNumbersInRange:(NSRange) inRange withAttributes:(NSDictionary *) inAttributes
{
	if (inAttributes!=nil)
	{
		NSTextStorage * tTextStorage=[_textView textStorage];
		NSLayoutManager * tLayoutManager=[[tTextStorage layoutManagers] objectAtIndex: 0];
		
		NSUInteger tFirstDigitIndex=inRange.location;
		
		NSUInteger tMaxIndex=NSMaxRange(inRange);
		
		NSString * tSourceCode=[_textView string];
		
		while (tFirstDigitIndex<tMaxIndex)
		{
			unichar tChar=[tSourceCode characterAtIndex:tFirstDigitIndex];
			
			if (tChar>='0' && tChar<='9')
			{
				NSUInteger tLastDigitIndex;
				NSUInteger tDotsCount=0;
				NSUInteger tExponentsCount=0;
				BOOL isHexaDecimal=NO;
				
				// Check if the preceding character is a valid number separator
				
				if (tFirstDigitIndex>inRange.location)
				{
					unichar tPrecedingChar;
					
					tPrecedingChar=[tSourceCode characterAtIndex:tFirstDigitIndex-1];
					
					if ([_numberPrecedingSeparatorSet characterIsMember:tPrecedingChar]==NO)
					{
						tFirstDigitIndex++;
						
						continue;
					}
					
					if (tPrecedingChar=='.')
						tFirstDigitIndex--;
				}
				
				tLastDigitIndex=tFirstDigitIndex+1;
				
				while (tLastDigitIndex<tMaxIndex)
				{
					tChar=[tSourceCode characterAtIndex:tLastDigitIndex];
					
					if (tChar=='.')
					{
						tDotsCount++;
						
						if (tDotsCount>1 || isHexaDecimal==YES)
							break;
					}
					else if (tChar=='e' || tChar=='E')
					{
						if (isHexaDecimal==NO)
						{
							tExponentsCount++;
						
							if (tExponentsCount>1 || isHexaDecimal==YES)
							{
								break;
							}
							else
							{
								if ((tLastDigitIndex+1)<tMaxIndex)
								{
									tChar=[tSourceCode characterAtIndex:tLastDigitIndex+1];
						
									if ((tChar<'0' || tChar>'9'))
										break;
									else
										tLastDigitIndex++;
								}
								else
								{
									break;
								}
							}
						}
					}
					else if (tChar=='x' || tChar=='X')	/* Hexadecimal */
					{
						if ((tLastDigitIndex==(tFirstDigitIndex+1)) && ([tSourceCode characterAtIndex:tFirstDigitIndex]=='0'))
						{
							isHexaDecimal=YES;
						}
						else
						{
							break;
						}
					}
					else if (tChar<'0' || tChar>'9')
					{
						if (isHexaDecimal==NO || ((tChar<'a' || tChar>'f') && (tChar<'A' || tChar>'F')))
							break;
					}
					
					tLastDigitIndex++;
				}
				
				[tLayoutManager addTemporaryAttributes:inAttributes forCharacterRange:NSMakeRange(tFirstDigitIndex,tLastDigitIndex-tFirstDigitIndex)];
				
				tFirstDigitIndex=tLastDigitIndex+1;
			}
			else
			{
				tFirstDigitIndex++;
			}
		}
	}
}

- (void)highlightKeywords:(NSArray *) inKeywordsArray inRange:(NSRange) inRange withAttributes:(NSDictionary *) inAttributes
{
	if (inKeywordsArray!=nil && inRange.length>0)
	{
		NSEnumerator * tEnumerator=[inKeywordsArray objectEnumerator];
			
		if (tEnumerator!=nil)
		{
			NSString * tKeyword;
			
			NSTextStorage * tTextStorage=[_textView textStorage];
			NSLayoutManager * tLayoutManager = [[tTextStorage layoutManagers] objectAtIndex: 0];
			
			
			NSString * tSourceCode=[_textView string];
			
			while (tKeyword=[tEnumerator nextObject])
			{
				NSRange tSearchableRange=inRange;
				
				NSUInteger tMaxRange=NSMaxRange(inRange);
				
				while (tSearchableRange.location<tMaxRange)
				{
					NSRange tFoundRange=[tSourceCode rangeOfString:tKeyword options:0 range:tSearchableRange];
				
					if (tFoundRange.location!=NSNotFound)
					{
						BOOL tProblem=NO;
						
						if (tFoundRange.location>inRange.location)
							tProblem=[_nonSeparatorsSet characterIsMember:[tSourceCode characterAtIndex:(tFoundRange.location-1)]];
						
						if (tProblem==NO)
						{
							if (NSMaxRange(tFoundRange)<NSMaxRange(inRange))
								tProblem=[_nonSeparatorsSet characterIsMember:[tSourceCode characterAtIndex:NSMaxRange(tFoundRange)]];
						}
						
						if (tProblem==NO)
							[tLayoutManager addTemporaryAttributes:inAttributes forCharacterRange:tFoundRange];
						
						tSearchableRange.length=NSMaxRange(tSearchableRange)-NSMaxRange(tFoundRange);
						tSearchableRange.location=NSMaxRange(tFoundRange);
					}
					else
					{
						break;
					}
				}
			}
		}
	}
}

- (NSUInteger)findForwardMatchingCharacter:(unichar) inCharacter inRanges:(NSArray *) inRangesArray startingAt:(NSUInteger) inStartingIndex
{
	NSUInteger tRangeIndex=[NSRangeUtilities indexOfRangeIncludingLocation:inStartingIndex withinRanges:inRangesArray];
	
	if (tRangeIndex!=NSNotFound)
	{
		NSUInteger tBracesDepth=0;
		NSUInteger tParenthesisDepth=0;
		
		if (inCharacter==')')
		{
			tParenthesisDepth=1;
		}
		else if (inCharacter=='}')
		{
			tBracesDepth=1;
		}
		else
		{
			return NSNotFound;
		}
		
		NSString * tSourceCode=[_textView string];
		
		NSCharacterSet * tLookingForSet=[NSCharacterSet characterSetWithCharactersInString:@"(){}"];
		
		NSInteger tRangesCount=[inRangesArray count];
		
		while (tRangeIndex<tRangesCount)
		{
			BOOL tContinue=YES;
			
			NSValue * tValue=[inRangesArray objectAtIndex:tRangeIndex];
			
			NSRange tPartialLookRange=[tValue rangeValue];
			
			if (tPartialLookRange.location<=inStartingIndex)
			{
				if (inStartingIndex==(NSMaxRange(tPartialLookRange)-1))
				{
					tRangeIndex++;
					
					continue;
				}
				
				tPartialLookRange.length=NSMaxRange(tPartialLookRange)-inStartingIndex-1;
				
				tPartialLookRange.location=inStartingIndex+1;
			}
			
			while (tContinue==YES)
			{
				NSRange tFoundRange=[tSourceCode rangeOfCharacterFromSet:tLookingForSet options:0 range:tPartialLookRange];
				
				if (tFoundRange.location==NSNotFound)
				{
					break;
				}
				else
				{
					unichar tFoundCharacter=[tSourceCode characterAtIndex:tFoundRange.location];
					
					switch (tFoundCharacter)
					{
						case '{':
						
							if (tParenthesisDepth!=0)
								return NSNotFound;
						
							tBracesDepth++;
							
							break;
						
						case '}':
						
							if (tParenthesisDepth!=0)
								return NSNotFound;
						
							tBracesDepth--;
							
							if (tBracesDepth==0 && inCharacter=='}')
							{
								return tFoundRange.location;
							}
							
							break;
							
						case '(':
							
							tParenthesisDepth++;
							
							break;
							
						case ')':
							
							tParenthesisDepth--;
							
							if (tParenthesisDepth==0 && inCharacter==')')
								return tFoundRange.location;
							
							break;
					}
					
					if ((tFoundRange.location+1)>=NSMaxRange(tPartialLookRange))
					{
						tContinue=NO;
					}
					else
					{
						tPartialLookRange.length=NSMaxRange(tPartialLookRange)-tFoundRange.location-1;
						tPartialLookRange.location=tFoundRange.location+1;
					}
				}
			}
			
			tRangeIndex++;
		}
	}
	
	return NSNotFound;
}

- (NSUInteger)findBackwardMatchingCharacter:(unichar) inCharacter inRanges:(NSArray *) inRangesArray startingAt:(NSUInteger) inStartingIndex
{
	NSUInteger tRangeIndex=[NSRangeUtilities indexOfRangeIncludingLocation:inStartingIndex withinRanges:inRangesArray];
	
	if (tRangeIndex!=NSNotFound)
	{
		NSValue * tValue;
		NSCharacterSet * tLookingForSet;
		NSString * tSourceCode;
		NSUInteger tBracesDepth=0;
		NSUInteger tParenthesisDepth=0;
		
		if (inCharacter=='(')
		{
			tParenthesisDepth=1;
		}
		else if (inCharacter=='{')
		{
			tBracesDepth=1;
		}
		else
		{
			return NSNotFound;
		}
		
		tRangeIndex++;
		
		tSourceCode=[_textView string];
		
		tLookingForSet=[NSCharacterSet characterSetWithCharactersInString:@"(){}"];
		
		while (tRangeIndex>0)
		{
			BOOL tContinue=YES;
			
			tValue=[inRangesArray objectAtIndex:(tRangeIndex-1)];
			
			NSRange tPartialLookRange=[tValue rangeValue];
			
			if (NSMaxRange(tPartialLookRange)>=inStartingIndex)
			{
				if (inStartingIndex==(tPartialLookRange.location))
				{
					tRangeIndex--;
					
					continue;
				}
				
				tPartialLookRange.length=inStartingIndex-tPartialLookRange.location;
			}
			
			while (tContinue==YES)
			{
				NSRange tFoundRange=[tSourceCode rangeOfCharacterFromSet:tLookingForSet options:NSBackwardsSearch range:tPartialLookRange];
				
				if (tFoundRange.location==NSNotFound)
				{
					break;
				}
				else
				{
					unichar tFoundCharacter=[tSourceCode characterAtIndex:tFoundRange.location];
					
					switch (tFoundCharacter)
					{
						case '}':
						
							if (tParenthesisDepth!=0)
								return NSNotFound;
						
							tBracesDepth++;
							
							break;
						
						case '{':
						
							if (tParenthesisDepth!=0)
								return NSNotFound;
						
							tBracesDepth--;
							
							if (tBracesDepth==0 && inCharacter=='{')
								return tFoundRange.location;
							
							break;
							
						case ')':
							
							tParenthesisDepth++;
							
							break;
							
						case '(':
							
							tParenthesisDepth--;
							
							if (tParenthesisDepth==0 && inCharacter=='(')
								return tFoundRange.location;
							
							break;
					}
					
					if (tFoundRange.location==tPartialLookRange.location)
						tContinue=NO;
					else
						tPartialLookRange.length=tFoundRange.location-tPartialLookRange.location;
				}
			}
			
			tRangeIndex--;
		}
	}
	
	return NSNotFound;
}

#pragma mark -

/*- (NSArray *) textView:(NSTextView *) inTextView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *) inIndex
{
	// A COMPLETER
}*/

#pragma mark -

- (void)textViewDidChangeFont:(NSNotification *) inNotification
{
	if ([inNotification object]==_textView)
	{
		NSUserDefaults * tUserDefaults=[NSUserDefaults standardUserDefaults];
		
		NSFont * tFont=[_textView font];
		
		[tUserDefaults setObject:[NSString stringWithFormat:@"%@ - %f",[tFont fontName],[tFont pointSize]]
						  forKey:IC_SOURCETEXTVIEW_DELEGATE_EDITOR_FONT];
	}
}

- (void)textDidChange:(NSNotification *) inNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedParseFunctions) object:nil];
	
	[self parseSourceCode];
	
	[self performSelector:@selector(delayedParseFunctions) withObject:nil afterDelay:0.5f];
}

- (void)textViewDidChangeSelection:(NSNotification *) inNotification
{
	if ([inNotification object]==_textView)
	{
		NSEvent * tCurrentEvent=[NSApp currentEvent];
		
		NSRange tSelectionRange  = [_textView selectedRange];
		
		// The NSTextViewDidChangeSelectionNotification is sent before the selection granularity is set.  Therefore we can't tell a double-click by examining the granularity.  
		// Fortunately there's another way.  The mouse-up event that ended the selection is still the current event for the app. 
		// We'll check that instead.  Perhaps, in an ideal world, after checking the length we'd do this instead: ([textView selectionGranularity] == NSSelectByWord).
		
		if (tCurrentEvent.type == WBEventTypeLeftMouseUp && tCurrentEvent.clickCount == 2 && tSelectionRange.length == 1)
		{
			NSString * tString=[_textView string];
			NSUInteger tLength=[tString length];
			
			NSUInteger tLocation=tSelectionRange.location;
			
			if (tLocation<tLength)
			{
				unichar tCharacter=[tString characterAtIndex:tLocation];
				unichar tOppositeCharacter=0;
				
				switch(tCharacter)
				{
					case '(':
					
						tOppositeCharacter=')';
						
						break;
					
					case '{':
						
						tOppositeCharacter='}';
						
						break;
						
					case '}':
					
						tOppositeCharacter='{';
						
						break;
					
					case ')':
						
						tOppositeCharacter='(';
						
						break;
					
				}
				
				if (tOppositeCharacter!=0)
				{
					if ([NSRangeUtilities location:tLocation isInsideRanges:_searchableRangesArray]==YES)
					{
						NSUInteger tMatchedLocation;
						
						if (tOppositeCharacter=='}' ||
							tOppositeCharacter==')')
							tMatchedLocation=[self findForwardMatchingCharacter:tOppositeCharacter inRanges:_searchableRangesArray startingAt:tLocation];
						else
							tMatchedLocation=[self findBackwardMatchingCharacter:tOppositeCharacter inRanges:_searchableRangesArray startingAt:tLocation];
						
						if (tMatchedLocation!=NSNotFound)
						{
							NSRange tSelectedRange;
							
							if (tOppositeCharacter=='}' ||
								tOppositeCharacter==')')
							{
								tSelectedRange=NSMakeRange(tLocation,tMatchedLocation-tLocation+1);
							}
							else
							{
								tSelectedRange=NSMakeRange(tMatchedLocation,tLocation-tMatchedLocation+1);
							}
							
							[_textView setSelectedRange:tSelectedRange];
							
							[_textView scrollRangeToVisible:tSelectedRange];
							
							return;
						}
					}
				
					NSBeep();
				}
			}
		}
		else
		{
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateFunctionsMenuSelectedItem) object:nil];
			
			[self performSelector:@selector(updateFunctionsMenuSelectedItem) withObject:nil afterDelay:IC_SOURCETEXTVIEW_DELEGATE_DELAYED_POPUP_UPDATE];
		}
	}
}

#pragma mark -

- (IBAction)showFunction:(id) sender
{
	NSInteger tIndex=[sender indexOfSelectedItem];
	
	NSString * tFunctionName=[sender titleOfSelectedItem];
	
	if (_functions!=nil && tIndex<[_functions count])
	{
		NSDictionary * tFunctionDictionary=[_functions objectAtIndex:tIndex];
		
		if ([tFunctionDictionary[ICJavaScriptFunctionNameKey] isEqualToString:tFunctionName]==NO)
		{
			for(tFunctionDictionary in _functions)
			{
				if ([tFunctionDictionary[ICJavaScriptFunctionNameKey] isEqualToString:tFunctionName]==YES)
					break;
			}
		}
		
		if (tFunctionDictionary!=nil)
		{
			NSValue * tValue=tFunctionDictionary[ICJavaScriptFunctionPrototypeRangeKey];
			
			if (tValue!=nil)
			{
				NSRange tRange=[tValue rangeValue];
				
				[_textView setSelectedRange:tRange];
    
				[_textView scrollRangeToVisible:tRange];
				
				NSRect tFrame=[_functionsPopupButton frame];
				
				[_functionsPopupButton sizeToFit];
				
				tFrame.size.width=NSWidth([_functionsPopupButton frame])+5.0f;
				
				[_functionsPopupButton setFrame:tFrame];
			
				[[_functionsPopupButton superview] setNeedsDisplay:YES];
			}
		}
	}
}

- (NSArray *)parametersForFunctionNamed:(NSString *) inFunctionName
{
	for (NSDictionary * tFunctionDictionary in _functions)
	{
		if ([tFunctionDictionary[ICJavaScriptFunctionNameKey] isEqualToString:inFunctionName]==YES)
			return tFunctionDictionary[ICJavaScriptFunctionParametersKey];
	}
	
	return [NSArray array];
}

- (NSArray *)functionsRanges
{
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
	if (tMutableArray!=nil)
	{
		for (NSDictionary * tFunctionDictionary in _functions)
			[tMutableArray addObject:tFunctionDictionary[ICJavaScriptFunctionBlockRangeKey]];
	}
	
	return [tMutableArray copy];
}

- (NSArray *)sortedFunctionsList
{
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
	if (tMutableArray!=nil)
	{
		for (NSDictionary * tFunctionDictionary in _functions)
			[tMutableArray addObject:tFunctionDictionary[ICJavaScriptFunctionNameKey]];
	}
	
	return [tMutableArray sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

@end
