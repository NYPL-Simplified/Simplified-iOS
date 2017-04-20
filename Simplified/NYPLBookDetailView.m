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
  <NYPLBookDetailDownloadFailedViewDelegate, NYPLBookDetailDownloadingViewDelegate>

@property (nonatomic) BOOL beganInitialRequest;
@property (nonatomic) UIView *contentView;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *subtitleLabel;
@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) UIImageView *coverImageView;
@property (nonatomic) UIImageView *unreadImageView;
@property (nonatomic) UIButton *closeButton;

@property (nonatomic) NYPLBookDetailDownloadFailedView *downloadFailedView;
@property (nonatomic) NYPLBookDetailDownloadingView *downloadingView;
@property (nonatomic) NYPLBookDetailNormalView *normalView;

@property (nonatomic) UITextView *summaryTextView;
@property (nonatomic) NSLayoutConstraint *textHeightConstraint;
@property (nonatomic) UIButton *readMoreLabel;

@property (nonatomic) UILabel *publishedLabelKey;
@property (nonatomic) UILabel *publisherLabelKey;
@property (nonatomic) UILabel *categoriesLabelKey;
@property (nonatomic) UILabel *distributorLabelKey;
@property (nonatomic) UILabel *publishedLabelValue;
@property (nonatomic) UILabel *publisherLabelValue;
@property (nonatomic) UILabel *categoriesLabelValue;
@property (nonatomic) UILabel *distributorLabelValue;

@end

static CGFloat const CoverImageHeight = 200.0;
static CGFloat const CoverImageWidth = 160.0;
static CGFloat const VerticalPadding = 10.0;
static CGFloat const MainTextPaddingLeft = 10.0;
static CGFloat const SummaryTextAbbreviatedHeight = 150.0;
static CGFloat const FooterLabelVertAxisMultiplier = 0.7;
static NSString *DetailHTMLTemplate = nil;

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
  
  [self createHeaderLabels];
  [self createFooterLabels];
  
  [self addSubview:self.contentView];
  [self.contentView addSubview:self.coverImageView];
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.subtitleLabel];
  [self.contentView addSubview:self.authorsLabel];
  [self.contentView addSubview:self.unreadImageView];
  [self.contentView addSubview:self.summaryTextView];
  [self.contentView addSubview:self.publishedLabelKey];
  [self.contentView addSubview:self.publisherLabelKey];
  [self.contentView addSubview:self.categoriesLabelKey];
  [self.contentView addSubview:self.distributorLabelKey];
  [self.contentView addSubview:self.publishedLabelValue];
  [self.contentView addSubview:self.publisherLabelValue];
  [self.contentView addSubview:self.categoriesLabelValue];
  [self.contentView addSubview:self.distributorLabelValue];
  [self.contentView addSubview:self.readMoreLabel];
  [self.contentView addSubview:self.reportProblemLabel];
//
//  if (self.book.acquisition.report != nil) {
//    [self.contentView addSubview:self.reportProblemLabel];
//  }

  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:NSLocalizedString(@"Close", nil) forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchDown];
    [self.contentView addSubview:self.closeButton];
  }
  
  [self createDownloadViews];
  [self setupAutolayoutConstraints];
  [self updateFonts];
  
  if (self.textHeightConstraint.constant >= SummaryTextAbbreviatedHeight) {
    self.readMoreLabel.hidden = NO;
  }
  
  return self;
}

- (void)updateFonts
{
  self.titleLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleHeadline];
  self.subtitleLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleSubheadline];
  self.authorsLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  self.summaryTextView.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption2];
  self.readMoreLabel.titleLabel.font = [UIFont systemFontOfSize:14];
  self.reportProblemLabel.titleLabel.font = [UIFont systemFontOfSize:14];

  self.publishedLabelKey.font = [UIFont systemFontOfSize:12];
  self.publisherLabelKey.font = [UIFont systemFontOfSize:12];
  self.categoriesLabelKey.font = [UIFont systemFontOfSize:12];
  self.distributorLabelKey.font = [UIFont systemFontOfSize:12];
  
  self.publishedLabelValue.font = [UIFont systemFontOfSize:12];
  self.publisherLabelValue.font = [UIFont systemFontOfSize:12];
  self.categoriesLabelValue.font = [UIFont systemFontOfSize:12];
  self.distributorLabelValue.font = [UIFont systemFontOfSize:12];
}

