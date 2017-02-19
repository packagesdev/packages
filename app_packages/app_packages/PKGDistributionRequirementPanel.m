
#import "PKGDistributionRequirementPanel.h"

#import "PKGPluginsManager+AppKit.h"

#import "PKGRequirementViewController.h"

#import "PKGRequirementPluginsManager.h"

#import "PKGEvent.h"

@interface PKGDistributionRequirementWindowController : NSWindowController
{
	
	IBOutlet NSImageView * _requirementTypeIcon;
	
	IBOutlet NSPopUpButton * _requirementTypePopUpButton;
	
	IBOutlet NSView * _requirementPlaceHolderView;
	
	IBOutlet NSButton * _okButton;
	
	IBOutlet NSButton * _cancelButton;
	
	
	
	
	CGFloat _defaultContentWidth;
	
	PKGRequirementViewController * _currentRequirementViewController;
	
	NSMutableDictionary * _cachedSettingsRepresentations;
}

	@property (nonatomic) PKGRequirement * requirement;

	@property (nonatomic,weak) id<PKGFilePathConverter> filePathConverter;

- (void)refreshUI;

- (void)showRequirementViewControllerWithIdentifier:(NSString *)inIdentifier;

- (IBAction)switchRequirementType:(id)sender;

- (IBAction)endDialog:(id)sender;

@end

@implementation PKGDistributionRequirementWindowController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
	return @"PKGDistributionRequirementPanel";
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	_defaultContentWidth=NSWidth(((NSView *)self.window.contentView).frame);
	
	// Popup Button
	
	[_requirementTypePopUpButton removeAllItems];
	
	
	NSArray * tPluginsNames=[[PKGRequirementPluginsManager defaultManager] allPluginsNameSorted];
	
	if (tPluginsNames==nil)
	{
		NSLog(@"Unable to retrieve the list of plugins names");
	}
	else
	{
		[_requirementTypePopUpButton addItemsWithTitles:tPluginsNames];
	}
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(optionKeyDidChange:)
												 name:PKGOptionKeyDidChangeStateNotification
											   object:self];
}

#pragma mark -

- (void)setRequirement:(PKGRequirement *)inRequirement
{
	if (_requirement!=inRequirement)
	{
		_requirement=inRequirement;
		
		_cachedSettingsRepresentations=[NSMutableDictionary dictionary];
	}
}

- (void)setFilePathConverter:(id<PKGFilePathConverter>)inFilePathConverter
{
	if (_filePathConverter!=inFilePathConverter)
	{
		_filePathConverter=inFilePathConverter;
	}
}

#pragma mark -

- (void)refreshUI
{
	if (_requirementTypePopUpButton==nil)
		return;
	
	NSString * tRequirementIdentifier=self.requirement.identifier;
	
	// Set the Requirement
	
	if (tRequirementIdentifier==nil)
	{
		NSLog(@"[PKGDistributionRequirementWindowController refreshUI]: Missing requirement identifier value");
		
		return;
	}
	
	NSString * tLocalizedName=[[PKGRequirementPluginsManager defaultManager] localizedPluginNameForIdentifier:tRequirementIdentifier];
	
	[_requirementTypePopUpButton selectItemWithTitle:tLocalizedName];
	
	[self showRequirementViewControllerWithIdentifier:tRequirementIdentifier];
}

