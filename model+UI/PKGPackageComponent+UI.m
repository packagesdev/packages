
#import "PKGPackageComponent+UI.h"

@implementation PKGPackageComponent (UI)

- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter
{
	return [inPathConverter absolutePathForFilePath:self.importPath];
}

@end
