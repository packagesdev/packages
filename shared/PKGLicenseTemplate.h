
#import <Foundation/Foundation.h>

@interface PKGLicenseTemplate : NSObject

	@property (readonly) NSDictionary * localizations;

	@property (readonly) NSArray * keywords;

	@property (readonly,copy) NSString * slaReference;

- (instancetype)initWithContentsOfDirectory:(NSString *)inPath;

@end
