
#import <Foundation/Foundation.h>

#import "PKGObjectProtocol.h"

#import "PKGPackagesError.h"

@interface PKGDistributionProjectSettingsAdvancedOptionsObject : NSObject <PKGObjectProtocol>

	@property (readonly) NSString * title;

	@property (nonatomic,readonly) BOOL supportsAdvancedEditor;

+ (NSDictionary *)advancedOptionsRegistryWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError;

@end
