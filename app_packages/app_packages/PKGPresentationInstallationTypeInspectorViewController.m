/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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

- (void)showSingleSelectionViewForItem:(id)inItem choicesForest:(PKGChoicesForest *)inChoicesForest;

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
			
			_nonSingleSelectionViewController.label=NSLocalizedStringFromTable(@"Not Editable", @"Presentation",@"");
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

- (void)showSingleSelectionViewForItem:(PKGChoiceTreeNode *)inItem choicesForest:(PKGChoicesForest *)inChoicesForest
{
	if (inItem==nil)
		return;
	
	if (_singleSelectionViewController==nil)
		_singleSelectionViewController=[[PKGPresentationInstallationTypeSingleSelectionViewController alloc] initWithDocument:self.document];
	
	_singleSelectionViewController.selectedChoiceTreeNode=inItem;
	_singleSelectionViewController.choicesForest=inChoicesForest;
	
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
			
			[self showSingleSelectionViewForItem:inNotification.userInfo[PKGInstallationHierarchySelectionItemKey] choicesForest:inNotification.userInfo[PKGInstallationHierarchyChoicesForestKey]];
			
			break;
	}
}

@end
