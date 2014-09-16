#import "NYPLAttributedString.h"
#import "NYPLBook.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookDetailDownloadFailedView.h"
#import "NYPLBookDetailDownloadingView.h"
#import "NYPLBookDetailNormalView.h"
#import "NYPLConfiguration.h"

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
@property (nonatomic) UILabel *summaryLabel;
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
  
  self.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.book = book;
  
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.authorsLabel.numberOfLines = 2;
  self.authorsLabel.font = [UIFont systemFontOfSize:12];
  self.authorsLabel.attributedText = NYPLAttributedStringForAuthorsFromString(book.authors);
  [self addSubview:self.authorsLabel];
  
  self.coverImageView = [[UIImageView alloc] init];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.coverImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  [self addSubview:self.coverImageView];
  
  [[NYPLBookCoverRegistry sharedRegistry]
   temporaryThumbnailImageForBook:book
   handler:^(UIImage *const image) {
     self.coverImageView.image = image;
   }];
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.titleLabel.numberOfLines = 4;
  self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
  self.titleLabel.attributedText = NYPLAttributedStringForTitleFromString(book.title);
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
  
  self.summaryLabel = [[UILabel alloc] init];
  self.summaryLabel.numberOfLines = 0;
  self.summaryLabel.text = book.summary;
  self.summaryLabel.font = [UIFont systemFontOfSize:12];
  [self addSubview:self.summaryLabel];
  
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
    // The extra five height pixels account for a bug in |sizeThatFits:| that does not properly take
    // into account |lineHeightMultiple|.
    self.titleLabel.frame = CGRectMake(x, y, w, h + 5);
  }
  
  {
    CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
    CGFloat const y = CGRectGetMaxY(self.titleLabel.frame);
    CGFloat const w = CGRectGetWidth(self.titleLabel.frame);
    CGFloat const h = [self.authorsLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
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
  
  {
    // 40 left padding, 35 right to visually compensate for ragged text.
    CGFloat const leftPadding = 40;
    CGFloat const rightPadding = 35;
    
    CGSize const size = [self.summaryLabel
                         sizeThatFits:CGSizeMake((CGRectGetWidth(self.frame) - leftPadding -
                                                  rightPadding),
                                                 CGFLOAT_MAX)];
    self.summaryLabel.frame = CGRectMake(leftPadding,
                                         CGRectGetMaxY(self.normalView.frame) + 10,
                                         size.width,
                                         size.height);
  }
  
  self.contentSize = CGSizeMake(CGRectGetWidth(self.frame),
                                CGRectGetMaxY(self.summaryLabel.frame) + 10);
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
    case NYPLMYBooksStateUsed:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = YES;
      self.normalView.state = NYPLBookDetailNormalViewStateUsed;
      self.unreadImageView.hidden = YES;
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
