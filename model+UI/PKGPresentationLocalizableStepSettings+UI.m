
#import "PKGPresentationLocalizableStepSettings+UI.h"

#import "NSMutableDictionary+Localizations.h"

@implementation PKGPresentationLocalizableStepSettings (UI)

- (id)valueForLocalization:(NSString *)inLocalization exactMatch:(BOOL)inExactMatch
{
	return [self.localizations valueForLocalization:inLocalization exactMatch:inExactMatch valueSetChecker:^BOOL(id bValue){
	
		return [self isValueSet:bValue];
	}];
}

@end
