
#import "PKGOwnershipAndReferenceStyleViewController.h"

@interface PKGOwnershipAndReferenceStyleViewController ()
{
	IBOutlet NSView * _keepOwnerAndGroupView;
	IBOutlet NSButton * _keepOwnerAndGroupButton;
	
	IBOutlet NSView * _referenceStyleView;
	IBOutlet NSPopUpButton * _referenceStylePopUpButton;
}

- (void)_updateViewLayout;

- (IBAction)switchKeepOwnerAndGroup:(id)sender;

- (IBAction)switchReferenceStyle:(id)sender;

@end

@implementation PKGOwnershipAndReferenceStyleViewController

- (NSString *)nibName
{
	return NSStringFromClass([self class]);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[self _updateViewLayout];
}

#pragma mark -

- (void)_updateViewLayout
{
	if (_canChooseOwnerAndGroupOptions==_keepOwnerAndGroupView.hidden)
	{
		_keepOwnerAndGroupView.hidden=!_keepOwnerAndGroupView.hidden;
		
		NSRect tFrame=self.view.frame;
		
		tFrame.size.height=NSHeight(_referenceStyleView.frame);
		
		if (_canChooseOwnerAndGroupOptions==YES)
			tFrame.size.height=tFrame.size.height+NSHeight(_keepOwnerAndGroupView.frame);
		
		self.view.frame=tFrame;
	}
}

#pragma mark -

- (void)WB_viewWillAdd
{
	[_keepOwnerAndGroupButton setState:(_keepOwnerAndGroup==YES) ? NSOnState : NSOffState];
	
	[_referenceStylePopUpButton selectItemWithTag:_referenceStyle];
}

#pragma mark -

- (void)setCanChooseOwnerAndGroupOptions:(BOOL)inCanChooseOwnerAndGroupOptions
{
	if (_canChooseOwnerAndGroupOptions!=inCanChooseOwnerAndGroupOptions)
	{
		_canChooseOwnerAndGroupOptions=inCanChooseOwnerAndGroupOptions;
		
		[self _updateViewLayout];
	}
}

#pragma mark -

- (void)setKeepOwnerAndGroup:(BOOL)inKeepOwnerAndGroup
{
	if (inKeepOwnerAndGroup!=_keepOwnerAndGroup)
	{
		_keepOwnerAndGroup=inKeepOwnerAndGroup;
		
		[_keepOwnerAndGroupButton setState:(_keepOwnerAndGroup==YES) ? NSOnState : NSOffState];
	}
}

- (void)setReferenceStyle:(PKGFilePathType)inReferenceStyle
{
	if (inReferenceStyle!=_referenceStyle)
	{
		_referenceStyle=inReferenceStyle;
		
		[_referenceStylePopUpButton selectItemWithTag:_referenceStyle];
	}
}

#pragma mark -

- (IBAction)switchKeepOwnerAndGroup:(id)sender
{
	_keepOwnerAndGroup=([_keepOwnerAndGroupButton state]==NSOnState);
}

- (IBAction)switchReferenceStyle:(id)sender
{
	_referenceStyle=[[_referenceStylePopUpButton selectedItem] tag];
}

@end
