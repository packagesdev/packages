
#import <Cocoa/Cocoa.h>

@interface PKGLocationTextField : NSTextField

@end

@protocol PKGLocationTextFieldDelegate <NSTextFieldDelegate>

- (BOOL)locationTextField:(PKGLocationTextField *)inLocationTextField validateDrop:(id <NSDraggingInfo>)inInfo;

- (BOOL)locationTextField:(PKGLocationTextField *)inLocationTextField acceptDrop:(id <NSDraggingInfo>)inInfo;

@end