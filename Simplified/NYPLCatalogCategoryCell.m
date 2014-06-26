#import "NYPLCatalogCategoryCell.h"

@interface NYPLCatalogCategoryCell ()

@property (nonatomic) UILabel *author;
@property (nonatomic) UILabel *title;

@end

@implementation NYPLCatalogCategoryCell

#pragma mark UIView

- (void)layoutSubviews
{
  [self.title sizeToFit];
  CGRect titleFrame = self.title.frame;
  titleFrame.origin = CGPointMake(5, 5);
  titleFrame.size.width = self.frame.size.width - 10;
  self.title.frame = titleFrame;
  
  [self.author sizeToFit];
  CGRect authorFrame = self.author.frame;
  authorFrame.origin = CGPointMake(5, titleFrame.origin.y + titleFrame.size.height + 5);
  authorFrame.size.width = self.frame.size.width - 10;
  self.author.frame = authorFrame;
}

#pragma mark -

- (void)setBook:(NYPLCatalogBook *const)book
{
  if(!self.author) {
    self.author = [[UILabel alloc] init];
    [self addSubview:self.author];
  }
  
  if(!self.title) {
    self.title = [[UILabel alloc] init];
    [self addSubview:self.title];
  }
  
  self.author.text = [book.authorStrings componentsJoinedByString:@"; "];
  self.title.text = book.title;
  
  [self setNeedsLayout];
}

@end
