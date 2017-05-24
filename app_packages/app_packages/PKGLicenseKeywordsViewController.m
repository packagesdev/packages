/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLicenseKeywordsViewController.h"

#import "PKGLicenseProvider.h"

#import "PKGPresentationStepSettings+UI.h"

@interface PKGLicenseKeywordsViewController () <NSTableViewDataSource,NSTableViewDelegate>
{
	PKGLicenseTemplate * _licenseTemplate;
}

	@property (readwrite) IBOutlet NSTableView * tableView;

- (IBAction)setKeywordValue:(id)sender;

@end

@implementation PKGLicenseKeywordsViewController

- (void)WB_viewDidLoad
{
	// A COMPLETER
}

#pragma mark -

- (void)setLicenseStepSettings:(PKGPresentationLicenseStepSettings *)inLicenseStepSettings
{
	_licenseStepSettings=inLicenseStepSettings;
	
	if (_licenseStepSettings==nil)
		_licenseTemplate=nil;
	else
		_licenseTemplate=[[PKGLicenseProvider defaultProvider] licenseTemplateNamed:_licenseStepSettings.templateName];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	// A COMPLETER
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self refreshUI];
}

- (void)refreshUI
{
	[self.tableView reloadData];
}

#pragma mark -

- (IBAction)setKeywordValue:(NSTextField *)sender
{
	NSInteger tRow=[self.tableView rowForView:sender];
	
	if (tRow==-1)
		return;
	
	NSString * tKey=_licenseTemplate.keywords[tRow];
	NSString * tValue=sender.stringValue;
	
	if ([self.licenseStepSettings.templateValues[tKey] isEqualToString:tValue]==YES)
		return;
	
	self.licenseStepSettings.templateValues[tKey]=tValue;
	
	// Notify the change
	
	[self noteDocumentHasChanged];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.licenseStepSettings userInfo:nil];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView!=self.tableView)
		return 0;
	
	return _licenseTemplate.keywords.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView!=self.tableView)
		return nil;
	
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	
	if ([tTableColumnIdentifier isEqualToString:@"keyword"]==YES)
	{
		NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		tTableCellView.textField.stringValue=_licenseTemplate.keywords[inRow];
		
		return tTableCellView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"value"]==YES)
	{
		NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		NSString * tValue=self.licenseStepSettings.templateValues[_licenseTemplate.keywords[inRow]];
		
		tTableCellView.textField.stringValue=(tValue!=nil) ? tValue : @"";
		tTableCellView.textField.editable=YES;
		
		return tTableCellView;
	}
	
	return nil;
}

@end
