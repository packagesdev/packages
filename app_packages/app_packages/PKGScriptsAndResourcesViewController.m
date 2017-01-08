
#import "PKGScriptsAndResourcesViewController.h"

#import "PKGPayloadDataSource.h"
#import "PKGFilesHierarchyViewController.h"

#import "PKGScriptViewController.h"

#import "PKGTellerView.h"

#import "PKGPackageScriptsStackView.h"

@interface PKGScriptsAndResourcesViewController ()
{
	IBOutlet PKGPackageScriptsStackView * _installationScriptView;
	
	IBOutlet NSView * _hierarchyPlaceHolderView;
	
	PKGScriptViewController * _preInstallationScriptViewController;
	
	PKGScriptViewController * _postInstallationScriptViewController;
	
	PKGFilesHierarchyViewController * _filesHierarchyViewController;
	
	PKGPayloadDataSource * _dataSource;
}

@end

@implementation PKGScriptsAndResourcesViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	_dataSource=[PKGPayloadDataSource new];
	_dataSource.editableRootNodes=YES;
	
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Pre-installation
	
	_preInstallationScriptViewController=[PKGScriptViewController new];
	_preInstallationScriptViewController.label=NSLocalizedString(@"Pre-installation", @"");
	
	[_installationScriptView addView:_preInstallationScriptViewController.view];
	
	// Post-installation
	
	_postInstallationScriptViewController=[PKGScriptViewController new];
	_postInstallationScriptViewController.label=NSLocalizedString(@"Post-installation", @"");
	
	[_installationScriptView addView:_postInstallationScriptViewController.view];
	
	// Files Hierarchy
	
	_filesHierarchyViewController=[PKGFilesHierarchyViewController new];
	
	_filesHierarchyViewController.label=NSLocalizedString(@"Additional Resources", @"");
	_filesHierarchyViewController.informationLabel=NSLocalizedString(@"These resources can be used by the pre and post-installation scripts.", @"");
	_filesHierarchyViewController.hierarchyDataSource=_dataSource;
	
	_filesHierarchyViewController.view.frame=_hierarchyPlaceHolderView.bounds;
	
	[_filesHierarchyViewController WB_viewWillAdd];
	
	[_hierarchyPlaceHolderView addSubview:_filesHierarchyViewController.view];
	
	[_filesHierarchyViewController WB_viewDidAdd];
}

#pragma mark -

- (void)WB_viewWillAdd
{
	_preInstallationScriptViewController.installationScriptPath=self.scriptsAndResources.preInstallationScriptPath;
	
	_postInstallationScriptViewController.installationScriptPath=self.scriptsAndResources.postInstallationScriptPath;
	
	_dataSource.rootNodes=self.scriptsAndResources.resourcesForest.rootNodes;
	
	_dataSource.delegate=_filesHierarchyViewController;
	
	// A COMPLETER
}

- (void)WB_viewDidAdd
{
	[self.view.window makeFirstResponder:_filesHierarchyViewController.outlineView];
	
	_dataSource.filePathConverter=self.filePathConverter;
	[_filesHierarchyViewController refreshHierarchy];
	
	// A COMPLETER
}

#pragma mark -

@end
