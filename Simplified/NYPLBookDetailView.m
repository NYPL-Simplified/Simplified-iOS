#import "NYPLAttributedString.h"
#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
#import "NYPLBookCellDelegate.h"
#import "NYPLBookDetailDownloadFailedView.h"
#import "NYPLBookDetailDownloadingView.h"
#import "NYPLBookDetailNormalView.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLBookDetailView.h"
#import "NYPLConfiguration.h"

@interface NYPLBookDetailView ()
  <NYPLBookDetailDownloadFailedViewDelegate, NYPLBookDetailDownloadingViewDelegate, UIWebViewDelegate>

@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) BOOL beganInitialRequest;
@property (nonatomic) UIImageView *coverImageView;
@property (nonatomic) NYPLBookDetailDownloadFailedView *downloadFailedView;
@property (nonatomic) NYPLBookDetailDownloadingView *downloadingView;
@property (nonatomic) NYPLBookDetailNormalView *normalView;
@property (nonatomic) UILabel *categoriesLabel;
@property (nonatomic) UILabel *distributorLabel;
@property (nonatomic) UILabel *publishedLabel;
@property (nonatomic) UILabel *publisherLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UIWebView *summaryWebView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIImageView *unreadImageView;
@property (nonatomic) UIButton *closeButton;

@end

static CGFloat const coverHeight = 120.0;
static CGFloat const coverWidth = 100.0;
static CGFloat const coverPaddingLeft = 40.0;
static CGFloat const coverPaddingTop = 10.0;
static CGFloat const mainTextPaddingTop = 10.0;
static CGFloat const mainTextPaddingLeft = 10.0;
static CGFloat const mainTextPaddingRight = 10.0;

static NSString *detailTemplate = nil;

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
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:NSLocalizedString(@"Close", nil) forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.closeButton];
  }

  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.authorsLabel.numberOfLines = 1;
  } else {
    self.authorsLabel.numberOfLines = 2;
  }
  self.authorsLabel.font = [UIFont systemFontOfSize:12];
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.authorsLabel.text = book.authors;
  } else {
    self.authorsLabel.attributedText = NYPLAttributedStringForAuthorsFromString(book.authors);
  }
  [self addSubview:self.authorsLabel];
  
  self.coverImageView = [[UIImageView alloc] init];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.coverImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  [self addSubview:self.coverImageView];
  
  [[NYPLBookRegistry sharedRegistry]
   thumbnailImageForBook:book
   handler:^(UIImage *const image) {
     self.coverImageView.image = image;
   }];
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.titleLabel.numberOfLines = 1;
  } else {
    self.titleLabel.numberOfLines = 2;
  }
  self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
  self.titleLabel.attributedText = NYPLAttributedStringForTitleFromString(book.title);
  [self addSubview:self.titleLabel];
  
  self.subtitleLabel = [[UILabel alloc] init];
  self.subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.subtitleLabel.numberOfLines = 1;
  } else {
    self.subtitleLabel.numberOfLines = 2;
  }
  self.subtitleLabel.text = book.subtitle;
  self.subtitleLabel.font = [UIFont systemFontOfSize:12];
  [self addSubview:self.subtitleLabel];
  
  self.downloadFailedView = [[NYPLBookDetailDownloadFailedView alloc] initWithWidth:0];
  self.downloadFailedView.delegate = self;
  self.downloadFailedView.hidden = YES;
  [self addSubview:self.downloadFailedView];
  
  self.downloadingView = [[NYPLBookDetailDownloadingView alloc] initWithWidth:0];
  self.downloadingView.delegate = self;
  self.downloadingView.hidden = YES;
  [self addSubview:self.downloadingView];
  
  self.normalView = [[NYPLBookDetailNormalView alloc] initWithWidth:0];
  self.normalView.delegate = [NYPLBookCellDelegate sharedDelegate];
  self.normalView.book = self.book;
  self.normalView.hidden = YES;
  [self addSubview:self.normalView];
  
  self.unreadImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unread"]];
  self.unreadImageView.image = [self.unreadImageView.image
                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self.unreadImageView setTintColor:[NYPLConfiguration accentColor]];
  [self addSubview:self.unreadImageView];
  
  self.distributorLabel = [[UILabel alloc] init];
  self.distributorLabel.font = [UIFont systemFontOfSize:12];
  self.distributorLabel.textColor = [UIColor grayColor];
  self.distributorLabel.numberOfLines = 1;
  [self addSubview:self.distributorLabel];
  
  self.summaryWebView = [[UIWebView alloc] init];
  self.summaryWebView.scrollView.alwaysBounceVertical = NO;
  self.summaryWebView.backgroundColor = [UIColor clearColor];
  self.summaryWebView.suppressesIncrementalRendering = YES;
  self.summaryWebView.delegate = self;
  self.summaryWebView.opaque = NO;
  self.summaryWebView.userInteractionEnabled = NO;
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  [self.summaryWebView
   loadHTMLString:[NSString stringWithFormat:detailTemplate,
                   [NYPLConfiguration systemFontName],
                   book.summary ? book.summary : @""]
   baseURL:nil];
