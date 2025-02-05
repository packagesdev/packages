/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectMainViewController.h"

#import "PKGDistributionProjectSourceListController.h"

#import "PKGDistributionProjectSourceListDataSource.h"

#import "PKGDistributionMultipleSelectionViewController.h"

#import "PKGDistributionProjectViewController.h"

#import "PKGDistributionPackageComponentViewController.h"

#import "PKGDistributionProject.h"

#import "PKGDistributionProjectSourceListTreeNode.h"
#import "PKGDistributionProjectSourceListProjectItem.h"
#import "PKGDistributionProjectSourceListPackageComponentItem.h"

#import "NSOutlineView+Selection.h"

#import "PKGChoiceItemOptionsDependencies+UI.h"
#import "PKGDistributionProject+UI.h"
#import "PKGPackageComponent+UI.h"

#import "PKGPresentationInstallationTypeStepSettings+Edition.h"

#import "PKGDistributionMainControlledView.h"

@interface PKGDistributionProjectMainViewController () <NSSplitViewDelegate>
{
	IBOutlet NSSplitView * _splitView;
	
	IBOutlet NSView * _sourceListPlaceHolderView;
	
	IBOutlet NSView * _contentsView;
	
	PKGDistributionProjectSourceListController * _sourceListController;
	
	PKGDistributionProjectSourceListDataSource * _dataSource;
	
	
	PKGViewController * _currentContentsViewController;
	
	CGFloat _savedSourceListWidth;
	BOOL _editingInstallationTypeChoice;
}

- (IBAction)selectCertificate:(id)sender;
- (IBAction)removeCertificate:(id) sender;

// Notifications

- (void)sourceListSelectionDidChange:(NSNotification *)inNotification;

- (void)packageComponentsDidRemove:(NSNotification *)inNotification;

- (void)choiceDependenciesEditionWillBegin:(NSNotification *)inNotification;
- (void)choiceDependenciesEditionDidEnd:(NSNotification *)inNotification;

- (void)distributionViewEffectiveAppearanceDidChange:(NSNotification *)inNotification;

@end

@implementation PKGDistributionProjectMainViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		_dataSource=[PKGDistributionProjectSourceListDataSource new];
		_dataSource.filePathConverter=self.filePathConverter;
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// Source List
	
	_sourceListController=[[PKGDistributionProjectSourceListController alloc] initWithDocument:self.document];
	_sourceListController.dataSource=_dataSource;
	
	_sourceListController.view.frame=_sourceListPlaceHolderView.bounds;
	
	[_sourceListPlaceHolderView addSubview:_sourceListController.view];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)self.project;
	
	_dataSource.distributionProject=tDistributionProject;
	
	_dataSource.delegate=_sourceListController;
	
	[_sourceListController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self.view.window makeFirstResponder:_sourceListController.outlineView];
	
	NSNotificationCenter * tDefaultCenter=[NSNotificationCenter defaultCenter];
	
	[tDefaultCenter addObserver:self selector:@selector(sourceListSelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_sourceListController.outlineView];
	
	[tDefaultCenter addObserver:self selector:@selector(packageComponentsDidRemove:) name:PKGDistributionProjectDidRemovePackageComponentsNotification object:self.document];
	
	[tDefaultCenter addObserver:self selector:@selector(choiceDependenciesEditionWillBegin:) name:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:self.document];
	[tDefaultCenter addObserver:self selector:@selector(choiceDependenciesEditionDidEnd:) name:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:self.document];
	
    [tDefaultCenter addObserver:self selector:@selector(distributionViewEffectiveAppearanceDidChange:) name:PKGDistributionViewEffectiveAppearanceDidChangeNotification object:self.view.window];
	
	[_sourceListController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	NSNotificationCenter * tDefaultCenter=[NSNotificationCenter defaultCenter];
	
	[tDefaultCenter removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:nil];
	
	[tDefaultCenter removeObserver:self name:PKGDistributionProjectDidRemovePackageComponentsNotification object:self.document];
	
	[tDefaultCenter removeObserver:self name:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:self.document];
	[tDefaultCenter removeObserver:self name:PKGChoiceItemOptionsDependenciesEditionDidEndNotification object:self.document];
	
	[tDefaultCenter removeObserver:self name:PKGDistributionViewEffectiveAppearanceDidChangeNotification object:nil];
	
	[_sourceListController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_sourceListController WB_viewDidDisappear];
}

#pragma mark - View Menu

- (IBAction)showProjectSettingsTab:(id)sender
{
	[_currentContentsViewController performSelector:@selector(showProjectSettingsTab:) withObject:sender];
}

- (IBAction)showDistributionPresentationTab:(id)sender
{
	[_currentContentsViewController performSelector:@selector(showDistributionPresentationTab:) withObject:sender];
}

- (IBAction)showDistributionRequirementsAndResourcesTab:(id)sender
{
	[_currentContentsViewController performSelector:@selector(showDistributionRequirementsAndResourcesTab:) withObject:sender];
}

- (IBAction)showProjectCommentsTab:(id)sender
{
	[_currentContentsViewController performSelector:@selector(showProjectCommentsTab:) withObject:sender];
}

- (IBAction)showPackageSettingsTab:(id)sender
{
	[_currentContentsViewController performSelector:@selector(showPackageSettingsTab:) withObject:sender];
}

- (IBAction)showPackagePayloadTab:(id)sender
{
	[_currentContentsViewController performSelector:@selector(showPackagePayloadTab:) withObject:sender];
}

- (IBAction)showPackageScriptsAndResourcesTab:(id)sender
{
	[_currentContentsViewController performSelector:@selector(showPackageScriptsAndResourcesTab:) withObject:sender];
}

#pragma mark - Presentation Menu

- (IBAction)switchShowRawNames:(id)sender
{
	[_currentContentsViewController performSelector:@selector(switchShowRawNames:) withObject:sender];
}

#pragma mark - Hierarchy Menu

- (IBAction)addFiles:(id)sender
{
	[_currentContentsViewController performSelector:@selector(addFiles:) withObject:sender];
}

- (IBAction)addNewFolder:(id)sender
{
	[_currentContentsViewController performSelector:@selector(addNewFolder:) withObject:sender];
}

- (IBAction)expandOneLevel:(id)sender
{
	[_currentContentsViewController performSelector:@selector(expandOneLevel:) withObject:sender];
}

- (IBAction)expand:(id)sender
{
	[_currentContentsViewController performSelector:@selector(expand:) withObject:sender];
}

- (IBAction)expandAll:(id)sender
{
	[_currentContentsViewController performSelector:@selector(expandAll:) withObject:sender];
}

- (IBAction)contract:(id)sender
{
	[_currentContentsViewController performSelector:@selector(contract:) withObject:sender];
}

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender
{
	[_currentContentsViewController performSelector:@selector(switchHiddenFolderTemplatesVisibility:) withObject:sender];
}

- (IBAction)setDefaultDestination:(id)sender
{
	[_currentContentsViewController performSelector:@selector(setDefaultDestination:) withObject:sender];
}

#pragma mark - Project Menu

- (IBAction)showProject:(id)sender
{
	[_sourceListController showProject:sender];
}

- (IBAction)addPackage:(id)sender
{
	[_sourceListController addPackage:sender];
}

- (IBAction)addPackageReference:(id)sender
{
	[_sourceListController addPackageReference:sender];
}

- (IBAction)importPackage:(id)sender
{
	[_sourceListController importPackage:sender];
}

- (IBAction)selectCertificate:(id)sender
{
	[((PKGDistributionProjectViewController *)_currentContentsViewController) selectCertificate:sender];
}

- (IBAction)removeCertificate:(id) sender
{
	[((PKGDistributionProjectViewController *)_currentContentsViewController) removeCertificate:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	if (_editingInstallationTypeChoice==YES)
		return NO;
	
	SEL tAction=[inMenuItem action];
	
	// View Menu
	
	if (tAction==@selector(showProjectSettingsTab:) ||
		tAction==@selector(showDistributionPresentationTab:) ||
		tAction==@selector(showDistributionRequirementsAndResourcesTab:) ||
		tAction==@selector(showProjectCommentsTab:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGDistributionProjectViewController.class]==NO)
		{
			inMenuItem.hidden=YES;
			inMenuItem.keyEquivalentModifierMask=0;
			inMenuItem.keyEquivalent=@"";
			
			return NO;
		}
		
		inMenuItem.keyEquivalentModifierMask=WBEventModifierFlagCommand;
		inMenuItem.hidden=NO;
		
		if (tAction==@selector(showProjectSettingsTab:))
		{
			inMenuItem.title=NSLocalizedString(@"Settings_Menu",@"");
			inMenuItem.keyEquivalent=@"1";
		}
		else if (tAction==@selector(showDistributionPresentationTab:))
		{
			inMenuItem.keyEquivalent=@"2";
		}
		else if (tAction==@selector(showDistributionRequirementsAndResourcesTab:))
		{
			inMenuItem.keyEquivalent=@"3";
		}
		else if (tAction==@selector(showProjectCommentsTab:))
		{
			inMenuItem.keyEquivalent=@"4";
		}
		
		return YES;
	}
	
	if (tAction==@selector(showPackageSettingsTab:) ||
		tAction==@selector(showPackagePayloadTab:) ||
		tAction==@selector(showPackageScriptsAndResourcesTab:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGDistributionPackageComponentViewController.class]==NO)
		{
			inMenuItem.hidden=YES;
			inMenuItem.keyEquivalentModifierMask=0;
			inMenuItem.keyEquivalent=@"";
			
			return NO;
		}
		
		inMenuItem.hidden=NO;
		
		return [_currentContentsViewController validateMenuItem:inMenuItem];
	}
	
	// Presentation Menu
	
	if (tAction==@selector(switchShowRawNames:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGDistributionProjectViewController.class]==NO)
			return NO;
		
		return [_currentContentsViewController validateMenuItem:inMenuItem];
	}
	
	// Hierarchy Menu
	
	if (tAction==@selector(addFiles:) ||
		tAction==@selector(addNewFolder:) ||
		tAction==@selector(expandOneLevel:) ||
		tAction==@selector(expand:) ||
		tAction==@selector(expandAll:) ||
		tAction==@selector(contract:) ||
		tAction==@selector(switchHiddenFolderTemplatesVisibility:) ||
		tAction==@selector(setDefaultDestination:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGDistributionPackageComponentViewController.class]==NO)
			return NO;
		
		return [_currentContentsViewController validateMenuItem:inMenuItem];
	}
	
	// Project Menu
	
	if (tAction==@selector(selectCertificate:) ||
		tAction==@selector(removeCertificate:))
	{
		if ([_currentContentsViewController isKindOfClass:PKGDistributionProjectViewController.class]==NO)
			return NO;
		
		return [_currentContentsViewController validateMenuItem:inMenuItem];
	}
	
	return YES;
}

