@import PureLayout;
#import "NYPLBook.h"
#import "NYPLConfiguration.h"
#import "SimplyE-Swift.h"

#import "NYPLCatalogLaneCell.h"

@interface NYPLCatalogLaneCell ()

@property (nonatomic) NSArray *buttons;
@property (nonatomic) NSUInteger laneIndex;
@property (nonatomic) UIScrollView *scrollView;

@end

@implementation NYPLCatalogLaneCell

- (instancetype)initWithLaneIndex:(NSUInteger const)laneIndex
                            books:(NSArray *const)books
          bookIdentifiersToImages:(NSDictionary *const)bookIdentifiersToImages
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
  if(!self) return nil;
  
  self.laneIndex = laneIndex;
  
  self.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                       | UIViewAutoresizingFlexibleHeight);
  
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.contentView.bounds];
  self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                      | UIViewAutoresizingFlexibleHeight);
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.alwaysBounceHorizontal = YES;
  self.scrollView.scrollsToTop = NO;
  [self.contentView addSubview:self.scrollView];
  
  NSMutableArray *const buttons = [NSMutableArray arrayWithCapacity:books.count];
  
  [books enumerateObjectsUsingBlock:^(NYPLBook *const book,
                                      NSUInteger const bookIndex,
                                      __attribute__((unused)) BOOL *stop) {
    UIButton *const button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = bookIndex;
    UIImage *const image = bookIdentifiersToImages[book.identifier];
    if(!image) {
//      NSDictionary *infodict = @{@"title":book.title, @"identifier":book.identifier};
      NYPLLOG_F(@"Did not receive cover for '%@'.", book.title);
    }
    [button setImage:(image ? image : [UIImage imageNamed:@"NoCover"])
            forState:UIControlStateNormal];
    if (@available(iOS 11.0, *)) {
      button.accessibilityIgnoresInvertColors = YES;
    }
    [button addTarget:self
               action:@selector(didSelectBookButton:)
     forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    [buttons addObject:button];
    button.accessibilityLabel = book.title;
    [self.scrollView addSubview:button];
    if ([book defaultBookContentType] == NYPLBookContentTypeAudiobook) {
      NYPLContentBadgeImageView *badge = [[NYPLContentBadgeImageView alloc] initWithBadgeImage:NYPLBadgeImageAudiobook];
      [NYPLContentBadgeImageView pinWithBadge:badge toView:button];
      button.accessibilityLabel = [@"Audiobook: " stringByAppendingString:book.title];
    }
  }];
  
  self.buttons = buttons;
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const padding = 10.0;
  
  CGFloat x = padding;
  CGFloat const height = CGRectGetHeight(self.contentView.frame);
  
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
