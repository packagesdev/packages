
#import "PKGPresentationContentView.h"

#import "NSWindow+Appearance.h"

@implementation PKGPresentationContentView

- (void)drawRect:(NSRect)inRect
{
	if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
		return;
	
	if ([[self.window WB_effectiveAppareanceName] isEqualToString:[self WB_effectiveAppareanceName]]==NO)
		return;
	
	if ([self WB_isEffectiveAppareanceDarkAqua]==YES)
	{
		[[NSColor colorWithDeviceWhite:1.0 alpha:1.0] set];
	}
	else
	{
		[[NSColor colorWithDeviceWhite:0.133 alpha:1.000] set];
	}
	
	NSRectFillUsingOperation(inRect, NSCompositeSourceOver);
}

@end
