#import "NYPLFacetView.h"

#import "NYPLFacetBarView.h"

@interface NYPLFacetBarView ()

@property (nonatomic) NYPLFacetView *facetView;

@end

@implementation NYPLFacetBarView

- (instancetype)initWithOrigin:(CGPoint const)origin width:(CGFloat const)width
{
  CGFloat const borderHeight = 1.0 / [UIScreen mainScreen].scale;
  CGFloat const toolbarHeight = 40;
  
  self = [super initWithFrame:CGRectMake(origin.x, origin.y, width, borderHeight + toolbarHeight)];
  if(!self) return nil;
  
  // This is not really the correct way to use a UIToolbar, but it seems to be the simplest way to
  // get a blur effect that matches that of the navigation bar.
  UIToolbar *const toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,
                                                                         0,
                                                                         width,
                                                                         toolbarHeight)];
  toolbar.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  [self addSubview:toolbar];
  
  self.facetView = [[NYPLFacetView alloc] initWithFrame:toolbar.bounds];
  self.facetView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                     UIViewAutoresizingFlexibleWidth);
  [toolbar addSubview:self.facetView];
  
  CGRect const frame = CGRectMake(0, CGRectGetMaxY(toolbar.frame), width, borderHeight);
  
  UIView *borderView = [[UIView alloc] initWithFrame:frame];
  borderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.9];
  borderView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                 UIViewAutoresizingFlexibleTopMargin);
  [self addSubview:borderView];
  
  return self;
}

@end
