
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PKGPresentationThemeVersion)
{
	PKGPresentationThemeMountainLion=0,
	PKGPresentationThemeYosemite=1,
	PKGPresentationThemeMojaveLight=PKGPresentationThemeYosemite,
	PKGPresentationThemeMojaveDark=3,
	PKGPresentationThemeMojaveDynamic=255
};

extern NSString * const PKGPresentationTheme;


extern NSString * const PKGPresentationThemeDidChangeNotification;

