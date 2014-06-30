#import "NYPLCatalogBook.h"

#import "NYPLCatalogLaneCell.h"

@interface NYPLCatalogLaneCell ()

@property (nonatomic) NSArray *buttons;
@property (nonatomic) NSUInteger laneIndex;
@property (nonatomic) UIScrollView *scrollView;

@end

@implementation NYPLCatalogLaneCell

- (instancetype)initWithLaneIndex:(NSUInteger const)laneIndex
                            books:(NSArray *const)books
              imageDataDictionary:(NSDictionary *const)imageDataDictionary
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
  if(!self) return nil;
  
  self.laneIndex = laneIndex;
  
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
  self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                      | UIViewAutoresizingFlexibleHeight);
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.alwaysBounceHorizontal = YES;
  [self addSubview:self.scrollView];
  
  NSMutableArray *const buttons = [NSMutableArray arrayWithCapacity:books.count];
  
  [books enumerateObjectsUsingBlock:^(NYPLCatalogBook *const book,
                                      NSUInteger const bookIndex,
                                      __attribute__((unused)) BOOL *stop) {
    UIButton *const button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = bookIndex;
    NSData *const imageData = imageDataDictionary[book.imageURL];
    UIImage *const image =
    imageData ? [UIImage imageWithData:imageData] : [UIImage imageNamed:@"NoCover"];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(didSelectBookButton:)
     forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    [buttons addObject:button];
    [self.scrollView addSubview:button];
  }];
  
  self.buttons = buttons;
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const padding = 10.0;
  
  CGFloat x = padding;
  CGFloat const height = self.frame.size.height;
  
  // TODO: A guard against absurdly wide covers is needed.
  
  for(UIButton *const button in self.buttons) {
    CGFloat width = button.imageView.image.size.width;
    if(width > 10.0) {
      width *= height / button.imageView.image.size.height;
    } else {
      NYPLLOG(@"Failing to correctly display cover with unusable width.");
      width = height * 0.75;
    }
    CGRect const frame = CGRectMake(x, 0.0, width, height);
    button.frame = frame;
    x += width + padding;
  }
  
  self.scrollView.contentSize = CGSizeMake(x, height);
}

#pragma mark -

- (void)didSelectBookButton:(UIButton *const)sender
{
  [self.delegate catalogLaneCell:self didSelectBookIndex:sender.tag];
}

@end
