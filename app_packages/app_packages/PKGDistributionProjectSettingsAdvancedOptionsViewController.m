
#import "PKGDistributionProjectSettingsAdvancedOptionsViewController.h"

@interface PKGDistributionProjectSettingsAdvancedOptionsViewController () <NSOutlineViewDelegate>

	@property (readwrite) IBOutlet NSOutlineView * outlineView;

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionsViewController


#pragma mark -

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(id)inItem
{
	return nil;
}

@end
