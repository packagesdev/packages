
#import "PKGInstallerSimulatorBundle.h"

#import "PKGLanguageConverter.h"

NSString * const PKGInstallerSimulatorBundleName=@"InstallerSimulator.bundle";

@interface PKGInstallerSimulatorBundle ()
{
	NSBundle * _bundle;
	
	NSMutableDictionary * _localizations;
}

- (NSDictionary *)localizableStringsForLocalization:(NSString *)inLanguage;

@end

@implementation PKGInstallerSimulatorBundle

+ (PKGInstallerSimulatorBundle *)installerSimulatorBundle
{
	static dispatch_once_t onceToken;
	static PKGInstallerSimulatorBundle * sInstallerSimulatorBundle=nil;
	
	dispatch_once(&onceToken, ^{
		sInstallerSimulatorBundle=[PKGInstallerSimulatorBundle new];
	});
	
	return sInstallerSimulatorBundle;
}

- (instancetype)init
{
	NSString * tBundlePath=[[NSBundle mainBundle].builtInPlugInsPath stringByAppendingPathComponent:PKGInstallerSimulatorBundleName];
	
	NSBundle * tBundle=[NSBundle bundleWithPath:tBundlePath];
	
	if (tBundle==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_bundle=tBundle;
	}
	
	return self;
}

#pragma mark -

- (NSDictionary *)localizableStringsForLocalization:(NSString *)inLocalization
{
	if (inLocalization==nil)
		return nil;
	
	NSMutableDictionary * tLocalizedDictionary=[NSMutableDictionary dictionary];
	
	NSString * tPath=[_bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:inLocalization];
	
	if (tPath==nil)
	{
		NSString * tISOLanguage=[[PKGLanguageConverter sharedConverter] ISOFromEnglish:inLocalization];
		
		tPath=[_bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:tISOLanguage];
		
		if (tPath==nil)
		{
			NSString * tISOFailOverLanguage=[[PKGLanguageConverter sharedConverter] ISOFailOverForISO:tISOLanguage];
			
			tPath=[_bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:tISOFailOverLanguage];
			
			if (tPath==nil)
			{
				tISOFailOverLanguage=[[PKGLanguageConverter sharedConverter] englishFromISO:tISOFailOverLanguage];
				
				tPath=[_bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:tISOFailOverLanguage];
			}
		}
	}
	
	if (tPath!=nil)
	{
		NSDictionary * tLocalizableDictionary=[[NSDictionary alloc] initWithContentsOfFile:tPath];
		
		if (tLocalizableDictionary!=nil)
			[tLocalizedDictionary addEntriesFromDictionary:tLocalizableDictionary];
	}
	
	return [tLocalizedDictionary copy];
}

- (NSString *)localizedStringForKey:(NSString *)inKey localization:(NSString *)inLocalization
{
	if (inKey==nil || inLocalization==nil)
		return nil;
	
	NSDictionary * tLocalization=_localizations[inLocalization];
	
	if (tLocalization!=nil)
		return tLocalization[inKey];
	
	tLocalization=[self localizableStringsForLocalization:inLocalization];
	
	if (tLocalization!=nil)
	{
		_localizations[inLocalization]=tLocalization;
		
		return tLocalization[inKey];
	}
	
	return nil;
}

@end
