
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

- (NSString *)payloadSelectionStatesKey
{
	return [NSString stringWithFormat:@"ui.package[%@].payload.selection",self.UUID];
}

- (NSString *)additionalResourcesSelectionStatesKey
{
	return [NSString stringWithFormat:@"ui.package[%@].additionalResources.selection",self.UUID];
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

- (NSArray *)selectionStatesKeys
{
	return @[self.payloadSelectionStatesKey,
			 self.additionalResourcesSelectionStatesKey];
}

@end
