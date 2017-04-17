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
#import "SimplyE-Swift.h"
#import "UIFont+NYPLSystemFontOverride.h"

#import <PureLayout/PureLayout.h>

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

@property (nonatomic) UIView *contentView;
@property (nonatomic) UITextView *summaryTextView;

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
  
  self.book = book;
  self.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.contentView = [[UIView alloc] init];
  
  self.coverImageView = [[UIImageView alloc] init];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
  
  [[NYPLBookRegistry sharedRegistry]
   thumbnailImageForBook:book
   handler:^(UIImage *const image) {
     self.coverImageView.image = image;
   }];
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.numberOfLines = 2;
  self.titleLabel.attributedText = NYPLAttributedStringForTitleFromString(book.title);

  self.subtitleLabel = [[UILabel alloc] init];
  self.subtitleLabel.text = book.subtitle;
  self.subtitleLabel.numberOfLines = 2;
  
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.authorsLabel.text = book.authors;
  } else {
    self.authorsLabel.attributedText = NYPLAttributedStringForAuthorsFromString(book.authors);
  }
  
  self.unreadImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unread"]];
  self.unreadImageView.image = [self.unreadImageView.image
                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self.unreadImageView setTintColor:[NYPLConfiguration accentColor]];
  
  self.distributorLabel = [[UILabel alloc] init];
  self.distributorLabel.font = [UIFont systemFontOfSize:12];
  self.distributorLabel.textColor = [UIColor grayColor];
  self.distributorLabel.numberOfLines = 1;
  
  self.summaryTextView = [[UITextView alloc] init];
  self.summaryTextView.backgroundColor = [UIColor clearColor];
  self.summaryTextView.scrollEnabled = NO;
  self.summaryTextView.editable = NO;
  
  NSString *htmlString = [NSString stringWithFormat:detailTemplate,
                          [NYPLConfiguration systemFontName],
                          book.summary ? book.summary : @""];
  NSData *htmlData = [htmlString dataUsingEncoding:NSUnicodeStringEncoding];
  NSDictionary *attributes = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
  NSAttributedString *atrString = [[NSAttributedString alloc] initWithData:htmlData options:attributes documentAttributes:nil error:nil];
  self.summaryTextView.attributedText = atrString;
  

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
  
  self.categoriesLabel = [[UILabel alloc] init];
  self.categoriesLabel.font = [UIFont systemFontOfSize:12];
  self.categoriesLabel.textColor = [UIColor lightGrayColor];
  self.categoriesLabel.text = categoriesString;

  self.publisherLabel = [[UILabel alloc] init];
  self.publisherLabel.font = [UIFont systemFontOfSize:12];
  self.publisherLabel.textColor = [UIColor lightGrayColor];
  self.publisherLabel.text = publisherString;
  
  self.publishedLabel = [[UILabel alloc] init];
  self.publishedLabel.font = [UIFont systemFontOfSize:12];
  self.publishedLabel.textColor = [UIColor lightGrayColor];
  self.publishedLabel.text = publishedString;
  
  
  [self addSubview:self.contentView];
  [self.contentView addSubview:self.coverImageView];
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.subtitleLabel];
  [self.contentView addSubview:self.authorsLabel];
  [self.contentView addSubview:self.unreadImageView];
  [self.contentView addSubview:self.distributorLabel];
  [self.contentView addSubview:self.summaryTextView];
//  [self.contentView addSubview:self.publishedLabel];
//  [self.contentView addSubview:self.publisherLabel];
  [self.contentView addSubview:self.categoriesLabel];
  
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:NSLocalizedString(@"Close", nil) forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchDown];
    [self.contentView addSubview:self.closeButton];
    [self.closeButton autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
    [self.closeButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:1];
  }
  
  [self setupDownloadViews];
  [self setupAutolayoutConstraints];
  [self updateFonts];
  
  return self;
}

