#import "NSIndexSet+Analysis.h"

@implementation NSIndexSet (Analysis)

- (BOOL)PKG_containsOnlyOneRange
{
    NSUInteger tCount=[self count];
    
    if (tCount>0)
    {
        NSUInteger tFirstIndex=[self firstIndex];
        NSUInteger tLastIndex=[self lastIndex];
        
        return ((tLastIndex-tFirstIndex+1)==tCount);
    }
    
    return NO;
}

@end
