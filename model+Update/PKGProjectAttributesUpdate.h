
#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, PKGProjectAttribute)
{
	PKGProjectAttributeNone=0,
	
	PKGProjectAttributeDefaultPayloadHierarchy = 1 << 0,
	
	PKGProjectAttributeAll=PKGProjectAttributeDefaultPayloadHierarchy
};

@protocol PKGProjectAttributesUpdate

- (void)updateProjectAttributes:(PKGProjectAttribute)inProjectUpdateAttributes completionHandler:(void (^)(PKGProjectAttribute bUpdatedAttributes))handler;

@end

