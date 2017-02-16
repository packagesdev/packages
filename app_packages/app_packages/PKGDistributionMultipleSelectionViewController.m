/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionMultipleSelectionViewController.h"

@interface PKGDistributionMultipleSelectionViewController ()
{
	IBOutlet NSTextField * _multipleSelectionLabel;
}

- (void)viewDidResize:(NSNotification *)inNotification;

@end

@implementation PKGDistributionMultipleSelectionViewController

- (void)WB_viewDidLoad
{
    [super viewDidLoad];
	
	// A COMPLETER
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self viewDidResize:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(viewDidResize:)
												 name:NSViewFrameDidChangeNotification
											   object:self.view];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
}

#pragma mark - Notifications

- (void)viewDidResize:(NSNotification *)inNotification
{
	NSRect tBounds=self.view.bounds;
	
	NSRect tOldFrame=_multipleSelectionLabel.frame;
	NSRect tFrame=tOldFrame;
	
	// Center horizontally
	
	tFrame.origin.x=round(NSMidX(tBounds)-NSWidth(tFrame)*0.5);
	
	// Center horizontally
	
	tFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tFrame)*0.5);
	
	if (NSEqualRects(tFrame,tOldFrame)==NO)
		_multipleSelectionLabel.frame=tFrame;
}

@end
