#import "NYPLAttributedString.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLRoundedButton.h"

#import "NYPLBookNormalCell.h"

@interface NYPLBookNormalCell ()

@property (nonatomic) UILabel *authors;
@property (nonatomic) UIImageView *cover;
@property (nonatomic) NYPLRoundedButton *deleteButton;
@property (nonatomic) NYPLRoundedButton *downloadButton;
@property (nonatomic) NYPLRoundedButton *readButton;
@property (nonatomic) UILabel *title;
@property (nonatomic) UIImageView *unreadImageView;
@property (nonatomic) NSArray *visibleButtons;

@end

@implementation NYPLBookNormalCell

#pragma mark UIView

- (void)layoutSubviews
{  
  self.cover.frame = CGRectMake(20,
                                5,
                                (CGRectGetHeight([self contentFrame]) - 10) * (10 / 12.0),
                                CGRectGetHeight([self contentFrame]) - 10);
  self.cover.contentMode = UIViewContentModeScaleAspectFit;

  // The extra five height pixels account for a bug in |sizeThatFits:| that does not properly take
  // into account |lineHeightMultiple|.
  CGFloat const titleWidth = CGRectGetWidth([self contentFrame]) - 120;
  self.title.frame = CGRectMake(115,
                                5,
                                titleWidth,
                                [self.title sizeThatFits:
                                 CGSizeMake(titleWidth, CGFLOAT_MAX)].height + 5);
  
  [self.authors sizeToFit];
  CGRect authorFrame = self.authors.frame;
  authorFrame.origin = CGPointMake(115, CGRectGetMaxY(self.title.frame));
  authorFrame.size.width = CGRectGetWidth([self contentFrame]) - 120;
  self.authors.frame = authorFrame;
  
  NYPLRoundedButton *lastButton = nil;
  for (NYPLRoundedButton *button in self.visibleButtons) {
    [button sizeToFit];
    CGRect frame = button.frame;
    if (!lastButton) {
      lastButton = button;
      frame.origin = CGPointMake(115,
                                 (CGRectGetHeight([self contentFrame]) -
                                  CGRectGetHeight(frame) - 5));
    } else {
      frame.origin = CGPointMake(CGRectGetMaxX(lastButton.frame) + 5,
                                 CGRectGetMinY(lastButton.frame));
    }
    button.frame = frame;
  }
  
  CGRect unreadImageViewFrame = self.unreadImageView.frame;
  unreadImageViewFrame.origin.x = (CGRectGetMinX(self.cover.frame) -
                                   CGRectGetWidth(unreadImageViewFrame) - 5);
  unreadImageViewFrame.origin.y = 5;
  self.unreadImageView.frame = unreadImageViewFrame;
}

#pragma mark -

- (void)setBook:(NYPLBook *const)book
{
  _book = book;
  
  if(!self.authors) {
    self.authors = [[UILabel alloc] init];
    self.authors.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:self.authors];
  }
  
  if(!self.cover) {
    self.cover = [[UIImageView alloc] init];
    [self.contentView addSubview:self.cover];
  }
  
  if(!self.deleteButton) {
    self.deleteButton = [NYPLRoundedButton button];
    [self.deleteButton addTarget:self
                          action:@selector(didSelectDelete)
                forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.deleteButton];
  }
  
  if(!self.downloadButton) {
    self.downloadButton = [NYPLRoundedButton button];
    [self.downloadButton addTarget:self
                            action:@selector(didSelectDownload)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.downloadButton];
  }
  
  if(!self.readButton) {
    self.readButton = [NYPLRoundedButton button];
    [self.readButton addTarget:self
                        action:@selector(didSelectRead)
              forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.readButton];
  }
  
  if(!self.title) {
    self.title = [[UILabel alloc] init];
    self.title.numberOfLines = 2;
    self.title.font = [UIFont systemFontOfSize:17];
    [self.contentView addSubview:self.title];
    [self.contentView setNeedsLayout];
  }
  
  if(!self.unreadImageView) {
    self.unreadImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unread"]];
    self.unreadImageView.image = [self.unreadImageView.image
                                  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.unreadImageView.tintColor = [NYPLConfiguration accentColor];
    [self.contentView addSubview:self.unreadImageView];
  }
  
  self.authors.attributedText = NYPLAttributedStringForAuthorsFromString(book.authors);
  self.cover.image = nil;
  self.title.attributedText = NYPLAttributedStringForTitleFromString(book.title);
  
  // This avoids hitting the server constantly when scrolling within a category and ensures images
  // will still be there when the user scrolls back up. It also avoids creating tasks and refetching
  // images when the collection view reloads its data in response to an additional page being
  // fetched (which otherwise would cause a flickering effect and pointless bandwidth usage).
  self.cover.image = [[NYPLBookRegistry sharedRegistry] cachedThumbnailImageForBook:book];
  
  if(!self.cover.image) {
    [[NYPLBookRegistry sharedRegistry]
     thumbnailImageForBook:book
     handler:^(UIImage *const image) {
       // This check prevents old operations from overwriting cover images in the case of cells
       // being reused before those operations completed.
       if([book.identifier isEqualToString:self.book.identifier]) {
         self.cover.image = image;
       }
     }];
  }
  
  [self setNeedsLayout];
}

