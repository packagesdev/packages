
#import "PKGPresentationControlledView.h"

NSString * const PKGPresentationControlledViewEffectiveAppearanceDidChangeNotification=@"PKGPresentationControlledViewEffectiveAppearanceDidChangeNotification";

@implementation PKGPresentationControlledView


- (void)viewDidChangeEffectiveAppearance
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationControlledViewEffectiveAppearanceDidChangeNotification object:self];
}

@end
