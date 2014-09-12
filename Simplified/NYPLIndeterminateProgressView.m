#import "NYPLIndeterminateProgressView.h"

@interface NYPLIndeterminateProgressView ()

@property (nonatomic) BOOL animating;
@property (nonatomic) CAReplicatorLayer *replicatorLayer;
@property (nonatomic) CAShapeLayer *stripeShape;

@end

@implementation NYPLIndeterminateProgressView

#pragma mark UIView

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if(!self) return nil;
  
  self.color = [UIColor lightGrayColor];
  self.speedMultiplier = 1.0;
  
  self.clipsToBounds = YES;
  self.layer.transform = CATransform3DMakeScale(1, -1, 1);
  
  return self;
}

- (void)layoutSubviews
{
  [self.replicatorLayer removeFromSuperlayer];
  [self setup];
}

#pragma mark -

- (void)setColor:(UIColor *const)color
{
  _color = color;
  
  [self setNeedsLayout];
}

- (void)setSpeedMultiplier:(CGFloat const)speedMultiplier
{
  _speedMultiplier = speedMultiplier;
  
  [self setNeedsLayout];
}

- (void)startAnimating
{
  self.animating = YES;
  
  [self setNeedsLayout];
}

- (void)stopAnimating
{
  self.animating = NO;
  
  [self setNeedsLayout];
}

- (void)setup
{
  CGFloat const stripeWidth = CGRectGetHeight(self.frame);
  
  self.layer.borderColor = self.color.CGColor;
  
  self.stripeShape = [CAShapeLayer layer];
  self.stripeShape.fillColor = self.color.CGColor;
  self.stripeShape.frame = CGRectMake(0,
                                      0,
                                      CGRectGetHeight(self.bounds) * 2,
                                      CGRectGetHeight(self.bounds));
  
  {
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, stripeWidth, 0);
    CGPathAddLineToPoint(path, NULL, stripeWidth * 2, stripeWidth);
    CGPathAddLineToPoint(path, NULL, stripeWidth, stripeWidth);
    
    self.stripeShape.path = path;
    
    CFRelease(path);
  }
  
  self.replicatorLayer = [CAReplicatorLayer layer];
  self.replicatorLayer.frame = self.bounds;
  self.replicatorLayer.instanceCount =
    ceil(CGRectGetWidth(self.frame) / (CGRectGetHeight(self.frame) * 2)) + 1;
  self.replicatorLayer.instanceTransform = CATransform3DMakeTranslation(stripeWidth * 2, 0, 0);
  [self.replicatorLayer addSublayer:self.stripeShape];
  
  if(self.animating) {
    CABasicAnimation *const animation =
      [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.fromValue = @0;
    animation.toValue = @(CGRectGetHeight(self.frame) * -2);
    animation.repeatCount = INFINITY;
    animation.duration = stripeWidth * 0.025 * (1.0 / self.speedMultiplier);
    [self.replicatorLayer addAnimation:animation forKey:nil];
  }
  
  [self.layer addSublayer:self.replicatorLayer];
}

@end
