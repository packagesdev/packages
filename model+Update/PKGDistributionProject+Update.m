
#import "PKGDistributionProject+Update.h"

#import "PKGPackageComponent+Update.h"

@implementation PKGDistributionProject (Update)

- (void)updateProjectAttributes:(PKGProjectAttribute)inProjectUpdateAttributes completionHandler:(void (^)(PKGProjectAttribute bUpdatedAttributes))handler
{
	__block PKGProjectAttribute tUpdatedAttributes=PKGProjectAttributeNone;
	
	for(PKGPackageComponent * tPackageComponent in self.packageComponents)
	{
		[tPackageComponent updateProjectAttributes:inProjectUpdateAttributes completionHandler:^(PKGProjectAttribute bUpdatedComponents) {
			
			tUpdatedAttributes|=bUpdatedComponents;
			
		}];
	}
	
	if (handler!=nil)
		handler(tUpdatedAttributes);
}

@end
