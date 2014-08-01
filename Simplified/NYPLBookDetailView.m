#import "NYPLBook.h"
#import "NYPLBookDetailDownloadFailedView.h"
#import "NYPLBookDetailDownloadingView.h"
#import "NYPLBookDetailNormalView.h"
#import "NYPLConfiguration.h"
#import "NYPLSession.h"

#import "NYPLBookDetailView.h"

@interface NYPLBookDetailView ()
  <NYPLBookDetailDownloadFailedViewDelegate, NYPLBookDetailDownloadingViewDelegate,
   NYPLBookDetailNormalViewDelegate>

@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) NYPLBook *book;
@property (nonatomic) UIImageView *coverImageView;
@property (nonatomic) NYPLBookDetailDownloadFailedView *downloadFailedView;
@property (nonatomic) NYPLBookDetailDownloadingView *downloadingView;
@property (nonatomic) NYPLBookDetailNormalView *normalView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIImageView *unreadImageView;

@end

static CGFloat const coverHeight = 120.0;
static CGFloat const coverWidth = 100.0;
static CGFloat const coverPaddingLeft = 40.0;
static CGFloat const coverPaddingTop = 10.0;
static CGFloat const mainTextPaddingTop = 10.0;
static CGFloat const mainTextPaddingLeft = 10.0;
static CGFloat const mainTextPaddingRight = 10.0;

@implementation NYPLBookDetailView

