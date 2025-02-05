/*
Copyright (c) 2007-2018, Stéphane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGPresentationSectionContentsView.h"

#import "PKGInstallerApp.h"

#import "PKGPresentationTheme.h"

#import "PKGDocument.h"

@interface PKGPresentationSectionContentsView ()

- (void)updateTheme;

// Notifications

- (void)presentationThemeDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationSectionContentsView

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
	self.boxType=NSBoxCustom;
	self.borderType=NSLineBorder;
	self.borderWidth=1.0;
	self.contentViewMargins=NSZeroSize;
}

#pragma mark -

- (BOOL)isOpaque
{
	return NO;
}

- (void)updateTheme
{
	PKGPresentationThemeVersion tThemeVersion=[((PKGDocument *)((NSWindowController *)self.window.windowController).document).registry[PKGPresentationTheme] unsignedIntegerValue];
	
	if (tThemeVersion==PKGPresentationThemeMojaveDynamic)
	{
		if ([self WB_isEffectiveAppearanceDarkAqua]==NO)
			tThemeVersion=PKGPresentationThemeMojaveLight;
		else
			tThemeVersion=PKGPresentationThemeMojaveDark;
	}
	
	switch(tThemeVersion)
	{
		case PKGPresentationThemeMountainLion:
			
			self.borderColor=[NSColor grayColor];
			break;
			
		case PKGPresentationThemeMojaveLight:
			
			if (NSAppKitVersionNumber<NSAppKitVersionNumber10_14)
			{
				self.borderColor=[NSColor colorWithDeviceWhite:0.8 alpha:1.0];
				break;
			}
			
		case PKGPresentationThemeMojaveDark:
			
			self.borderColor=[NSColor containerBorderColor];

			break;
			
		default:
			
			self.borderColor=[NSColor redColor];
			NSLog(@"Unsupported Theme");
			
			break;
	}
	
	switch(tThemeVersion)
	{
		case PKGPresentationThemeMountainLion:
			
			self.fillColor=[NSColor colorWithCalibratedWhite:1.0 alpha:0.6];
			break;
			
		case PKGPresentationThemeMojaveLight:
		case PKGPresentationThemeMojaveDark:
			
			self.fillColor=(NSAppKitVersionNumber>=NSAppKitVersionNumber10_14) ? [NSColor controlBackgroundColor] : [NSColor whiteColor];
			break;
			
		default:
			
			self.fillColor=[NSColor redColor];
			NSLog(@"Unsupported Theme");
			
			break;
	}
	
	[self setNeedsDisplay:YES];
}

#pragma mark - PKGControlledView

#if (MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10)

- (void)superSetNextResponder:(NSResponder *)inNextResponder
{
	[super setNextResponder:inNextResponder];
}

#endif

- (void)viewWillMoveToWindow:(NSWindow *)inWindow
{
	if (inWindow==nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		return;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentationThemeDidChange:) name:PKGPresentationThemeDidChangeNotification object:inWindow];
}

- (void)viewDidMoveToWindow
{
	[self updateTheme];
}

#pragma mark -

- (void)drawRect:(NSRect)frame
{
	[super drawRect:frame];
}

/*- (void)drawRect:(NSRect)frame
{
	PKGPresentationThemeVersion tThemeVersion=[((PKGDocument *)((NSWindowController *)self.window.windowController).document).registry[PKGPresentationTheme] unsignedIntegerValue];
	
	if (tThemeVersion==PKGPresentationThemeMojaveDynamic)
	{
		if ([self WB_isEffectiveAppearanceDarkAqua]==NO)
			tThemeVersion=PKGPresentationThemeMojaveLight;
		else
			tThemeVersion=PKGPresentationThemeMojaveDark;
	}
	
	switch(tThemeVersion)
	{
		case PKGPresentationThemeMountainLion:
			
			[[NSColor colorWithDeviceWhite:0.5 alpha:1.0] set];
			break;
		
		case PKGPresentationThemeMojaveLight:
			
			[[NSColor colorWithDeviceWhite:0.8 alpha:1.0] set];
			break;
			
		case PKGPresentationThemeMojaveDark:
			
			[[NSColor colorWithDeviceWhite:0.21 alpha:1.0] set];
			break;
			
		default:
			
			[[NSColor redColor] set];
			NSLog(@"Unsupported Theme");
			
			break;
	}
	
	NSRect tBounds=self.bounds;
    NSFrameRect(tBounds);
    
	tBounds=NSInsetRect(tBounds, 1.0,1.0);
    
	switch(tThemeVersion)
	{
		case PKGPresentationThemeMountainLion:
			
			[[NSColor colorWithDeviceWhite:1.0 alpha:0.6] set];
			break;
			
		case PKGPresentationThemeMojaveLight:
			
			[[NSColor whiteColor] set];
			break;
			
		case PKGPresentationThemeMojaveDark:
			
			[[NSColor colorWithDeviceWhite:0.10 alpha:1.0] set];
			break;
			
		default:
			
			[[NSColor redColor] set];
			NSLog(@"Unsupported Theme");
			
			break;
	}
	
    NSRectFillUsingOperation(tBounds,WBCompositingOperationSourceOver);
}*/

#pragma mark - Notifications

- (void)presentationThemeDidChange:(NSNotification *)inNotification
{
	if (self.window==nil)
		return;
	
	[self updateTheme];
}

@end
