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
        return CGSizeMake(384, 120);
      case UIInterfaceOrientationLandscapeLeft:
        // fallthrough
      case UIInterfaceOrientationLandscapeRight:
        return CGSizeMake(341, 120);
    }
  } else {
    return CGSizeMake(320, 120);
  }
}

@interface NYPLBookCell ()

@property (nonatomic) UILabel *author;
@property (nonatomic) UIImageView *cover;
@property (nonatomic) UILabel *title;
@property (nonatomic) NSURL *coverURL;

@end

@implementation NYPLBookCell

#pragma mark UIView

- (void)layoutSubviews
{
  self.contentView.frame = self.bounds;
  
  self.cover.frame = CGRectMake(5, 5, 90, CGRectGetHeight(self.frame) - 10);
  self.cover.contentMode = UIViewContentModeScaleAspectFit;
  
  [self.title sizeToFit];
  CGRect titleFrame = self.title.frame;
  titleFrame.origin = CGPointMake(100, 5);
  titleFrame.size.width = CGRectGetWidth(self.frame) - 105;
  self.title.frame = titleFrame;
  
  [self.author sizeToFit];
  CGRect authorFrame = self.author.frame;
  authorFrame.origin = CGPointMake(100, CGRectGetMaxY(titleFrame) + 5);
  authorFrame.size.width = CGRectGetWidth(self.frame) - 105;
  self.author.frame = authorFrame;
}

#pragma mark -

- (void)setBook:(NYPLBook *const)book
{
  if(!self.author) {
    self.author = [[UILabel alloc] init];
    [self.contentView addSubview:self.author];
  }
  
  if(!self.cover) {
    self.cover = [[UIImageView alloc] init];
    [self.contentView addSubview:self.cover];
  }
  
  if(!self.title) {
    self.title = [[UILabel alloc] init];
    [self.contentView addSubview:self.title];
  }
  
  self.author.text = [book.authorStrings componentsJoinedByString:@"; "];
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

@end
