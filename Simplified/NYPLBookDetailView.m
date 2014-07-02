#import "NYPLBookDetailView.h"

@interface NYPLBookDetailView ()

@property (nonatomic) UILabel *authors;
@property (nonatomic) UIView *cover;
@property (nonatomic) UILabel *title;

@end

static CGFloat const coverHeight = 120.0;
static CGFloat const coverWidth = 100.0;
static CGFloat const coverPaddingLeft = 40.0;
static CGFloat const coverPaddingTop = 10.0;
static CGFloat const mainTextPaddingTop = 10.0;
static CGFloat const mainTextPaddingLeft = 10.0;
static CGFloat const mainTextPaddingRight = 10.0;

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
  self.authors.font = [UIFont fontWithName:@"AvenirNext-Medium" size:12.0];
  self.authors.numberOfLines = 3;
  self.authors.text = [book.authorStrings componentsJoinedByString:@"; "];
  [self addSubview:self.authors];
  
  {
    if(coverImage) {
      UIImageView *const imageView = [[UIImageView alloc] initWithImage:coverImage];
      imageView.contentMode = UIViewContentModeScaleAspectFit;
      self.cover = imageView;
    } else {
      // TODO: If |coverImage| is nil, a book cover should be generated.
      NYPLLOG(@"Book cover generation is required but unimplemented.");
      self.cover = [[UIView alloc] init];
    }
    
    [self addSubview:self.cover];
  }
  
  self.title = [[UILabel alloc] init];
  self.title.font = [UIFont fontWithName:@"AvenirNext-Bold" size:14.0];
  self.title.numberOfLines = 3;
  self.title.text = book.title;
  [self addSubview:self.title];

  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGRect const frame = CGRectMake(coverPaddingLeft, coverPaddingTop, coverWidth, coverHeight);
  self.cover.frame = frame;
  
  {
    CGFloat const x = self.cover.frame.size.width + self.cover.frame.origin.x + mainTextPaddingLeft;
    CGFloat const y = mainTextPaddingTop;
    CGFloat const w = self.bounds.size.width - x - mainTextPaddingRight;
    CGFloat const h = [self.title sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.title.frame = CGRectMake(x, y, w, h);
  }
  
  {
    CGFloat const x = self.title.frame.origin.x;
    CGFloat const y = self.title.frame.origin.y + self.title.frame.size.height;
    CGFloat const w = self.title.frame.size.width;
    CGFloat const h = [self.title sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.authors.frame = CGRectMake(x, y, w, h);
  }
}

@end