#pragma mark - NSSplitViewDelegate

#define ICDOCUMENT_RIGHTVIEW_MIN_WIDTH		1026

- (void)splitView:(NSSplitView *) inSplitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect tSplitViewFrame=[inSplitView frame];
	
	NSRect tLeftFrame=_sourceListPlaceHolderView.frame;
	NSRect tRightFrame=_contentsView.frame;
	
	tRightFrame.size.width=NSWidth(tSplitViewFrame)-inSplitView.dividerThickness-NSWidth(tLeftFrame);
	
	if (NSWidth(tRightFrame)<ICDOCUMENT_RIGHTVIEW_MIN_WIDTH)
	{
		tRightFrame.size.width=ICDOCUMENT_RIGHTVIEW_MIN_WIDTH;
		
		tLeftFrame.size.width=NSWidth(tSplitViewFrame)-inSplitView.dividerThickness-NSWidth(tRightFrame);
		
		if (NSWidth(tLeftFrame)<0)
			tLeftFrame.size.width=0;
	}
	
	tRightFrame.size.height=NSHeight(tSplitViewFrame);
	
	tRightFrame.origin.y=0;
	
	_contentsView.frame=tRightFrame;
	
	tLeftFrame.size.height=NSHeight(tSplitViewFrame);
	
	tLeftFrame.origin.y=0;
	
	_sourceListPlaceHolderView.frame=tLeftFrame;
	
	[inSplitView adjustSubviews];
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	return NO;
}

- (CGFloat)splitView:(NSSplitView *)inSplitView constrainMaxCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	return (NSWidth(inSplitView.frame)-(ICDOCUMENT_RIGHTVIEW_MIN_WIDTH+inSplitView.dividerThickness));
}

#pragma mark -

