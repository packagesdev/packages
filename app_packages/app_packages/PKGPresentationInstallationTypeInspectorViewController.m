
#import "PKGPresentationInstallationTypeInspectorViewController.h"

#import "PKGPresentationInstallationTypeNonSingleSelectionViewController.h"
#import "PKGPresentationInstallationTypeSingleSelectionViewController.h"


#import "PKGInstallationHierarchy+UI.h"

@interface PKGPresentationInstallationTypeInspectorViewController ()
{
	PKGPresentationInstallationTypeNonSingleSelectionViewController * _nonSingleSelectionViewController;
	
	PKGPresentationInstallationTypeSingleSelectionViewController * _singleSelectionViewController;
	
	PKGViewController * _currentViewController;
}

- (void)showNonSingleSelectionViewForSelectionType:(PKGInstallationHierarchySelectionType)inSelectionType;

- (void)showSingleSelectionViewForItem:(id)inItem;

// Notifications

- (void)installationHierarchyDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationInstallationTypeInspectorViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSettings:(PKGDistributionProjectPresentationSettings *)inPresentationSettings
{
	self=[super initWithDocument:inDocument presentationSettings:inPresentationSettings];
	
	return self;
}

#pragma mark -

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Register for notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(installationHierarchyDidChange:) name:PKGInstallationHierarchySelectionDidChangeNotification object:self.document];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGInstallationHierarchySelectionDidChangeNotification object:self.document];
}

#pragma mark -

- (void)showNonSingleSelectionViewForSelectionType:(PKGInstallationHierarchySelectionType)inSelectionType
{
	if (_nonSingleSelectionViewController==nil)
		_nonSingleSelectionViewController=[PKGPresentationInstallationTypeNonSingleSelectionViewController new];
	
	switch(inSelectionType)
	{
		case PKGInstallationHierarchySelectionEmpty:
			
			_nonSingleSelectionViewController.label=NSLocalizedString(@"Empty Selection",@"");
			break;
			
		case PKGInstallationHierarchySelectionSingleNonEditable:
			
			_nonSingleSelectionViewController.label=NSLocalizedString(@"Not Editable",@"");
			break;
			
		case PKGInstallationHierarchySelectionMultiple:
			
			_nonSingleSelectionViewController.label=NSLocalizedString(@"Multiple Selection",@"");
			break;
			
		default:
			break;
			
	}
	
	if (_currentViewController!=_nonSingleSelectionViewController)
	{
		if (_currentViewController!=nil)
		{
			[_currentViewController WB_viewWillDisappear];
			
			[_currentViewController.view removeFromSuperview];
			
			[_currentViewController WB_viewDidDisappear];
		}
		
		_nonSingleSelectionViewController.view.frame=self.view.bounds;
		
		[_nonSingleSelectionViewController WB_viewWillAppear];
		
		[self.view addSubview:_nonSingleSelectionViewController.view];
		
		[_nonSingleSelectionViewController WB_viewDidAppear];
		
		_currentViewController=_nonSingleSelectionViewController;
	}
}

- (void)showSingleSelectionViewForItem:(PKGChoiceTreeNode *)inItem
{
	if (inItem==nil)
		return;
	
	if (_singleSelectionViewController==nil)
		_singleSelectionViewController=[[PKGPresentationInstallationTypeSingleSelectionViewController alloc] initWithDocument:self.document];
	
	_singleSelectionViewController.choiceTreeNode=inItem;
	
	if (_currentViewController!=_singleSelectionViewController)
	{
		if (_currentViewController!=nil)
		{
			[_currentViewController WB_viewWillDisappear];
			
			[_currentViewController.view removeFromSuperview];
			
			[_currentViewController WB_viewDidDisappear];
		}
		
		_singleSelectionViewController.view.frame=self.view.bounds;
		
		[_singleSelectionViewController WB_viewWillAppear];
		
		[self.view addSubview:_singleSelectionViewController.view];
		
		[_singleSelectionViewController WB_viewDidAppear];
		
		_currentViewController=_singleSelectionViewController;
	}
}

#pragma mark - Notifications

- (void)installationHierarchyDidChange:(NSNotification *)inNotification
{
	if (inNotification==nil)
		return;
	
	PKGInstallationHierarchySelectionType tSelectionType=[((NSNumber *)inNotification.userInfo[PKGInstallationHierarchySelectionTypeKey]) unsignedIntegerValue];
	
	switch(tSelectionType)
	{
		case PKGInstallationHierarchySelectionEmpty:
		case PKGInstallationHierarchySelectionSingleNonEditable:
		case PKGInstallationHierarchySelectionMultiple:
			
			[self showNonSingleSelectionViewForSelectionType:tSelectionType];
			
			break;
		
		case PKGInstallationHierarchySelectionSingle:
			
			[self showSingleSelectionViewForItem:inNotification.userInfo[PKGInstallationHierarchySelectionItemKey]];
			
			break;
	}
}

@end
