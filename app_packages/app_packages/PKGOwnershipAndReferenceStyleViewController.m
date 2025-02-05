/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGOwnershipAndReferenceStyleViewController.h"

@interface PKGOwnershipAndReferenceStyleViewController ()
{
	IBOutlet NSView * _keepOwnerAndGroupView;
	IBOutlet NSButton * _keepOwnerAndGroupButton;
	
	IBOutlet NSView * _referenceStyleView;
	IBOutlet NSPopUpButton * _referenceStylePopUpButton;
}

- (void)_updateViewLayout;

- (IBAction)switchKeepOwnerAndGroup:(id)sender;

- (IBAction)switchReferenceStyle:(id)sender;

@end

@implementation PKGOwnershipAndReferenceStyleViewController

- (NSString *)nibName
{
	return NSStringFromClass([self class]);
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
    [self _updateViewLayout];
}

#pragma mark -

- (void)_updateViewLayout
{
	if (_canChooseOwnerAndGroupOptions==[_keepOwnerAndGroupView isHidden])
	{
		[_keepOwnerAndGroupView setHidden:![_keepOwnerAndGroupView  isHidden]];
		
		NSRect tFrame=self.view.frame;
		
		tFrame.size.height=NSHeight(_referenceStyleView.frame);
		
		if (_canChooseOwnerAndGroupOptions==YES)
			tFrame.size.height=tFrame.size.height+NSHeight(_keepOwnerAndGroupView.frame);
		
		self.view.frame=tFrame;
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	_keepOwnerAndGroupButton.state=(_keepOwnerAndGroup==YES) ? WBControlStateValueOn : WBControlStateValueOff;
	
	[_referenceStylePopUpButton selectItemWithTag:_referenceStyle];
}

#pragma mark -

- (void)setCanChooseOwnerAndGroupOptions:(BOOL)inCanChooseOwnerAndGroupOptions
{
	if (_canChooseOwnerAndGroupOptions!=inCanChooseOwnerAndGroupOptions)
	{
		_canChooseOwnerAndGroupOptions=inCanChooseOwnerAndGroupOptions;
		
		[self _updateViewLayout];
	}
}

#pragma mark -

- (void)setKeepOwnerAndGroup:(BOOL)inKeepOwnerAndGroup
{
	if (inKeepOwnerAndGroup!=_keepOwnerAndGroup)
	{
		_keepOwnerAndGroup=inKeepOwnerAndGroup;
		
		_keepOwnerAndGroupButton.state=(_keepOwnerAndGroup==YES) ? WBControlStateValueOn : WBControlStateValueOff;
	}
}

- (void)setReferenceStyle:(PKGFilePathType)inReferenceStyle
{
	if (inReferenceStyle!=_referenceStyle)
	{
		_referenceStyle=inReferenceStyle;
		
		[_referenceStylePopUpButton selectItemWithTag:_referenceStyle];
	}
}

#pragma mark -

- (IBAction)switchKeepOwnerAndGroup:(id)sender
{
	_keepOwnerAndGroup=(_keepOwnerAndGroupButton.state==WBControlStateValueOn);
}

- (IBAction)switchReferenceStyle:(id)sender
{
	_referenceStyle=_referenceStylePopUpButton.selectedItem.tag;
}

@end
