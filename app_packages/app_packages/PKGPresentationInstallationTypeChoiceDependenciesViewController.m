/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationInstallationTypeChoiceDependenciesViewController.h"

#import "PKGDocumentWindowController.h"

#import "PKGChoiceDependencyTree+Edition.h"
#import "PKGChoiceItemOptionsDependencies+UI.h"
#import "PKGChoiceTreeNode+UI.h"
#import "PKGChoicesForest+DependenciesEdition.h"


#import "NSPopUpButton+OptimizedSize.h"

#import "PKGChoiceDependencyPopUpButton.h"
#import "PKGChoiceDependencyContainerView.h"

#define ICDEPENDENCYCONTAINERVIEW_BRANCH_INTERSPACE_VERTICAL	5.0

//#define ICDEPENDENCYCONTAINERVIEW_LEAF_WIDTH	400

#define ICDEPENDENCYMARGIN_LEFT		13.0

#define ICDEPENDENCYMARGIN_RIGHT	13.0

#define ICDEPENDENCYMARGIN_TOP		12.0

#define ICDEPENDENCYMARGIN_BOTTOM	13.0

#define BIG_FLOAT	65535.0


@interface PKGAvailableChoiceRecord : NSObject

	@property (copy) NSString * choiceUUID;
	@property BOOL enabledDependencySupported;
	@property BOOL selectedDependencySupported;

@end

@implementation PKGAvailableChoiceRecord

@end

@interface PKGPresentationInstallationTypeChoiceDependenciesViewController () <PKGChoiceDependencyPopUpButtonDelegate>
{
	IBOutlet NSTextField * _choiceEnabledDependencyTextLabel;
	
	IBOutlet NSPopUpButton * _choiceEnabledDependencyPopupButton;
	
	IBOutlet NSTextField * _choiceEnabledDependencyColonLabel;
	
	IBOutlet NSScrollView * _choiceEnabledDependencyScrollView;
	
	IBOutlet NSView * _choiceEnabledDependencyView;
	
	IBOutlet NSTextField * _choiceSelectedDependencyTextLabel;
	
	IBOutlet NSScrollView * _choiceSelectedDependencyScrollView;
	
	IBOutlet NSView * _choiceSelectedDependencyView;
	
	
	IBOutlet NSView * _accessoryView;
    
	NSView * _savedAccessoryView;
	
	BOOL _isGroup;
	
	NSMutableDictionary * _availableEnabledDependenciesDictionary;
	
	NSMutableDictionary * _availableSelectedDependenciesDictionary;
	
	NSDictionary * _enabledChoicesDictionary;
	
	NSDictionary * _selectedChoicesDictionary;
	
	NSMutableDictionary * _UUIDsDictionary;
	
	
	NSSize _availableChoicesPopUpButtonSize;
	
	NSSize _operatorPopUpButtonSize;
	
	NSSize _comparatorPopUpButtonSize;
	
	NSSize _stateObjectPopUpButtonSize;
	
	CGFloat _leafWidth;
	
	CGFloat _branchWidth;
}

- (NSMenu *)_enabledAvailableChoicesMenu;
- (NSMenu *)_selectedAvailableChoicesMenu;
- (NSMenu *)_operatorsMenu;
- (NSMenu *)_comparatorsMenu;
- (NSMenu *)_stateObjectsMenu;

- (void)_initializeDependenciesDictionaries;

- (NSMutableArray *)_availableListOfChoicesFromAvailableDependenciesDictionary:(NSDictionary *)inDependenciesDictionary;
- (NSDictionary *)_availableChoicesDictionaryFromAvailableDependenciesDictionary:(NSDictionary *)inDependenciesDictionary;
- (NSMutableDictionary *)_UUIDDictionaryFromAvailableDependenciesDictionary:(NSDictionary *)inDependenciesDictionary;

- (PKGChoiceDependencyTreePredicateNode *)_defaultEnabledPredicateNode;
- (PKGChoiceDependencyTreePredicateNode *)_defaultSelectedPredicateNode;

- (void)_computePopupButtonSizes;

- (IBAction)switchEnabledStateMode:(id)sender;

- (IBAction)switchEnabledChoice:(NSPopUpButton *)sender;
- (IBAction)switchSelectedChoice:(NSPopUpButton *)sender;
- (IBAction)switchOperator:(id)sender;
- (IBAction)switchComparator:(id)sender;

- (IBAction)addBranch:(id)sender;
- (IBAction)removeBranch:(id)sender;
- (IBAction)switchBranches:(id)sender;

- (IBAction)returnToInspector:(id)sender;

@end

@implementation PKGPresentationInstallationTypeChoiceDependenciesViewController

- (void)setChoiceTreeNode:(PKGChoiceTreeNode *)inChoiceTreeNode
{
	if (_choiceTreeNode==inChoiceTreeNode)
		return;
	
	_choiceTreeNode=inChoiceTreeNode;
	
	_isGroup=_choiceTreeNode.isGenuineGroupChoice;
	
	[self _initializeDependenciesDictionaries];
	
	// Pre-compute popup buttons size
	
	[self _computePopupButtonSizes];
	
	[self refreshUI];
}

- (void)setChoicesForest:(PKGChoicesForest *)inChoicesForest
{
	if (_choicesForest==inChoicesForest)
		return;
	
	_choicesForest=inChoicesForest;
	
	[self _initializeDependenciesDictionaries];
	
	[self _computePopupButtonSizes];
	
	[self refreshUI];
}

#pragma mark -

- (void)_initializeDependenciesDictionaries
{
	if (self.choiceTreeNode==nil || self.choicesForest==nil)
		return;
	
	if (_isGroup==YES)
	{
		_availableEnabledDependenciesDictionary=[self.choicesForest availableDependenciesDictionaryForEnabledStateOfGroupNode:self.choiceTreeNode];
	}
	else
	{
		_availableEnabledDependenciesDictionary=[self.choicesForest availableDependenciesDictionaryForEnabledStateOfLeafNode:self.choiceTreeNode skipEnabledIfConstant:NO];
		
		_availableSelectedDependenciesDictionary=[self.choicesForest availableDependenciesDictionaryForSelectedStateOfLeafNode:self.choiceTreeNode];
	}
	
	if (_availableEnabledDependenciesDictionary!=nil)
	{
		_enabledChoicesDictionary=[self _availableChoicesDictionaryFromAvailableDependenciesDictionary:_availableEnabledDependenciesDictionary];
		
		_UUIDsDictionary=[[self _UUIDDictionaryFromAvailableDependenciesDictionary:_availableEnabledDependenciesDictionary] mutableCopy];
	}
	
	if (_availableSelectedDependenciesDictionary!=nil)
	{
		_selectedChoicesDictionary=[self _availableChoicesDictionaryFromAvailableDependenciesDictionary:_availableSelectedDependenciesDictionary];
		
		if (_UUIDsDictionary==nil)
			_UUIDsDictionary=[self _UUIDDictionaryFromAvailableDependenciesDictionary:_availableSelectedDependenciesDictionary];
		else
			[_UUIDsDictionary addEntriesFromDictionary:[self _UUIDDictionaryFromAvailableDependenciesDictionary:_availableSelectedDependenciesDictionary]];
	}
}

#pragma mark -

- (NSArray *)_availableListOfChoicesFromAvailableDependenciesDictionary:(NSDictionary *)inDependenciesDictionary
{
	if (inDependenciesDictionary==nil)
		return nil;
	
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[inDependenciesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bUUID, PKGChoiceDependencyRecord * bDependencyRecord, BOOL *bOutStop) {
		
		PKGChoiceTreeNode * tChoiceNode=bDependencyRecord.choiceTreeNode;
		
		NSString * tChoiceIndexString=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Choice %@",@"Presentation",@""),[self.choicesForest indentationStringForTreeNode:tChoiceNode]];
			
		[tMutableArray addObject:tChoiceIndexString];
	}];
	
	[tMutableArray sortUsingComparator:^NSComparisonResult(NSString * bString1,NSString * bString2){
	
		return [bString1 compare:bString2 options:NSNumericSearch];
	}];
	
	return [tMutableArray copy];
}

