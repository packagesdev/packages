
#import "PKGPresentationContentView.h"

@implementation PKGPresentationContentView

- (void)drawRect:(NSRect)inRect
{
	if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
		return;
	
	if ([self WB_isEffectiveAppearanceDarkAqua]==NO)
	{
		[[NSColor colorWithDeviceWhite:0.98 alpha:1.0] set];	// Window Background Color Light: 0.93
	}
	else
	{
		[[NSColor colorWithDeviceWhite:0.17 alpha:1.0] set];	// Window Background Color Light: 0.20
	}
	
	NSRectFillUsingOperation(inRect, WBCompositingOperationSourceOver);
}

@end
