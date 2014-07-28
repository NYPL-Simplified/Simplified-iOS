#import "NYPLConfiguration.h"
#import "NYPLSession.h"

#import "NYPLBookCell.h"

CGSize NYPLBookCellSizeForIdiomAndOrientation(UIUserInterfaceIdiom idiom,
                                              UIInterfaceOrientation orientation)
{
  if(idiom == UIUserInterfaceIdiomPad) {
    switch(orientation) {
      case UIInterfaceOrientationPortrait:
        // fallthrough
      case UIInterfaceOrientationPortraitUpsideDown:
        return CGSizeMake(384, 110);
      case UIInterfaceOrientationLandscapeLeft:
        // fallthrough
      case UIInterfaceOrientationLandscapeRight:
        return CGSizeMake(341, 110);
    }
  } else {
    return CGSizeMake(320, 110);
  }
}

@interface NYPLBookCell ()

@property (nonatomic) UILabel *author;
@property (nonatomic) UIImageView *cover;
@property (nonatomic) NSURL *coverURL;
@property (nonatomic) UIButton *downloadButton;
@property (nonatomic) UILabel *title;
@property (nonatomic) UIImageView *unreadImageView;

@end

@implementation NYPLBookCell

#pragma mark UIView

- (void)layoutSubviews
{
  self.contentView.frame = self.bounds;
  
  self.cover.frame = CGRectMake(20, 5, 90, CGRectGetHeight(self.frame) - 10);
  self.cover.contentMode = UIViewContentModeScaleAspectFit;
  
  [self.title sizeToFit];
  CGRect titleFrame = self.title.frame;
  titleFrame.origin = CGPointMake(115, 5);
  titleFrame.size.width = CGRectGetWidth(self.frame) - 120;
  self.title.frame = titleFrame;
  
  [self.author sizeToFit];
  CGRect authorFrame = self.author.frame;
  authorFrame.origin = CGPointMake(115, CGRectGetMaxY(titleFrame));
  authorFrame.size.width = CGRectGetWidth(self.frame) - 120;
  self.author.frame = authorFrame;
  
  [self.downloadButton sizeToFit];
  self.downloadButton.frame = CGRectInset(self.downloadButton.frame, -8, 0);
  CGRect downloadButtonFrame = self.downloadButton.frame;
  downloadButtonFrame.origin = CGPointMake(115,
                                           (CGRectGetHeight(self.contentView.frame) -
                                            CGRectGetHeight(downloadButtonFrame) - 5));
  self.downloadButton.frame = downloadButtonFrame;
  
  CGRect unreadImageViewFrame = self.unreadImageView.frame;
  unreadImageViewFrame.origin = CGPointMake(10, 10);
  self.unreadImageView.frame = unreadImageViewFrame;
}

#pragma mark -

- (void)setBook:(NYPLBook *const)book
{
  _book = book;
  
  if(!self.author) {
    self.author = [[UILabel alloc] init];
    self.author.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:self.author];
  }
  
  if(!self.cover) {
    self.cover = [[UIImageView alloc] init];
    [self.contentView addSubview:self.cover];
  }
  
  if(!self.downloadButton) {
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downloadButton setTitle:@"Download" forState:UIControlStateNormal];
    [self.downloadButton addTarget:self
                            action:@selector(didSelectDownload)
                  forControlEvents:UIControlEventTouchUpInside];
    self.downloadButton.layer.cornerRadius = 2;
    self.downloadButton.layer.borderWidth = 1;
    self.downloadButton.layer.borderColor = [NYPLConfiguration mainColor].CGColor;
    [self.contentView addSubview:self.downloadButton];
  }
  
  if(!self.title) {
    self.title = [[UILabel alloc] init];
    self.title.font = [UIFont boldSystemFontOfSize:17];
    self.title.numberOfLines = 2;
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
  
  self.author.text = book.authors;
  self.cover.image = nil;
  self.coverURL = book.imageURL;
  self.title.text = book.title;
  
  // TODO: The approach below will keep showing old covers across launches even if they've been
  // updated on the server. Consider if there's a better way to do this.
  
  // This avoids hitting the server constantly when scrolling within a category and ensures images
  // will still be there when the user scrolls back up. It also avoids creating tasks and refetching
  // images when the collection view reloads its data in response to an additional page being
  // fetched (which otherwise would cause a flickering effect and pointless bandwidth usage).
  self.cover.image = [UIImage imageWithData:
                      [[NYPLSession sharedSession] cachedDataForURL:book.imageURL]];
  
  if(!self.cover.image) {
    [[NYPLSession sharedSession]
     withURL:book.imageURL
     completionHandler:^(NSData *const data) {
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         // TODO: This check prevents old operations from overwriting cover images in the case of
         // cells being reused before those operations completed. It avoids visual bugs, but said
         // operations should be killed to avoid unnecesssary bandwidth usage. Once that is in
         // place, this check and |self.coverURL| may no longer be needed.
         if([book.imageURL isEqual:self.coverURL]) {
           self.cover.image = [UIImage imageWithData:data];
           // Drop the now-useless URL reference.
           self.coverURL = nil;
         }
       }];
     }];
  }
  
  [self setNeedsLayout];
}

- (void)didSelectDownload
{
  [self.delegate didSelectDownloadForBookCell:self];
}

- (BOOL)downloadButtonHidden
{
  return self.downloadButton.hidden;
}

- (void)setDownloadButtonHidden:(BOOL const)hidden
{
  self.downloadButton.hidden = hidden;
}

- (BOOL)unreadIconHidden
{
  return self.unreadImageView.hidden;
}

- (void)setUnreadIconHidden:(BOOL const)hidden
{
  self.unreadImageView.hidden = hidden;
}

@end
