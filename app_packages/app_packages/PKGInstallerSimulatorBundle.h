
#import <Foundation/Foundation.h>

@interface PKGInstallerSimulatorBundle : NSObject

+ (PKGInstallerSimulatorBundle *)installerSimulatorBundle;

- (NSString *)localizedStringForKey:(NSString *)inKey localization:(NSString *)inLocalization;

@end
