//
//  PKGReplaceableStringFormatter.m
//  app_packages
//
//  Created by stephane on 24/09/2021.
//

#import "PKGReplaceableStringFormatter.h"

@implementation PKGReplaceableStringFormatter

- (nullable NSString *)editingStringForObjectValue:(id)inObject
{
    if (inObject==nil)
        return @"";
    
    if ([inObject isKindOfClass:NSString.class])
        return inObject;
    
    if ([inObject isKindOfClass:NSAttributedString.class]==YES)
        return ((NSAttributedString *)inObject).string;
    
    return @"";
}

- (NSString *)stringForObjectValue:(id)inObject
{
    if (inObject==nil)
        return @"";
    
    NSString * tEditingString=@"";
    
    if ([inObject isKindOfClass:NSString.class])
    {
        tEditingString=[inObject copy];
    }
    else
    {
        if ([inObject isKindOfClass:NSAttributedString.class]==YES)
            tEditingString=((NSAttributedString *)inObject).string;
        
        return tEditingString;
    }
    
    if (self.keysReplacer==nil)
        return tEditingString;
    
    return [self.keysReplacer stringByReplacingKeysInString:tEditingString];
}

- (NSAttributedString *)attributedStringForObjectValue:(id)inObject withDefaultAttributes:(NSDictionary<NSAttributedStringKey, id> *)inAttributes
{
    if (inObject==nil)
        return [[NSAttributedString alloc] initWithString:@"" attributes:inAttributes];;
    
    NSString * tEditingString=@"";
    
    if ([inObject isKindOfClass:NSString.class])
    {
        tEditingString=inObject;
    }
    else
    {
        if ([inObject isKindOfClass:NSAttributedString.class]==YES)
            tEditingString=((NSAttributedString *)inObject).string;
    }
    
    if (self.keysReplacer!=nil)
        tEditingString=[self.keysReplacer stringByReplacingKeysInString:tEditingString];
    
    return [[NSAttributedString alloc] initWithString:tEditingString attributes:inAttributes];
}

#pragma mark -

- (BOOL)getObjectValue:(id *) outObject forString:(NSString *) inString errorDescription:(out NSString **) outError
{
    *outObject=[inString copy];
    
    return YES;
}

@end
