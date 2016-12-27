
#import "PKGOwnershipAndReferenceStylePanel.h"

#import "PKGOwnershipAndReferenceStyleViewController.h"

@interface PKGOwnershipAndReferenceStyleWindowController : NSWindowController
{
	IBOutlet NSView * _placeHolderView;
	
	IBOutlet NSButton * _defaultButton;
	
	PKGOwnershipAndReferenceStyleViewController * _ownershipAndReferenceStyleController;
}

	@property (nonatomic) BOOL canChooseOwnerAndGroupOptions;

	@property (nonatomic) BOOL keepOwnerAndGroup;

	@property (nonatomic) PKGFilePathType referenceStyle;

	@property (nonatomic,copy) NSString * prompt;

- (void)_updateLayout;

- (IBAction)endDialog:(id)sender;

@end


@implementation PKGOwnershipAndReferenceStyleWindowController

@synthesize keepOwnerAndGroup=_keepOwnerAndGroup;
@synthesize referenceStyle=_referenceStyle;

- (NSString *)windowNibName
{
	return @"PKGOwnershipAndReferenceStylePanel";
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	_ownershipAndReferenceStyleController=[PKGOwnershipAndReferenceStyleViewController new];
	
	[_placeHolderView addSubview:_ownershipAndReferenceStyleController.view];
	
	_ownershipAndReferenceStyleController.canChooseOwnerAndGroupOptions=self.canChooseOwnerAndGroupOptions;
	_ownershipAndReferenceStyleController.keepOwnerAndGroup=self.keepOwnerAndGroup;
	_ownershipAndReferenceStyleController.referenceStyle=self.referenceStyle;
	
	NSString * tTitle=self.prompt;
	
	if (tTitle==nil)
		tTitle=NSLocalizedString(@"Finsih", @"");
	
	_defaultButton.title=tTitle;
	
	[self _updateLayout];
}

#pragma mark -

- (void)setCanChooseOwnerAndGroupOptions:(BOOL)inBool
{
	if (_canChooseOwnerAndGroupOptions!=inBool)
	{
		_canChooseOwnerAndGroupOptions=inBool;
		
		if (_ownershipAndReferenceStyleController!=nil)
		{
			_ownershipAndReferenceStyleController.canChooseOwnerAndGroupOptions=inBool;
			
			[self _updateLayout];
		}
	}
}

- (BOOL)keepOwnerAndGroup
{
	if (_ownershipAndReferenceStyleController!=nil)
		_keepOwnerAndGroup=_ownershipAndReferenceStyleController.keepOwnerAndGroup;
	
	return _keepOwnerAndGroup;
}

- (void)setKeepOwnerAndGroup:(BOOL)inBool
{
	if (_keepOwnerAndGroup!=inBool)
	{
		_keepOwnerAndGroup=inBool;
		
		if (_ownershipAndReferenceStyleController!=nil)
			_ownershipAndReferenceStyleController.keepOwnerAndGroup=inBool;
	}
}

- (PKGFilePathType)referenceStyle
{
	if (_ownershipAndReferenceStyleController!=nil)
		_referenceStyle=_ownershipAndReferenceStyleController.referenceStyle;
	
	return _referenceStyle;
}

- (void)setReferenceStyle:(PKGFilePathType)inReferenceStyle
{
	if (_referenceStyle!=inReferenceStyle)
	{
		_referenceStyle=inReferenceStyle;
		
		if (_ownershipAndReferenceStyleController!=nil)
			_ownershipAndReferenceStyleController.referenceStyle=inReferenceStyle;
	}
}

- (void)setPrompt:(NSString *)inPrompt
{
	_prompt=[inPrompt copy];
	
	_defaultButton.title=((inPrompt==nil) ? @"" : inPrompt);
}

#pragma mark -

- (void)_updateLayout
{
	NSView * tView=[_placeHolderView subviews][0];
	
	NSRect tRect=tView.bounds;
	NSRect tPlaceHolderBounds=_placeHolderView.bounds;
	
	CGFloat tDelta=NSHeight(tPlaceHolderBounds)-NSHeight(tRect);
	
	NSRect tWindowFrame=[self.window frame];
	tWindowFrame.size.height-=tDelta;
	tWindowFrame.origin.y+=tDelta;
	
	[self.window setFrame:tWindowFrame display:YES animate:YES];
}

#pragma mark -

- (IBAction)endDialog:(NSButton *)sender
{
	[NSApp endSheet:self.window returnCode:sender.tag];
}

@end

@interface PKGOwnershipAndReferenceStylePanel ()
{
	PKGOwnershipAndReferenceStyleWindowController * retainedWindowController;
}

- (void)_sheetDidEndSelector:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;

@end

@implementation PKGOwnershipAndReferenceStylePanel

+ (PKGOwnershipAndReferenceStylePanel *) ownershipAndReferenceStylePanel
{
	PKGOwnershipAndReferenceStyleWindowController * tWindowController=[PKGOwnershipAndReferenceStyleWindowController new];
	
	PKGOwnershipAndReferenceStylePanel * tPanel=(PKGOwnershipAndReferenceStylePanel *)tWindowController.window;
	
	tPanel->retainedWindowController=tWindowController;
	
	return tPanel;
}

#pragma mark -

- (void)setCanChooseOwnerAndGroupOptions:(BOOL)inBool
{
	retainedWindowController.canChooseOwnerAndGroupOptions=inBool;
}

- (BOOL)canChooseOwnerAndGroupOptions
{
	return retainedWindowController.canChooseOwnerAndGroupOptions;
}

- (BOOL)keepOwnerAndGroup
{
	return retainedWindowController.canChooseOwnerAndGroupOptions;
}

- (void)setKeepOwnerAndGroup:(BOOL)inBool
{
	retainedWindowController.keepOwnerAndGroup=inBool;
}

- (PKGFilePathType)referenceStyle
{
	return retainedWindowController.referenceStyle;
}

- (void)setReferenceStyle:(PKGFilePathType)inReferenceStyle
{
	retainedWindowController.referenceStyle=inReferenceStyle;
}

- (NSString *)prompt
{
	return retainedWindowController.prompt;
}

- (void)setPrompt:(NSString *)inPrompt
{
	retainedWindowController.prompt=inPrompt;
}

#pragma mark -

- (void)_sheetDidEndSelector:(PKGOwnershipAndReferenceStylePanel *)inPanel returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
	
	if (handler!=nil)
		handler(inReturnCode);
	
	inPanel->retainedWindowController=nil;
	
	[inPanel orderOut:self];
}

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSInteger result))handler
{
	[NSApp beginSheet:self
	   modalForWindow:inWindow
		modalDelegate:self
	   didEndSelector:@selector(_sheetDidEndSelector:returnCode:contextInfo:)
		  contextInfo:(__bridge_retained void*)[handler copy]];
}

@end
