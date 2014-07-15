#import "NYPLBookDetailView.h"

@interface NYPLBookDetailViewPad : UIView

@property (nonatomic, readonly) NYPLBookDetailView *bookDetailView;

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *)book;

- (void)animateDisplayInView:(UIView *)view;

@end
