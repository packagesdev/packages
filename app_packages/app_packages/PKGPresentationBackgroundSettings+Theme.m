
#import "PKGPresentationBackgroundSettings+Theme.h"

@implementation PKGPresentationBackgroundSettings (PKGPresentationTheme)

- (PKGPresentationBackgroundAppearanceSettings *)appearanceSettingsForTheme:(PKGPresentationThemeVersion)inTheme
{
	switch(inTheme)
	{
		case PKGPresentationThemeMountainLion:
		case PKGPresentationThemeMojaveLight:
			
			return [self appearanceSettingsForAppearanceMode:PKGPresentationAppearanceModeLight];
			
		case PKGPresentationThemeMojaveDark:
			
			return [self appearanceSettingsForAppearanceMode:PKGPresentationAppearanceModeDark];
			
		default:
			
			NSLog(@"Unsupported theme");
			break;
	}
	
	return nil;
}

@end
