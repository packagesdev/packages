/*
Copyright (c) 2009-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "NSRangeUtilities.h"

@implementation NSValue (SortRange)

- (NSComparisonResult) compareRangeLocation:(NSValue *) inValue
{
	if (inValue!=nil)
	{
		NSRange tRange=self.rangeValue;
		NSRange tOtherRange=inValue.rangeValue;
		
		if (tRange.location<tOtherRange.location)
			return NSOrderedAscending;
		
		if (tRange.location>tOtherRange.location)
			return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

@end

@implementation NSRangeUtilities

+ (NSUInteger) indexOfRangeIncludingLocation:(NSUInteger) inLocation withinRanges:(NSArray *) inArray
{
	__block NSUInteger tFoundIndex=NSNotFound;
	
	[inArray enumerateObjectsUsingBlock:^(NSValue * bValue,NSUInteger bIndex,BOOL * bOutStop){
	
		NSRange tRange=bValue.rangeValue;
		
		if (NSLocationInRange(inLocation,tRange)==YES)
		{
			tFoundIndex=bIndex;
			*bOutStop=YES;
		}
	}];

	return tFoundIndex;
}

+ (BOOL) location:(NSUInteger) inLocation isInsideRanges:(NSArray *) inArray
{
	for(NSValue * tValue in inArray)
    {
        NSRange tOtherRange=tValue.rangeValue;
        
        if (NSLocationInRange(inLocation,tOtherRange)==YES)
			return YES;
    }
	
	return NO;
}

+ (BOOL) range:(NSRange) inRange intersectsRanges:(NSArray *) inArray
{
	for(NSValue * tValue in inArray)
    {
        NSRange tOtherRange=tValue.rangeValue;
        
        if (NSIntersectionRange(inRange,tOtherRange).length!=0)
			return YES;
    }
	
	return NO;
}

+ (BOOL) range:(NSRange) inRange intersectsSortedRanges:(NSArray *) inArray
{
	for(NSValue * tValue in inArray)
    {
        NSRange tOtherRange=tValue.rangeValue;
        
        if (tOtherRange.location>=NSMaxRange(inRange))
			return NO;
        
        if (NSIntersectionRange(inRange,tOtherRange).length!=0)
			return YES;
    }
	
	return NO;
}

+ (NSArray *) rangesFromRange:(NSRange) inRange excludingRanges:(NSArray *) inRanges
{
	if (inRanges==nil)
		return [NSArray arrayWithObject:[NSValue valueWithRange:inRange]];
	
	NSMutableArray * tAvailableRanges=[NSMutableArray array];
	
	NSMutableArray * tSortedRangesArray=[NSMutableArray arrayWithArray:inRanges];
		
	if (tSortedRangesArray!=nil)
	{
		[tSortedRangesArray sortUsingSelector:@selector(compareRangeLocation:)];
		
		if (tAvailableRanges!=nil)
		{
			NSRange tNextAvailableRange=inRange;
			
			for(NSValue * tValue in tSortedRangesArray)
			{
				NSRange tExcludedRange=tValue.rangeValue;
				NSUInteger tMaxExcludedRange=NSMaxRange(tExcludedRange);
				NSUInteger tMaxAvailableRange=NSMaxRange(tNextAvailableRange);
				
				if (tExcludedRange.location<tMaxAvailableRange)
				{
					if (tExcludedRange.location>tNextAvailableRange.location)
					{
						NSValue * tAvailableValue=[NSValue valueWithRange:NSMakeRange(tNextAvailableRange.location,tExcludedRange.location-tNextAvailableRange.location)];
						
						[tAvailableRanges addObject:tAvailableValue];
						
						if (tMaxExcludedRange<tMaxAvailableRange)
						{
							tNextAvailableRange.location=tMaxExcludedRange;
							tNextAvailableRange.length=tMaxAvailableRange-tMaxExcludedRange;
						}
						else
						{
							tNextAvailableRange.length=0;
							
							break;
						}
					}
					else if (tMaxExcludedRange>tNextAvailableRange.location)
					{
						NSRange tReallyExcludedRange=NSMakeRange(tNextAvailableRange.location,tMaxExcludedRange-tNextAvailableRange.location);
						
						if (NSMaxRange(tReallyExcludedRange)>=tMaxAvailableRange)
						{
							tNextAvailableRange.length=0;
							
							break;
						}
						
						tNextAvailableRange.location=NSMaxRange(tReallyExcludedRange);
						tNextAvailableRange.length=tMaxAvailableRange-NSMaxRange(tReallyExcludedRange);
					}
				}
			}
			
			if (tNextAvailableRange.length>0)
			{
				NSValue * tAvailableValue=[NSValue valueWithRange:tNextAvailableRange];
						
				[tAvailableRanges addObject:tAvailableValue];
			}
		}
	}
	
	return [tAvailableRanges copy];
}

+ (NSArray *) sortedRanges:(NSArray *) inArray intersectingRange:(NSRange) inRange
{
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
	if (inArray!=nil && (inRange.length>0))
	{
		for(NSValue * tValue in inArray)
		{
			NSRange tRange=tValue.rangeValue;
			
			if (tRange.location>=NSMaxRange(inRange))
				break;
			
			if (NSIntersectionRange(tRange,inRange).length>0)
				[tMutableArray addObject:tValue];
		}
	}
	
	return [tMutableArray copy];
}

@end