- (NSDictionary *)_availableChoicesDictionaryFromAvailableDependenciesDictionary:(NSDictionary *)inDependenciesDictionary
{
	if (inDependenciesDictionary==nil)
		return nil;
	
	NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
		
	[inDependenciesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bUUID, PKGChoiceDependencyRecord * bDependencyRecord, BOOL *bOutStop) {
		
		PKGChoiceTreeNode * tChoiceNode=bDependencyRecord.choiceTreeNode;
		
		NSString * tChoiceIndexString=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Choice %@",@"Presentation",@""),[self.choicesForest indentationStringForTreeNode:tChoiceNode]];
		
		PKGAvailableChoiceRecord * tAvailableChoiceRecord=[PKGAvailableChoiceRecord new];
		tAvailableChoiceRecord.choiceUUID=bUUID;
		tAvailableChoiceRecord.enabledDependencySupported=bDependencyRecord.enabledDependencySupported;
		tAvailableChoiceRecord.selectedDependencySupported=bDependencyRecord.selectedDependencySupported;
		
		tMutableDictionary[tChoiceIndexString]=tAvailableChoiceRecord;
	}];
	
	return [tMutableDictionary copy];
}

- (NSDictionary *)_UUIDDictionaryFromAvailableDependenciesDictionary:(NSDictionary *)inDependenciesDictionary
{
	if (inDependenciesDictionary==nil)
		return nil;
	
	NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	[inDependenciesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bUUID, PKGChoiceDependencyRecord * bDependencyRecord, BOOL *bOutStop) {
		
		PKGChoiceTreeNode * tChoiceNode=bDependencyRecord.choiceTreeNode;
		
		NSString * tChoiceIndexString=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Choice %@",@"Presentation",@""),[self.choicesForest indentationStringForTreeNode:tChoiceNode]];
		
		tMutableDictionary[bUUID]=tChoiceIndexString;
	}];
	
	return [tMutableDictionary copy];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self refreshUI];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Add Return to Inspector button
	
	PKGDocumentWindowController * tDocumentWindowController=self.document.windowControllers.firstObject;
	
    _savedAccessoryView=[tDocumentWindowController contentViewOfRightAccessoryView];
    
	[tDocumentWindowController setContentViewOfRightAccessoryView:_accessoryView];
	
	// Register Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	// Remove Return to Inspector button
	
	PKGDocumentWindowController * tDocumentWindowController=self.document.windowControllers.firstObject;
	
	[tDocumentWindowController setContentViewOfRightAccessoryView:_savedAccessoryView];
	
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
}

- (void)refreshUI
{
	if (self.choiceTreeNode==nil || self.choicesForest==nil || _choiceEnabledDependencyTextLabel==nil)
		return;
	
	if (_isGroup==YES)
	{
		// Set the Text Label
		
		_choiceEnabledDependencyTextLabel.stringValue=NSLocalizedStringFromTable(@"Choice is enabled when:",@"Presentation",@"");
		
		[_choiceEnabledDependencyTextLabel sizeToFit];
		
		_choiceEnabledDependencyPopupButton.hidden=YES;
		
		_choiceEnabledDependencyColonLabel.hidden=YES;
		
		_choiceEnabledDependencyScrollView.hidden=NO;
		
		_choiceSelectedDependencyTextLabel.hidden=YES;
		
		_choiceSelectedDependencyScrollView.hidden=YES;
	}
	else
	{
		// Set the Text Label
		
		_choiceEnabledDependencyTextLabel.stringValue=NSLocalizedStringFromTable(@"Choice is ",@"Presentation",@"");
		
		[_choiceEnabledDependencyTextLabel sizeToFit];
		
		_choiceEnabledDependencyPopupButton.hidden=NO;
		
		_choiceEnabledDependencyColonLabel.hidden=NO;
		_choiceSelectedDependencyTextLabel.hidden=NO;

		_choiceSelectedDependencyScrollView.hidden=NO;
	}
	
	[self refreshView];
}

#pragma mark -

- (void)_computePopupButtonSizes
{
	if (self.choiceTreeNode==nil || self.choicesForest==nil)
		return;
	
	NSPopUpButton * tPopupButton=[[NSPopUpButton alloc] initWithFrame:NSMakeRect(0.0,0.0,100.0,17.0) pullsDown:NO];
	
	[[tPopupButton cell] setControlSize:WBControlSizeSmall];
	
	tPopupButton.font=[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:WBControlSizeSmall]];
	tPopupButton.alignment=WBTextAlignmentCenter;
	tPopupButton.bezelStyle=WBBezelStyleRoundRect;
	
	// Available choices
	
	NSMenu * tMenu=[self _selectedAvailableChoicesMenu];
	
	if (tMenu.numberOfItems==0)
		tMenu=[self _enabledAvailableChoicesMenu];
	
	tPopupButton.menu=tMenu;
	
	_availableChoicesPopUpButtonSize=[tPopupButton optimizedSize];
	
	_availableChoicesPopUpButtonSize.width=100.0;
	
	// Operators
	
	tPopupButton.menu=[self _operatorsMenu];
	
	_operatorPopUpButtonSize=[tPopupButton optimizedSize];
	
	_operatorPopUpButtonSize.width-=25.0;
	
	// Comparators
	
	tPopupButton.menu=[self _comparatorsMenu];
	
	_comparatorPopUpButtonSize=[tPopupButton optimizedSize];
	
	_comparatorPopUpButtonSize.width-=25.0;
	
	// State Objects
	
	tPopupButton.menu=[self _stateObjectsMenu];
	
	_stateObjectPopUpButtonSize=[tPopupButton optimizedSize];
	
	_stateObjectPopUpButtonSize.width-=25.0;
	

	
	_leafWidth=_availableChoicesPopUpButtonSize.width+10.0+_comparatorPopUpButtonSize.width+10.0+_stateObjectPopUpButtonSize.width+10.0+16.0+5.0+16.0;
	
	_branchWidth=_operatorPopUpButtonSize.width+10.0+16.0+5.0+16.0+5.0+16.0;
}

- (NSMenu *)_enabledAvailableChoicesMenu
{
	NSMenu * tMenu=[[NSMenu alloc] init];
	
	NSMutableArray * tChoicesList=[self _availableListOfChoicesFromAvailableDependenciesDictionary:_availableEnabledDependenciesDictionary];
	
	for(NSString * tChoiceName in tChoicesList)
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:tChoiceName action:nil keyEquivalent:@""];
		
		[tMenu addItem:tMenuItem];
	}
	
	return tMenu;
}

- (NSMenu *)_selectedAvailableChoicesMenu
{
	NSMenu * tMenu=[[NSMenu alloc] init];
	
	NSMutableArray * tChoicesList=[self _availableListOfChoicesFromAvailableDependenciesDictionary:_availableSelectedDependenciesDictionary];
	
	for(NSString * tChoiceName in tChoicesList)
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:tChoiceName action:nil keyEquivalent:@""];
		
		[tMenu addItem:tMenuItem];
	}
	
	return tMenu;
}

- (NSMenu *)_operatorsMenu
{
	NSMenu * tMenu=[[NSMenu alloc] init];
	
	NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"And",@"Presentation",@"") action:nil keyEquivalent:@""];
	tMenuItem.tag=PKGLogicOperatorTypeConjunction;
		
	[tMenu addItem:tMenuItem];
	
	
	tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Or",@"Presentation",@"") action:nil keyEquivalent:@""];
	tMenuItem.tag=PKGLogicOperatorTypeDisjunction;
		
	[tMenu addItem:tMenuItem];
	
	return tMenu;
}

- (NSMenu *)_comparatorsMenu
{
	NSMenu * tMenu=[[NSMenu alloc] init];
	
	NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Is",@"Presentation",@"") action:nil keyEquivalent:@""];
	tMenuItem.tag=PKGPredicateOperatorTypeEqualTo;
		
	[tMenu addItem:tMenuItem];
	
	
	tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Is Not",@"Presentation",@"") action:nil keyEquivalent:@""];
	tMenuItem.tag=PKGPredicateOperatorTypeNotEqualTo;
		
	[tMenu addItem:tMenuItem];
	
	return tMenu;
}

