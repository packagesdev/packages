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

#import "PKGDistributionProject.h"

@interface PKGDistributionProjectMainViewController () <NSSplitViewDelegate>
{
	IBOutlet NSSplitView * _splitView;
	
	
	PKGDistributionProjectSourceListController * _sourceListController;
	
	PKGDistributionProjectSourceListDataSource * _dataSource;
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
	
	NSView * tLeftView=_splitView.subviews[0];
	
	_sourceListController.view.frame=tLeftView.bounds;
	
	[tLeftView addSubview:_sourceListController.view];
	
	// A COMPLETER
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)self.project;
	
	_dataSource.packageComponents=tDistributionProject.packageComponents;
	
	[_sourceListController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self.view.window makeFirstResponder:_sourceListController.outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceListSelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_sourceListController.outlineView];
	
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

#pragma mark -

- (void)sourceListSelectionDidChange:(NSNotification *)inNotification
{
	// A COMPLETER
}

@end