- (void)sourceListSelectionDidChange:(NSNotification *)inNotification
{
	NSOutlineView * tOutlineView=_sourceListController.outlineView;
	
	if (inNotification.object!=tOutlineView)
		return;
	
	PKGViewController * tNewViewController=nil;
	
	NSUInteger tNumberOfSelectedRows=tOutlineView.numberOfSelectedRows;
	
	if (tNumberOfSelectedRows>1)
	{
		if (_currentContentsViewController!=nil && [_currentContentsViewController isKindOfClass:PKGDistributionMultipleSelectionViewController.class]==YES)
			return;
		
		tNewViewController=[PKGDistributionMultipleSelectionViewController new];
	}
	else
	{
		PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)self.project;
		NSArray * tSelectedItems=[tOutlineView WB_selectedItems];
		
		if (tSelectedItems.count==0)
			return;
		
		PKGDistributionProjectSourceListTreeNode * tSourceListTreeNode=tSelectedItems[0];
		PKGDistributionProjectSourceListItem * tSourceListItem=[tSourceListTreeNode representedObject];
		
		if ([tSourceListItem isKindOfClass:PKGDistributionProjectSourceListProjectItem.class]==YES)
		{
			if (_currentContentsViewController!=nil && [_currentContentsViewController isKindOfClass:PKGDistributionProjectViewController.class]==YES)
				return;
			
			tNewViewController=[[PKGDistributionProjectViewController alloc] initWithDocument:self.document];
			
			((PKGDistributionProjectViewController *)tNewViewController).project=tDistributionProject;
		}
		else if ([tSourceListItem isKindOfClass:PKGDistributionProjectSourceListPackageComponentItem.class]==YES)
		{
			PKGPackageComponent * tPackageComponent=((PKGDistributionProjectSourceListPackageComponentItem *) tSourceListItem).packageComponent;
			
			if (_currentContentsViewController!=nil && [_currentContentsViewController isKindOfClass:PKGDistributionPackageComponentViewController.class]==YES)
			{
				if (((PKGDistributionPackageComponentViewController *)_currentContentsViewController).packageComponent==tPackageComponent)
					return;
			}
			
			tNewViewController=[[PKGDistributionPackageComponentViewController alloc] initWithDocument:self.document];
			
			((PKGDistributionPackageComponentViewController *)tNewViewController).packageComponent=tPackageComponent;
		}
	}
	
	if (_currentContentsViewController!=nil)
	{
		[_currentContentsViewController WB_viewWillDisappear];
		
		if (_currentContentsViewController!=tNewViewController)
			[_currentContentsViewController.view removeFromSuperview];
	
		[_currentContentsViewController WB_viewDidDisappear];
	}
	
	tNewViewController.view.frame=_contentsView.bounds;
	
	[tNewViewController WB_viewWillAppear];
	
	if (_currentContentsViewController!=tNewViewController)
		[_contentsView addSubview:tNewViewController.view];
	
	[tNewViewController WB_viewDidAppear];
	
	_currentContentsViewController=tNewViewController;
	
	[self updateViewMenu];
}

- (void)packageComponentsDidRemove:(NSNotification *)inNotification
{
	NSArray * tComponents=inNotification.userInfo[@"Objects"];
	
	// Remove the registry records for the package components
	
	for(PKGPackageComponent * tPackageComponent in tComponents)
	{
		NSArray * tKeys=tPackageComponent.disclosedStatesKeys;
		
		[self.documentRegistry removeObjectForKeys:tKeys];
	}
	
	// A COMPLETER
}

- (void)choiceDependenciesEditionWillBegin:(NSNotification *)inNotification
{
	// Hide Source List
	
	_editingInstallationTypeChoice=YES;

	NSRect tFrame=_sourceListPlaceHolderView.frame;
	
	_savedSourceListWidth=NSWidth(tFrame);
	
	tFrame.size.width=0.0;
	
	_sourceListPlaceHolderView.frame=tFrame;
	
	NSRect tSplitViewBounds=_splitView.bounds;
	
	_contentsView.frame=tSplitViewBounds;
	
	tFrame=_splitView.frame;
	tFrame.size.width+=_splitView.dividerThickness;
	tFrame.origin.x-=_splitView.dividerThickness;
	
	_splitView.frame=tFrame;
	
	//[_splitView display];
}

- (void)choiceDependenciesEditionDidEnd:(NSNotification *)inNotification
{
	// Show Source List
	
	NSRect tFrame=_sourceListPlaceHolderView.frame;
	
	tFrame.size.width=_savedSourceListWidth;
	
	_sourceListPlaceHolderView.frame=tFrame;
	
	tFrame=_splitView.frame;
	
	tFrame.size.width-=_splitView.dividerThickness;
	tFrame.origin.x+=_splitView.dividerThickness;
	
	_splitView.frame=tFrame;
	
	NSRect tSplitViewBounds=_splitView.bounds;
	
	tFrame=_contentsView.frame;
	
	tFrame.origin.x=_savedSourceListWidth+_splitView.dividerThickness;
	tFrame.size.width=NSWidth(tSplitViewBounds)-tFrame.origin.x;
	
	_contentsView.frame=tSplitViewBounds;
	
	//[_splitView display];
	
	_editingInstallationTypeChoice=NO;
}

- (void)distributionViewEffectiveAppearanceDidChange:(NSNotification *)inNotification
{
	[self.documentRegistry removeObjectForKey:PKGDistributionPresentationSelectedAppearance];
}

@end