- (NSMenu *)_stateObjectsMenu
{
	NSMenu * tMenu=[[NSMenu alloc] init];
	
	NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Enabled",@"Presentation",@"") action:nil keyEquivalent:@""];
	tMenuItem.tag=PKGPredicateReferenceStateEnabled;
		
	[tMenu addItem:tMenuItem];
	
	tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Selected",@"Presentation",@"") action:nil keyEquivalent:@""];
	tMenuItem.tag=PKGPredicateReferenceStateSelected;
		
	[tMenu addItem:tMenuItem];
	
	return tMenu;
}

#pragma mark -

- (void)computeViewSizeWithDependencyTreeNode:(PKGChoiceDependencyTreeNode *)inTreeNode maxY:(CGFloat *) inOutMaxY minX:(CGFloat *) outMinX midY:(CGFloat *) outMidY
{
	// Is it a branch or leaf?
	
	if ([inTreeNode isKindOfClass:PKGChoiceDependencyTreePredicateNode.class]==YES)
	{
		// Leaf
		
		*outMidY=floor((*inOutMaxY)-_comparatorPopUpButtonSize.height*0.5f);
		
		*outMinX=BIG_FLOAT-_leafWidth-ICDEPENDENCYMARGIN_RIGHT-ICDEPENDENCYMARGIN_LEFT;
		
		*inOutMaxY=(*inOutMaxY)-_comparatorPopUpButtonSize.height;
	}
	else
	{
		PKGChoiceDependencyTreeLogicNode * tTreeLogicNode=(PKGChoiceDependencyTreeLogicNode *)inTreeNode;
		
		// Branch
		
		CGFloat tMinXTop=0.0;
		CGFloat tMidYTop=0.0;
		CGFloat tMinXBottom=0.0;
		CGFloat tMidYBottom=0.0;
		
		[self computeViewSizeWithDependencyTreeNode:tTreeLogicNode.topChildNode maxY:inOutMaxY minX:&tMinXTop midY:&tMidYTop];
		
		*outMidY=floor(*inOutMaxY-(ICDEPENDENCYCONTAINERVIEW_BRANCH_INTERSPACE_VERTICAL+(_operatorPopUpButtonSize.height*0.5)));
		
		*inOutMaxY-=(2*ICDEPENDENCYCONTAINERVIEW_BRANCH_INTERSPACE_VERTICAL+_operatorPopUpButtonSize.height);
		
		[self computeViewSizeWithDependencyTreeNode:tTreeLogicNode.bottomChildNode maxY:inOutMaxY minX:&tMinXBottom midY:&tMidYBottom];
		
		if (tMinXTop>tMinXBottom)
			tMinXTop=tMinXBottom;
		
		*outMinX=tMinXTop-(_operatorPopUpButtonSize.width+10.0);
	}
}

- (NSSize)optimizedSizeForDependencyTree:(PKGChoiceDependencyTree *)inDependencyTree
{
	CGFloat tMidY;
	CGFloat tMinX=0;
	CGFloat tMaxY=BIG_FLOAT;
	
	[self computeViewSizeWithDependencyTreeNode:inDependencyTree.rootNode maxY:&tMaxY minX:&tMinX midY:&tMidY];
	
	NSSize tSize={
		.width=BIG_FLOAT-tMinX,
		.height=BIG_FLOAT-tMaxY};
	
	return tSize;
}

