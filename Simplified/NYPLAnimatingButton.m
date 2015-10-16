//
//  NYPLAnimatingButton.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/13/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLAnimatingButton.h"
#import <pop/POP.h>

@implementation NYPLAnimatingButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) setEnabled:(BOOL)enabled animated:(BOOL)animated
{
  if (animated && enabled) {
    CGFloat duration = 0.2;
    POPBasicAnimation *startAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewScaleXY];
    startAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    startAnim.fromValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
    startAnim.toValue = [NSValue valueWithCGPoint:CGPointMake(1.08, 1.08)];
    startAnim.duration = duration;
    startAnim.completionBlock = ^(__attribute__((unused)) POPAnimation *anim, BOOL complete) {
      if (complete) {
        POPSpringAnimation *returnAnim = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        returnAnim.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
        returnAnim.springSpeed = 200.0;
        returnAnim.springBounciness = 100.0;
        [self pop_addAnimation:returnAnim forKey:@"return"];
      }
    };
    [self pop_addAnimation:startAnim forKey:@"scale"];
    
    POPBasicAnimation *colorAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLabelTextColor];
    colorAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    colorAnim.fromValue = [self titleColorForState:UIControlStateDisabled];
    colorAnim.toValue = [self titleColorForState:UIControlStateNormal];
    colorAnim.duration = duration;
    colorAnim.completionBlock = ^(__attribute__((unused)) POPAnimation *anim, BOOL complete) {
      if (complete) {
        [self setEnabled:YES];
      }
    };
    [self.titleLabel pop_addAnimation:colorAnim forKey:@"color"];
  } else {
    [self setEnabled:enabled];
  }
}

@end
