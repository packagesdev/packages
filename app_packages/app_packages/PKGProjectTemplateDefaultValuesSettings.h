
#import <Foundation/Foundation.h>

extern NSString * const PKGProjectTemplateCompanyNameKey;

extern NSString * const PKGProjectTemplateCompanyIdentifierPrefixKey;

@interface PKGProjectTemplateDefaultValuesSettings : NSObject

+ (PKGProjectTemplateDefaultValuesSettings *)sharedSettings;

@property (readonly) NSArray * allKeys;

- (id)valueForKey:(NSString *)inKey;

- (void)setValue:(id)inValue forKey:(NSString *)inKey;

@end
