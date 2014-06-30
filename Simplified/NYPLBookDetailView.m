#import "NYPLBookDetailView.h"

@interface NYPLBookDetailView ()

@property (nonatomic) UILabel *authors;
@property (nonatomic) UIView *cover;
@property (nonatomic) UILabel *title;

@end

@implementation NYPLBookDetailView

// designated initializer
- (instancetype)initWithBook:(NYPLCatalogBook *const)book
                  coverImage:(UIImage *const)coverImage

{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  self.backgroundColor = [UIColor whiteColor];
  
  self.authors = [[UILabel alloc] init];
  self.authors.text = [book.authorStrings componentsJoinedByString:@"; "];
  [self addSubview:self.authors];
  
  {
    if(coverImage) {
      self.cover = [[UIImageView alloc] initWithImage:coverImage];
    } else {
      // TODO: If |coverImage| is nil, a book cover should be generated.
      NYPLLOG(@"Book cover generation is required but unimplemented.");
      self.cover = [[UIView alloc] init];
    }
    
    [self addSubview:self.cover];
  }
  
  self.title = [[UILabel alloc] init];
  self.title.text = book.title;
  [self addSubview:self.title];

  return self;
}

#pragma mark UIView

// TODO: This is a near copy-paste of the code from NYPLCatalogLaneCell. It is probably necessary to
// factor out a cover view class to eliminate this duplication.
- (void)layoutSubviews
{
  CGFloat const padding = 10.0;
  
  CGFloat const height = 115.0;
  
  CGFloat width = self.cover.frame.size.width;
  if(width > 10.0) {
    width *= height / self.cover.frame.size.height;
  } else {
    NYPLLOG(@"Failing to correctly display cover with unusable width.");
    width = height * 0.75;
  }
  CGRect const frame = CGRectMake(padding, 0.0, width, height);
  self.cover.frame = frame;
  
  // TODO: This needs to be done properly.
  [self.authors sizeToFit];
  [self.title sizeToFit];
}

@end
