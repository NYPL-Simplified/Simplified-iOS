#import "NYPLBook.h"
#import "NYPLBookDetailNormalView.h"
#import "NYPLSession.h"

#import "NYPLBookDetailView.h"

@interface NYPLBookDetailView ()

@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) NYPLBook *book;
@property (nonatomic) UIImageView *coverImageView;
@property (nonatomic) NYPLBookDetailNormalView *normalView;
@property (nonatomic) UILabel *titleLabel;

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
  
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.authorsLabel.numberOfLines = 3;
  self.authorsLabel.text = book.authors;
  [self addSubview:self.authorsLabel];
  
  self.coverImageView = [[UIImageView alloc] init];
  self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.coverImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  [self addSubview:self.coverImageView];
  
  self.coverImageView.image =
    [UIImage imageWithData:[[NYPLSession sharedSession] cachedDataForURL:book.imageURL]];
  
  if(!self.coverImageView.image) {
    [[NYPLSession sharedSession]
     withURL:book.imageURL
     completionHandler:^(NSData *const data) {
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         self.coverImageView.image = [UIImage imageWithData:data];
       }];
     }];
  }
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  self.titleLabel.numberOfLines = 3;
  self.titleLabel.text = book.title;
  [self addSubview:self.titleLabel];
  
  self.normalView = [[NYPLBookDetailNormalView alloc] initWithWidth:0];
  [self addSubview:self.normalView];

  return self;
}

- (void)didSelectDownload
{
  [self.detailViewDelegate didSelectDownloadForDetailView:self];
}

#pragma mark UIView

- (void)layoutSubviews
{
  {
    CGRect const frame = CGRectMake(coverPaddingLeft, coverPaddingTop, coverWidth, coverHeight);
    self.coverImageView.frame = frame;
  }
  
  {
    CGFloat const x = CGRectGetMaxX(self.coverImageView.frame) + mainTextPaddingLeft;
    CGFloat const y = mainTextPaddingTop;
    CGFloat const w = CGRectGetWidth(self.bounds) - x - mainTextPaddingRight;
    CGFloat const h = [self.titleLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.titleLabel.frame = CGRectMake(x, y, w, h);
  }
  
  {
    CGFloat const x = CGRectGetMinX(self.titleLabel.frame);
    CGFloat const y = CGRectGetMaxY(self.titleLabel.frame);
    CGFloat const w = CGRectGetWidth(self.titleLabel.frame);
    CGFloat const h = [self.titleLabel sizeThatFits:CGSizeMake(w, CGFLOAT_MAX)].height;
    self.authorsLabel.frame = CGRectMake(x, y, w, h);
  }
  
  {
    self.normalView.frame = CGRectMake(0,
                                       CGRectGetMaxY(self.coverImageView.frame) + 10.0,
                                       CGRectGetWidth(self.frame),
                                       CGRectGetHeight(self.normalView.frame));
  }
}

@end
