#import "NYPLAttributedString.h"
#import "NYPLBook.h"
#import "NYPLConfiguration.h"
#import "NYPLMyBooksCoverRegistry.h"
#import "NYPLRoundedButton.h"

#import "NYPLBookNormalCell.h"

@interface NYPLBookNormalCell ()

@property (nonatomic) UILabel *authors;
@property (nonatomic) UIImageView *cover;
@property (nonatomic) NYPLRoundedButton *deleteButton;
@property (nonatomic) NYPLRoundedButton *downloadButton;
@property (nonatomic) UILabel *title;
@property (nonatomic) NYPLRoundedButton *readButton;
@property (nonatomic) UIImageView *unreadImageView;

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
  
  [self.deleteButton sizeToFit];
  CGRect deleteButtonFrame = self.deleteButton.frame;
  deleteButtonFrame.origin = CGPointMake(115,
                                         (CGRectGetHeight([self contentFrame]) -
                                          CGRectGetHeight(deleteButtonFrame) - 5));
  self.deleteButton.frame = deleteButtonFrame;
  
  [self.readButton sizeToFit];
  CGRect readButtonFrame = self.readButton.frame;
  readButtonFrame.origin = CGPointMake(CGRectGetMaxX(self.deleteButton.frame) + 5,
                                       CGRectGetMinY(self.deleteButton.frame));
  self.readButton.frame = readButtonFrame;
  
  [self.downloadButton sizeToFit];
  CGRect downloadButtonFrame = self.downloadButton.frame;
  downloadButtonFrame.origin = CGPointMake(115,
                                           (CGRectGetHeight([self contentFrame]) -
                                            CGRectGetHeight(downloadButtonFrame) - 5));
  self.downloadButton.frame = downloadButtonFrame;
  
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
    [self.deleteButton setTitle:NSLocalizedString(@"Delete", nil)
                       forState:UIControlStateNormal];
    [self.deleteButton addTarget:self
                          action:@selector(didSelectDelete)
                forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.deleteButton];
  }
  
  if(!self.downloadButton) {
    self.downloadButton = [NYPLRoundedButton button];
    [self.downloadButton setTitle:NSLocalizedString(@"Download", nil)
                         forState:UIControlStateNormal];
    [self.downloadButton addTarget:self
                            action:@selector(didSelectDownload)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.downloadButton];
  }
  
  if(!self.readButton) {
    self.readButton = [NYPLRoundedButton button];
    [self.readButton setTitle:NSLocalizedString(@"Read", nil) forState:UIControlStateNormal];
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
  self.cover.image = [[NYPLMyBooksCoverRegistry sharedRegistry] cachedThumbnailImageForBook:book];
  
  if(!self.cover.image) {
    [[NYPLMyBooksCoverRegistry sharedRegistry]
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
  
  switch(state) {
    case NYPLBookNormalCellStateUnregistered:
      // fallthrough
    case NYPLBookNormalCellStateDownloadNeeded:
      self.deleteButton.hidden = YES;
      self.downloadButton.hidden = NO;
      self.readButton.hidden = YES;
      self.unreadImageView.hidden = YES;
      break;
    case NYPLBookNormalCellStateDownloadSuccessful:
      self.deleteButton.hidden = NO;
      self.downloadButton.hidden = YES;
      self.readButton.hidden = NO;
      self.unreadImageView.hidden = NO;
      break;
    case NYPLBookNormalCellStateUsed:
      self.deleteButton.hidden = NO;
      self.downloadButton.hidden = YES;
      self.readButton.hidden = NO;
      self.unreadImageView.hidden = YES;
      break;
  }
}

@end
