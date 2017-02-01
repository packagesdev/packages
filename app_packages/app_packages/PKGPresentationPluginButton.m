
#import "PKGPresentationPluginButton.h"

@implementation PKGPresentationPluginButton

- (void)setPluginButtonType:(PKGPresentationPluginButtonType)inPluginButtonType
{
	if (_pluginButtonType!=inPluginButtonType)
	{
		_pluginButtonType=inPluginButtonType;
		
		((PKGPresentationPluginButtonCell *) self.cell).pluginButtonType=inPluginButtonType;
		
		[self setNeedsDisplay:YES];
	}
}

@end
