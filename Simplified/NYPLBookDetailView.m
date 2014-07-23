#import "NYPLBook.h"
#import "NYPLSession.h"

#import "NYPLBookDetailView.h"

@interface NYPLBookDetailView ()

@property (nonatomic) UILabel *authors;
@property (nonatomic) NYPLBook *book;
@property (nonatomic) UIImageView *cover;
@property (nonatomic) UIButton *downloadButton;
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
- (instancetype)initWithBook:(NYPLBook *const)book
{
  self = [super init];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  self.backgroundColor = [UIColor whiteColor];
  
  self.book = book;
  
  self.authors = [[UILabel alloc] init];
  self.authors.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
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

  self.downloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [self.downloadButton setTitle:@"Download" forState:UIControlStateNormal];
  [self.downloadButton addTarget:self
                          action:@selector(didSelectDownload)
                forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.downloadButton];

  
  [self addSubview:self.downloadButton];
  
  self.title = [[UILabel alloc] init];
  self.title.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.title.numberOfLines = 3;
  self.title.text = book.title;
  [self addSubview:self.title];

  return self;
}

- (void)didSelectDownload
{
  [self.detailViewDelegate didSelectDownloadForDetailView:self];
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGRect const frame = CGRectMake(coverPaddingLeft, coverPaddingTop, coverWidth, coverHeight);
  self.cover.frame = frame;
  
  {
    CGFloat const x = CGRectGetMaxX(self.cover.frame) + mainTextPaddingLeft;
    CGFloat const y = mainTextPaddingTop;
    CGFloat const w = CGRectGetWidth(self.bounds) - x - mainTextPaddingRight;
    CGFloat const h = [self.title sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.title.frame = CGRectMake(x, y, w, h);
  }
  
  {
    CGFloat const x = CGRectGetMinX(self.title.frame);
    CGFloat const y = CGRectGetMaxY(self.title.frame);
    CGFloat const w = CGRectGetWidth(self.title.frame);
    CGFloat const h = [self.title sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.authors.frame = CGRectMake(x, y, w, h);
  }
  
  {
    [self.downloadButton sizeToFit];
    CGRect frame = self.downloadButton.frame;
    frame.origin.x = CGRectGetMinX(self.authors.frame);
    frame.origin.y = CGRectGetMaxY(self.authors.frame) + mainTextPaddingTop;
    self.downloadButton.frame = frame;
  }
}

@end
