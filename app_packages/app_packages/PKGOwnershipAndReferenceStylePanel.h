
#import <Cocoa/Cocoa.h>

#import "PKGFilePath.h"

enum {
	PKGOwnershipAndReferenceStylePanelCancelButton	= NSModalResponseCancel,
	PKGOwnershipAndReferenceStylePanelOKButton	= NSModalResponseOK,
};

@interface PKGOwnershipAndReferenceStylePanel : NSPanel

	@property (nonatomic) BOOL canChooseOwnerAndGroupOptions;

	@property (nonatomic) BOOL keepOwnerAndGroup;

	@property (nonatomic) PKGFilePathType referenceStyle;

	@property (nonatomic,copy) NSString * prompt;

+ (PKGOwnershipAndReferenceStylePanel *) ownershipAndReferenceStylePanel;

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSInteger result))handler;

@end
