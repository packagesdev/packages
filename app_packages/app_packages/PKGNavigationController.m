
#import "PKGNavigationController.h"

@interface PKGNavigationController ()
{
	NSMutableArray * _viewControllers;
}

@end

@implementation PKGNavigationController

- (instancetype)initWithRootViewController:(NSViewController *)inRootViewController
{
	if (inRootViewController==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_viewControllers=[NSMutableArray arrayWithObject:inRootViewController];
	}
	
	return self;
}

- (void)loadView
{
	NSView * tView=[[NSView alloc] initWithFrame:NSZeroRect];
	
	tView.autoresizesSubviews=YES;
	
	self.view=tView;
}

#pragma mark -

- (void)WB_viewWillAdd
{
	if ([[self.view subviews] count]>0)
		return;
	
	NSViewController * tVisibleViewController=[_viewControllers lastObject];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]==YES)
		[self.delegate  navigationController:self willShowViewController:tVisibleViewController animated:NO];
	
	NSView * tView=tVisibleViewController.view;
	
	tView.frame=self.view.bounds;
	
	[tVisibleViewController WB_viewWillAdd];
	
	[self.view addSubview:tView];
	
	[tVisibleViewController WB_viewDidAdd];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]==YES)
		[self.delegate navigationController:self didShowViewController:tVisibleViewController animated:NO];
}

#pragma mark -

- (NSViewController *)topViewController
{
	if ([_viewControllers count]==0)
		return nil;
	
	return _viewControllers[0];
}

- (NSViewController *)visibleViewController
{
	return [_viewControllers lastObject];
}

#pragma mark -

- (void)pushViewController:(NSViewController *)inViewController animated:(BOOL)inAnimated
{
	if (inViewController==nil)
		return;
	
	NSViewController * tPreviouslyVisibleViewController=[_viewControllers lastObject];
	
	[_viewControllers addObject:inViewController];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]==YES)
		[self.delegate  navigationController:self willShowViewController:inViewController animated:inAnimated];
	
	NSView * tView=inViewController.view;
	
	tView.frame=[self.view bounds];
	
	[tPreviouslyVisibleViewController WB_viewWillRemove];
	
	[inViewController WB_viewWillAdd];
	
	// Here we can animate
	
	[tPreviouslyVisibleViewController.view removeFromSuperview];
	
	[self.view addSubview:tView];
	
	[tPreviouslyVisibleViewController WB_viewDidRemove];
	
	[inViewController WB_viewDidAdd];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]==YES)
		[self.delegate navigationController:self didShowViewController:inViewController animated:inAnimated];
}

- (NSViewController *)popViewControllerAnimated:(BOOL)inAnimated
{
	if ([_viewControllers count]<2)
		return nil;
	
	NSViewController * tPreviouslyVisibleViewController=[_viewControllers lastObject];
	
	[_viewControllers removeLastObject];
	
	NSViewController * tNewVisibleViewController=[_viewControllers lastObject];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]==YES)
		[self.delegate  navigationController:self willShowViewController:tNewVisibleViewController animated:inAnimated];
	
	NSView * tView=tNewVisibleViewController.view;
	
	tView.frame=[self.view bounds];
	
	[tPreviouslyVisibleViewController WB_viewWillRemove];
	
	[tNewVisibleViewController WB_viewWillAdd];
	
	// Here we can animate
	
	[tPreviouslyVisibleViewController.view removeFromSuperview];
	
	[self.view addSubview:tView];
	
	[tPreviouslyVisibleViewController WB_viewDidRemove];
	
	[tNewVisibleViewController WB_viewDidAdd];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]==YES)
		[self.delegate navigationController:self didShowViewController:tNewVisibleViewController animated:inAnimated];
	
	return tPreviouslyVisibleViewController;
}

- (void)popToRootViewControllerAnimated:(BOOL)inAnimated
{
	if ([_viewControllers count]>0)
		return;
	
	[self popToViewController:_viewControllers[0] animated:inAnimated];
}

- (NSArray *)popToViewController:(NSViewController *)inViewController animated:(BOOL)inAnimated
{
	NSUInteger tIndex=[_viewControllers indexOfObject:inViewController];
	
	if (tIndex==NSNotFound)
		return nil;
	
	NSUInteger tCount=[_viewControllers count];
	
	if (tIndex==(tCount-1))
		return nil;
	
	NSViewController * tVisibleViewController=[_viewControllers lastObject];
	
	NSArray * tArray=[_viewControllers objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tIndex+1,tCount-tIndex)]];
	
	[_viewControllers removeObjectsInRange:NSMakeRange(tIndex+1,tCount-tIndex)];
	
	NSViewController * tNewVisibleViewController=inViewController;
	
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]==YES)
		[self.delegate  navigationController:self willShowViewController:tNewVisibleViewController animated:inAnimated];
	
	NSView * tView=tNewVisibleViewController.view;
	
	tView.frame=[self.view bounds];
	
	[tVisibleViewController WB_viewWillRemove];
	
	[tNewVisibleViewController WB_viewWillAdd];
	
	// Here we can animate
	
	[tVisibleViewController.view removeFromSuperview];
	
	[self.view addSubview:tView];
	
	[tVisibleViewController WB_viewDidRemove];
	
	[tNewVisibleViewController WB_viewDidAdd];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]==YES)
		[self.delegate navigationController:self didShowViewController:tNewVisibleViewController animated:inAnimated];
	
	return tArray;
}

@end
