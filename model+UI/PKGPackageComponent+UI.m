
#import "PKGPackageComponent+UI.h"

@implementation PKGPackageComponent (UI)

- (NSString *)payloadDisclosedStatesKey
{
	return [NSString stringWithFormat:@"ui.package[%@].payload.disclosed",self.UUID];
}

- (NSString *)additionalResourcesDisclosedStatesKey
{
	return [NSString stringWithFormat:@"ui.package[%@].additionalResources.disclosed",self.UUID];
}

#pragma mark -

- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter
{
	return [inPathConverter absolutePathForFilePath:self.importPath];
}

- (NSArray *)disclosedStatesKeys
{
	return @[self.payloadDisclosedStatesKey,
			 self.additionalResourcesDisclosedStatesKey];
}

@end
