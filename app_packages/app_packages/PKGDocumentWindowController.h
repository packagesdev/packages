
#import <Cocoa/Cocoa.h>

#import "PKGProject.h"

@interface PKGDocumentWindowController : NSWindowController

	@property IBOutlet NSView * leftAccessoryView;
	@property IBOutlet NSView * middleAccessoryView;
	@property IBOutlet NSView * rightAccessoryView;

	@property (readonly) PKGProject * project;

- (instancetype)initWithProject:(PKGProject *)inProject;

@end
