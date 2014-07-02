#import "NYPLBookDetailView.h"

#import "NYPLBookDetailViewiPad.h"

@interface NYPLBookDetailViewiPad ()

@property (nonatomic) NYPLBookDetailView *bookDetailView;
@property (nonatomic) UIButton *closeButton;

@end

static CGFloat const bookDetailViewiPadAnimationSeconds = 0.333;
static CGFloat const bookDetailViewWidth = 380;
static CGFloat const bookDetailViewHeight = 440;

@implementation NYPLBookDetailViewiPad

- (instancetype)initWithBook:(NYPLCatalogBook *const)book
                  coverImage:(UIImage *const)coverImage
{
  self = [super init];
  if(!self) return nil;
  
  self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  self.alpha = 0.0;
  
  self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
  
  self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.closeButton.frame = self.bounds;
  self.closeButton.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight);
  self.closeButton.exclusiveTouch = YES;
  [self addSubview:self.closeButton];
  
  self.bookDetailView = [[NYPLBookDetailView alloc] initWithBook:book coverImage:coverImage];
  self.bookDetailView.frame = CGRectMake(0, 0, bookDetailViewWidth, bookDetailViewHeight);
  self.bookDetailView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                          UIViewAutoresizingFlexibleRightMargin |
                                          UIViewAutoresizingFlexibleTopMargin |
                                          UIViewAutoresizingFlexibleBottomMargin);
  [self addSubview:self.bookDetailView];
  
  return self;
}

- (void)animateDisplay
{
  [self setFrame:self.superview.bounds];
  self.bookDetailView.center = self.center;
  
  [UIView animateWithDuration:bookDetailViewiPadAnimationSeconds animations:^{
    self.alpha = 1.0;
  }];
}

- (void)animateRemoveFromSuperview
{
  [UIView animateWithDuration:bookDetailViewiPadAnimationSeconds animations:^{
    self.alpha = 0.0;
  }];
  
  [NSTimer scheduledTimerWithTimeInterval:1.0
                                   target:self
                                 selector:@selector(removeFromSuperview)
                                 userInfo:nil
                                  repeats:NO];
}

@end
