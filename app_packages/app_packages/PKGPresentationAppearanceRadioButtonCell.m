
#import "PKGPresentationAppearanceRadioButtonCell.h"

static BOOL PKGAppearanceRadioButtonCellCheatEnabled=NO;

@interface NSButtonCell (Apple_Private)

- (NSButtonType)_buttonType;

@end

@implementation PKGPresentationAppearanceRadioButtonCell

- (NSButtonType)_buttonType
{
	if (PKGAppearanceRadioButtonCellCheatEnabled==YES)
		return WBButtonTypeRadio;
	
	return [super _buttonType];
}

- (void)setState:(NSInteger)state
{
	PKGAppearanceRadioButtonCellCheatEnabled=YES;
	
	[super setState:state];
	
	PKGAppearanceRadioButtonCellCheatEnabled=NO;
}

@end
