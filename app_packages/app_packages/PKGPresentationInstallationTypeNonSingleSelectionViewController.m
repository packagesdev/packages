
#import "PKGPresentationInstallationTypeNonSingleSelectionViewController.h"

@interface PKGPresentationInstallationTypeNonSingleSelectionViewController ()
{
	IBOutlet NSTextField * _labelTextField;
}

// Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationInstallationTypeNonSingleSelectionViewController

- (void)setLabel:(NSString *)inLabel
{
	if (_label==inLabel)
		return;
	
	_label=[inLabel copy];
	
	[self refreshUI];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self refreshUI];
	
	[self viewFrameDidChange:nil];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:)name:NSViewFrameDidChangeNotification object:self.view];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter]  removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
}

- (void)refreshUI
{
	_labelTextField.stringValue=(self.label==nil) ? @"" : self.label;
}

#pragma mark - Notification

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	NSRect tBounds=self.view.bounds;
	
	NSRect tFrame=_labelTextField.frame;
	
	// Center vertically
	
	tFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tFrame)*0.5);
	
	_labelTextField.frame=tFrame;
}

@end
