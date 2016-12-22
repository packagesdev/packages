
#import "PKGPayloadFilesHierarchyViewController.h"

#import "PKGPackagePayloadDataSource.h"

#import "PKGPayloadTreeNode+UI.h"

@interface PKGPayloadFilesHierarchyViewController ()

- (IBAction)setInstallationLocation:(id)sender;

@end

@implementation PKGPayloadFilesHierarchyViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Add menu items
	
	[self.outlineView.menu addItem:[NSMenuItem separatorItem]];
	
	NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Show Hidden Folders", @"") action:NSSelectorFromString(@"switchHiddenFolderTemplatesVisibility:") keyEquivalent:@""];
	[self.outlineView.menu addItem:tMenuItem];
	
	[self.outlineView.menu addItem:[NSMenuItem separatorItem]];
	
	tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Set as Default Location", @"") action:NSSelectorFromString(@"setDefaultDestination:") keyEquivalent:@""];
	
	[self.outlineView.menu addItem:tMenuItem];
}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldDeleteItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems==nil)
		return NO;
	
	NSArray * tMinimumCover=[PKGTreeNode minimumNodeCoverFromNodesInArray:inItems];
	
	if (tMinimumCover.count==0)
		return NO;
	
	PKGPackagePayloadDataSource * tDataSource=(PKGPackagePayloadDataSource *) self.hierarchyDatasource;
	
	for(PKGPayloadTreeNode * tTreeNode in tMinimumCover)
	{
		if ([tTreeNode isTemplateNode]==YES)
			return NO;
		
		if (tTreeNode==tDataSource.installLocationNode)
			return NO;
		
		if ([tDataSource.installLocationNode isDescendantOfNode:tTreeNode]==YES)
			return NO;
	}
	
	return YES;
}

#pragma mark -

- (void)showHiddenFolderTemplates
{
	[((PKGPackagePayloadDataSource *) self.hierarchyDatasource) outlineView:self.outlineView showHiddenFolderTemplates:YES];
}

- (void)hideHiddenFolderTemplates
{
	[((PKGPackagePayloadDataSource *) self.hierarchyDatasource) outlineView:self.outlineView showHiddenFolderTemplates:NO];
}

#pragma mark -

- (IBAction)setInstallationLocation:(id)sender
{
	// A COMPLETER
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tSelector=inMenuItem.action;
	
	// A COMPLETER
	
	if ([super validateMenuItem:inMenuItem]==NO)
		return NO;
	
	return YES;
}

@end