- (void)createHeaderLabels
{
  
  self.coverImageView = [[UIImageView alloc] init];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
  
  [[NYPLBookRegistry sharedRegistry]
   thumbnailImageForBook:self.book
   handler:^(UIImage *const image) {
     self.coverImageView.image = image;
   }];
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.numberOfLines = 2;
  self.titleLabel.attributedText = NYPLAttributedStringForTitleFromString(self.book.title);
  
  self.subtitleLabel = [[UILabel alloc] init];
  self.subtitleLabel.text = self.book.subtitle;
  self.subtitleLabel.numberOfLines = 2;
  
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.authorsLabel.text = self.book.authors;
  } else {
    self.authorsLabel.attributedText = NYPLAttributedStringForAuthorsFromString(self.book.authors);
  }
  
  self.unreadImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unread"]];
  self.unreadImageView.image = [self.unreadImageView.image
                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self.unreadImageView setTintColor:[NYPLConfiguration accentColor]];
  
  self.summaryTextView = [[UITextView alloc] init];
  self.summaryTextView.backgroundColor = [UIColor clearColor];
  self.summaryTextView.scrollEnabled = NO;
  self.summaryTextView.editable = NO;
  [self.summaryTextView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0) ];
  [self.summaryTextView setTextContainerInset:UIEdgeInsetsMake(0, 0, 0, 0)];
  
  self.readMoreLabel = [[UIButton alloc] init];
  self.readMoreLabel.hidden = YES;
  self.readMoreLabel.titleLabel.textAlignment = NSTextAlignmentRight;
  [self.readMoreLabel addTarget:self action:@selector(readMoreTapped:) forControlEvents:UIControlEventTouchUpInside];
  //GODO translate
  [self.readMoreLabel setTitle:@"...Read More" forState:UIControlStateNormal];
  [self.readMoreLabel setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateNormal];
  
  
  NSString *htmlString = [NSString stringWithFormat:DetailHTMLTemplate,
                          [NYPLConfiguration systemFontName],
                          self.book.summary ? self.book.summary : @""];
  NSData *htmlData = [htmlString dataUsingEncoding:NSUnicodeStringEncoding];
  NSDictionary *attributes = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
  NSAttributedString *atrString = [[NSAttributedString alloc] initWithData:htmlData options:attributes documentAttributes:nil error:nil];
  self.summaryTextView.attributedText = atrString;
}

- (void)createDownloadViews
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
  [self.downloadFailedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.coverImageView withOffset:VerticalPadding];
  //GODO TEMP
  [self.downloadFailedView autoSetDimension:ALDimensionHeight toSize:70];
  
  self.downloadingView = [[NYPLBookDetailDownloadingView alloc] initWithWidth:0];
  self.downloadingView.delegate = self;
  self.downloadingView.hidden = YES;
  [self.contentView addSubview:self.downloadingView];
  [self.downloadingView autoPinEdgeToSuperviewEdge:ALEdgeRight];
  [self.downloadingView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.downloadingView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.coverImageView withOffset:VerticalPadding];
  //GODO TEMP
  [self.downloadingView autoSetDimension:ALDimensionHeight toSize:70];
}

