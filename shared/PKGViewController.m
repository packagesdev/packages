
#import "PKGViewController.h"

@interface PKGViewController ()

@end

@implementation PKGViewController

#if (MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10)

- (instancetype)initWithNibName:(NSString *)inNibName bundle:(NSBundle *)inBundle
{
	self=[super initWithNibName:inNibName bundle:inBundle];
	
	if (self!=nil)
	{
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10)
		if (NSAppKitVersionNumber<NSAppKitVersionNumber10_10)
#endif
		[self.view setNextResponder:self];
	}
	
	return self;
}

#endif

- (void) dealloc
{
	// Remove observer
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)nibName
{
	return NSStringFromClass([self class]);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark -

- (BOOL)PKG_viewCanBeRemoved
{
	return YES;
}

@end
