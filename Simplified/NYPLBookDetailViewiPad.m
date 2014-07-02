#import "NYPLBookDetailViewiPad.h"

@interface NYPLBookDetailViewiPad ()

@property (nonatomic) NYPLBookDetailView *bookDetailView;
@property (nonatomic) UIButton *closeButton;

@end

static CGFloat const bookDetailViewWidth = 380;
static CGFloat const bookDetailViewHeight = 440;

@implementation NYPLBookDetailViewiPad

- (instancetype)initWithBookDetailView:(NYPLBookDetailView *const)bookDetailView
                                 frame:(CGRect const)frame
{
  self = [super initWithFrame:frame];
  if(!self) return nil;
  
  self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
  
  self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.closeButton.frame = self.bounds;
  self.closeButton.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight);
  self.closeButton.exclusiveTouch = YES;
  [self addSubview:self.closeButton];
  
  self.bookDetailView = bookDetailView;
  self.bookDetailView.frame = CGRectMake(0, 0, bookDetailViewWidth, bookDetailViewHeight);
  self.bookDetailView.center = self.center;
  self.bookDetailView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                          UIViewAutoresizingFlexibleRightMargin |
                                          UIViewAutoresizingFlexibleTopMargin |
                                          UIViewAutoresizingFlexibleBottomMargin);
  [self addSubview:self.bookDetailView];
  
  return self;
}
   
@end
