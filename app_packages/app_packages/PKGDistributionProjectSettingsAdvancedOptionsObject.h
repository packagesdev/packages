
#import <Foundation/Foundation.h>

#import "PKGObjectProtocol.h"

@interface PKGDistributionProjectSettingsAdvancedOptionsObject : NSObject <PKGObjectProtocol>

	@property (readonly) NSString * title;

+ (NSDictionary *)advancedOptionsRegistryWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError;

@end