- (NSButton *)layoutView:(NSView *)inView forDependencyTreeNode:(PKGChoiceDependencyTreeNode *)inTreeNode maxY:(CGFloat *) inOutMaxY minX:(CGFloat *) outMinX midY:(CGFloat *) outMidY
{
	NSButton * tMinusButton=nil;
	
	// Is it a branch or leaf?
	
	if ([inTreeNode isKindOfClass:PKGChoiceDependencyTreePredicateNode.class]==YES)
	{
		PKGChoiceDependencyTreePredicateNode * tTreePredicateNode=(PKGChoiceDependencyTreePredicateNode *)inTreeNode;
		
		// Leaf
		
		NSRect tBounds=inView.bounds;
		
		PKGChoiceDependencyContainerView * tContainerView=[[PKGChoiceDependencyContainerView alloc] initWithFrame:NSMakeRect(NSWidth(tBounds)-_leafWidth-ICDEPENDENCYMARGIN_RIGHT,(*inOutMaxY)-_comparatorPopUpButtonSize.height,_leafWidth,_comparatorPopUpButtonSize.height)];
		
		tContainerView.dependencyTreeNode=inTreeNode;
		tContainerView.controller=self;
		
		[inView addSubview:tContainerView];
		
		NSRect tContainerBounds=tContainerView.bounds;
		
		// Layout the leaf subviews
		
		// Choices
		
		PKGChoiceDependencyPopUpButton * tDependencyPopupButton=[[PKGChoiceDependencyPopUpButton alloc] initWithFrame:NSMakeRect(NSMinX(tContainerBounds),NSMinY(tContainerBounds),_availableChoicesPopUpButtonSize.width,_availableChoicesPopUpButtonSize.height) pullsDown:NO];
		
		tDependencyPopupButton.bezelStyle=WBBezelStyleRoundRect;
		tDependencyPopupButton.font=[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:WBControlSizeSmall]];
		tDependencyPopupButton.alignment=WBTextAlignmentLeft;
		[[tDependencyPopupButton cell] setControlSize:WBControlSizeSmall];
		
		if (inView==_choiceEnabledDependencyView)
		{
			tDependencyPopupButton.menu=[self _enabledAvailableChoicesMenu];
			tDependencyPopupButton.action=@selector(switchEnabledChoice:);
		}
		else if (inView==_choiceSelectedDependencyView)
		{
			tDependencyPopupButton.menu=[self _selectedAvailableChoicesMenu];
			tDependencyPopupButton.action=@selector(switchSelectedChoice:);
		}
		
		tDependencyPopupButton.target=self;
		
		tDependencyPopupButton.delegate=self;
		
		[tContainerView addSubview:tDependencyPopupButton];
		
		
		NSString * tChoiceLabel=_UUIDsDictionary[tTreePredicateNode.choiceUUID];
		
		if (tChoiceLabel!=nil)
		{
			[tDependencyPopupButton selectItemWithTitle:tChoiceLabel];
		}
		else
		{
			// A COMPLETER
		}
		
		[tDependencyPopupButton unregisterDraggedTypes];
		[tDependencyPopupButton registerForDraggedTypes:@[PKGInstallationHierarchyChoicesUUIDsPboardType]];

		
		tBounds=tDependencyPopupButton.frame;
		
		// Comparator
		
		NSPopUpButton * tPopupButton=[[NSPopUpButton alloc] initWithFrame:NSMakeRect(NSMaxX(tBounds)+10.0,NSMinY(tBounds),_comparatorPopUpButtonSize.width,_comparatorPopUpButtonSize.height) pullsDown:NO];
		
		tPopupButton.bezelStyle=WBBezelStyleRoundRect;
		tPopupButton.menu=[self _comparatorsMenu];
		[[tPopupButton cell] setControlSize:WBControlSizeSmall];
		tPopupButton.font=[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:WBControlSizeSmall]];
		tPopupButton.alignment=WBTextAlignmentLeft;
		tPopupButton.action=@selector(switchComparator:);
		tPopupButton.target=self;
		
		[tContainerView addSubview:tPopupButton];
		
		[tPopupButton selectItemWithTag:tTreePredicateNode.operatorType];

		
		tBounds=tPopupButton.frame;
		
		// State
		
		tPopupButton=[[NSPopUpButton alloc] initWithFrame:NSMakeRect(NSMaxX(tBounds)+10.0,NSMinY(tBounds),_stateObjectPopUpButtonSize.width,_stateObjectPopUpButtonSize.height) pullsDown:NO];
        tPopupButton.bezelStyle=WBBezelStyleRoundRect;;
		tPopupButton.menu=[self _stateObjectsMenu];
		[[tPopupButton cell] setControlSize:WBControlSizeSmall];
		tPopupButton.font=[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:WBControlSizeSmall]];
		tPopupButton.alignment=WBTextAlignmentLeft;
		
		if (inView==_choiceEnabledDependencyView)
			tPopupButton.action=@selector(switchEnabledStateObject:);
		else if (inView==_choiceSelectedDependencyView)
			tPopupButton.action=@selector(switchSelectedStateObject:);
		
		tPopupButton.target=tContainerView;
		
		[tContainerView addSubview:tPopupButton];
		
		[tPopupButton selectItemWithTag:tTreePredicateNode.referenceState];

		
		tBounds=tPopupButton.frame;
		
		// Minus
		
		NSButton * tButton;
		
		tMinusButton=tButton=[[NSButton alloc] initWithFrame:NSMakeRect(NSMaxX(tBounds)+10.0,NSMinY(tBounds)-1,16.0,19.0)];
		
		tButton.bezelStyle=WBBezelStyleRoundRect;
		tButton.imagePosition=NSImageOnly;
		tButton.image=[NSImage imageNamed:@"dependency_minus"];
		[[tButton cell] setControlSize:WBControlSizeSmall];
		tButton.enabled=NO;
		
		// A COMPLETER ?
		
		tButton.action=@selector(removeBranch:);
		tButton.target=self;
		
		[tContainerView addSubview:tButton];
		
		
		tBounds=tButton.frame;
		
		
		// Plus
		
		tButton=[[NSButton alloc] initWithFrame:NSMakeRect(NSMaxX(tBounds)+5.0,NSMinY(tBounds),16.0,19.0)];
		
		tButton.bezelStyle=WBBezelStyleRoundRect;
		tButton.imagePosition=NSImageOnly;
		tButton.image=[NSImage imageNamed:@"dependency_plus"];
		[[tButton cell] setControlSize:WBControlSizeSmall];
		
		tButton.action=@selector(addBranch:);
		tButton.target=self;
		
		[tContainerView addSubview:tButton];
		
		// Compute for the other views;
		
		*outMidY=floor((*inOutMaxY)-_comparatorPopUpButtonSize.height*0.5);
		
		*outMinX=NSWidth([inView bounds])-_leafWidth-ICDEPENDENCYMARGIN_RIGHT;
		
		*inOutMaxY=(*inOutMaxY)-_comparatorPopUpButtonSize.height;
	}
	else
	{
		PKGChoiceDependencyTreeLogicNode * tTreeLogicNode=(PKGChoiceDependencyTreeLogicNode *)inTreeNode;
		
		// Branch
		
		CGFloat tMinXTop=0;
		CGFloat tMidYTop=0;
		CGFloat tMinXBottom=0;
		CGFloat tMidYBottom=0;
		CGFloat tMinX=0;
		CGFloat tSavedYMax;
		NSBox * tBox;
		
		tMinusButton=[self layoutView:inView forDependencyTreeNode:tTreeLogicNode.topChildNode maxY:inOutMaxY minX:&tMinXTop midY:&tMidYTop];
		
		if (tMinusButton!=nil)
		{
			tMinusButton.enabled=YES;
			
			((PKGChoiceDependencyContainerView *) tMinusButton.superview).parentDependencyTreeNode=tTreeLogicNode;
		}
		
		tSavedYMax=*inOutMaxY;
		
		*outMidY=floor(*inOutMaxY-(ICDEPENDENCYCONTAINERVIEW_BRANCH_INTERSPACE_VERTICAL+(_operatorPopUpButtonSize.height*0.5)));
		
		*inOutMaxY-=(2*ICDEPENDENCYCONTAINERVIEW_BRANCH_INTERSPACE_VERTICAL+_operatorPopUpButtonSize.height);
		
		
		tMinusButton=[self layoutView:inView forDependencyTreeNode:tTreeLogicNode.bottomChildNode maxY:inOutMaxY minX:&tMinXBottom midY:&tMidYBottom];
		
		if (tMinusButton!=nil)
		{
			tMinusButton.enabled=YES;
			
			((PKGChoiceDependencyContainerView *) tMinusButton.superview).parentDependencyTreeNode=tTreeLogicNode;
		}
		
		tMinX=tMinXTop;
		
		if (tMinX>tMinXBottom)
			tMinX=tMinXBottom;
		
		*outMinX=tMinX-(_operatorPopUpButtonSize.width+10.0);
		
		// Branches
		
		// Top
		
		tBox=[[NSBox alloc] initWithFrame:NSMakeRect(floor((*outMinX)+_operatorPopUpButtonSize.width*0.5),tMidYTop,floor(tMinXTop-2.0-((*outMinX)+_operatorPopUpButtonSize.width*0.5)),1.0)];
		
		tBox.borderType=NSLineBorder;
		tBox.titlePosition=NSNoTitle;
		tBox.boxType=NSBoxSeparator;
		
		[inView addSubview:tBox];
		
		tBox=[[NSBox alloc] initWithFrame:NSMakeRect(floor((*outMinX)+_operatorPopUpButtonSize.width*0.5),tSavedYMax-ICDEPENDENCYCONTAINERVIEW_BRANCH_INTERSPACE_VERTICAL+2.0,1.0,(tMidYTop)-(tSavedYMax-ICDEPENDENCYCONTAINERVIEW_BRANCH_INTERSPACE_VERTICAL+2.0))];
		
		tBox.borderType=NSLineBorder;
		tBox.titlePosition=NSNoTitle;
		tBox.boxType=NSBoxSeparator;
		
		[inView addSubview:tBox];
		
		// Bottom
		
		// Top
		
		tBox=[[NSBox alloc] initWithFrame:NSMakeRect(floor((*outMinX)+_operatorPopUpButtonSize.width*0.5),tMidYBottom,floor(tMinXBottom-2.0-((*outMinX)+_operatorPopUpButtonSize.width*0.5)),1.0)];
		
		tBox.borderType=NSLineBorder;
		tBox.titlePosition=NSNoTitle;
		tBox.boxType=NSBoxSeparator;
		
		[inView addSubview:tBox];
		
		tBox=[[NSBox alloc] initWithFrame:NSMakeRect(floor((*outMinX)+_operatorPopUpButtonSize.width*0.5),tMidYBottom+1.0,1.0,tSavedYMax-_operatorPopUpButtonSize.height-ICDEPENDENCYCONTAINERVIEW_BRANCH_INTERSPACE_VERTICAL-2.0-(tMidYBottom+1.0))];
		
		tBox.borderType=NSLineBorder;
		tBox.titlePosition=NSNoTitle;
		tBox.boxType=NSBoxSeparator;
		
		[inView addSubview:tBox];
		
		// Container Operator
		
		PKGChoiceDependencyContainerView * tContainerView=[[PKGChoiceDependencyContainerView alloc] initWithFrame:NSMakeRect(*outMinX,tSavedYMax-_operatorPopUpButtonSize.height-ICDEPENDENCYCONTAINERVIEW_BRANCH_INTERSPACE_VERTICAL,_branchWidth,_operatorPopUpButtonSize.height)];
		
		tContainerView.dependencyTreeNode=inTreeNode;
		
		
		[inView addSubview:tContainerView];
		
		NSRect tContainerBounds=tContainerView.bounds;
		
		// Layout the operator subviews
		
		// Operator
		
		NSPopUpButton * tPopupButton=[[NSPopUpButton alloc] initWithFrame:NSMakeRect(NSMinX(tContainerBounds),NSMinY(tContainerBounds),_operatorPopUpButtonSize.width,_operatorPopUpButtonSize.height) pullsDown:NO];
		
		tPopupButton.bezelStyle=WBBezelStyleRoundRect;
		tPopupButton.font=[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:WBControlSizeSmall]];
		[[tPopupButton cell] setControlSize:WBControlSizeSmall];
		tPopupButton.alignment=WBTextAlignmentLeft;
		tPopupButton.menu=[self _operatorsMenu];
		tPopupButton.action=@selector(switchOperator:);
		tPopupButton.target=self;
		
		[tContainerView addSubview:tPopupButton];
		
		[tPopupButton selectItemWithTag:tTreeLogicNode.operatorType];
		
		NSRect tBounds=tPopupButton.frame;
		
		// Switch
		
		NSButton * tButton=[[NSButton alloc] initWithFrame:NSMakeRect(NSMaxX(tBounds)+10.0,NSMinY(tBounds)-1,16.0,19.0)];
		
		tButton.bezelStyle=WBBezelStyleRoundRect;
		tButton.imagePosition=NSImageOnly;
		tButton.image=[NSImage imageNamed:@"dependency_switch"];
		[[tButton cell] setControlSize:WBControlSizeSmall];
		tButton.action=@selector(switchBranches:);
		tButton.target=self;
		
		[tContainerView addSubview:tButton];

		
		tBounds=tButton.frame;
		
		// Minus
		
		tMinusButton=tButton=[[NSButton alloc] initWithFrame:NSMakeRect(NSMaxX(tBounds)+5.0,NSMinY(tBounds),16.0,19.0)];
		
		tButton.bezelStyle=WBBezelStyleRoundRect;
		tButton.imagePosition=NSImageOnly;
		tButton.image=[NSImage imageNamed:@"dependency_minus"];
		[[tButton cell] setControlSize:WBControlSizeSmall];
		tButton.enabled=NO;
		
		// A COMPLETER ?
		
		tButton.action=@selector(removeBranch:);
		tButton.target=self;
		
		[tContainerView addSubview:tButton];
		
		tBounds=tButton.frame;
		
		
		// Plus
		
		tButton=[[NSButton alloc] initWithFrame:NSMakeRect(NSMaxX(tBounds)+5.0,NSMinY(tBounds),16.0,19.0)];
		
		tButton.bezelStyle=WBBezelStyleRoundRect;
		tButton.imagePosition=NSImageOnly;
		tButton.image=[NSImage imageNamed:@"dependency_plus"];
		[[tButton cell] setControlSize:WBControlSizeSmall];
		
		// A COMPLETER ?
		
		tButton.action=@selector(addBranch:);
		tButton.target=self;
		
		[tContainerView addSubview:tButton];
	}
	
	return tMinusButton;
}

