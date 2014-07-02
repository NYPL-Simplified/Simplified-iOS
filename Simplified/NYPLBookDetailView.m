#import "NYPLCatalogBook.h"
#import "NYPLSession.h"

#import "NYPLBookDetailView.h"

@interface NYPLBookDetailView ()

@property (nonatomic) UILabel *authors;
@property (nonatomic) UIImageView *cover;
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
{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  self.backgroundColor = [UIColor whiteColor];
  
  self.authors = [[UILabel alloc] init];
  self.authors.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.authors.font = [UIFont fontWithName:@"AvenirNext-Medium" size:12.0];
  self.authors.numberOfLines = 3;
  self.authors.text = [book.authorStrings componentsJoinedByString:@"; "];
  [self addSubview:self.authors];
  
  self.cover = [[UIImageView alloc] init];
  self.cover.contentMode = UIViewContentModeScaleAspectFit;
  self.cover.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  [self addSubview:self.cover];
  
  self.cover.image =
    [UIImage imageWithData:[[NYPLSession sharedSession] cachedDataForURL:book.imageURL]];
  
  if(!self.cover.image) {
    [[NYPLSession sharedSession]
     withURL:book.imageURL
     completionHandler:^(NSData *const data) {
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         self.cover.image = [UIImage imageWithData:data];
       }];
     }];
  }

  self.title = [[UILabel alloc] init];
  self.title.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
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
