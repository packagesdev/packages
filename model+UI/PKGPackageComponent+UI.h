
#import "PKGPackageComponent.h"

@interface PKGPackageComponent (UI)

	@property (nonatomic,readonly) NSString * payloadDisclosedStatesKey;

	@property (nonatomic,readonly) NSString * additionalResourcesDisclosedStatesKey;

- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter;

- (NSArray *)disclosedStatesKeys;

@end