#pragma mark -

- (PKGChoiceDependencyTreePredicateNode *)_defaultEnabledPredicateNode
{
	NSMenu * tMenu=[self _enabledAvailableChoicesMenu];
	
	if (tMenu.numberOfItems==0)
		return nil;
	
	NSString * tDefaultChoiceLabel=[tMenu itemAtIndex:0].title;
	
	PKGAvailableChoiceRecord * tAvailableChoiceRecord=_enabledChoicesDictionary[tDefaultChoiceLabel];
	
	if (tAvailableChoiceRecord==nil)
		return nil;

	PKGChoiceDependencyTreePredicateNode * tPredicateNode=[PKGChoiceDependencyTreePredicateNode new];
	tPredicateNode.choiceUUID=tAvailableChoiceRecord.choiceUUID;
	tPredicateNode.operatorType=PKGPredicateOperatorTypeEqualTo;
	tPredicateNode.referenceState=(tAvailableChoiceRecord.enabledDependencySupported==YES) ? PKGPredicateReferenceStateEnabled : PKGPredicateReferenceStateSelected;
	
	return tPredicateNode;
}

- (PKGChoiceDependencyTreePredicateNode *)_defaultSelectedPredicateNode
{
	NSMenu * tMenu=[self _selectedAvailableChoicesMenu];
	
	if (tMenu.numberOfItems==0)
		return nil;
	
	NSString * tDefaultChoiceLabel=[tMenu itemAtIndex:0].title;
	
	PKGAvailableChoiceRecord * tAvailableChoiceRecord=_selectedChoicesDictionary[tDefaultChoiceLabel];
	
	if (tAvailableChoiceRecord==nil)
		return nil;
	
	PKGChoiceDependencyTreePredicateNode * tPredicateNode=[PKGChoiceDependencyTreePredicateNode new];
	tPredicateNode.choiceUUID=tAvailableChoiceRecord.choiceUUID;
	tPredicateNode.operatorType=PKGPredicateOperatorTypeEqualTo;
	tPredicateNode.referenceState=(tAvailableChoiceRecord.enabledDependencySupported==YES) ? PKGPredicateReferenceStateEnabled : PKGPredicateReferenceStateSelected;
	
	return tPredicateNode;
}

#pragma mark -

- (IBAction)switchEnabledStateMode:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	PKGEnabledStateDependencyType tStateDependencyType=PKGEnabledStateDependencyTypeAlways;
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemOptionsDependencies * tStateDependencies=tChoiceItem.options.stateDependencies;
	
	if (tStateDependencies!=nil)
		tStateDependencyType=tStateDependencies.enabledStateDependencyType;
	
	if (tTag==tStateDependencyType)
		return;
	
	tStateDependencies.enabledStateDependencyType=tTag;
	
	[self refreshView];
		
	[self noteDocumentHasChanged];
}

- (IBAction)returnToInspector:(id)sender
{
	dispatch_async(dispatch_get_main_queue(), ^{
	
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:self.document];
	});
}

- (IBAction)switchEnabledStateObject:(NSPopUpButton *)sender
{
	PKGChoiceDependencyContainerView * tContainer=(PKGChoiceDependencyContainerView *) sender.superview;
	
	if (tContainer==nil)
		return;
	
	PKGChoiceDependencyTreePredicateNode * tPredicateNode=(PKGChoiceDependencyTreePredicateNode *)tContainer.dependencyTreeNode;
		
	tPredicateNode.referenceState=sender.selectedItem.tag;
		
	[self noteDocumentHasChanged];
}

- (IBAction)switchSelectedStateObject:(id)sender
{
	[self switchEnabledStateObject:sender];
}



