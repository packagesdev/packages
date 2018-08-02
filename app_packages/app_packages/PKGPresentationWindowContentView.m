
#import "PKGPresentationWindowContentView.h"

@implementation PKGPresentationWindowContentView

- (void)awakeFromNib
{
	self.boxType=NSBoxCustom;
	self.borderType=NSNoBorder;
	
#if DEBUG_DARK_AQUA_PKG==1
	self.fillColor=[NSColor redColor];
#else
	self.fillColor=[NSColor windowBackgroundColor];
#endif
}

@end
