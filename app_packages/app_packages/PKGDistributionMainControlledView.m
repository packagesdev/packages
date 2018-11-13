
#import "PKGDistributionMainControlledView.h"

NSString * const PKGDistributionPresentationSelectedAppearance=@"ui.project.presentation.appearance";

NSString * const PKGDistributionViewEffectiveAppearanceDidChangeNotification=@"PKGDistributionViewEffectiveAppearanceDidChangeNotification";

@implementation PKGDistributionMainControlledView

- (void)viewDidChangeEffectiveAppearance
{
   [[NSNotificationCenter defaultCenter] postNotificationName:PKGDistributionViewEffectiveAppearanceDidChangeNotification object:self.window userInfo:@{@"EffectiveAppearance":[self WB_effectiveAppearanceName]}];
}

@end
