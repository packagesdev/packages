
#import "PKGSectionView.h"

@class PKGLocationDropView;

@protocol PKGLocationDropViewDelegate

- (BOOL)locationDropView:(PKGLocationDropView *)inView validateDrop:(id <NSDraggingInfo>)inInfo;

- (BOOL)locationDropView:(PKGLocationDropView *)inView acceptDrop:(id <NSDraggingInfo>)inInfo;

@end

@interface PKGLocationDropView : PKGSectionView

	@property (weak) id<PKGLocationDropViewDelegate> delegate;

	@property (nonatomic,readonly,getter=isHighlighted) BOOL highlighted;

@end
