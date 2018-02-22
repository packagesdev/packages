//
//  PKGPackageNameFormatter.m
//  app_packages
//
//  Created by stephane on 2/13/18.
//
//

#import "PKGPackageNameFormatter.h"

@interface PKGPackageNameFormatter ()

+ (NSCharacterSet *)forbiddenCharaterSet;

@end

@implementation PKGPackageNameFormatter

+ (NSCharacterSet *)forbiddenCharaterSet
{
	static NSCharacterSet * sForbiddenCharacterSet=nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		NSMutableCharacterSet * tMutableCharacterSet=[NSMutableCharacterSet characterSetWithRange:NSMakeRange(0,128)];
		
		[tMutableCharacterSet invert];
		[tMutableCharacterSet addCharactersInString:@"/"];
		
		sForbiddenCharacterSet=[tMutableCharacterSet copy];
		
	});
	
	return sForbiddenCharacterSet;
}

#pragma mark -

- (NSString *)stringForObjectValue:(id) inObject
{
	if ([inObject isKindOfClass:NSAttributedString.class]==YES)
		return ((NSAttributedString *)inObject).string;
	
	if ([inObject isKindOfClass:NSString.class]==NO)
		return inObject;
	
	return inObject;
}

- (BOOL)getObjectValue:(id *) outObject forString:(NSString *) inString errorDescription:(out NSString **) outError
{
	*outObject=[inString copy];
	
	return YES;
}

#pragma mark -

- (BOOL)isPartialStringValid:(NSString *) inPartialString newEditingString:(NSString **) outNewString errorDescription:(out NSString **) outError
{
	NSUInteger tLength=inPartialString.length;
	if (tLength==0)
		return YES;
	
	NSRange tRange=[inPartialString rangeOfCharacterFromSet:[PKGPackageNameFormatter forbiddenCharaterSet]];
	if (tRange.location==NSNotFound)
		return YES;
	
	if (outNewString!=NULL)
		*outNewString=nil;
	
	if (outError!=NULL)
		*outError=@"Error";
	
	return NO;
}

@end
