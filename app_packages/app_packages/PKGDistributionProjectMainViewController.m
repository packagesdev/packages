/*
 Copyright (c) 2016, Stephane Sudre
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

#import "PKGDistributionProject.h"

#import "PKGDistributionProjectSourceListTreeNode.h"
#import "PKGDistributionProjectSourceListProjectItem.h"
#import "PKGDistributionProjectSourceListPackageComponentItem.h"

#import "NSOutlineView+Selection.h"

@interface PKGDistributionProjectMainViewController () <NSSplitViewDelegate>
{
	IBOutlet NSSplitView * _splitView;
	
	IBOutlet NSView * _sourceListPlaceHolderView;
	
	IBOutlet NSView * _contentsView;
	
	PKGDistributionProjectSourceListController * _sourceListController;
	
	PKGDistributionProjectSourceListDataSource * _dataSource;
	
	
	PKGDistributionMultipleSelectionViewController * _multipleSectionViewController;
	
	PKGDistributionProjectViewController * _projectViewController;
	
	PKGViewController * _currentContentsViewController;
}

// Notifications

- (void)sourceListSelectionDidChange:(NSNotification *)inNotification;

@end

@implementation PKGDistributionProjectMainViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	_dataSource=[PKGDistributionProjectSourceListDataSource new];
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// Source List
	
	_sourceListController=[PKGDistributionProjectSourceListController new];
	_sourceListController.dataSource=_dataSource;
	
	_sourceListController.view.frame=_sourceListPlaceHolderView.bounds;
	
	[_sourceListPlaceHolderView addSubview:_sourceListController.view];
	
	// A COMPLETER
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)self.project;
	
	_dataSource.packageComponents=tDistributionProject.packageComponents;
	
	_dataSource.delegate=_sourceListController;
	
	[_sourceListController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self.view.window makeFirstResponder:_sourceListController.outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceListSelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_sourceListController.outlineView];
	
	_dataSource.filePathConverter=self.filePathConverter;
	
	[_sourceListController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:nil];
	
	[_sourceListController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_sourceListController WB_viewDidDisappear];
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
	
	NSUInteger tNumberOfSelectedRows=tOutlineView.numberOfSelectedRows;
	
	if (tNumberOfSelectedRows>1)
	{
		if (_multipleSectionViewController==nil)
			_multipleSectionViewController=[PKGDistributionMultipleSelectionViewController new];
		
		if (_currentContentsViewController!=_multipleSectionViewController)
		{
			[_currentContentsViewController WB_viewWillDisappear];
			
			[_currentContentsViewController.view removeFromSuperview];
			
			[_currentContentsViewController WB_viewDidDisappear];
			
			_currentContentsViewController=_multipleSectionViewController;
			
			_currentContentsViewController.view.frame=_contentsView.bounds;
			
			[_currentContentsViewController WB_viewWillAppear];
			
			[_contentsView addSubview:_currentContentsViewController.view];
			
			[_currentContentsViewController WB_viewDidAppear];
		}
	}
	else
	{
		PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)self.project;
		
		PKGDistributionProjectSourceListTreeNode * tSourceListTreeNode=[tOutlineView WB_selectedItems][0];
		PKGDistributionProjectSourceListItem * tSourceListItem=[tSourceListTreeNode representedObject];

		PKGViewController * tNewViewController=nil;
		
		if ([tSourceListItem isKindOfClass:PKGDistributionProjectSourceListProjectItem.class]==YES)
		{
			if (_projectViewController==nil)
			{
				_projectViewController=[PKGDistributionProjectViewController new];
			}
			
			_projectViewController.project=tDistributionProject;
			
			tNewViewController=_projectViewController;
		}
		
		if (_currentContentsViewController!=tNewViewController)
		{
			[_currentContentsViewController WB_viewWillDisappear];
			
			[_currentContentsViewController.view removeFromSuperview];
			
			[_currentContentsViewController WB_viewDidDisappear];
			
			_currentContentsViewController=tNewViewController;
			
			_currentContentsViewController=tNewViewController;
			
			_currentContentsViewController.view.frame=_contentsView.bounds;
			
			[_currentContentsViewController WB_viewWillAppear];
			
			[_contentsView addSubview:_currentContentsViewController.view];
			
			[_currentContentsViewController WB_viewDidAppear];
		}
	}
}

@end
