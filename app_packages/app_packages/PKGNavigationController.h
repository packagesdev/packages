
#import <Cocoa/Cocoa.h>

@protocol PKGNavigationControllerDelegate;

@interface PKGNavigationController : NSViewController

	@property (nonatomic,copy) NSArray * viewControllers;

	@property (weak) id<PKGNavigationControllerDelegate> delegate;

	@property(nonatomic, readonly) NSViewController *topViewController;

	@property (nonatomic,readonly) NSViewController * visibleViewController;


- (instancetype)initWithRootViewController:(NSViewController *)inRootViewController;

- (void)pushViewController:(NSViewController *)viewController animated:(BOOL)inAnimated;

- (NSViewController *)popViewControllerAnimated:(BOOL)inAnimated;

- (void)popToRootViewControllerAnimated:(BOOL)inAnimated;

- (NSArray *)popToViewController:(NSViewController *)inViewController animated:(BOOL)inAnimated;

@end



@protocol PKGNavigationControllerDelegate <NSObject>

@optional

- (void)navigationController:(PKGNavigationController *)inNavigationController willShowViewController:(NSViewController *)inViewController animated:(BOOL)inAnimated;

- (void)navigationController:(PKGNavigationController *)inNavigationController didShowViewController:(NSViewController *)inViewController animated:(BOOL)inAnimated;

@end