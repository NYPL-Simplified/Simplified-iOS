#import "NYPLBookDetailView.h"

@interface NYPLBookDetailView ()

@property (nonatomic) UILabel *authors;
@property (nonatomic) UIView *cover;
@property (nonatomic) UILabel *title;

@end

@implementation NYPLBookDetailView

// designated initializer
- (instancetype)initWithBook:(NYPLBook *const)book
                  coverImage:(UIImage *const)coverImage
                       frame:(CGRect const)frame

{
  self = [super initWithFrame:frame];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
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

- (void)layoutSubviews
{
  // TODO: Layout subviews.
}

@end
