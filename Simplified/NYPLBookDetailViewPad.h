#import "NYPLBookDetailView.h"

@class NYPLBookDetailViewPad;

@protocol NYPLBookDetailViewPadDelegate <NYPLBookDetailViewDelegate>

- (void)didSelectCloseForBookDetailViewPad:(NYPLBookDetailViewPad *)bookDetailViewPad;

@end

@interface NYPLBookDetailViewPad : UIView

@property (nonatomic, weak) id<NYPLBookDetailViewPadDelegate> delegate;

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *)book;

- (void)animateDisplayInView:(UIView *)view;

- (void)animateRemoveFromSuperview;

@end
