
#import <Foundation/Foundation.h>

@interface PKGDocumentRegistry : NSObject

- (id)objectForKey:(NSString *)inKey;
- (NSInteger)integerForKey:(NSString *)inKey;

- (void)setObject:(id)inObject forKey:(NSString *)inKey;
- (void)setInteger:(NSInteger)inInteger forKey:(NSString *)inKey;

- (void)removeObjectForKey:(NSString *)inKey;

- (id)objectForKeyedSubscript:(id)inKey;
- (void)setObject:(id)inObject forKeyedSubscript:(id)inKey;

@end