- (IBAction)switchOperator:(NSPopUpButton *)sender
{
	PKGChoiceDependencyContainerView * tContainer=(PKGChoiceDependencyContainerView *) sender.superview;
	
	if (tContainer==nil)
		return;
	
	PKGChoiceDependencyTreePredicateNode * tPredicateNode=(PKGChoiceDependencyTreePredicateNode *)tContainer.dependencyTreeNode;
	
	tPredicateNode.operatorType=sender.selectedItem.tag;
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchEnabledChoice:(NSPopUpButton *)sender
{
	PKGChoiceDependencyContainerView * tContainer=(PKGChoiceDependencyContainerView *) sender.superview;
	
	if (tContainer==nil)
		return;
	
	NSString * tChoiceLabel=sender.titleOfSelectedItem;
	
	PKGAvailableChoiceRecord * tChoiceRecord=_enabledChoicesDictionary[tChoiceLabel];
	
	if (tChoiceRecord==nil)
		return;
	
	PKGChoiceDependencyTreePredicateNode * tPredicateNode=(PKGChoiceDependencyTreePredicateNode *)tContainer.dependencyTreeNode;
	
	tPredicateNode.choiceUUID=tChoiceRecord.choiceUUID;
	
	// Check that we can use the enabled state object
	
	switch(tPredicateNode.referenceState)
	{
		case PKGPredicateReferenceStateEnabled:
			
			if (tChoiceRecord.enabledDependencySupported==NO)
				tPredicateNode.referenceState=PKGPredicateReferenceStateSelected;
			
			break;
			
		case PKGPredicateReferenceStateSelected:
			
			if (tChoiceRecord.selectedDependencySupported==NO)
				tPredicateNode.referenceState=PKGPredicateReferenceStateEnabled;
			
			break;
	}
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchSelectedChoice:(NSPopUpButton *)sender
{
	PKGChoiceDependencyContainerView * tContainer=(PKGChoiceDependencyContainerView *) sender.superview;
	
	if (tContainer==nil)
		return;
	
	NSString * tChoiceLabel=sender.titleOfSelectedItem;
	
	PKGAvailableChoiceRecord * tChoiceRecord=_selectedChoicesDictionary[tChoiceLabel];
	
	if (tChoiceRecord==nil)
		return;
	
	PKGChoiceDependencyTreePredicateNode * tPredicateNode=(PKGChoiceDependencyTreePredicateNode *)tContainer.dependencyTreeNode;
	
	tPredicateNode.choiceUUID=tChoiceRecord.choiceUUID;
	
	// Check that we can use the selected state object
	
	switch(tPredicateNode.referenceState)
	{
		case PKGPredicateReferenceStateEnabled:
			
			if (tChoiceRecord.enabledDependencySupported==NO)
				tPredicateNode.referenceState=PKGPredicateReferenceStateSelected;
			
			break;
			
		case PKGPredicateReferenceStateSelected:
			
			if (tChoiceRecord.selectedDependencySupported==NO)
				tPredicateNode.referenceState=PKGPredicateReferenceStateEnabled;
			
			break;
	}
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchComparator:(NSPopUpButton *)sender
{
	PKGChoiceDependencyContainerView * tContainer=(PKGChoiceDependencyContainerView *) sender.superview;
	
	if (tContainer==nil)
		return;
	
	PKGChoiceDependencyTreeLogicNode * tLogicNode=(PKGChoiceDependencyTreeLogicNode *)tContainer.dependencyTreeNode;
	
	tLogicNode.operatorType=sender.selectedItem.tag;
	
	[self noteDocumentHasChanged];
}

- (IBAction)addBranch:(NSButton *)sender
{
	PKGChoiceDependencyContainerView * tContainer=(PKGChoiceDependencyContainerView *) sender.superview;
	
	if (tContainer==nil)
		return;
	
	PKGChoiceDependencyTreePredicateNode * tNewPredicateNode=nil;
	
	if (tContainer.superview==_choiceEnabledDependencyView)
	{
		tNewPredicateNode=[self _defaultEnabledPredicateNode];
	}
	else if (tContainer.superview==_choiceSelectedDependencyView)
	{
		tNewPredicateNode=[self _defaultSelectedPredicateNode];
	}
	

	PKGChoiceDependencyTreeNode * tNode=tContainer.dependencyTreeNode;
	
	PKGChoiceDependencyTreeLogicNode * tNewParentLogicNode=[PKGChoiceDependencyTreeLogicNode new];
	
	tNewParentLogicNode.topChildNode=tNode;
	tNewParentLogicNode.operatorType=PKGLogicOperatorTypeConjunction;
	tNewParentLogicNode.bottomChildNode=tNewPredicateNode;
	
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemOptions * tItemOptions=tChoiceItem.options;
	PKGChoiceItemOptionsDependencies * tDependencies=tItemOptions.stateDependencies;
	
	if (tDependencies.enabledStateDependenciesTree!=nil && tDependencies.enabledStateDependenciesTree.rootNode==tNode)
	{
		tDependencies.enabledStateDependenciesTree.rootNode=tNewParentLogicNode;
	}
	else
	{
		if (tDependencies.selectedStateDependenciesTree!=nil && tDependencies.selectedStateDependenciesTree.rootNode==tNode)
		{
			tDependencies.selectedStateDependenciesTree.rootNode=tNewParentLogicNode;
		}
		else
		{
			PKGChoiceDependencyTreeLogicNode * tParentNode=tContainer.parentDependencyTreeNode;
			
			if (tParentNode.topChildNode==tNode)
				tParentNode.topChildNode=tNewParentLogicNode;
			else
				tParentNode.bottomChildNode=tNewParentLogicNode;
			
			tNewParentLogicNode.parentNode=tParentNode;
		}
	}
	
	[self refreshView];
	
	[self noteDocumentHasChanged];
}

- (IBAction)removeBranch:(NSButton *)sender
{
	PKGChoiceDependencyContainerView * tContainer=(PKGChoiceDependencyContainerView *) sender.superview;
	
	if (tContainer==nil)
		return;
	
	PKGChoiceDependencyTreeLogicNode * tParentNode=tContainer.parentDependencyTreeNode;
	
	if (tParentNode==nil)
		return;
	
	PKGChoiceDependencyTreeNode * tNode=tContainer.dependencyTreeNode;
	
	PKGChoiceDependencyTreeNode * tRemainingTreeNode=(tParentNode.bottomChildNode==tNode) ? tParentNode.topChildNode : tParentNode.bottomChildNode;
	
	PKGChoiceDependencyTreeLogicNode * tGrandParentNode=(PKGChoiceDependencyTreeLogicNode *)tParentNode.parentNode;
	
	if (tGrandParentNode!=nil)
	{
		if (tGrandParentNode.topChildNode==tParentNode)
			tGrandParentNode.topChildNode=tRemainingTreeNode;
		else
			tGrandParentNode.bottomChildNode=tRemainingTreeNode;
		
		tRemainingTreeNode.parentNode=tGrandParentNode;
		tNode.parentNode=nil;
	}
	else
	{
		PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
		PKGChoiceItemOptions * tItemOptions=tChoiceItem.options;
		PKGChoiceItemOptionsDependencies * tDependencies=tItemOptions.stateDependencies;
		
		if (tParentNode==tDependencies.enabledStateDependenciesTree.rootNode)
			tDependencies.enabledStateDependenciesTree.rootNode=tRemainingTreeNode;
		else if (tParentNode==tDependencies.selectedStateDependenciesTree.rootNode)
			tDependencies.selectedStateDependenciesTree.rootNode=tRemainingTreeNode;
		
		tRemainingTreeNode.parentNode=nil;
		tNode.parentNode=nil;
	}
	
	[self refreshView];
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchBranches:(NSButton *)sender
{
	PKGChoiceDependencyContainerView * tContainer=(PKGChoiceDependencyContainerView *) sender.superview;
	
	if (tContainer==nil)
		return;
	
	PKGChoiceDependencyTreeLogicNode * tLogicNode=(PKGChoiceDependencyTreeLogicNode *)tContainer.dependencyTreeNode;
	
	PKGChoiceDependencyTreeNode * tTreeNode=tLogicNode.topChildNode;
	
	tLogicNode.topChildNode=tLogicNode.bottomChildNode;
	tLogicNode.bottomChildNode=tTreeNode;
	
	[self refreshView];
	
	[self noteDocumentHasChanged];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchEnabledStateMode:))
	{
		if (_isGroup==NO && inMenuItem.tag==PKGEnabledStateDependencyTypeDependent)
		{
			NSMutableDictionary * tMutableDictionary=[self.choicesForest availableDependenciesDictionaryForEnabledStateOfLeafNode:self.choiceTreeNode skipEnabledIfConstant:NO];
			
			if (tMutableDictionary.count==0)
				return NO;
		}
	}
	
	return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem forTreeNode:(PKGChoiceDependencyTreePredicateNode *)inPredicateNode
{
	if (inPredicateNode==nil)
		return NO;

	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchEnabledStateObject:))
	{
		NSString * tChoiceLabel=_UUIDsDictionary[inPredicateNode.choiceUUID];
		
		if (tChoiceLabel==nil)
			return NO;

		PKGAvailableChoiceRecord * tChoiceRecord=_enabledChoicesDictionary[tChoiceLabel];
		
		if (tChoiceRecord==nil)
			return NO;
		
		if (inMenuItem.tag==PKGPredicateReferenceStateEnabled)
			return tChoiceRecord.enabledDependencySupported;

		if (inMenuItem.tag==PKGPredicateReferenceStateSelected)
			return tChoiceRecord.selectedDependencySupported;
		
		return NO;
	}
	
	if (tAction==@selector(switchSelectedStateObject:))
	{
		NSString * tChoiceLabel=_UUIDsDictionary[inPredicateNode.choiceUUID];
		
		if (tChoiceLabel==nil)
			return NO;
		
		PKGAvailableChoiceRecord * tChoiceRecord=_selectedChoicesDictionary[tChoiceLabel];
		
		if (tChoiceRecord==nil)
			return NO;
		
		if (inMenuItem.tag==PKGPredicateReferenceStateEnabled)
			return tChoiceRecord.enabledDependencySupported;
		
		if (inMenuItem.tag==PKGPredicateReferenceStateSelected)
			return tChoiceRecord.selectedDependencySupported;
		
		return NO;
	}
	
	return YES;
}

#pragma mark -

- (void)refreshView
{
	// Remove all the contents in the Enabled and Selected views
	
	NSArray * tArray=_choiceEnabledDependencyView.subviews;
	
	[tArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSView * bSubView, NSUInteger bIndex, BOOL *bOutStop) {
		[bSubView removeFromSuperview];
	}];
	
	tArray=_choiceSelectedDependencyView.subviews;

	[tArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSView * bSubView, NSUInteger bIndex, BOOL *bOutStop) {
		[bSubView removeFromSuperview];
	}];
	
	// Layout the Inspector
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemOptions * tItemOptions=tChoiceItem.options;
	
	if (_isGroup==YES)
	{
		PKGChoiceItemOptionsDependencies * tDependencies=tItemOptions.stateDependencies;
		
		if (tDependencies==nil)
		{
			tDependencies=tItemOptions.stateDependencies=[PKGChoiceItemOptionsDependencies new];
			tDependencies.enabledStateDependencyType=PKGEnabledStateDependencyTypeDependent;
		}
		
		if (tDependencies.enabledStateDependenciesTree==nil)
			tDependencies.enabledStateDependenciesTree=[[PKGChoiceDependencyTree alloc] initWithNode:[self _defaultEnabledPredicateNode]];
		
		PKGChoiceDependencyTree * tDependencyTree=tDependencies.enabledStateDependenciesTree;
		
		NSSize tOpimizedEnabledViewSize=[self optimizedSizeForDependencyTree:tDependencyTree];
		
		NSRect tEnabledViewFrame=NSMakeRect(0,0,tOpimizedEnabledViewSize.width,tOpimizedEnabledViewSize.height+ICDEPENDENCYMARGIN_TOP+ICDEPENDENCYMARGIN_BOTTOM);
		
		_choiceEnabledDependencyView.frame=tEnabledViewFrame;
		
		// Relayout
		
		CGFloat tMaxY=tOpimizedEnabledViewSize.height+ICDEPENDENCYMARGIN_TOP;
		CGFloat tMinX=0;
		CGFloat tMidY=0;
		
		[self layoutView:_choiceEnabledDependencyView forDependencyTreeNode:tDependencyTree.rootNode maxY:&tMaxY minX:&tMinX midY:&tMidY];
		
		[self viewFrameDidChange:nil];
		
		[self.view setNeedsDisplay:YES];
		
		return;
	}

	PKGChoiceItemOptionsDependencies * tDependencies=tItemOptions.stateDependencies;
	
	if (tDependencies==nil)
	{
		tDependencies=tItemOptions.stateDependencies=[PKGChoiceItemOptionsDependencies new];
		tDependencies.enabledStateDependencyType=PKGEnabledStateDependencyTypeAlways;
	}
	
	PKGEnabledStateDependencyType tStateDependency=tDependencies.enabledStateDependencyType;
	
	BOOL enabledViewIsHidden=YES;
	
	[_choiceEnabledDependencyPopupButton selectItemWithTag:tStateDependency];
	
	NSSize tOpimizedEnabledViewSize=NSZeroSize;
	
	if (tStateDependency==PKGEnabledStateDependencyTypeDependent)
	{
		enabledViewIsHidden=NO;
		
		_choiceEnabledDependencyColonLabel.hidden=NO;
		_choiceEnabledDependencyScrollView.hidden=NO;
		
		if (tDependencies.enabledStateDependenciesTree==nil)
			tDependencies.enabledStateDependenciesTree=[[PKGChoiceDependencyTree alloc] initWithNode:[self _defaultEnabledPredicateNode]];
		
		PKGChoiceDependencyTree * tDependencyTree=tDependencies.enabledStateDependenciesTree;
		
		tOpimizedEnabledViewSize=[self optimizedSizeForDependencyTree:tDependencyTree];
			
		NSRect tEnabledViewFrame=NSMakeRect(0,0,tOpimizedEnabledViewSize.width,tOpimizedEnabledViewSize.height+ICDEPENDENCYMARGIN_TOP+ICDEPENDENCYMARGIN_BOTTOM);
		
		_choiceEnabledDependencyView.frame=tEnabledViewFrame;
	}
	else
	{
		_choiceEnabledDependencyColonLabel.hidden=YES;
		_choiceEnabledDependencyScrollView.hidden=YES;
	}
	
	if (enabledViewIsHidden==NO)
	{
		CGFloat tMaxY=tOpimizedEnabledViewSize.height+ICDEPENDENCYMARGIN_TOP;
		CGFloat tMinX=0;
		CGFloat tMidY=0;
		
		[self layoutView:_choiceEnabledDependencyView forDependencyTreeNode:tDependencies.enabledStateDependenciesTree.rootNode maxY:&tMaxY minX:&tMinX midY:&tMidY];
	}
	
	if (tDependencies.selectedStateDependenciesTree==nil)
		tDependencies.selectedStateDependenciesTree=[[PKGChoiceDependencyTree alloc] initWithNode:[self _defaultSelectedPredicateNode]];
	
	PKGChoiceDependencyTree * tDependencyTree=tDependencies.selectedStateDependenciesTree;
	

	NSSize tOpimizedSelectedViewSize=[self optimizedSizeForDependencyTree:tDependencyTree];
	
	NSRect tSelectedViewFrame=NSMakeRect(0,0,tOpimizedSelectedViewSize.width,tOpimizedSelectedViewSize.height+ICDEPENDENCYMARGIN_TOP+ICDEPENDENCYMARGIN_BOTTOM);
	
	_choiceSelectedDependencyView.frame=tSelectedViewFrame;

	
	
	
	CGFloat tMaxY=tOpimizedSelectedViewSize.height+ICDEPENDENCYMARGIN_TOP;
	CGFloat tMinX=0;
	CGFloat tMidY=0;
	
	[self layoutView:_choiceSelectedDependencyView forDependencyTreeNode:tDependencies.selectedStateDependenciesTree.rootNode maxY:&tMaxY minX:&tMinX midY:&tMidY];
	
	[self viewFrameDidChange:nil];
	
	[self.view setNeedsDisplay:YES];
}



