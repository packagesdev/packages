
#import "PKGPanel.h"

#import "PKGDistributionProjectSettingsAdvancedOptionObject.h"

@interface PKGAdvancedOptionPanel : PKGPanel

	@property (nonatomic) id optionValue;

	@property (nonatomic) PKGDistributionProjectSettingsAdvancedOptionObject * advancedOptionObject;

+ (id)advancedOptionPanel;

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSInteger result))handler;

@end