- (void)updateFonts
{
  self.titleLabel.font = [UIFont systemFontForTextStyle:UIFontTextStyleTitle2];
  self.subtitleLabel.font = [UIFont systemFontForTextStyle:UIFontTextStyleCaption1];
  self.authorsLabel.font = [UIFont systemFontForTextStyle:UIFontTextStyleCaption1];
  self.summaryTextView.font = [UIFont systemFontForTextStyle:UIFontTextStyleCaption2];
}

- (void)setupDownloadViews
{
  self.normalView = [[NYPLBookDetailNormalView alloc] initWithWidth:0];
  self.normalView.delegate = [NYPLBookCellDelegate sharedDelegate];
  self.normalView.book = self.book;
  self.normalView.hidden = YES;
  [self.contentView addSubview:self.normalView];
  [self.normalView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.normalView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  
  //GODO TEMP
  [self.normalView autoSetDimension:ALDimensionHeight toSize:70];
  
  self.downloadFailedView = [[NYPLBookDetailDownloadFailedView alloc] initWithWidth:0];
  self.downloadFailedView.delegate = self;
  self.downloadFailedView.hidden = YES;
  [self.contentView addSubview:self.downloadFailedView];
  [self.downloadFailedView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.downloadFailedView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.downloadFailedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.coverImageView withOffset:coverPaddingTop];
  //GODO TEMP
  [self.downloadFailedView autoSetDimension:ALDimensionHeight toSize:70];
  
  self.downloadingView = [[NYPLBookDetailDownloadingView alloc] initWithWidth:0];
  self.downloadingView.delegate = self;
  self.downloadingView.hidden = YES;
  [self.contentView addSubview:self.downloadingView];
  [self.downloadingView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.downloadingView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.downloadingView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.coverImageView withOffset:coverPaddingTop];
  //GODO TEMP
  [self.downloadingView autoSetDimension:ALDimensionHeight toSize:70];
}

- (void)setupAutolayoutConstraints
{
  [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
  [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
  [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
  
  [self.coverImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:coverPaddingLeft];
  [self.coverImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:coverPaddingTop];
  [self.coverImageView autoSetDimension:ALDimensionWidth toSize:coverWidth];
  [self.coverImageView autoSetDimension:ALDimensionHeight toSize:coverHeight];
  
  [self.titleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:mainTextPaddingLeft];
  [self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.titleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.coverImageView];
  
  [self.subtitleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:mainTextPaddingLeft];
  [self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel];
  
  [self.authorsLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:mainTextPaddingLeft];
  [self.authorsLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.authorsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.subtitleLabel];
  
  [self.unreadImageView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.coverImageView withOffset:5];
  [self.unreadImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
  
  [self.distributorLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
  [self.distributorLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.normalView withOffset:coverPaddingTop];
  
  [self.categoriesLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:mainTextPaddingLeft];
  [self.categoriesLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.categoriesLabel autoAlignAxis:ALAxisBaseline toSameAxisOfView:self.coverImageView];
  
  //  [self.categoriesLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.publisherLabel];
  ////  [self.categoriesLabel autoPinEdge:NSLayoutAttributeBaseline toEdge:ALEdgeBottom ofView:self.coverImageView];
  ////
  [self.normalView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.categoriesLabel withOffset:coverPaddingTop];
  //
  //  [self.publishedLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:mainTextPaddingLeft];
  //  [self.publishedLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  //  [self.publishedLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.publisherLabel];
  //  //GODO Temp
  //  [self.publishedLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.authorsLabel withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
  //
  //  [self.publisherLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:mainTextPaddingLeft];
  //  [self.publisherLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  //  [self.publisherLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.categoriesLabel];
  //  [self.publisherLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.publishedLabel];
  
  [self.summaryTextView autoPinEdgeToSuperviewMargin:ALEdgeRight];
  [self.summaryTextView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.summaryTextView autoPinEdgeToSuperviewMargin:ALEdgeBottom];
  [self.summaryTextView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.distributorLabel withOffset:12];
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
      if(self.book.acquisition.openAccess || ![[AccountsManager sharedInstance] currentAccount].needsAuth) {
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

- (void)runProblemReportedAnimation
{
  [self.normalView runProblemReportedAnimation];
}


@end
