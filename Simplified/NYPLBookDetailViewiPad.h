// While this class is technically a view, it's morally a view controller. As such, it handles tasks
// like setting the |detailViewDelegate| of its underlying NYPLBookDetailView.

#import "NYPLBookDetailView.h"

@interface NYPLBookDetailViewiPad : UIView

@property (nonatomic, readonly) NYPLBookDetailView *bookDetailView;

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLBook *)book;

- (void)animateDisplayInView:(UIView *)view;

@end
