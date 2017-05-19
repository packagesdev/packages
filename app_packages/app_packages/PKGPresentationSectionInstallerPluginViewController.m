/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationSectionInstallerPluginViewController.h"

#import "PKGInstallerPlugin.h"

#import "PKGPresentationSection+UI.h"

@interface PKGPresentationSectionInstallerPluginViewController ()
{
	IBOutlet NSImageView * _iconView;
	
	NSImage * _pluginIcon;
	
	NSImage * _pluginNotFoundIcon;
	
	PKGPresentationSection * _presentationSection;
}

// Notifications

- (void)windowStateDidChange:(NSNotification *)inNotification;

- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationSectionInstallerPluginViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument presentationSection:(PKGPresentationSection *)inPresentationSection
{
	self=[super initWithDocument:inDocument];
	
	if (self!=nil)
	{
		_presentationSection=inPresentationSection;
	}
	
	return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_pluginIcon=[NSImage imageWithSize:NSMakeSize(128.0,128.0) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		
		NSImage * tSourceImage=[PKGPresentationSection installerPluginIcon];
		
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		
		[tSourceImage drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
		return YES;
		
	}];
	
	_pluginNotFoundIcon=[NSImage imageWithSize:NSMakeSize(128.0,128.0) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		
		NSImage * tSourceImage=[PKGPresentationSection installerPluginIcon];
		
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		
		[tSourceImage drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
		
		tSourceImage=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kQuestionMarkIcon)];
		
		[tSourceImage drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
		return YES;
		
	}];
}

#pragma mark -

- (NSString *)sectionPaneTitle
{
	NSString * tPaneTitle=nil;
	
	PKGFilePath * tFilePath=_presentationSection.pluginPath;
	
	if (tFilePath.isSet==YES)
	{
		NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tFilePath];
		PKGInstallerPlugin * tInstallerPlugin=[[PKGInstallerPlugin alloc] initWithBundleAtPath:tAbsolutePath];
		
		tPaneTitle=[tInstallerPlugin stringForKey:@"PaneTitle" localization:self.localization];
	}
	
	if (tPaneTitle==nil)
		tPaneTitle=NSLocalizedString(@"Not Found",@"");
	
	return tPaneTitle;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self refreshUIForLocalization:self.localization];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidResignMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
}

#pragma mark -

- (void)refreshUIForLocalization:(NSString *)inLocalization
{
	if (_presentationSection==nil || _iconView==nil)
		return;
	
	[self viewFrameDidChange:nil];
	
	PKGFilePath * tFilePath=_presentationSection.pluginPath;
	
	if (tFilePath.isSet==NO)
	{
		_iconView.image=_pluginNotFoundIcon;
		
		return;
	}
	
	NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tFilePath];
	
	if (tAbsolutePath==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	BOOL isDirectory=NO;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:tAbsolutePath isDirectory:&isDirectory]==NO || isDirectory==NO)
	{
		// A COMPLETER
		
		return;
	}
	
	NSBundle * tBundle=[NSBundle bundleWithPath:tAbsolutePath];
	
	if ([[tBundle objectForInfoDictionaryKey:@"InstallerSectionTitle"] isKindOfClass:NSString.class]==NO)
	{
		// A COMPLETER
		
		return;
	}
	
	_iconView.image=_pluginIcon;
}

#pragma mark - Notifications

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	[self refreshUIForLocalization:self.localization];
}

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	NSRect tBounds=self.view.bounds;
	
	NSRect tFrame=_iconView.frame;
	
	tFrame.origin.x=round(NSMidX(tBounds)-NSWidth(tFrame)*0.5);
	tFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tFrame)*0.5);
	
	_iconView.frame=tFrame;
}

@end