- (void)createFooterLabels
{
  NSDateFormatter *const dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.timeStyle = NSDateFormatterNoStyle;
  dateFormatter.dateStyle = NSDateFormatterLongStyle;
  
  NSString *const publishedKeyString =
  self.book.published
  ? [NSString stringWithFormat:@"%@: ",
     NSLocalizedString(@"Published", nil)]
  : nil;
  
  NSString *const publisherKeyString =
  self.book.publisher
  ? [NSString stringWithFormat:@"%@: ",
     NSLocalizedString(@"Publisher", nil)]
  : nil;
  
  NSString *const categoriesKeyString =
  self.book.categoryStrings.count
  ? [NSString stringWithFormat:@"%@: ",
     (self.book.categoryStrings.count == 1
      ? NSLocalizedString(@"Category", nil)
      : NSLocalizedString(@"Categories", nil))]
  : nil;
  
  NSString *const categoriesValueString = self.book.categories;
  NSString *const publishedValueString = self.book.published ? [dateFormatter stringFromDate:self.book.published] : nil;
  NSString *const publisherValueString = self.book.publisher;
  NSString *const distributorKeyString = self.book.distributor ? [NSString stringWithFormat:NSLocalizedString(@"BookDetailViewControllerDistributedByFormat", nil)] : nil;
  
  self.categoriesLabelKey = [self createFooterLabelWithString:categoriesKeyString alignment:NSTextAlignmentRight];
  self.publisherLabelKey = [self createFooterLabelWithString:publisherKeyString alignment:NSTextAlignmentRight];
  self.publishedLabelKey = [self createFooterLabelWithString:publishedKeyString alignment:NSTextAlignmentRight];
  self.distributorLabelKey = [self createFooterLabelWithString:distributorKeyString alignment:NSTextAlignmentRight];
  
  self.categoriesLabelValue = [self createFooterLabelWithString:categoriesValueString alignment:NSTextAlignmentLeft];
  self.categoriesLabelValue.numberOfLines = 2;
  self.publisherLabelValue = [self createFooterLabelWithString:publisherValueString alignment:NSTextAlignmentLeft];
  self.publisherLabelValue.numberOfLines = 2;
  self.publishedLabelValue = [self createFooterLabelWithString:publishedValueString alignment:NSTextAlignmentLeft];
  self.distributorLabelValue = [self createFooterLabelWithString:self.book.distributor alignment:NSTextAlignmentLeft];
  
  self.reportProblemLabel = [[UIButton alloc] init];
  [self.reportProblemLabel setTitle:NSLocalizedString(@"ReportProblem", nil) forState:UIControlStateNormal];
  [self.reportProblemLabel addTarget:self action:@selector(reportProblemTapped:) forControlEvents:UIControlEventTouchUpInside];
  [self.reportProblemLabel setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateNormal];

}

- (UILabel *)createFooterLabelWithString:(NSString *)string alignment:(NSTextAlignment)alignment
{
  UILabel *label = [[UILabel alloc] init];
  label.textAlignment = alignment;
  label.textColor = [UIColor grayColor];
  label.text = string;
  return label;
}