#pragma clang diagnostic pop
  
  [self addSubview:self.summaryWebView];
  
  NSDateFormatter *const dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.timeStyle = NSDateFormatterNoStyle;
  dateFormatter.dateStyle = NSDateFormatterLongStyle;
  
  NSString *const publishedString =
    self.book.published
    ? [NSString stringWithFormat:@"%@: %@",
       NSLocalizedString(@"Published", nil),
       [dateFormatter stringFromDate:self.book.published]]
    : nil;
  
  NSString *const publisherString =
    self.book.publisher
    ? [NSString stringWithFormat:@"%@: %@",
       NSLocalizedString(@"Publisher", nil),
       self.book.publisher]
    : nil;
  
  NSString *const categoriesString =
    self.book.categoryStrings.count
    ? [NSString stringWithFormat:@"%@: %@",
       (self.book.categoryStrings.count == 1
        ? NSLocalizedString(@"Category", nil)
        : NSLocalizedString(@"Categories", nil)),
       self.book.categories]
    : nil;
  
  
  self.distributorLabel.text = book.distributor ? [NSString stringWithFormat:NSLocalizedString(@"BookDetailViewControllerDistributedByFormat", nil), book.distributor] : nil;
  
  // Metadata is shown via separate lines to the right of the cover. As such, we to
  // use a series of labels in order to get the desired truncation.
  self.categoriesLabel = [[UILabel alloc] init];
  self.categoriesLabel.font = [UIFont systemFontOfSize:12];
  self.categoriesLabel.textColor = [UIColor lightGrayColor];
  self.categoriesLabel.text = categoriesString;
  [self addSubview:self.categoriesLabel];
  self.publishedLabel = [[UILabel alloc] init];
  self.publishedLabel.font = [UIFont systemFontOfSize:12];
  self.publishedLabel.textColor = [UIColor lightGrayColor];
  self.publishedLabel.text = publishedString;
  [self addSubview:self.publishedLabel];
  self.publisherLabel = [[UILabel alloc] init];
  self.publisherLabel.font = [UIFont systemFontOfSize:12];
  self.publisherLabel.textColor = [UIColor lightGrayColor];
  self.publisherLabel.text = publisherString;
  [self addSubview:self.publisherLabel];
  
  return self;
}

#pragma mark NSObject

+ (void)initialize
{
  detailTemplate = [NSString
                    stringWithContentsOfURL:[[NSBundle mainBundle]
                                             URLForResource:@"DetailSummaryTemplate"
                                             withExtension:@"html"]
                    encoding:NSUTF8StringEncoding
                    error:NULL];
  
  assert(detailTemplate);
}

#pragma mark UIView

