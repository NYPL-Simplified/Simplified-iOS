#import "NYPLBookDetailView.h"

@interface NYPLBookDetailViewiPad : UIView

@property (nonatomic, readonly) NYPLBookDetailView *bookDetailView;
@property (nonatomic, readonly) UIButton *closeButton;

// designated initializer
// |bookDetailView| must not be nil.
- (instancetype)initWithBookDetailView:(NYPLBookDetailView *)bookDetailView
                                 frame:(CGRect)frame;

@end
