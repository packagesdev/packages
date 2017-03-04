/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadFilesSelectionInspectorScriptsViewController.h"

#import "PKGStackView.h"

#import "PKGPayloadTreeNode.h"
#import "PKGPayloadBundleItem.h"
#import "PKGPayloadBundleItem+Safe.h"

#import "PKGBundleScriptViewController.h"

@interface PKGPayloadFilesSelectionInspectorScriptsViewController ()
{
	IBOutlet PKGStackView * _installationBundleScriptView;
	
	PKGBundleScriptViewController * _preInstallationScriptViewController;
	PKGBundleScriptViewController * _postInstallationScriptViewController;
}

@end

@implementation PKGPayloadFilesSelectionInspectorScriptsViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	// Pre-installation
	
	_preInstallationScriptViewController=[[PKGBundleScriptViewController alloc] initWithDocument:self.document];
	_preInstallationScriptViewController.label=NSLocalizedString(@"Pre-installation", @"");
	
	[_installationBundleScriptView addView:_preInstallationScriptViewController.view];
	
	// Post-installation
	
	_postInstallationScriptViewController=[[PKGBundleScriptViewController alloc] initWithDocument:self.document];
	_postInstallationScriptViewController.label=NSLocalizedString(@"Post-installation", @"");
	
	[_installationBundleScriptView addView:_postInstallationScriptViewController.view];
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[_preInstallationScriptViewController WB_viewWillAppear];
	[_postInstallationScriptViewController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[_preInstallationScriptViewController WB_viewDidAppear];
	[_postInstallationScriptViewController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_preInstallationScriptViewController WB_viewWillDisappear];
	[_postInstallationScriptViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_preInstallationScriptViewController WB_viewDidDisappear];
	[_postInstallationScriptViewController WB_viewDidDisappear];
}

#pragma mark -

- (void)refreshSingleSelection
{
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGPayloadBundleItem * tBundleItem=[tTreeNode representedObject];
	
	if ([tBundleItem isKindOfClass:PKGPayloadBundleItem.class]==NO)
		return;
	
	_preInstallationScriptViewController.installationScriptPath=[tBundleItem preInstallationScriptPath_safe];
	
	_postInstallationScriptViewController.installationScriptPath=[tBundleItem postInstallationScriptPath_safe];
}

@end
