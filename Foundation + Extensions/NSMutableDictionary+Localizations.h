
#import <Foundation/Foundation.h>

@interface NSMutableDictionary (PKG_Localizations)

- (id)valueForLocalization:(NSString *)inLocalization exactMatch:(BOOL)inExactMatch valueSetChecker:(BOOL (^)(id))valueChecker;

@end