// designated initializer
- (instancetype)initWithBook:(NYPLBook *const)book
{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  self.backgroundColor = [UIColor whiteColor];
  
  self.book = book;
  
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.font = [UIFont systemFontOfSize:12];
  self.authorsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.authorsLabel.numberOfLines = 2;
  self.authorsLabel.text = book.authors;
  [self addSubview:self.authorsLabel];
  
  self.coverImageView = [[UIImageView alloc] init];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.coverImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  [self addSubview:self.coverImageView];
  
  self.coverImageView.image =
    [UIImage imageWithData:[[NYPLSession sharedSession] cachedDataForURL:book.imageURL]];
  
  if(!self.coverImageView.image) {
    [[NYPLSession sharedSession]
     withURL:book.imageURL
     completionHandler:^(NSData *const data) {
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         self.coverImageView.image = [UIImage imageWithData:data];
       }];
     }];
  }
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
  self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.titleLabel.numberOfLines = 3;
  self.titleLabel.text = book.title;
  [self addSubview:self.titleLabel];
  
  self.downloadFailedView = [[NYPLBookDetailDownloadFailedView alloc] initWithWidth:0];
  self.downloadFailedView.delegate = self;
  self.downloadFailedView.hidden = YES;
  [self addSubview:self.downloadFailedView];
  
  self.downloadingView = [[NYPLBookDetailDownloadingView alloc] initWithWidth:0];
  self.downloadingView.delegate = self;
  self.downloadingView.hidden = YES;
  [self addSubview:self.downloadingView];
  
  self.normalView = [[NYPLBookDetailNormalView alloc] initWithWidth:0];
  self.normalView.delegate = self;
  self.normalView.hidden = YES;
  [self addSubview:self.normalView];
  
  self.unreadImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unread"]];
  self.unreadImageView.image = [self.unreadImageView.image
                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self.unreadImageView setTintColor:[NYPLConfiguration accentColor]];
  [self addSubview:self.unreadImageView];
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  {
    CGRect const frame = CGRectMake(coverPaddingLeft, coverPaddingTop, coverWidth, coverHeight);
    self.coverImageView.frame = frame;
  }
  
  {
    CGFloat const x = CGRectGetMaxX(self.coverImageView.frame) + mainTextPaddingLeft;
    CGFloat const y = mainTextPaddingTop;
    CGFloat const w = CGRectGetWidth(self.bounds) - x - mainTextPaddingRight;
    CGFloat const h = [self.titleLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.titleLabel.frame = CGRectMake(x, y, w, h);
  }
  
  {
    CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
    CGFloat const y = CGRectGetMaxY(self.titleLabel.frame);
    CGFloat const w = CGRectGetWidth(self.titleLabel.frame);
    CGFloat const h = [self.titleLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.authorsLabel.frame = CGRectMake(x, y, w, h);
  }
  
  {
    self.normalView.frame = CGRectMake(0,
                                       CGRectGetMaxY(self.coverImageView.frame) + 10.0,
                                       CGRectGetWidth(self.frame),
                                       CGRectGetHeight(self.normalView.frame));
    
    self.downloadingView.frame = self.normalView.frame;
    
    self.downloadFailedView.frame = self.normalView.frame;
  }
  
  {
    CGRect unreadImageViewFrame = self.unreadImageView.frame;
    unreadImageViewFrame.origin.x = (CGRectGetMinX(self.coverImageView.frame) -
                                     CGRectGetWidth(unreadImageViewFrame) - 5);
    unreadImageViewFrame.origin.y = 10;
    self.unreadImageView.frame = unreadImageViewFrame;
  }
}

#pragma mark NYPLBookDetailDownloadFailedViewDelegate

- (void)didSelectCancelForBookDetailDownloadFailedView:
(__attribute__((unused)) NYPLBookDetailDownloadFailedView *)NYPLBookDetailDownloadFailedView
{
  [self.detailViewDelegate didSelectCancelDownloadFailedForBookDetailView:self];
}

- (void)didSelectTryAgainForBookDetailDownloadFailedView:
(__attribute__((unused)) NYPLBookDetailDownloadFailedView *)NYPLBookDetailDownloadFailedView
{
  [self.detailViewDelegate didSelectTryAgainForBookDetailView:self];
}

#pragma mark NYPLBookDetailDownloadingViewDelegate

- (void)didSelectCancelForBookDetailDownloadingView:
(__attribute__((unused)) NYPLBookDetailDownloadingView *)bookDetailDownloadingView
{
  [self.detailViewDelegate didSelectCancelDownloadingForBookDetailView:self];
}

#pragma mark NYPLBookDetailNormalViewDelegate

- (void)didSelectDeleteForBookDetailNormalView:
(__attribute__((unused)) NYPLBookDetailNormalView *)bookDetailNormalView
{
  [self.detailViewDelegate didSelectDeleteForBookDetailView:self];
}

- (void)didSelectDownloadForBookDetailNormalView:
(__attribute__((unused)) NYPLBookDetailNormalView *)bookDetailNormalView
{
  [self.detailViewDelegate didSelectDownloadForBookDetailView:self];
}

- (void)didSelectReadForBookDetailNormalView:
(__attribute__((unused)) NYPLBookDetailNormalView *)bookDetailNormalView
{
  [self.detailViewDelegate didSelectReadForBookDetailView:self];
}

#pragma mark -

- (void)setState:(NYPLMyBooksState)state
{
  _state = state;
  
  switch(state) {
    case NYPLMyBooksStateUnregistered:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = YES;
      self.normalView.state = NYPLBookDetailNormalViewStateUnregistered;
      self.unreadImageView.hidden = YES;
      break;
    case NYPLMyBooksStateDownloadNeeded:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = YES;
      self.normalView.state = NYPLBookDetailNormalViewStateDownloadNeeded;
      self.unreadImageView.hidden = YES;
      break;
    case NYPLMyBooksStateDownloading:
      self.normalView.hidden = YES;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = NO;
      self.unreadImageView.hidden = YES;
      break;
    case NYPLMyBooksStateDownloadFailed:
      self.normalView.hidden = YES;
      self.downloadFailedView.hidden = NO;
      self.downloadingView.hidden = YES;
      self.unreadImageView.hidden = YES;
      break;
    case NYPLMyBooksStateDownloadSuccessful:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = YES;
      self.normalView.state = NYPLBookDetailNormalViewStateDownloadSuccessful;
      self.unreadImageView.hidden = NO;
      break;
  }
}

- (double)downloadProgress
{
  return self.downloadingView.downloadProgress;
}

- (void)setDownloadProgress:(double)downloadProgress
{
  self.downloadingView.downloadProgress = downloadProgress;
}

@end
