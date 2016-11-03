
#import <Cocoa/Cocoa.h>

#import "PKGFilePath.h"

@interface PKGFilePathTypeMenu : NSMenu

+ (instancetype)menuForAction:(SEL)inAction target:(id)inTarget controlSize:(NSControlSize)inControlSize;

+ (NSSize)sizeOfPullDownImageForControlSize:(NSControlSize)inControlSize;

+ (NSImage *)pullDownImageForPathType:(PKGFilePathType)inPathType controlSize:(NSControlSize)inControlSize;

@end
