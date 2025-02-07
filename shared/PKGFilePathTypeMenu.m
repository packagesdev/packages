/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFilePathTypeMenu.h"

@interface PKGFilePathTypeMenu ()

+ (NSImage *)_menuItemImageForPathType:(PKGFilePathType) inPathType controlSize:(NSControlSize) inControlSize;

@end

@implementation PKGFilePathTypeMenu

+ (NSImage *)_menuItemImageForPathType:(PKGFilePathType) inPathType controlSize:(NSControlSize) inControlSize
{
	switch(inControlSize)
	{
		case WBControlSizeRegular:
			
			switch(inPathType)
			{
				case PKGFilePathTypeAbsolute:
					
					return [NSImage imageNamed:@"AbsoluteMenuItemUbuntu"];
					
				case PKGFilePathTypeRelativeToProject:
					
					return [NSImage imageNamed:@"RelativeMenuItemUbuntu"];
					
				case PKGFilePathTypeRelativeToReferenceFolder:
					
					return [NSImage imageNamed:@"ReferenceFolderMenuItemUbuntu"];
					
				default:
					
					return nil;
			}
		
			break;
	
		case WBControlSizeSmall:
	
			switch(inPathType)
			{
				case PKGFilePathTypeAbsolute:
					
					return [NSImage imageNamed:@"AbsoluteMenuItemSmallUbuntu"];
					
				case PKGFilePathTypeRelativeToProject:
					
					return [NSImage imageNamed:@"RelativeMenuItemSmallUbuntu"];
					
				case PKGFilePathTypeRelativeToReferenceFolder:
					
					return [NSImage imageNamed:@"ReferenceFolderMenuItemSmallUbuntu"];
					
				default:
					
					return nil;
			}
			
			break;
			
		default:
			
			break;
	}
	
	return nil;
}

#pragma mak -

+ (instancetype)menuForAction:(SEL)inAction target:(id)inTarget controlSize:(NSControlSize)inControlSize
{
	PKGFilePathTypeMenu * tMenu=[[PKGFilePathTypeMenu alloc] initWithTitle:@""];
	
	if (tMenu!=nil)
	{
		tMenu.font=[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:inControlSize]];
		
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Relative to Reference Folder",@"") action:inAction keyEquivalent:@""];
		
		tMenuItem.tag=PKGFilePathTypeRelativeToReferenceFolder;
		tMenuItem.image=[PKGFilePathTypeMenu _menuItemImageForPathType:PKGFilePathTypeRelativeToReferenceFolder controlSize:inControlSize];
		if (inTarget!=nil)
			tMenuItem.target=inTarget;
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Relative to Project",@"") action:inAction keyEquivalent:@""];
		
		tMenuItem.tag=PKGFilePathTypeRelativeToProject;
		tMenuItem.image=[PKGFilePathTypeMenu _menuItemImageForPathType:PKGFilePathTypeRelativeToProject controlSize:inControlSize];
		if (inTarget!=nil)
			tMenuItem.target=inTarget;
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Absolute Path",@"") action:inAction keyEquivalent:@""];
		
		tMenuItem.tag=PKGFilePathTypeAbsolute;
		tMenuItem.image=[PKGFilePathTypeMenu _menuItemImageForPathType:PKGFilePathTypeAbsolute controlSize:inControlSize];
		if (inTarget!=nil)
			tMenuItem.target=inTarget;
		
		[tMenu addItem:tMenuItem];
	}
	
	return tMenu;
}

+ (NSSize)sizeOfPullDownImageForControlSize:(NSControlSize)inControlSize
{
	if (inControlSize==WBControlSizeRegular)
		return NSMakeSize(27.0,21.0);
	
	return NSZeroSize;
}

+ (NSImage *)pullDownImageForPathType:(PKGFilePathType)inPathType controlSize:(NSControlSize)inControlSize
{
	if (inControlSize==WBControlSizeRegular)
	{
		switch(inPathType)
		{
			case PKGFilePathTypeAbsolute:
				
				return [NSImage imageNamed:@"AbsoluteRegularTextFieldPulldownUbuntu"];
				
			case PKGFilePathTypeRelativeToProject:
				
				return [NSImage imageNamed:@"RelativeRegularTextFieldPulldownUbuntu"];
				
			case PKGFilePathTypeRelativeToReferenceFolder:
				
				return [NSImage imageNamed:@"ReferenceFolderRegularTextFieldPulldownUbuntu"];
				
			default:
				
				return nil;
		}
	}
	
	return nil;
}

@end
