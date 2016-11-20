/*
Copyright (c) 2003 Karelia Software, LLC.  All rights reserved. 
 
 Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies. 
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 
 Except as contained in this notice, the name of a copyright holder shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization of the copyright holder.
*/

#import "NSString+Karelia.h"

@implementation NSString ( Karelia )

/*"	Find a string from one string to another with the default options; the delimeter strings are included in the result.
"*/

- (NSRange) rangeFromString:(NSString *)inString1 toString:(NSString *)inString2
{
	return [self rangeFromString:inString1 toString:inString2 options:0];
}

/*"	Find a string from one string to another with the given options inMask; the delimeter strings %are included in the result.  The inMask parameter is the same as is passed to [NSString rangeOfString:options:range:].
"*/

- (NSRange) rangeFromString:(NSString *)inString1 toString:(NSString *)inString2
	options:(unsigned)inMask
{
	return [self rangeFromString:inString1 toString:inString2
		options:inMask
		range:NSMakeRange(0,[self length])];
}

/*"	Find a string from one string to another with the given options inMask and the given substring range inSearchRange; the delimeter strings %are included in the result.  The inMask parameter is the same as is passed to [NSString rangeOfString:options:range:].
"*/

- (NSRange) rangeFromString:(NSString *)inString1 toString:(NSString *)inString2
	options:(unsigned)inMask range:(NSRange)inSearchRange
{
	NSRange result;
	NSRange stringStart = NSMakeRange(inSearchRange.location,0); // if no start string, start here
	NSUInteger foundLocation = inSearchRange.location;	// if no start string, start here
	NSRange stringEnd = NSMakeRange(NSMaxRange(inSearchRange),0); // if no end string, end here
	NSRange endSearchRange;
	if (nil != inString1)
	{
		// Find the range of the list start
		stringStart = [self rangeOfString:inString1 options:inMask range:inSearchRange];
		if (NSNotFound == stringStart.location)
		{
			return stringStart;	// not found
		}
		foundLocation = NSMaxRange(stringStart);
	}
	endSearchRange = NSMakeRange( foundLocation, NSMaxRange(inSearchRange) - foundLocation );
	if (nil != inString2)
	{
		stringEnd = [self rangeOfString:inString2 options:inMask range:endSearchRange];
		if (NSNotFound == stringEnd.location)
		{
			return stringEnd;	// not found
		}
	}
	result = NSMakeRange (stringStart.location, NSMaxRange(stringEnd) - stringStart.location );
	return result;
}

- (NSString *) replaceAllTextBetweenString:(NSString *)inString1 andString:(NSString *)inString2
	fromDictionary:(NSDictionary *)inDict
	options:(unsigned)inMask range:(NSRange)inSearchRange
{
	NSRange range = inSearchRange;	// We'll increment this
	NSUInteger startLength = [inString1 length];
	NSUInteger delimLength = startLength + [inString2 length];
	NSMutableString *buf = [NSMutableString string];

	NSRange beforeSearchRange = NSMakeRange(0,inSearchRange.location);
	[buf appendString:[self substringWithRange:beforeSearchRange]];

	// Now loop through; looking.
	while (range.length != 0)
	{
		NSRange foundRange = [self rangeFromString:inString1 toString:inString2 options:inMask range:range];
		if (foundRange.location != NSNotFound)
		{
			// First, append what was the search range and the found range -- before match -- to output
			{
				NSRange beforeRange = NSMakeRange(range.location, foundRange.location - range.location);
				NSString *before = [self substringWithRange:beforeRange];
				[buf appendString:before];
			}
			// Now, figure out what was between those two strings
			{
				NSRange betweenRange = NSMakeRange(foundRange.location + startLength, foundRange.length - delimLength);
				NSString *between = [self substringWithRange:betweenRange];
				if (nil != inDict)
				{
					between = [inDict objectForKey:between];	// replace string
				}
				// Now append the between value if not nil
				if (nil != between)
				{
					[buf appendString:[between description]];
				}
			}
			// Now, update things and move on.
			range.length = NSMaxRange(range) - NSMaxRange(foundRange);
			range.location = NSMaxRange(foundRange);
		}
		else
		{
			NSString *after = [self substringWithRange:range];
			[buf appendString:after];
			// Now, update to be past the range, to finish up.
			range.location = NSMaxRange(range);
			range.length = 0;
		}
	}
	// Finally, append stuff after the search range
	{
		NSRange afterSearchRange = NSMakeRange(range.location, [self length] - range.location);
		[buf appendString:[self substringWithRange:afterSearchRange]];
	}
	return [NSString stringWithString:buf];
}


/*"	Replace between the two given strings with the given options inMask; the delimeter strings are not included in the result.  The inMask parameter is the same as is passed to [NSString rangeOfString:options:range:].
"*/

- (NSString *) replaceAllTextBetweenString:(NSString *)inString1 andString:(NSString *)inString2
						 fromDictionary:(NSDictionary *)inDict
							options:(unsigned)inMask

{
	return [self replaceAllTextBetweenString:inString1 andString:inString2
								fromDictionary:inDict 
							  	options:inMask
								range:NSMakeRange(0,[self length])];
}

/*"	Replace between the two given strings with the default options; the delimeter strings are not included in the result.
"*/

- (NSString *) replaceAllTextBetweenString:(NSString *)inString1 andString:(NSString *)inString2
										fromDictionary:(NSDictionary *)inDict
{
	return [self replaceAllTextBetweenString:inString1 andString:inString2 fromDictionary:inDict options:0];
}

@end
