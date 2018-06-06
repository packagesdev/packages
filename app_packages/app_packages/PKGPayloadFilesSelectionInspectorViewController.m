/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadFilesSelectionInspectorViewController.h"

#import "PKGPayloadTreeNode+UI.h"

#import "PKGPayloadBundleItem.h"

#import "PKGPayloadFilesSelectionInspectorAttributesViewController.h"
#import "PKGPayloadFilesSelectionInspectorRulesViewController.h"
#import "PKGPayloadFilesSelectionInspectorScriptsViewController.h"

@interface PKGPayloadFilesSelectionInspectorViewController ()
{
	NSTabViewItem * _rulesTabViewItem;
	
	NSTabViewItem * _scriptsTabViewItem;
	
	PKGPayloadFilesSelectionInspectorRulesViewController * _rulesViewController;
	
	PKGPayloadFilesSelectionInspectorRulesViewController * _scriptsViewController;
}

@end

@implementation PKGPayloadFilesSelectionInspectorViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// Rules
	
	NSUInteger tIndex=[tabView indexOfTabViewItemWithIdentifier:@"tabviewitem.rules"];
	
	if (tIndex==NSNotFound)
	{
		// A COMPLETER
		
		return;
	}
	
	_rulesTabViewItem=[tabView tabViewItemAtIndex:tIndex];
	
	NSView * tView=_rulesTabViewItem.view;
	
	PKGFilesSelectionInspectorTabViewItemViewController * tTabViewItemViewController=[[PKGPayloadFilesSelectionInspectorRulesViewController alloc] initWithDocument:self.document];
	
	if (tTabViewItemViewController==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	tTabViewItemViewController.delegate=self.delegate;
	
	[self.tabViewItemViewControllers addObject:tTabViewItemViewController];
	
	tTabViewItemViewController.view.frame=tView.bounds;
	
	[tView addSubview:tTabViewItemViewController.view];
	
	// Scripts
	
	tIndex=[tabView indexOfTabViewItemWithIdentifier:@"tabviewitem.scripts"];
	
	if (tIndex==NSNotFound)
	{
		// A COMPLETER
		
		return;
	}
	
	_scriptsTabViewItem=[tabView tabViewItemAtIndex:tIndex];
	
	tView=_scriptsTabViewItem.view;
	
	tTabViewItemViewController=[[PKGPayloadFilesSelectionInspectorScriptsViewController alloc] initWithDocument:self.document];
	
	if (tTabViewItemViewController==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	tTabViewItemViewController.delegate=self.delegate;
	
	[self.tabViewItemViewControllers addObject:tTabViewItemViewController];
	
	tTabViewItemViewController.view.frame=tView.bounds;
	
	[tView addSubview:tTabViewItemViewController.view];
}

#pragma mark -

- (PKGFilesSelectionInspectorTabViewItemViewController *)attributesViewController
{
	return [[PKGPayloadFilesSelectionInspectorAttributesViewController alloc] init];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
}

#pragma mark -

- (void)refreshSingleSelection
{
	PKGPayloadTreeNode * tSelectedNode=[self.selectedItems lastObject];
	PKGFileItem * tSelectedItem=[tSelectedNode representedObject];
	
	if ([tSelectedItem isKindOfClass:PKGPayloadBundleItem.class]==YES)
	{
		if ([tabView indexOfTabViewItem:_rulesTabViewItem]==NSNotFound)
			[tabView insertTabViewItem:_rulesTabViewItem atIndex:1];
		if ([tabView indexOfTabViewItem:_scriptsTabViewItem ]==NSNotFound)
			[tabView insertTabViewItem:_scriptsTabViewItem atIndex:2];
	}
	else
	{
		if ([tabView indexOfTabViewItem:_rulesTabViewItem]!=NSNotFound)
			[tabView removeTabViewItem:_rulesTabViewItem];
		if ([tabView indexOfTabViewItem:_scriptsTabViewItem]!=NSNotFound)
			[tabView removeTabViewItem:_scriptsTabViewItem];
	}
	
	[super refreshSingleSelection];
}

- (void)refreshMultipleSelection
{
	if ([tabView indexOfTabViewItem:_rulesTabViewItem]!=NSNotFound)
		[tabView removeTabViewItem:_rulesTabViewItem];
	if ([tabView indexOfTabViewItem:_scriptsTabViewItem]!=NSNotFound)
		[tabView removeTabViewItem:_scriptsTabViewItem];
	
	[super refreshMultipleSelection];
}

@end
