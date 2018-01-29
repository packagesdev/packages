
#import "PKGPackageProject+Update.h"

#import "PKGPackagePayload+Update.h"

@implementation PKGPackageProject (Update)

- (void)updateProjectAttributes:(PKGProjectAttribute)inProjectUpdateAttributes completionHandler:(void (^)(PKGProjectAttribute bUpdatedAttributes))handler
{
	__block PKGProjectAttribute tUpdatedAttributes=PKGProjectAttributeNone;
	
	if ((inProjectUpdateAttributes & PKGProjectAttributeDefaultPayloadHierarchy)!=0)
	{
		[self.payload updateProjectAttributes:inProjectUpdateAttributes completionHandler:^(PKGProjectAttribute bUpdatedComponents) {
			
			tUpdatedAttributes|=bUpdatedComponents;
			
		}];
	}
	
	if (handler!=nil)
		handler(tUpdatedAttributes);
}

@end
