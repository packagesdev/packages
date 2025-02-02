/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGProjectMainViewController.h"

@interface PKGProjectMainViewController () <NSMenuItemValidation>


@end

@implementation PKGProjectMainViewController

- (void)updateViewMenu
{
	NSMenu * tMenuBar=[NSApp mainMenu];
	
	NSMenu * tViewMenu=[tMenuBar itemWithTag:PKGViewMenuItemTag].submenu;
	
	for(NSMenuItem * tMenuItem in tViewMenu.itemArray)
	{
		[self validateMenuItem:tMenuItem];
	}
}

#pragma mark - View Menu

- (IBAction)showDistributionPresentationTab:(id)sender
{
	// Empty implementation but needed to dynamically set the contents of the View menu
}

- (IBAction)showDistributionRequirementsAndResourcesTab:(id)sender
{
	// Empty implementation but needed to dynamically set the contents of the View menu
}

- (IBAction)showProjectSettingsTab:(id)sender
{
}

- (IBAction)showProjectCommentsTab:(id)sender
{
}

- (IBAction)showPackageSettingsTab:(id)sender
{
}

- (IBAction)showPackagePayloadTab:(id)sender
{
}

- (IBAction)showPackageScriptsAndResourcesTab:(id)sender
{
}

#pragma mark - Hierarchy Menu

- (IBAction)addFiles:(id)sender
{
}

- (IBAction)addNewFolder:(id)sender
{
}

- (IBAction)expandOneLevel:(id)sender
{
}

- (IBAction)expand:(id)sender
{
}

- (IBAction)expandAll:(id)sender
{
}

- (IBAction)contract:(id)sender
{
}

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender
{
}

- (IBAction)setDefaultDestination:(id)sender
{
}

@end
