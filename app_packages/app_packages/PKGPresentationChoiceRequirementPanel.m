/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationChoiceRequirementPanel.h"

#import "PKGRequirementWindowController.h"

#import "PKGPresentationChoiceRequirementBehaviorViewController.h"

@interface PKGChoiceRequirementWindowController : PKGRequirementWindowController
{
	IBOutlet NSView * _behaviorPlaceHolderView;
	
	PKGPresentationChoiceRequirementBehaviorViewController * _behaviorController;
    
    PKGRequirementMessagesDataSource * _dataSource;
}

@end

@implementation PKGChoiceRequirementWindowController

- (instancetype)init
{
    self=[super init];
    
    if (self!=nil)
    {
        _dataSource=[PKGRequirementMessagesDataSource new];
    }
    
    return self;
}

- (NSString *)windowNibName
{
	return @"PKGPresentationChoiceRequirementPanel";
}

#pragma mark -

- (void)setRequirement:(PKGRequirement *)inRequirement
{
	[super setRequirement:inRequirement];
	
	_dataSource.messages=inRequirement.messages;
}

#pragma mark -

- (void)showRequirementViewControllerWithIdentifier:(NSString *)inIdentifier
{
	[super showRequirementViewControllerWithIdentifier:inIdentifier];
	
    if (_behaviorController==nil)
    {
        PKGRequirementPanel * tRequirementPanel=(PKGRequirementPanel *)self.window;
        
        _behaviorController=[[PKGPresentationChoiceRequirementBehaviorViewController alloc] initWithDocument:tRequirementPanel.document];
        
        _behaviorController.dataSource=_dataSource;
        
        _behaviorController.view.frame=_behaviorPlaceHolderView.bounds;
        
        [_behaviorController WB_viewWillAppear];
        
        [_behaviorPlaceHolderView addSubview:_behaviorController.view];
        
        [_behaviorController WB_viewDidAppear];
    }
    
	_behaviorController.requirementBehavior=self.requirement.failureBehavior;
	
	[_behaviorController refreshUI];
	
	NSView * tPreviousKeyView=[self.currentRequirementViewController previousKeyView];
	
	if (tPreviousKeyView!=nil)
	{
		[_behaviorController.tableView setNextKeyView:tPreviousKeyView];
		
		[self.currentRequirementViewController setNextKeyView:_behaviorController.tableView];
		
		[self.window makeFirstResponder:tPreviousKeyView];
	}
	else
	{
		[self.window makeFirstResponder:_behaviorController.tableView];
	}
}

- (IBAction)endDialog:(NSButton *)sender
{
	self.requirement.failureBehavior=_behaviorController.requirementBehavior;
	
	[super endDialog:sender];
}

@end


@interface PKGRequirementPanel ()

	@property PKGRequirementWindowController * retainedWindowController;

@end

@interface PKGPresentationChoiceRequirementPanel ()

@end

@implementation PKGPresentationChoiceRequirementPanel

+ (PKGPresentationChoiceRequirementPanel *)choiceRequirementPanel
{
	PKGChoiceRequirementWindowController * tWindowController=[PKGChoiceRequirementWindowController new];
	
	PKGPresentationChoiceRequirementPanel * tPanel=(PKGPresentationChoiceRequirementPanel *)tWindowController.window;
	tPanel.retainedWindowController=tWindowController;
	
	return tPanel;
}

@end
