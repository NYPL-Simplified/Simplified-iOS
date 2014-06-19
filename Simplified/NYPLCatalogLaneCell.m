#import "NYPLCatalogBook.h"

#import "NYPLCatalogLaneCell.h"

@interface NYPLCatalogLaneCell ()

@property (nonatomic) NSArray *buttons;
@property (nonatomic) NSUInteger laneIndex;
@property (nonatomic) UIScrollView *scrollView;

@end

@implementation NYPLCatalogLaneCell

- (id)initWithLaneIndex:(NSUInteger const)laneIndex
                  books:(NSArray *const)books
    imageDataDictionary:(NSDictionary *const)imageDataDictionary
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
  if(!self) return nil;
  
  self.laneIndex = laneIndex;
  
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
  self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.alwaysBounceHorizontal = YES;
  [self addSubview:self.scrollView];
  
  NSMutableArray *const buttons = [NSMutableArray arrayWithCapacity:books.count];
  
  for(NYPLCatalogBook *const book in books) {
    UIButton *const button = [UIButton buttonWithType:UIButtonTypeCustom];
    NSData *const imageData = [imageDataDictionary objectForKey:book.imageURL];
    UIImage *const image =
      imageData ? [UIImage imageWithData:imageData] : [UIImage imageNamed:@"NoCover"];
    [button setImage:image forState:UIControlStateNormal];
    [buttons addObject:button];
    [self.scrollView addSubview:button];
  }
  
  self.buttons = buttons;
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const padding = 20.0;
  
  CGFloat x = padding;
  CGFloat const height = self.frame.size.height;
  
  for(UIButton *const button in self.buttons) {
    CGFloat width = button.imageView.image.size.width;
    width *= height / button.imageView.image.size.height;
    CGRect const frame = CGRectMake(x, 0.0, width, height);
    button.frame = frame;
    x += width + padding;
  }
  
  self.scrollView.contentSize = CGSizeMake(x, height);
  
  CGRect frame = self.scrollView.frame;
  frame.size.height = height;
  self.scrollView.frame = frame;
}

@end
