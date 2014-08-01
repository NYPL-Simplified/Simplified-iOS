#import "NYPLLinearView.h"

@interface NYPLLinearView ()

@property (nonatomic) CGFloat minimumRequiredHeight;
@property (nonatomic) CGFloat minimumRequiredWidth;

@end

@implementation NYPLLinearView

#pragma mark UIView

- (void)layoutSubviews
{
  [self layoutSubviewsNow];
}

- (void)sizeToFit
{
  [self layoutSubviewsNow];
  
  self.frame = CGRectMake(CGRectGetMinX(self.frame),
                          CGRectGetMinY(self.frame),
                          self.minimumRequiredWidth,
                          self.minimumRequiredHeight);
}

- (CGSize)sizeThatFits:(CGSize)size
{
  [self layoutSubviewsNow];
  
  CGFloat const w = self.minimumRequiredWidth;
  CGFloat const h = self.minimumRequiredHeight;
  
  return CGSizeMake(w > size.width ? size.width : w, h > size.height ? size.height : h);
}

#pragma mark -

- (void)setPadding:(CGFloat const)padding
{
  _padding = padding;
  
  [self setNeedsLayout];
}

- (void)layoutSubviewsNow
{
  CGFloat x = 0.0;
  
  for(UIView *const view in self.subviews) {
    CGFloat const w = CGRectGetWidth(view.frame);
    CGFloat const h = CGRectGetHeight(view.frame);
    view.frame = CGRectMake(x, 0, w, h);
    self.minimumRequiredWidth = x + w;
    self.minimumRequiredHeight = h > self.minimumRequiredHeight ? h : self.minimumRequiredHeight;
    x += w + self.padding;
  }
}

@end
