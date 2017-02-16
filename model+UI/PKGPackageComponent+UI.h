
#import "PKGPackageComponent.h"

@interface PKGPackageComponent (UI)

- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter;

@end
