#import "NYPLLinearView.h"

@interface NYPLLinearView ()

@property (nonatomic) CGFloat minimumRequiredHeight;
@property (nonatomic) CGFloat minimumRequiredWidth;

@end

@implementation NYPLLinearView

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat x = 0.0;
  
  for(UIView *const view in self.subviews) {
    CGFloat const w = CGRectGetWidth(view.frame);
    CGFloat const h = CGRectGetHeight(view.frame);
    CGFloat y;
    switch(self.contentVerticalAlignment) {
      case NYPLLinearViewContentVerticalAlignmentTop:
        y = 0;
        break;
      case NYPLLinearViewContentVerticalAlignmentMiddle:
        y = round((CGRectGetHeight(self.frame) - h) / 2.0);
        break;
      case NYPLLinearViewContentVerticalAlignmentBottom:
        y = CGRectGetHeight(self.frame) - h;
        break;
    }
    view.frame = CGRectMake(x, y, w, h);
    self.minimumRequiredWidth = x + w;
    self.minimumRequiredHeight = h > self.minimumRequiredHeight ? h : self.minimumRequiredHeight;
    x += w + self.padding;
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  [self layoutIfNeeded];
  
  CGFloat const w = self.minimumRequiredWidth;
  CGFloat const h = self.minimumRequiredHeight;
  
  if(CGSizeEqualToSize(size, CGSizeZero)) {
    return CGSizeMake(w, h);
  }
  
  return CGSizeMake(w > size.width ? size.width : w, h > size.height ? size.height : h);
}

#pragma mark -

- (void)setContentVerticalAlignment:
(NYPLLinearViewContentVerticalAlignment const)contentVerticalAlignment
{
  _contentVerticalAlignment = contentVerticalAlignment;
  
  [self setNeedsLayout];
}

- (void)setPadding:(CGFloat const)padding
{
  _padding = padding;
  
  [self setNeedsLayout];
}

@end
