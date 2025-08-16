#import "PKGDiskSpaceFormatter.h"

@implementation PKGDiskSpaceFormatter

- (NSString *) stringForObjectValue:(id) inObject
{
    if ([inObject isKindOfClass:NSString.class]==NO)
		return inObject;
    
    return inObject;
}

- (BOOL) getObjectValue:(id *) outObject forString:(NSString *) inString errorDescription:(NSString **) outError
{
    *outObject=[inString copy];
     
    return YES;
}

#pragma mark -

- (BOOL) isPartialStringValid:(NSString *) inPartialString newEditingString:(NSString **) outNewString errorDescription:(NSString **) outError
{
    if (inPartialString!=nil)
	{
		NSUInteger tLength=inPartialString.length;
		
		if (tLength>5)
		{
			*outNewString=nil;
			*outError=@"NSBeep";
				
			return NO;
		}
		
		for(NSUInteger tIndex=0;tIndex<tLength;tIndex++)
		{
			unichar tChar=[inPartialString characterAtIndex:tIndex];
			
			if (tChar<'0' || tChar>'9')
			{
				*outNewString=nil;
				*outError=@"NSBeep";
				
				return NO;
			}
		}
	}
	
	return YES;
}

@end