- (void)showRequirementViewControllerWithIdentifier:(NSString *)inIdentifier
{
	if (inIdentifier==nil)
		return;
	
	if (_currentRequirementViewController!=nil)
	{
		[self.window makeFirstResponder:nil];
		
		NSDictionary * tSettings=_currentRequirementViewController.settings;
		
		if (tSettings!=nil)
			_cachedSettingsRepresentations[self.requirement.identifier]=tSettings;
		
		if (_currentRequirementViewController.isResizableWindow==YES)
		{
			NSRect tBounds=_currentRequirementViewController.view.bounds;
			
			NSString * tKey=[NSString stringWithFormat:@"%@.size",self.requirement.identifier];
			
			[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(tBounds) forKey:tKey];
			
			_currentRequirementViewController.view.autoresizingMask=0;
		}
		
		[_currentRequirementViewController WB_viewWillDisappear];
		
		[_currentRequirementViewController.view removeFromSuperview];
		
		[_currentRequirementViewController WB_viewDidDisappear];
		
		_currentRequirementViewController=nil;
	}
	
	self.requirement.identifier=inIdentifier;
	
	_requirementTypeIcon.image=[[PKGRequirementPluginsManager defaultManager] iconForIdentifier:inIdentifier];
	
	_currentRequirementViewController=[[PKGRequirementPluginsManager defaultManager] createPluginUIControllerForIdentifier:inIdentifier];
	
	if (_cachedSettingsRepresentations[inIdentifier]!=nil)
	{
		self.requirement.settingsRepresentation=_cachedSettingsRepresentations[inIdentifier];
	}
	else
	{
		if (self.requirement.settingsRepresentation==nil)
			self.requirement.settingsRepresentation=[_currentRequirementViewController defaultSettings];
	}
	
	_currentRequirementViewController.settings=self.requirement.settingsRepresentation;
	
	if (_currentRequirementViewController==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	NSRect tBounds=_requirementPlaceHolderView.bounds;
	
	NSRect tCurrentViewBounds=_currentRequirementViewController.view.bounds;
	
	if (_currentRequirementViewController.isResizableWindow==YES)
	{
		NSString * tKey=[NSString stringWithFormat:@"%@.size",inIdentifier];
		
		NSString * tSizeString=[[NSUserDefaults standardUserDefaults] objectForKey:tKey];
		
		if (tSizeString!=nil)
			tCurrentViewBounds=NSRectFromString(tSizeString);
		
		self.window.showsResizeIndicator=YES;
	}
	else
	{
		self.window.showsResizeIndicator=NO;
	}
	
	// Resize window
	
	NSRect tOldWindowFrame=self.window.frame;
	
	NSRect tComputeRect=NSMakeRect(0,0,NSWidth(tCurrentViewBounds)-NSWidth(tBounds),NSHeight(tCurrentViewBounds)-NSHeight(tBounds));
	
	tComputeRect=[NSWindow frameRectForContentRect:tComputeRect styleMask:NSBorderlessWindowMask];
	
	NSRect tNewWindowFrame;
	
	tNewWindowFrame.size=NSMakeSize(NSWidth(tOldWindowFrame)+NSWidth(tComputeRect),NSHeight(tOldWindowFrame)+NSHeight(tComputeRect));
	
	tNewWindowFrame.origin.x=floor(NSMidX(tOldWindowFrame)-NSWidth(tNewWindowFrame)*0.5);
	tNewWindowFrame.origin.y=NSMaxY(tOldWindowFrame)-NSHeight(tNewWindowFrame);
	
	[self.window setFrame:tNewWindowFrame display:YES animate:NO];
	
	
	[_currentRequirementViewController WB_viewWillAppear];
	
	if (_currentRequirementViewController.isResizableWindow==YES)
		_currentRequirementViewController.view.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
	
	_currentRequirementViewController.view.frame=_requirementPlaceHolderView.bounds;
	
	[_requirementPlaceHolderView addSubview:_currentRequirementViewController.view];
	
	[_currentRequirementViewController WB_viewDidAppear];
	
	NSView * tPreviousKeyView=[_currentRequirementViewController previousKeyView];
	
	if (tPreviousKeyView!=nil)
	{
		[_currentRequirementViewController setNextKeyView:tPreviousKeyView];
		
		[self.window makeFirstResponder:tPreviousKeyView];
	}
	else
	{
		[self.window makeFirstResponder:nil];
	}
	
	// Set Min and Max window size
	
	NSSize tSize=((NSView *)self.window.contentView).frame.size;
	
	if (_currentRequirementViewController.isResizableWindow==YES)
	{
		NSRect tContentFrame=((NSView *)self.window.contentView).frame;
		
		NSRect tRequirementFrame=_currentRequirementViewController.view.frame;
		
		tContentFrame.size.height=NSHeight(tContentFrame)-NSHeight(tRequirementFrame)+[_currentRequirementViewController minHeight];
		
		self.window.contentMinSize=NSMakeSize(_defaultContentWidth, NSHeight(tContentFrame));
		self.window.contentMaxSize=NSMakeSize(2000.0,2000.0);
	}
	else
	{
		tSize.width=_defaultContentWidth;
		
		self.window.contentMinSize=tSize;
		self.window.contentMaxSize=tSize;
	}
}

#pragma mark -

- (IBAction)switchRequirementType:(NSPopUpButton *)sender
{
	NSString * tRequirementIdentifier=[[PKGRequirementPluginsManager defaultManager] identifierForLocalizedPluginName:sender.titleOfSelectedItem];
	
	if ([tRequirementIdentifier isEqualToString:self.requirement.identifier]==NO)
	{
		self.requirement.settingsRepresentation=nil;	
		
		[self showRequirementViewControllerWithIdentifier:tRequirementIdentifier];
	}
}

- (IBAction)endDialog:(NSButton *)sender
{
	[self.window makeFirstResponder:nil];
	
	if (_currentRequirementViewController.isResizableWindow==YES)
	{
		NSRect tBounds=_currentRequirementViewController.view.bounds;
		
		NSString * tKey=[NSString stringWithFormat:@"%@.size",self.requirement.identifier];
		
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(tBounds) forKey:tKey];
		
		_currentRequirementViewController.view.autoresizingMask=0;
	}
	
	self.requirement.settingsRepresentation=[_currentRequirementViewController settings];
	
	[NSApp endSheet:self.window returnCode:sender.tag];
}

@end


@interface PKGDistributionRequirementPanel ()
{
	PKGDistributionRequirementWindowController * retainedWindowController;
}

- (void)_sheetDidEndSelector:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;

@end

@implementation PKGDistributionRequirementPanel

+ (PKGDistributionRequirementPanel *)distributionRequirementPanel
{
	PKGDistributionRequirementWindowController * tWindowController=[PKGDistributionRequirementWindowController new];
	
	PKGDistributionRequirementPanel * tPanel=(PKGDistributionRequirementPanel *)tWindowController.window;
	tPanel->retainedWindowController=tWindowController;
	
	return tPanel;
}

#pragma mark -

- (PKGRequirement *)requirement
{
	return retainedWindowController.requirement;
}

- (void)setRequirement:(PKGRequirement *)inRequirement
{
	retainedWindowController.requirement=inRequirement;
}

- (id<PKGFilePathConverter>)filePathConverter
{
	return retainedWindowController.filePathConverter;
}

- (void)setFilePathConverter:(id<PKGFilePathConverter>)inFilePathConverter
{
	retainedWindowController.filePathConverter=inFilePathConverter;
}


#pragma mark -

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSInteger result))handler
{
	[retainedWindowController refreshUI];
	
	[NSApp beginSheet:self
	   modalForWindow:inWindow
		modalDelegate:self
	   didEndSelector:@selector(_sheetDidEndSelector:returnCode:contextInfo:)
		  contextInfo:(__bridge_retained void*)[handler copy]];
}

- (void)_sheetDidEndSelector:(PKGDistributionRequirementPanel *)inPanel returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
	
	if (handler!=nil)
		handler(inReturnCode);
	
	inPanel->retainedWindowController=nil;
	
	[inPanel orderOut:self];
}

@end
