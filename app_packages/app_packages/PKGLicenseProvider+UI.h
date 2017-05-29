
#import "PKGLicenseProvider.h"

@interface PKGTokenTextAttachmentCell : NSTextAttachmentCell

	@property CGFloat maximumWidth;

	@property NSAttributedString * tokenLabel;

@end

@interface PKGLicenseProvider (UI)

+ (void)UI_replaceKeywords:(NSDictionary *)inDictionary inAttributedString:(NSMutableAttributedString *)inMutableAttributedString;

@end
