/*
Copyright (c) 2003 Karelia Software, LLC.  All rights reserved. 
 
 Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies. 
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 
 Except as contained in this notice, the name of a copyright holder shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization of the copyright holder.
*/

#import <Foundation/Foundation.h>

@interface NSString ( Karelia )

- (NSRange) rangeFromString:(NSString *)inString1 toString:(NSString *)inString2;
- (NSRange) rangeFromString:(NSString *)inString1 toString:(NSString *)inString2 options:(unsigned)inMask;
- (NSRange) rangeFromString:(NSString *)inString1 toString:(NSString *)inString2 options:(unsigned)inMask range:(NSRange)inSearchRange;

- (NSString *) replaceAllTextBetweenString:(NSString *)inString1 andString:(NSString *)inString2 fromDictionary:(NSDictionary *)inDict options:(unsigned)inMask range:(NSRange)inSearchRange;

- (NSString *) replaceAllTextBetweenString:(NSString *)inString1 andString:(NSString *)inString2 fromDictionary:(NSDictionary *)inDict options:(unsigned)inMask;

- (NSString *) replaceAllTextBetweenString:(NSString *)inString1 andString:(NSString *)inString2 fromDictionary:(NSDictionary *)inDict;

@end
