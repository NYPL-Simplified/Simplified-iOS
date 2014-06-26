#import "NYPLCoverSession.h"

#import "NYPLCatalogCategoryCell.h"

@interface NYPLCatalogCategoryCell ()

@property (nonatomic) UILabel *author;
@property (nonatomic) UIImageView *cover;
@property (nonatomic) UILabel *title;

@end

@implementation NYPLCatalogCategoryCell

#pragma mark UIView

- (void)layoutSubviews
{
  self.cover.frame = CGRectMake(5, 5, 90, self.frame.size.height - 10);
  
  [self.title sizeToFit];
  CGRect titleFrame = self.title.frame;
  titleFrame.origin = CGPointMake(100, 5);
  titleFrame.size.width = self.frame.size.width - 105;
  self.title.frame = titleFrame;
  
  [self.author sizeToFit];
  CGRect authorFrame = self.author.frame;
  authorFrame.origin = CGPointMake(100, titleFrame.origin.y + titleFrame.size.height + 5);
  authorFrame.size.width = self.frame.size.width - 105;
  self.author.frame = authorFrame;
}

#pragma mark -

- (void)setBook:(NYPLCatalogBook *const)book
{
  if(!self.author) {
    self.author = [[UILabel alloc] initWithFrame:CGRectZero];
    [self addSubview:self.author];
  }
  
  if(!self.cover) {
    self.cover = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.cover];
  }
  
  if(!self.title) {
    self.title = [[UILabel alloc] initWithFrame:CGRectZero];
    [self addSubview:self.title];
  }
  
  self.author.text = [book.authorStrings componentsJoinedByString:@"; "];
  self.cover.image = nil;
  self.title.text = book.title;
  
  self.cover.image = [[NYPLCoverSession sharedSession] cachedImageForURL:book.imageURL];
  
  if(!self.cover.image) {
    [[NYPLCoverSession sharedSession]
     withURL:book.imageURL
     completionHandler:^(UIImage *const image) {
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         self.cover.image = image;
         [self.cover sizeToFit];
       }];
     }];
  }
  
  [self setNeedsLayout];
}

@end
