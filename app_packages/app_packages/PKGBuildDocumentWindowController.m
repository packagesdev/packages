/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildDocumentWindowController.h"

#import "PKGBuildDocumentViewController.h"

#import "PKGDocument.h"

@interface PKGBuildDocumentWindowController ()
{
	PKGBuildDocumentViewController * _mainViewController;
}

@end

@implementation PKGBuildDocumentWindowController

- (NSString *)windowNibName
{
	return @"PKGBuildDocumentWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	_mainViewController=[PKGBuildDocumentViewController new];
	
	_mainViewController.view.frame=((NSView *)self.window.contentView).bounds;
	
	[_mainViewController WB_viewWillAppear];
	
	[self.window.contentView addSubview:_mainViewController.view];
	
	[_mainViewController WB_viewDidAppear];
	
	_mainViewController.outlineView.dataSource=self.dataSource;
	self.dataSource.delegate=_mainViewController;
	
	[self.window center];
}

#pragma mark -

- (void)setDataSource:(PKGBuildAndCleanObserverDataSource *)inDataSource
{
	if (_dataSource==inDataSource)
		return;
	
	_dataSource=inDataSource;
	
	_mainViewController.outlineView.dataSource=inDataSource;
	
	inDataSource.delegate=_mainViewController;
}

#pragma mark -

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)inDisplayName
{
	return [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ - Build Log",@"Build",@"No comments"),inDisplayName];
}

@end
