
#import "PKGAdvancedOptionPanel.h"

#import "PKGAdvancedOptionEditorViewController.h"

#import "PKGAdvancedOptionListEditorViewController.h"

@interface PKGAdvancedOptionWindowController : NSWindowController
{
	IBOutlet NSView * _optionPlaceHolderView;
	
	IBOutlet NSButton * _okButton;
	
	IBOutlet NSButton * _cancelButton;
	
	PKGAdvancedOptionEditorViewController * _editorViewController;
}

	@property (nonatomic,copy) NSString * prompt;

	@property (nonatomic) id optionValue;
	@property (nonatomic) PKGDistributionProjectSettingsAdvancedOptionObject * advancedOptionObject;

- (void)refreshUI;

- (IBAction)endDialog:(id)sender;

// Notifications

- (void)editorViewSizeShallChange:(NSNotification *)inNotification;

@end



@implementation PKGAdvancedOptionWindowController

@synthesize optionValue=_optionValue;

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"PKGAdvancedOptionPanel";
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	// A COMPLETER
}

#pragma mark -

- (void)setPrompt:(NSString *)inPrompt
{
	_prompt=[inPrompt copy];
	
	if (_okButton!=nil && _prompt!=nil)
	{
		NSRect tButtonFrame=_okButton.frame;
		
		_okButton.title=_prompt;
		
		[_okButton sizeToFit];
		
		CGFloat tWidth=NSWidth(_okButton.frame);
		
		if (tWidth<PKGAppkitMinimumPushButtonWidth)
			tWidth=PKGAppkitMinimumPushButtonWidth;
		
		CGFloat tDeltaWidth=tWidth-NSWidth(tButtonFrame);
		
		tButtonFrame.origin.x-=tDeltaWidth;
		tButtonFrame.size.width=tWidth;
		
		_okButton.frame=tButtonFrame;
		
		tButtonFrame=_cancelButton.frame;
		tButtonFrame.origin.x-=tDeltaWidth;
		
		_cancelButton.frame=tButtonFrame;
	}
}

- (id)optionValue
{
	if (_editorViewController==nil)
		return nil;
	
	return _editorViewController.optionValue;
}

- (void)setOptionValue:(id)inOptionValue
{
	_optionValue=inOptionValue;
	
	if (_editorViewController==nil)
		return;
	
	_editorViewController.optionValue=_optionValue;
}

- (void)setAdvancedOptionObject:(PKGDistributionProjectSettingsAdvancedOptionObject *)inAdvancedOptionObject
{
	if (inAdvancedOptionObject==nil)
		return;
	
	if (_editorViewController!=nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGAdvancedOptionEditorViewSizeShallChangeNotification object:_editorViewController.view];
		
		[_editorViewController WB_viewWillDisappear];
		
		[_editorViewController.view removeFromSuperview];
		
		[_editorViewController WB_viewDidDisappear];
	}
	
	PKGAdvancedOptionEditorViewController * nEditorViewController=[PKGAdvancedOptionListEditorViewController new];
	
	nEditorViewController.editorRepresentation=inAdvancedOptionObject.advancedEditorRepresentation;
	nEditorViewController.optionValue=_optionValue;
	
	nEditorViewController.view.frame=_optionPlaceHolderView.bounds;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editorViewSizeShallChange:) name:PKGAdvancedOptionEditorViewSizeShallChangeNotification object:nEditorViewController.view];
	
	[nEditorViewController WB_viewWillAppear];
	
	[_optionPlaceHolderView addSubview:nEditorViewController.view];
	
	[nEditorViewController WB_viewDidAppear];
	
	_editorViewController=nEditorViewController;
}

#pragma mark -

- (void)refreshUI
{
	// A COMPLETER
}

#pragma mark -

- (IBAction)endDialog:(NSButton *)sender
{
	[self.window makeFirstResponder:nil];
	
	//self.locator.settingsRepresentation=[_currentLocatorViewController settings];
	
	[NSApp endSheet:self.window returnCode:sender.tag];
}

#pragma mark - Notifications

- (void)editorViewSizeShallChange:(NSNotification *)inNotification
{
	NSDictionary * tUserInfo=inNotification.userInfo;
	NSString * tSizeString=tUserInfo[@"Size"];
	
	NSSize tSize=NSSizeFromString(tSizeString);
	
	NSRect tPlaceHolderFrame=_optionPlaceHolderView.frame;
	
	CGFloat tDeltaX=tSize.width-NSWidth(tPlaceHolderFrame);
	CGFloat tDeltaY=tSize.height-NSHeight(tPlaceHolderFrame);
	
	NSRect tWindowFrame=self.window.frame;
	
	tWindowFrame.size.width+=tDeltaX;
	tWindowFrame.size.height+=tDeltaY;
	tWindowFrame.origin.y-=tDeltaY;
	
	[self.window setFrame:tWindowFrame display:YES];
}

@end

@interface PKGAdvancedOptionPanel ()
{
	PKGAdvancedOptionWindowController * _retainedWindowController;
}

- (void)_sheetDidEndSelector:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;

@end

@implementation PKGAdvancedOptionPanel

+ (id)advancedOptionPanel
{
	PKGAdvancedOptionWindowController * tWindowController=[PKGAdvancedOptionWindowController new];
	
	PKGAdvancedOptionPanel * tPanel=(PKGAdvancedOptionPanel *)tWindowController.window;
	tPanel->_retainedWindowController=tWindowController;
	
	return tPanel;
}

#pragma mark -

- (NSString *)prompt
{
	return _retainedWindowController.prompt;
}

- (void)setPrompt:(NSString *)inPrompt
{
	_retainedWindowController.prompt=inPrompt;
}


- (id)optionValue
{
	return _retainedWindowController.optionValue;
}

- (void)setOptionValue:(id)inOptionValue
{
	_retainedWindowController.optionValue=inOptionValue;
}

- (void)setAdvancedOptionObject:(PKGDistributionProjectSettingsAdvancedOptionObject *)inAdvancedOptionObject
{
	_retainedWindowController.advancedOptionObject=inAdvancedOptionObject;
}

#pragma mark -

- (void)_sheetDidEndSelector:(PKGAdvancedOptionPanel *)inPanel returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
	
	if (handler!=nil)
		handler(inReturnCode);
	
	inPanel->_retainedWindowController=nil;
	
	[inPanel orderOut:self];
}

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSInteger result))handler
{
	//[_retainedWindowController refreshUI];
	
	[NSApp beginSheet:self
	   modalForWindow:inWindow
		modalDelegate:self
	   didEndSelector:@selector(_sheetDidEndSelector:returnCode:contextInfo:)
		  contextInfo:(__bridge_retained void*)[handler copy]];
}

@end
