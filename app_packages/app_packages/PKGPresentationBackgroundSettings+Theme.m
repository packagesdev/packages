
#import "PKGPresentationBackgroundSettings+Theme.h"

@implementation PKGPresentationBackgroundSettings (PKGPresentationTheme)

- (PKGPresentationBackgroundAppearanceSettings *)appearanceSettingsForTheme:(PKGPresentationThemeVersion)inTheme
{
	switch(inTheme)
	{
		case PKGPresentationThemeMountainLion:
		case PKGPresentationThemeMojaveLight:
			
			return [self appearanceSettingsForAppearanceMode:PKGPresentationAppareanceModeLight];
			
		case PKGPresentationThemeMojaveDark:
			
			return [self appearanceSettingsForAppearanceMode:PKGPresentationAppareanceModeDark];
			
		default:
			
			NSLog(@"Unsupported theme");
			break;
	}
	
	return nil;
}

@end
