
#import "PKGDistributionRequirementsAndResourcesViewController.h"

#import "PKGPayloadDataSource.h"

#import "PKGFilesHierarchyViewController.h"

#import "PKGFilesEmptySelectionInspectorViewController.h"
#import "PKGFilesSelectionInspectorViewController.h"

#import "NSOutlineView+Selection.h"

#import "PKGApplicationPreferences.h"

@interface PKGDistributionRequirementsAndResourcesViewController ()
{
	IBOutlet NSView * _hierarchyPlaceHolderView;
	IBOutlet NSView * _inspectorPlaceHolderView;
	
	PKGFilesHierarchyViewController * _filesHierarchyViewController;
	
	PKGViewController *_emptySelectionInspectorViewController;
	PKGFilesSelectionInspectorViewController * _selectionInspectorViewController;
	
	PKGViewController *_currentInspectorViewController;
	
	PKGPayloadDataSource * _dataSource;
}

// Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification;

@end

@implementation PKGDistributionRequirementsAndResourcesViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	_dataSource=[PKGPayloadDataSource new];
	_dataSource.editableRootNodes=YES;
	
	return self;
}

- (NSUInteger)tag
{
	return PKGPreferencesGeneralDistributionProjectPaneRequirementsAndResources;
}

- (void)WB_viewDidLoad
{
    [super WB_viewDidLoad];
	
	// A COMPLETER
	
	// Files Hierarchy
	
	_filesHierarchyViewController=[PKGFilesHierarchyViewController new];
	
	_filesHierarchyViewController.label=NSLocalizedString(@"Additional Resources", @"");
	_filesHierarchyViewController.informationLabel=NSLocalizedString(@"These resources can be used by the above requirements and scripts \nor the requirements for the choices of the Installation Type step.", @"");
	_filesHierarchyViewController.hierarchyDataSource=_dataSource;
	
	_filesHierarchyViewController.view.frame=_hierarchyPlaceHolderView.bounds;
	
	[_hierarchyPlaceHolderView addSubview:_filesHierarchyViewController.view];
	
	_dataSource.delegate=_filesHierarchyViewController;
}

#pragma mark -

- (void)setRequirementsAndResources:(PKGDistributionProjectRequirementsAndResources *)inRequirementsAndResources
{
	if (_requirementsAndResources!=inRequirementsAndResources)
	{
		_requirementsAndResources=inRequirementsAndResources;
		
		// A COMPLETER
		
		_dataSource.rootNodes=self.requirementsAndResources.resourcesForest.rootNodes;
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	
	[_filesHierarchyViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self.view.window makeFirstResponder:_filesHierarchyViewController.outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHierarchySelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView];
	
	_dataSource.filePathConverter=self.filePathConverter;
	
	
	[_filesHierarchyViewController WB_viewDidAppear];
	
	[self fileHierarchySelectionDidChange:[NSNotification notificationWithName:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView]];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:nil];
	
	[_filesHierarchyViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_filesHierarchyViewController WB_viewDidDisappear];
}

#pragma mark - Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification
{
	NSOutlineView * tOutlineView=_filesHierarchyViewController.outlineView;
	
	if (inNotification.object!=tOutlineView)
		return;
	
	NSUInteger tNumberOfSelectedRows=tOutlineView.numberOfSelectedRows;
	
	// Inspector
	
	if (tNumberOfSelectedRows==0)
	{
		if (_emptySelectionInspectorViewController==nil)
			_emptySelectionInspectorViewController=[PKGFilesEmptySelectionInspectorViewController new];
		
		if (_currentInspectorViewController!=_emptySelectionInspectorViewController)
		{
			[_currentInspectorViewController WB_viewWillDisappear];
			
			[_currentInspectorViewController.view removeFromSuperview];
			
			[_currentInspectorViewController WB_viewDidDisappear];
			
			_currentInspectorViewController=_emptySelectionInspectorViewController;
			
			_currentInspectorViewController.view.frame=_inspectorPlaceHolderView.bounds;
			
			[_currentInspectorViewController WB_viewWillAppear];
			
			[_inspectorPlaceHolderView addSubview:_currentInspectorViewController.view];
			
			[_currentInspectorViewController WB_viewDidAppear];
		}
	}
	else
	{
		if (_selectionInspectorViewController==nil)
		{
			_selectionInspectorViewController=[PKGFilesSelectionInspectorViewController new];
			_selectionInspectorViewController.delegate=_filesHierarchyViewController;
		}
		
		if (_currentInspectorViewController!=_selectionInspectorViewController)
		{
			[_currentInspectorViewController WB_viewWillDisappear];
			
			[_currentInspectorViewController.view removeFromSuperview];
			
			[_currentInspectorViewController WB_viewDidDisappear];
			
			
			_currentInspectorViewController=_selectionInspectorViewController;
			
			_currentInspectorViewController.view.frame=_inspectorPlaceHolderView.bounds;
			
			[_currentInspectorViewController WB_viewWillAppear];
			
			[_inspectorPlaceHolderView addSubview:_currentInspectorViewController.view];
			
			[_currentInspectorViewController WB_viewDidAppear];
		}
		
		_selectionInspectorViewController.selectedItems=[tOutlineView WB_selectedItems];
	}
	
	// A COMPLETER
}

@end
