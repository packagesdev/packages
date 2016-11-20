
#import <Cocoa/Cocoa.h>

@class PKGFileDeadDropTextField;

@protocol PKGFileDeadDropTextFieldDelegate

- (BOOL)fileDeadDropTextField:(PKGFileDeadDropTextField *)inView validateDropFiles:(NSArray *) inFilenames;

- (BOOL)fileDeadDropTextField:(PKGFileDeadDropTextField *)inView acceptDropFiles:(NSArray *) inFilenames;

@end

@interface PKGFileDeadDropTextField : NSTextField

	@property (weak) id<PKGFileDeadDropTextFieldDelegate> deadDropDelegate;

@end
