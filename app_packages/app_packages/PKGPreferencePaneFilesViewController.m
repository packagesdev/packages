/*
 Copyright (c) 2008-2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPreferencePaneFilesViewController.h"

#import "PKGApplicationPreferences.h"

@interface PKGPreferencePaneFilesViewController ()
{
	IBOutlet NSButton * _showAllFilesCheckbox;
	
	IBOutlet NSButton * _highlightExcludedFilesCheckbox;
	
	IBOutlet NSButton * _keepOwnerAndGroupCheckbox;
	
	IBOutlet NSButton * _showCustomizationDialogCheckbox;
	
	IBOutlet NSButton * _showServicesUsersAndGroupsCheckbox;
}

- (IBAction)switchShowAllFiles:(id) sender;

- (IBAction)switchHighlightExcludedFiles:(id) sender;

- (IBAction)switchKeepOwnerAndGroup:(id) sender;

- (IBAction)switchShowCustomizationDialog:(id) sender;

- (IBAction)switchShowServicesUsersAndGroups:(id) sender;

@end

@implementation PKGPreferencePaneFilesViewController

- (void) awakeFromNib
{
    [super awakeFromNib];
	
	// Set Reference Style Menu
	
	NSAttributedString * tAttributedString=[[NSAttributedString alloc] initWithString:[_highlightExcludedFilesCheckbox title]
																		   attributes:@{NSFontAttributeName:[_highlightExcludedFilesCheckbox font],
																						NSStrikethroughStyleAttributeName:@(NSUnderlineStyleSingle)}];

	if (tAttributedString!=nil)
		[_highlightExcludedFilesCheckbox setAttributedTitle:tAttributedString];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	// Show All Files
	
	_showAllFilesCheckbox.state=([PKGApplicationPreferences sharedPreferences].showAllFilesInOpenDialog==YES) ? WBControlStateValueOn: WBControlStateValueOff;
	
	// Highlight Excluded Files
	
	_highlightExcludedFilesCheckbox.state=([PKGApplicationPreferences sharedPreferences].highlightExcludedFiles==YES) ? WBControlStateValueOn: WBControlStateValueOff;
	
	// Default Permission Mode
	
	_keepOwnerAndGroupCheckbox.state=([PKGApplicationPreferences sharedPreferences].keepOwnership==YES) ? WBControlStateValueOn: WBControlStateValueOff;
	
	// Show Customization Dialog
	
	_showCustomizationDialogCheckbox.state=([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES) ? WBControlStateValueOn: WBControlStateValueOff;
	
	// Show Services Users and Groups
	
	_showServicesUsersAndGroupsCheckbox.state=([PKGApplicationPreferences sharedPreferences].showServicesUsersAndGroups==YES) ? WBControlStateValueOn: WBControlStateValueOff;
}

#pragma mark -

- (IBAction)switchShowAllFiles:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].showAllFilesInOpenDialog=(_showAllFilesCheckbox.state==WBControlStateValueOn);
}

- (IBAction)switchHighlightExcludedFiles:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].highlightExcludedFiles=(_highlightExcludedFilesCheckbox.state==WBControlStateValueOn);
	
	// Post Notification
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPreferencesFilesHighlightExcludedFilesDidChangeNotification
														object:nil];
}

- (IBAction)switchKeepOwnerAndGroup:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].keepOwnership=(_keepOwnerAndGroupCheckbox.state==WBControlStateValueOn);
}

- (IBAction)switchShowCustomizationDialog:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog=(_showCustomizationDialogCheckbox.state==WBControlStateValueOn);
}

- (IBAction)switchShowServicesUsersAndGroups:(id) sender
{
	[PKGApplicationPreferences sharedPreferences].showServicesUsersAndGroups=(_showServicesUsersAndGroupsCheckbox.state==WBControlStateValueOn);
	
	// Post Notification
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPreferencesFilesShowServicesUsersAndGroupsDidChangeNotification
														object:nil];
}

@end
