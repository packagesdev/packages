
#import <Foundation/Foundation.h>

@interface NSDictionary (WB_DeepCopy)

- (instancetype)deepCopy;

@end

@interface NSArray (WB_DeepCopy)

- (instancetype)deepCopy;

@end

@interface NSSet (WB_DeepCopy)

- (instancetype)deepCopy;

@end

@interface NSOrderedSet (WB_DeepCopy)

- (instancetype)deepCopy;

@end


