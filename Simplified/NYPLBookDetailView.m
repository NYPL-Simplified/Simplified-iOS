#import "NYPLAttributedString.h"
#import "NYPLBook.h"
#import "NYPLMyBooksCoverRegistry.h"
#import "NYPLBookDetailDownloadFailedView.h"
#import "NYPLBookDetailDownloadingView.h"
#import "NYPLBookDetailNormalView.h"
#import "NYPLConfiguration.h"

#import "NYPLBookDetailView.h"

@interface NYPLBookDetailView ()
  <NYPLBookDetailDownloadFailedViewDelegate, NYPLBookDetailDownloadingViewDelegate,
   NYPLBookDetailNormalViewDelegate, UIWebViewDelegate>

@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) BOOL beganInitialRequest;
@property (nonatomic) NYPLBook *book;
@property (nonatomic) UIImageView *coverImageView;
@property (nonatomic) NYPLBookDetailDownloadFailedView *downloadFailedView;
@property (nonatomic) NYPLBookDetailDownloadingView *downloadingView;
@property (nonatomic) NYPLBookDetailNormalView *normalView;
@property (nonatomic) UILabel *padCategoriesLabel;
@property (nonatomic) UILabel *padPublishedLabel;
@property (nonatomic) UILabel *padPublisherLabel;
@property (nonatomic) UILabel *phoneMetadataLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UIWebView *summaryWebView;
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
  
  [[NYPLMyBooksCoverRegistry sharedRegistry]
   thumbnailImageForBook:book
   handler:^(UIImage *const image) {
     self.coverImageView.image = image;
   }];
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.titleLabel.numberOfLines = 1;
  } else {
    self.titleLabel.numberOfLines = 3;
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
  self.normalView.delegate = self;
  self.normalView.hidden = YES;
  [self addSubview:self.normalView];
  
  self.unreadImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unread"]];
  self.unreadImageView.image = [self.unreadImageView.image
                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self.unreadImageView setTintColor:[NYPLConfiguration accentColor]];
  [self addSubview:self.unreadImageView];
  
  self.summaryWebView = [[UIWebView alloc] init];
  self.summaryWebView.scrollView.alwaysBounceVertical = NO;
  self.summaryWebView.backgroundColor = [UIColor clearColor];
  self.summaryWebView.suppressesIncrementalRendering = YES;
  self.summaryWebView.delegate = self;
  self.summaryWebView.opaque = NO;
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  [self.summaryWebView
   loadHTMLString:[NSString stringWithFormat:detailTemplate,
                   [NYPLConfiguration systemFontName],
                   book.summary]
   baseURL:nil];
#pragma clang diagnostic pop
  
  [self addSubview:self.summaryWebView];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    // Metadata on the iPad is shown via separate lines to the right of the cover. As such, we to
    // use a series of labels in order to get the desired truncation.
    self.padCategoriesLabel = [[UILabel alloc] init];
    self.padCategoriesLabel.font = [UIFont systemFontOfSize:12];
    self.padCategoriesLabel.textColor = [UIColor lightGrayColor];
    self.padCategoriesLabel.text = @"Categories: FIXME, TODO";
    [self addSubview:self.padCategoriesLabel];
    self.padPublishedLabel = [[UILabel alloc] init];
    self.padPublishedLabel.font = [UIFont systemFontOfSize:12];
    self.padPublishedLabel.textColor = [UIColor lightGrayColor];
    self.padPublishedLabel.text = @"Published: January 1st, 1970";
    [self addSubview:self.padPublishedLabel];
    self.padPublisherLabel = [[UILabel alloc] init];
    self.padPublisherLabel.font = [UIFont systemFontOfSize:12];
    self.padPublisherLabel.textColor = [UIColor lightGrayColor];
    self.padPublisherLabel.text = @"Publisher: Imaginary Metadata";
    [self addSubview:self.padPublisherLabel];
  } else {
    // Metadata on the iPhone is shown as a single block of wrapped text.
    self.phoneMetadataLabel = [[UILabel alloc] init];
    self.phoneMetadataLabel.numberOfLines = 0;
    self.phoneMetadataLabel.textAlignment = NSTextAlignmentCenter;
    self.phoneMetadataLabel.font = [UIFont systemFontOfSize:10];
    self.phoneMetadataLabel.textColor = [UIColor lightGrayColor];
    self.phoneMetadataLabel.text =
      @"Published: January 1st, 1970 "
      @"Publisher: Imaginary Metadata "
      @"Categories: FIXME, TODO";
    [self addSubview:self.phoneMetadataLabel];
  }
  
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
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    {
      CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
      CGFloat const w = CGRectGetWidth(self.subtitleLabel.frame);
      CGFloat const h = [self.padCategoriesLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
      CGFloat const y = CGRectGetMaxY(self.coverImageView.frame) - h;
      self.padCategoriesLabel.frame = CGRectMake(x, y, w, h);
    }
    {
      CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
      CGFloat const w = CGRectGetWidth(self.subtitleLabel.frame);
      CGFloat const h = [self.padPublisherLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
      CGFloat const y = CGRectGetMinY(self.padCategoriesLabel.frame) - h;
      self.padPublisherLabel.frame = CGRectMake(x, y, w, h);
    }
    {
      CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
      CGFloat const w = CGRectGetWidth(self.subtitleLabel.frame);
      CGFloat const h = [self.padPublishedLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
      CGFloat const y = CGRectGetMinY(self.padPublisherLabel.frame) - h;
      self.padPublishedLabel.frame = CGRectMake(x, y, w, h);
    }
  } else {
    CGFloat const x = 10;
    CGFloat const y = CGRectGetMaxY(self.coverImageView.frame) + 10;
    CGFloat const w = CGRectGetWidth(self.frame) - 20;
    CGFloat const h = [self.phoneMetadataLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.phoneMetadataLabel.frame = CGRectMake(x, y, w, h);
  }
  
  {
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
      self.normalView.frame = CGRectMake(0,
                                         CGRectGetMaxY(self.coverImageView.frame) + 10.0,
                                         CGRectGetWidth(self.frame),
                                         CGRectGetHeight(self.normalView.frame));
    } else {
      self.normalView.frame = CGRectMake(0,
                                         CGRectGetMaxY(self.phoneMetadataLabel.frame) + 10.0,
                                         CGRectGetWidth(self.frame),
                                         CGRectGetHeight(self.normalView.frame));
    }
    
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
    
    self.summaryWebView.frame = CGRectMake(0,
                                           0,
                                           CGRectGetWidth(self.frame) - leftPadding - rightPadding,
                                           5);
    
    CGSize const size = [self.summaryWebView
                         sizeThatFits:CGSizeMake(CGRectGetWidth(self.summaryWebView.frame),
                                                 CGFLOAT_MAX)];
    
    self.summaryWebView.frame = CGRectMake(leftPadding,
                                           CGRectGetMaxY(self.normalView.frame) + 10,
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
