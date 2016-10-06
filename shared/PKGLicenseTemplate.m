
#import "PKGLicenseTemplate.h"

#import "PKGFilePath.h"

NSString * const PKGLicenseTemplateFileName=@"License.rtf";
NSString * const PKGLicenseTemplateKeywordsFileName=@"Keywords.plist";
NSString * const PKGLicenseTemplateSLAFileName=@"sla.plist";

@interface PKGLicenseTemplate ()

	@property (readwrite) NSDictionary * localizations;

	@property (readwrite) NSArray * keywords;

	@property (readwrite,copy) NSString * slaReference;

@end

@implementation PKGLicenseTemplate

- (instancetype)initWithContentsOfDirectory:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		NSFileManager * tFileManager=[NSFileManager defaultManager];
		
		// Localizations
		
		NSMutableDictionary * tLocalizations=[NSMutableDictionary dictionary];
		
		NSArray * tComponents=[tFileManager contentsOfDirectoryAtPath:inPath error:NULL];
		
		if (tComponents==nil)
			return nil;
		
		for(NSString * tLanguageName in tComponents)
		{
			NSString * tLicensePath=[[inPath stringByAppendingPathComponent:tLanguageName] stringByAppendingPathComponent:PKGLicenseTemplateFileName];
			BOOL isDirectory;
			
			if ([tFileManager fileExistsAtPath:tLicensePath isDirectory:&isDirectory]==YES && isDirectory==NO)
				tLocalizations[[tLanguageName stringByDeletingPathExtension]]=[PKGFilePath filePathWithAbsolutePath:tLicensePath];
		}
		
		_localizations=[tLocalizations copy];
		
		// Keywords
		
		_keywords=[NSArray arrayWithContentsOfFile:[inPath stringByAppendingPathComponent:PKGLicenseTemplateKeywordsFileName]];
		
		// Software License Agreement Reference (only used by Apple)
		
		NSDictionary * tSLADictionary=[NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:PKGLicenseTemplateSLAFileName]];
		_slaReference=[tSLADictionary[@"sla"] copy];
	}
	
	return self;
}

#pragma mark -

- (NSUInteger)hash
{
	return [_localizations hash];
}

@end
