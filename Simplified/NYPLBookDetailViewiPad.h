#import "NYPLBookDetailView.h"

@interface NYPLBookDetailViewiPad : UIView

@property (nonatomic, readonly) NYPLBookDetailView *bookDetailView;
@property (nonatomic, readonly) UIButton *closeButton;

// designated initializer
// |book| must not be nil.
- (instancetype)initWithBook:(NYPLCatalogBook *)book
                  coverImage:(UIImage *)coverImage;

- (void)animateDisplay;

- (void)animateRemoveFromSuperview;

@end
