/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDocumentWindowController.h"

#import "PKGPackageProjectMainViewController.h"
#import "PKGDistributionProjectMainViewController.h"

#define PKGDocumentWindowPackageProjectMinWidth				1026.0
#define PKGDocumentWindowDistributionProjectMinWidth		1200.0
#define PKGDocumentWindowMinHeight							613.0

@interface PKGDocumentWindowController ()
{
	PKGProjectMainViewController * _projectMainViewController;
}

	@property (readwrite) PKGProject * project;

@end

@implementation PKGDocumentWindowController

- (instancetype)initWithProject:(PKGProject *)inProject
{
	self=[super init];
	
	if (self!=nil)
	{
		_project=inProject;
		
		self.shouldCloseDocument=YES;
	}
	
	return self;
}

- (NSString *)windowNibName
{
	return @"PKGDocumentWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	switch(self.project.type)
	{
		case PKGProjectTypeDistribution:
			
			_projectMainViewController=[[PKGDistributionProjectMainViewController alloc] initWithDocument:self.document];
			
			[self.window setMinSize:NSMakeSize(PKGDocumentWindowDistributionProjectMinWidth, PKGDocumentWindowMinHeight)];
			
			break;
			
		case PKGProjectTypePackage:
			
			_projectMainViewController=[[PKGPackageProjectMainViewController alloc] initWithDocument:self.document];
			
			[self.window setMinSize:NSMakeSize(PKGDocumentWindowPackageProjectMinWidth, PKGDocumentWindowMinHeight)];
			
			break;
	}
	
	_projectMainViewController.project=self.project;
	
	NSView * tContentView=self.window.contentView;
	
	NSView * tMainView=_projectMainViewController.view;
	
	NSRect tBounds=tContentView.bounds;
	
	tMainView.frame=tBounds;
	
	[_projectMainViewController WB_viewWillAppear];
	
	[tContentView addSubview:tMainView];
	
	[_projectMainViewController WB_viewDidAppear];
	
	[self.window setContentBorderThickness:33.0 forEdge:NSMinYEdge];
}

#pragma mark -

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[_projectMainViewController updateViewMenu];
}

@end