#pragma mark - PKGChoiceDependencyPopUpButtonDelegate

- (BOOL)popUpButton:(PKGChoiceDependencyPopUpButton *)inPopUpButton canSelectChoice:(NSString *)inUUID
{
	if (inUUID==NO)
		return NO;
	
	return (_UUIDsDictionary[inUUID]!=nil);
}

- (void)selectItemOfPopUpButton:(PKGChoiceDependencyPopUpButton *)inPopUpButton forChoice:(NSString *)inUUID
{
	if (inUUID==NO)
		return;
	
	PKGChoiceDependencyContainerView * tContainer=(PKGChoiceDependencyContainerView *) inPopUpButton.superview;
	
	if (tContainer==nil)
		return;
	
	PKGChoiceDependencyTreePredicateNode * tPredicateNode=(PKGChoiceDependencyTreePredicateNode *)tContainer.dependencyTreeNode;
	
	if ([tPredicateNode.choiceUUID isEqualToString:inUUID]==YES)
		return;
	
	NSString * tChoiceLabel=_UUIDsDictionary[inUUID];
	
	[inPopUpButton selectItemWithTitle:tChoiceLabel];
	
	if (tContainer.superview==_choiceEnabledDependencyView)
	{
		[self switchEnabledChoice:inPopUpButton];
	}
	else if (tContainer.superview==_choiceSelectedDependencyView)
	{
		[self switchSelectedChoice:inPopUpButton];
	}
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	if (_isGroup==YES)
	{
		CGFloat tAvailableVertical=NSMinY(_choiceEnabledDependencyTextLabel.frame)-8.0 -20.0;
		
		NSRect tEnabledViewFrame=_choiceEnabledDependencyView.frame;
		
		NSSize tIdealEnabledScrollSize=[NSScrollView frameSizeForContentSize:tEnabledViewFrame.size horizontalScrollerClass:nil verticalScrollerClass:nil borderType:NSBezelBorder controlSize:WBControlSizeSmall scrollerStyle:NSScrollerStyleLegacy];

		
		if (tIdealEnabledScrollSize.width>NSWidth(_choiceEnabledDependencyScrollView.frame))
			tIdealEnabledScrollSize.height+=16.0;
		
		NSRect tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
		
		if (tIdealEnabledScrollSize.height>=tAvailableVertical)
		{
			tScrollViewFrame.origin.y=20.0;
			tScrollViewFrame.size.height=tAvailableVertical;
		}
		else
		{
			tScrollViewFrame.size.height=tIdealEnabledScrollSize.height;
			tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
		}
		
		_choiceEnabledDependencyScrollView.frame=tScrollViewFrame;
	}
	else
	{
		PKGEnabledStateDependencyType tStateDependencyType=PKGEnabledStateDependencyTypeAlways;
	 
		PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
		PKGChoiceItemOptionsDependencies * tStateDependencies=tChoiceItem.options.stateDependencies;
	 
		if (tStateDependencies!=nil)
			tStateDependencyType=tStateDependencies.enabledStateDependencyType;
		
		NSRect tSelectedViewFrame=_choiceSelectedDependencyView.frame;
		
		if (tStateDependencyType==PKGEnabledStateDependencyTypeDependent)
		{
			NSRect tEnabledViewFrame=_choiceEnabledDependencyView.frame;
			
			CGFloat tAvailableVertical=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0 -20.0 -NSHeight(_choiceSelectedDependencyTextLabel.bounds) -8.0 -20.0;
			
			NSSize tIdealEnabledScrollSize=[NSScrollView frameSizeForContentSize:tEnabledViewFrame.size horizontalScrollerClass:nil verticalScrollerClass:nil borderType:NSBezelBorder controlSize:WBControlSizeSmall scrollerStyle:NSScrollerStyleLegacy];
			
			if (tIdealEnabledScrollSize.width>NSWidth(_choiceEnabledDependencyScrollView.frame))
				tIdealEnabledScrollSize.height+=16.0;
			
			NSSize tIdealSelectedScrollSize=[NSScrollView frameSizeForContentSize:tSelectedViewFrame.size horizontalScrollerClass:nil verticalScrollerClass:nil borderType:NSBezelBorder controlSize:WBControlSizeSmall scrollerStyle:NSScrollerStyleLegacy];
			
			if (tIdealSelectedScrollSize.width>NSWidth(_choiceSelectedDependencyScrollView.frame))
				tIdealSelectedScrollSize.height+=16.0;
			
			if ((tIdealEnabledScrollSize.height+tIdealSelectedScrollSize.height)>=tAvailableVertical)
			{
				if (tIdealEnabledScrollSize.height<(tAvailableVertical*0.5))
				{
					NSRect tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tIdealEnabledScrollSize.height;
					tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tScrollViewFrame.size.height;
					
					_choiceEnabledDependencyScrollView.frame=tScrollViewFrame;
					
					
					NSRect tLabelFrame=_choiceSelectedDependencyTextLabel.frame;
					
					tLabelFrame.origin.y=NSMinY(_choiceEnabledDependencyScrollView.frame)-20.0-tLabelFrame.size.height;
					
					_choiceSelectedDependencyTextLabel.frame=tLabelFrame;
					
					
					tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tAvailableVertical-tIdealEnabledScrollSize.height;
					tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
					
					_choiceSelectedDependencyScrollView.frame=tScrollViewFrame;
					
					
				}
				else if (tIdealSelectedScrollSize.height<(tAvailableVertical*0.5))
				{
					NSRect tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tAvailableVertical-tIdealSelectedScrollSize.height;
					
					tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tScrollViewFrame.size.height;
					
					_choiceEnabledDependencyScrollView.frame=tScrollViewFrame;
					
					
					NSRect tLabelFrame=_choiceSelectedDependencyTextLabel.frame;
					
					tLabelFrame.origin.y=NSMinY(_choiceEnabledDependencyScrollView.frame)-20.0-tLabelFrame.size.height;
					
					_choiceSelectedDependencyTextLabel.frame=tLabelFrame;
					
					
					tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tIdealSelectedScrollSize.height;
					tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
					
					_choiceSelectedDependencyScrollView.frame=tScrollViewFrame;
				}
				else
				{
					// Proprotionnaly scale down
					
					CGFloat tRatio=(tIdealEnabledScrollSize.height+tIdealSelectedScrollSize.height)/tAvailableVertical;
					
					tIdealEnabledScrollSize.height=round(tIdealEnabledScrollSize.height/tRatio);
					
					tIdealSelectedScrollSize.height=tAvailableVertical-tIdealEnabledScrollSize.height;
					
					
					NSRect tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tIdealEnabledScrollSize.height;
					tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tScrollViewFrame.size.height;
					
					_choiceEnabledDependencyScrollView.frame=tScrollViewFrame;
					
					
					NSRect tLabelFrame=[_choiceSelectedDependencyTextLabel frame];
					
					tLabelFrame.origin.y=NSMinY([_choiceEnabledDependencyScrollView frame])-20.0-tLabelFrame.size.height;
					
					_choiceSelectedDependencyTextLabel.frame=tLabelFrame;
					
					
					tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
					
					tScrollViewFrame.size.height=tIdealSelectedScrollSize.height;
					tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
					
					_choiceSelectedDependencyScrollView.frame=tScrollViewFrame;
				}
			}
			else
			{
				NSRect tScrollViewFrame=_choiceEnabledDependencyScrollView.frame;
				
				tScrollViewFrame.size.height=tIdealEnabledScrollSize.height;
				tScrollViewFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tScrollViewFrame.size.height;
				
				_choiceEnabledDependencyScrollView.frame=tScrollViewFrame;
				
				
				NSRect tLabelFrame=_choiceSelectedDependencyTextLabel.frame;
				
				tLabelFrame.origin.y=NSMinY(_choiceEnabledDependencyScrollView.frame)-20.0-tLabelFrame.size.height;
				
				_choiceSelectedDependencyTextLabel.frame=tLabelFrame;
				
				
				tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
				
				tScrollViewFrame.size.height=tIdealSelectedScrollSize.height;
				tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
				
				_choiceSelectedDependencyScrollView.frame=tScrollViewFrame;
			}
		}
		else
		{
			// Set the position of the label view
			
			NSRect tLabelFrame=_choiceSelectedDependencyTextLabel.frame;
			
			tLabelFrame.origin.y=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0-tLabelFrame.size.height;
			
			_choiceSelectedDependencyTextLabel.frame=tLabelFrame;
			
			CGFloat tAvailableVertical=NSMinY(_choiceEnabledDependencyTextLabel.frame)-20.0 -NSHeight(_choiceSelectedDependencyTextLabel.bounds)-8.0       -20.0;
			
			NSSize tIdealSelectedScrollSize=[NSScrollView frameSizeForContentSize:tSelectedViewFrame.size horizontalScrollerClass:nil verticalScrollerClass:nil borderType:NSBezelBorder controlSize:WBControlSizeSmall scrollerStyle:NSScrollerStyleLegacy];
			
			if (tIdealSelectedScrollSize.width>NSWidth(_choiceSelectedDependencyScrollView.frame))
				tIdealSelectedScrollSize.height+=16.0;
			
			NSRect tScrollViewFrame=_choiceSelectedDependencyScrollView.frame;
			
			if (tIdealSelectedScrollSize.height>=tAvailableVertical)
			{
				tScrollViewFrame.size.height=tAvailableVertical;
				tScrollViewFrame.origin.y=20.0;
			}
			else
			{
				tScrollViewFrame.size.height=tIdealSelectedScrollSize.height;
				tScrollViewFrame.origin.y=NSMinY(_choiceSelectedDependencyTextLabel.frame)-8.0-tScrollViewFrame.size.height;
			}
			
			[_choiceSelectedDependencyScrollView setFrame:tScrollViewFrame];
		}
	}
}

@end