- (void)layoutSubviews
{
  {
    CGRect const frame = CGRectMake(coverPaddingLeft, coverPaddingTop, coverWidth, coverHeight);
    self.coverImageView.frame = frame;
  }
  
  {
    float closeButtonRigthPadding = 7.0f;
    [self.closeButton sizeToFit];
    CGFloat const x = CGRectGetMaxX(self.coverImageView.frame) + mainTextPaddingLeft;
    CGFloat const y = mainTextPaddingTop;
    CGFloat const w = CGRectGetWidth(self.bounds) - x - mainTextPaddingRight - self.closeButton.frame.size.width - closeButtonRigthPadding;
    CGFloat const h = [self.titleLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    // The extra five height pixels account for a bug in |sizeThatFits:| that does not properly take
    // into account |lineHeightMultiple|.
    self.titleLabel.frame = CGRectMake(x, y, w, h + 5);
    self.closeButton.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame), self.titleLabel.frame.origin.y - 1, self.closeButton.frame.size.width, self.titleLabel.frame.size.height);
  }
  
  {
    CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
    CGFloat const y = CGRectGetMaxY(self.titleLabel.frame);
    CGFloat const w = CGRectGetWidth(self.titleLabel.frame);
    CGFloat const h = [self.subtitleLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.subtitleLabel.frame = CGRectMake(x, y, w, h);
  }
  
  {
    CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
    CGFloat const y = CGRectGetMaxY(self.subtitleLabel.frame);
    CGFloat const w = CGRectGetWidth(self.titleLabel.frame);
    CGFloat const h = [self.authorsLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.authorsLabel.frame = CGRectMake(x, y, w, h);
  }
  
  {
    CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
    CGFloat const w = CGRectGetWidth(self.subtitleLabel.frame);
    CGFloat const h = [self.categoriesLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    CGFloat const y = CGRectGetMaxY(self.coverImageView.frame) - h;
    self.categoriesLabel.frame = CGRectMake(x, y, w, h);
  }
  {
    CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
    CGFloat const w = CGRectGetWidth(self.subtitleLabel.frame);
    CGFloat const h = [self.publisherLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    CGFloat const y = CGRectGetMinY(self.categoriesLabel.frame) - h;
    self.publisherLabel.frame = CGRectMake(x, y, w, h);
  }
  {
    CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
    CGFloat const w = CGRectGetWidth(self.subtitleLabel.frame);
    CGFloat const h = [self.publishedLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    CGFloat const y = CGRectGetMinY(self.publisherLabel.frame) - h;
    self.publishedLabel.frame = CGRectMake(x, y, w, h);
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
    [self.distributorLabel sizeToFit];
    CGFloat const x = CGRectGetWidth(self.frame) / 2 - CGRectGetWidth(self.distributorLabel.frame) / 2;
    CGFloat const w = CGRectGetWidth(self.distributorLabel.frame);
    CGFloat const h = CGRectGetHeight(self.distributorLabel.frame);
    CGFloat const y = CGRectGetMaxY(self.normalView.frame) + 10.0;
    self.distributorLabel.frame = CGRectMake(x, y, w, h);
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
    
    self.summaryWebView.frame = CGRectMake(0,
                                           0,
                                           CGRectGetWidth(self.frame) - leftPadding - rightPadding,
                                           5);
    
    CGSize const size = [self.summaryWebView
                         sizeThatFits:CGSizeMake(CGRectGetWidth(self.summaryWebView.frame),
                                                 CGFLOAT_MAX)];
    
    self.summaryWebView.frame = CGRectMake(leftPadding,
                                           CGRectGetMaxY(self.distributorLabel.frame) + 10,
                                           size.width,
                                           size.height);
  }
  
  self.contentSize = CGSizeMake(CGRectGetWidth(self.frame),
                                CGRectGetMaxY(self.summaryWebView.frame) + 10);
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

#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(__attribute__((unused)) UIWebView *)webView
{
  [self setNeedsLayout];
}

- (BOOL)webView:(__attribute__((unused)) UIWebView *)webView
shouldStartLoadWithRequest:(__attribute__((unused)) NSURLRequest *)request
navigationType:(__attribute__((unused)) UIWebViewNavigationType)navigationType
{
  // Deny any secondary requests generated by rendering the HTML (e.g. from 'img' tags).
  if(self.beganInitialRequest) return NO;
  
  self.beganInitialRequest = YES;
  
  return YES;
}

#pragma mark -

- (void)setState:(NYPLBookState)state
{
  _state = state;
  
  switch(state) {
    case NYPLBookStateUnregistered:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = YES;
      if(self.book.acquisition.openAccess) {
        self.normalView.state = NYPLBookButtonsStateCanKeep;
      } else {
        if (self.book.availableCopies > 0) {
          self.normalView.state = NYPLBookButtonsStateCanBorrow;
        } else {
          self.normalView.state = NYPLBookButtonsStateCanHold;
        }
      }
      self.unreadImageView.hidden = YES;
      break;
    case NYPLBookStateDownloadNeeded:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = YES;
      self.normalView.state = NYPLBookButtonsStateDownloadNeeded;
      self.unreadImageView.hidden = YES;
      break;
    case NYPLBookStateDownloading:
      self.normalView.hidden = YES;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = NO;
      self.unreadImageView.hidden = YES;
      break;
    case NYPLBookStateDownloadFailed:
      self.normalView.hidden = YES;
      self.downloadFailedView.hidden = NO;
      self.downloadingView.hidden = YES;
      self.unreadImageView.hidden = YES;
      break;
    case NYPLBookStateDownloadSuccessful:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = YES;
      self.normalView.state = NYPLBookButtonsStateDownloadSuccessful;
      self.unreadImageView.hidden = NO;
      break;
    case NYPLBookStateHolding:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = YES;
      if (self.book.availabilityStatus == NYPLBookAvailabilityStatusReady) {
        self.normalView.state = NYPLBookButtonsStateHoldingFOQ;
      } else {
        self.normalView.state = NYPLBookButtonsStateHolding;
      }
      self.unreadImageView.hidden = YES;
      break;
    case NYPLBookStateUsed:
      self.normalView.hidden = NO;
      self.downloadFailedView.hidden = YES;
      self.downloadingView.hidden = YES;
      self.normalView.state = NYPLBookButtonsStateUsed;
      self.unreadImageView.hidden = YES;
      break;
  }
}

- (void)setBook:(NYPLBook *)book
{
  _book = book;
  self.normalView.book = book;
}

- (double)downloadProgress
{
  return self.downloadingView.downloadProgress;
}

- (void)setDownloadProgress:(double)downloadProgress
{
  self.downloadingView.downloadProgress = downloadProgress;
}

- (BOOL)downloadStarted
{
  return self.downloadingView.downloadStarted;
}

- (void)setDownloadStarted:(BOOL)downloadStarted
{
  self.downloadingView.downloadStarted = downloadStarted;
}

- (void)closeButtonPressed
{
  [self.detailViewDelegate didSelectCloseButton:self];
}

-(BOOL)accessibilityPerformEscape {
  [self.detailViewDelegate didSelectCloseButton:self];
  return YES;
}


@end
