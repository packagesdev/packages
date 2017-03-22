#import "PKGAdvancedOptionsOutlineView.h"

@implementation PKGAdvancedOptionsOutlineView

- (id)makeViewWithIdentifier:(NSString *)inIdentifier owner:(id)inOwner
{
	id tView=[super makeViewWithIdentifier:inIdentifier owner:inOwner];
	
	if ([inIdentifier isEqualToString:NSOutlineViewDisclosureButtonKey]==YES)
	{
		NSButton * tButton=(NSButton *)tView;
		
		//[tButton.cell setBackgroundStyle:NSBackgroundStyleDark];
		
		static NSImage * sCloseImage=nil;
		static NSImage * sDiscloseImage=nil;
		static dispatch_once_t onceToken;
		
		dispatch_once(&onceToken, ^{
			sCloseImage=[NSImage imageNamed:@"olv_close"];
			sDiscloseImage=[NSImage imageNamed:@"olv_disclose"];
		});
		
		tButton.image=sDiscloseImage;
		tButton.alternateImage=sCloseImage;
	}
	
	return tView;
}

@end
