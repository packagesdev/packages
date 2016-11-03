
#import "PKGFilePathTypeMenu.h"

@interface PKGFilePathTypeMenu ()

+ (NSImage *)_menuItemImageForPathType:(PKGFilePathType) inPathType controlSize:(NSControlSize) inControlSize;

@end

@implementation PKGFilePathTypeMenu

+ (NSImage *)_menuItemImageForPathType:(PKGFilePathType) inPathType controlSize:(NSControlSize) inControlSize
{
	if (inControlSize==NSRegularControlSize)
	{
		switch(inPathType)
		{
			case PKGFilePathTypeAbsolute:
				
				return [NSImage imageNamed:@"AbsoluteMenuItemUbuntu"];
				
			case PKGFilePathTypeRelativeToProject:
				
				return [NSImage imageNamed:@"RelativeMenuItemUbuntu"];
				
			case PKGFilePathTypeRelativeToReferenceFolder:
				
				return [NSImage imageNamed:@"ReferenceFolderMenuItemUbuntu"];
				
			default:
				break;
		}
		
		return nil;
	}
	
	if (inControlSize==NSSmallControlSize)
	{
		switch(inPathType)
		{
			case PKGFilePathTypeAbsolute:
				
				return [NSImage imageNamed:@"AbsoluteMenuItemSmallUbuntu"];
				
			case PKGFilePathTypeRelativeToProject:
				
				return [NSImage imageNamed:@"RelativeMenuItemSmallUbuntu"];
				
			case PKGFilePathTypeRelativeToReferenceFolder:
				
				return [NSImage imageNamed:@"ReferenceFolderMenuItemSmallUbuntu"];
				
			default:
				break;
		}
		
		return nil;
	}
	
	return nil;
}

#pragma mak -

+ (instancetype)menuForAction:(SEL)inAction target:(id)inTarget controlSize:(NSControlSize)inControlSize
{
	PKGFilePathTypeMenu * tMenu=[[PKGFilePathTypeMenu alloc] init];
	
	if (tMenu!=nil)
	{
		tMenu.font=[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:inControlSize]];
		
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Relative to Reference Folder",@"") action:inAction keyEquivalent:@""];
		
		tMenuItem.tag=PKGFilePathTypeRelativeToReferenceFolder;
		tMenuItem.image=[PKGFilePathTypeMenu _menuItemImageForPathType:PKGFilePathTypeRelativeToReferenceFolder controlSize:inControlSize];
		tMenuItem.target=inTarget;
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Relative to Project",@"") action:inAction keyEquivalent:@""];
		
		tMenuItem.tag=PKGFilePathTypeRelativeToProject;
		tMenuItem.image=[PKGFilePathTypeMenu _menuItemImageForPathType:PKGFilePathTypeRelativeToProject controlSize:inControlSize];
		tMenuItem.target=inTarget;
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Absolute Path",@"") action:inAction keyEquivalent:@""];
		
		tMenuItem.tag=PKGFilePathTypeAbsolute;
		tMenuItem.image=[PKGFilePathTypeMenu _menuItemImageForPathType:PKGFilePathTypeAbsolute controlSize:inControlSize];
		tMenuItem.target=inTarget;
		
		// Icon
		
		[tMenu addItem:tMenuItem];
	}
	
	return tMenu;
}

+ (NSSize)sizeOfPullDownImageForControlSize:(NSControlSize)inControlSize
{
	if (inControlSize==NSRegularControlSize)
	{
		return NSMakeSize(27.0,21.0);
	}
	
	return NSZeroSize;
}

+ (NSImage *)pullDownImageForPathType:(PKGFilePathType)inPathType controlSize:(NSControlSize)inControlSize
{
	if (inControlSize==NSRegularControlSize)
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
				break;
		}
		
		return nil;
	}
	
	return nil;
}

@end
