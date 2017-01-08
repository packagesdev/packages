/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGAssistantController.h"

#import "PKGNavigationController.h"

#import "PKGAssistantStepViewController.h"

@interface PKGAssistantController ()
{
	PKGNavigationController * _navigationController;
	
	IBOutlet NSView * _placeHolderView;
	
	IBOutlet NSButton * _previousButton;
}

	@property (readwrite) IBOutlet NSButton * nextButton;

	@property (readwrite) PKGAssistantSettings * assistantSettings;

- (IBAction)previous:(id)sender;

- (IBAction)next:(id)sender;

@end

@implementation PKGAssistantController

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_assistantSettings=[PKGAssistantSettings new];
		
		PKGAssistantStepViewController * tRootViewController=[self rootViewController];
		
		tRootViewController.assistantController=self;
		
		_navigationController=[[PKGNavigationController alloc] initWithRootViewController:tRootViewController];
	}
	
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_previousButton.enabled=NO;
	self.nextButton.enabled=YES;
	
	_navigationController.view.frame=_placeHolderView.frame;
	
	[_placeHolderView removeFromSuperview];
	
	[self.view addSubview:_navigationController.view];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[_navigationController WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[_navigationController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[_navigationController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[_navigationController WB_viewDidDisappear];
}

#pragma mark -

- (PKGAssistantStepViewController *)rootViewController
{
	return nil;
}

#pragma mark -

- (void)finalizeAssistant
{
}

#pragma mark -

- (IBAction)previous:(id)sender
{
	self.nextButton.title=NSLocalizedString(@"Next",@"");
	self.nextButton.enabled=YES;
	
	[_navigationController popViewControllerAnimated:NO];
	
	[_previousButton setEnabled:(_navigationController.visibleViewController!=_navigationController.topViewController)];
}

- (IBAction)next:(id)sender
{
	PKGAssistantStepViewController * tVisibleController=(PKGAssistantStepViewController *)_navigationController.visibleViewController;
	
	if ([tVisibleController shouldShowNextStepViewController]==NO)
		return;
	
	PKGAssistantStepViewController * tNextViewController=tVisibleController.nextStepViewController;
	
	if (tNextViewController==nil)
	{
		[self finalizeAssistant];
		
		return;
	}
	
	tNextViewController.assistantController=self;
	
	[_navigationController pushViewController:tNextViewController animated:NO];
	
	_previousButton.enabled=YES;
}

@end