- (void)setupAutolayoutConstraints
{
  [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
  [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
  [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
  [self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
  
  [self.coverImageView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
  [self.coverImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:VerticalPadding];

  //  [self.coverImageView autoSetDimension:ALDimensionWidth toSize:coverWidth];
  //  [self.coverImageView autoSetDimension:ALDimensionHeight toSize:coverHeight];
  
  //GODO TEMP
  [self.coverImageView autoSetDimension:ALDimensionWidth toSize:CoverImageWidth];
  [self.coverImageView autoSetDimension:ALDimensionHeight toSize:CoverImageHeight];
  
  [self.titleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.titleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.coverImageView];
//  [self.titleLabel autoSetDimension:ALDimensionWidth toSize:100 relation:NSLayoutRelationGreaterThanOrEqual];
  
  [self.subtitleLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel];
  
  [self.authorsLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.coverImageView withOffset:MainTextPaddingLeft];
  [self.authorsLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
  [self.authorsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.subtitleLabel];
  
  [self.unreadImageView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.coverImageView withOffset:5];
  [self.unreadImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
  
  [self.normalView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.coverImageView withOffset:VerticalPadding];
  
  [self.summaryTextView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.normalView withOffset:VerticalPadding];
  self.textHeightConstraint = [self.summaryTextView autoSetDimension:ALDimensionHeight toSize:SummaryTextAbbreviatedHeight relation:NSLayoutRelationLessThanOrEqual];
  [self.summaryTextView autoPinEdgeToSuperviewMargin:ALEdgeRight];
  [self.summaryTextView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  
  [self.readMoreLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.summaryTextView];
  [self.readMoreLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.summaryTextView];
  
  
  [self.publishedLabelValue autoPinEdgeToSuperviewMargin:ALEdgeRight];
  [self.publishedLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.summaryTextView withOffset:VerticalPadding];
  [self.publishedLabelValue autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.publishedLabelKey withOffset:MainTextPaddingLeft];
  
  [self.publisherLabelValue autoPinEdgeToSuperviewMargin:ALEdgeRight];
  [self.publisherLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.publishedLabelValue];
  [self.publisherLabelValue autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.publisherLabelKey withOffset:MainTextPaddingLeft];
  
  [self.categoriesLabelValue autoPinEdgeToSuperviewMargin:ALEdgeRight];
  [self.categoriesLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.publisherLabelValue];
  [self.categoriesLabelValue autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.categoriesLabelKey withOffset:MainTextPaddingLeft];
  
  [self.distributorLabelValue autoPinEdgeToSuperviewMargin:ALEdgeRight];
  [self.distributorLabelValue autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.categoriesLabelValue];
  [self.distributorLabelValue autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.distributorLabelKey withOffset:MainTextPaddingLeft];
  
  
  [self.publishedLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.publishedLabelKey autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeMarginAxisVertical ofView:self.contentView withMultiplier:FooterLabelVertAxisMultiplier];
  [self.publishedLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.publishedLabelValue];
  
  [self.publisherLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.publisherLabelKey autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeMarginAxisVertical ofView:self.contentView withMultiplier:FooterLabelVertAxisMultiplier];
  [self.publisherLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.publisherLabelValue];
  
  [self.categoriesLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.categoriesLabelKey autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeMarginAxisVertical ofView:self.contentView withMultiplier:FooterLabelVertAxisMultiplier];
  [self.categoriesLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.categoriesLabelValue];
  
  [self.distributorLabelKey autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.distributorLabelKey autoConstrainAttribute:ALAttributeTrailing toAttribute:ALAttributeMarginAxisVertical ofView:self.contentView withMultiplier:FooterLabelVertAxisMultiplier];
  [self.distributorLabelKey autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.distributorLabelValue];
  
  [self.reportProblemLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.distributorLabelValue withOffset:12];
  [self.reportProblemLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [self.reportProblemLabel autoPinEdgeToSuperviewMargin:ALEdgeBottom];
  
  if (self.book.acquisition.report == nil) {
    self.reportProblemLabel.hidden = YES;
    [self.reportProblemLabel autoSetDimension:ALDimensionHeight toSize:0];
  }

  if (self.closeButton) {
    [self.closeButton autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
    [self.closeButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:1];
  }
}

#pragma mark NSObject

+ (void)initialize
{
  DetailHTMLTemplate = [NSString
                    stringWithContentsOfURL:[[NSBundle mainBundle]
                                             URLForResource:@"DetailSummaryTemplate"
                                             withExtension:@"html"]
                    encoding:NSUTF8StringEncoding
                    error:NULL];
  
  assert(DetailHTMLTemplate);
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

- (void)reportProblemTapped:(id)sender
{
  [self.detailViewDelegate didSelectReportProblemForBook:self.book sender:sender];
}

- (void)readMoreTapped:(__unused UIButton *)sender
{
  self.textHeightConstraint.active = NO;
  [self.readMoreLabel removeFromSuperview];
}


@end
