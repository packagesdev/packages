
#import <Cocoa/Cocoa.h>

#import "PKGFilePath.h"

@interface PKGOwnershipAndReferenceStyleViewController : NSViewController

	@property (nonatomic) BOOL canChooseOwnerAndGroupOptions;

	@property (nonatomic) BOOL keepOwnerAndGroup;

	@property (nonatomic) PKGFilePathType referenceStyle;

@end
