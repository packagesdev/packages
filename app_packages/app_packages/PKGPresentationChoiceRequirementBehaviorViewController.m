
#import "PKGPresentationChoiceRequirementBehaviorViewController.h"

@interface PKGPresentationChoiceRequirementBehaviorViewController ()
{
	IBOutlet NSButton * _removeChoiceRadioButton;
	IBOutlet NSButton * _disableChoiceRadioButton;
}

- (IBAction)switchBehavior:(id)sender;

@end

@implementation PKGPresentationChoiceRequirementBehaviorViewController

- (PKGRequirementFailureMessage *)defaultMessage
{
	PKGRequirementFailureMessage * tMessage=[PKGRequirementFailureMessage new];
	
	tMessage.messageTitle=@"";
	tMessage.messageDescription=nil;
	
	return tMessage;
}

- (void)setRequirementBehavior:(PKGRequirementOnFailureBehavior)inRequirementBehavior
{
	[super setRequirementBehavior:inRequirementBehavior];
	
	switch(inRequirementBehavior)
	{
		case PKGRequirementOnFailureBehaviorDeselectAndHideChoice:
			
			_removeChoiceRadioButton.state=WBControlStateValueOn;
			
			break;
			
		case PKGRequirementOnFailureBehaviorDeselectAndDisableChoice:
			
			_disableChoiceRadioButton.state=WBControlStateValueOn;
			
			break;
			
		default:
			break;
	}
}


#pragma mark -

- (IBAction)switchBehavior:(NSButton *)sender
{
	[super setRequirementBehavior:sender.tag];
}

@end
