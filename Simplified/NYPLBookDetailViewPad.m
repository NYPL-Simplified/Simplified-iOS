#import "NYPLBookDetailView.h"
#import "NYPLBookDetailViewDelegate.h"

#import "NYPLBookDetailViewPad.h"

@interface NYPLBookDetailViewPad () <NYPLBookDetailViewDelegate>

@property (nonatomic) NYPLBookDetailView *bookDetailView;
@property (nonatomic) UIButton *closeButton;

@end

static CGFloat const bookDetailViewiPadAnimationSeconds = 0.333;
static CGFloat const bookDetailViewWidth = 380;
static CGFloat const bookDetailViewHeight = 440;

@implementation NYPLBookDetailViewPad

- (instancetype)initWithBook:(NYPLBook *const)book
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
  [self.closeButton addTarget:self
                       action:@selector(didSelectClose)
             forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.closeButton];
  
  self.bookDetailView = [[NYPLBookDetailView alloc] initWithBook:book];
  self.bookDetailView.frame = CGRectMake(0, 0, bookDetailViewWidth, bookDetailViewHeight);
  self.bookDetailView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                          UIViewAutoresizingFlexibleRightMargin |
                                          UIViewAutoresizingFlexibleTopMargin |
                                          UIViewAutoresizingFlexibleBottomMargin);
  self.bookDetailView.detailViewDelegate = self;
  [self addSubview:self.bookDetailView];
  
  return self;
}

- (void)animateDisplayInView:(UIView *)view
{
  [view addSubview:self];
  
  [self setFrame:self.superview.bounds];
  self.bookDetailView.center = self.center;
  self.bookDetailView.detailViewDelegate = self;
  
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

- (void)didSelectClose
{
  [self.delegate didSelectCloseForBookDetailViewPad:self];
}

#pragma mark NYPLBookDetailViewDelegate

- (void)didSelectDownloadForDetailView:(NYPLBookDetailView *const)detailView
{
  [self.delegate didSelectDownloadForDetailView:detailView];
}

@end
