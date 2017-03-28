
#import "PKGPackageComponent.h"

@interface PKGPackageComponent (UI)

	@property (nonatomic,readonly) NSString * payloadDisclosedStatesKey;

	@property (nonatomic,readonly) NSString * payloadSelectionStatesKey;

	@property (nonatomic,readonly) NSString * additionalResourcesDisclosedStatesKey;

	@property (nonatomic,readonly) NSString * additionalResourcesSelectionStatesKey;

- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter;

- (NSArray *)disclosedStatesKeys;

- (NSArray *)selectionStatesKeys;

@end