- (void)didSelectDelete
{
  [self.delegate didSelectDeleteForBookNormalCell:self];
}

- (void)didSelectDownload
{
  [self.delegate didSelectDownloadForBookNormalCell:self];
}

- (void)didSelectRead
{
  [self.delegate didSelectReadForBookNormalCell:self];
}

- (void)setState:(NYPLBookNormalCellState const)state
{
  _state = state;
  
  NSArray *visibleButtonInfo = nil;
  static NSString *const ButtonKey = @"button";
  static NSString *const TitleKey = @"title";
  static NSString *const AddIndicatorKey = @"addIndicator";
  
  self.unreadImageView.hidden = YES;
  switch(state) {
    case NYPLBookNormalCellStateCanBorrow:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton, TitleKey: @"Borrow"}];
      break;
    case NYPLBookNormalCellStateCanKeep:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton, TitleKey: @"Download"}];
      break;
    case NYPLBookNormalCellStateCanHold:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton, TitleKey: @"Hold"}];
      break;
    case NYPLBookNormalCellStateHolding:
      visibleButtonInfo = @[@{ButtonKey: self.deleteButton,   TitleKey: @"CancelHold", AddIndicatorKey: @(YES)}];
      break;
    case NYPLBookNormalCellStateHoldingFOQ:
      visibleButtonInfo = @[@{ButtonKey: self.downloadButton, TitleKey: @"Borrow", AddIndicatorKey: @(YES)},
                            @{ButtonKey: self.deleteButton,   TitleKey: @"CancelHold"}];
      break;
    case NYPLBookNormalCellStateDownloadNeeded:
      visibleButtonInfo = @[@{ButtonKey: self.deleteButton,   TitleKey: @"ReturnNow", AddIndicatorKey: @(YES)},
                            @{ButtonKey: self.downloadButton, TitleKey: @"Download"}];
      break;
    case NYPLBookNormalCellStateDownloadSuccessful:
      self.unreadImageView.hidden = NO;
      // Fallthrough
    case NYPLBookNormalCellStateUsed:
      visibleButtonInfo = @[@{ButtonKey: self.readButton,     TitleKey: @"Read"},
                            @{ButtonKey: self.deleteButton,   TitleKey: @"ReturnNow", AddIndicatorKey: @(YES)}];
      break;
  }
  
  NSMutableArray *visibleButtons = [NSMutableArray array];
  for (NSDictionary *buttonInfo in visibleButtonInfo) {
    NYPLRoundedButton *button = buttonInfo[ButtonKey];
    button.hidden = NO;
    [button setTitle:NSLocalizedString(buttonInfo[TitleKey], nil) forState:UIControlStateNormal];
    if ([buttonInfo[AddIndicatorKey] isEqualToValue:@(YES)]) {
      if (self.book.availableUntil && [self.book.availableUntil timeIntervalSinceNow] > 0) {
        button.type = NYPLRoundedButtonTypeClock;
        button.endDate = self.book.availableUntil;
      } else {
        button.type = NYPLRoundedButtonTypeNormal;
        // We could handle queue support here if we wanted it.
        // button.type = NYPLRoundedButtonTypeQueue;
        // button.queuePosition = self.book.holdPosition;
      }
    } else {
      button.type = NYPLRoundedButtonTypeNormal;
    }
    [visibleButtons addObject:button];
  }
  for (NYPLRoundedButton *button in @[self.downloadButton, self.deleteButton, self.readButton]) {
    if (![visibleButtons containsObject:button]) {
      button.hidden = YES;
    }
  }
  self.visibleButtons = visibleButtons;
  [self setNeedsLayout];
}

@end
