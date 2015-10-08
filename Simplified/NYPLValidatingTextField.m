//
//  NYPLValidatingTextField.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLValidatingTextField.h"
#import "pop/POP.h"

@implementation NYPLValidatingTextField

- (void) sharedInit
{
  _valid = YES;
  self.clipsToBounds = NO;
  self.layer.masksToBounds = NO;
  self.layer.cornerRadius = 4.0;
  self.layer.borderColor = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0].CGColor;
}

- (id) init
{
  self = [super init];
  if (self) {
    [self sharedInit];
  }
  return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self sharedInit];
  }
  return self;
}

- (id) initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self sharedInit];
  }
  return self;
}

- (void) animateForValidity
{
  if (self.valid) {
    POPBasicAnimation *borderWidthAnimation = [POPBasicAnimation easeOutAnimation];
    borderWidthAnimation.property = [POPAnimatableProperty propertyWithName:@"borderWidth"];
    borderWidthAnimation.toValue = @(0.0);
    
    POPBasicAnimation *borderColorAnimation = [POPBasicAnimation easeOutAnimation];
    borderColorAnimation.property = [POPAnimatableProperty propertyWithName:@"borderColor"];
    borderColorAnimation.toValue = (__bridge id)([UIColor colorWithRed:1.0 green:0 blue:0 alpha:0].CGColor);
    
    [self.layer pop_addAnimation:borderWidthAnimation forKey:nil];
    [self.layer pop_addAnimation:borderColorAnimation forKey:nil];
    
  } else {
    
    POPSpringAnimation *borderWidthAnimation = [POPSpringAnimation animationWithPropertyNamed:@"borderWidth"];
    borderWidthAnimation.fromValue = @(8.0);
    borderWidthAnimation.toValue = @(2.0);
    
    POPBasicAnimation *borderColorAnimation = [POPBasicAnimation easeInEaseOutAnimation];
    borderColorAnimation.property = [POPAnimatableProperty propertyWithName:@"borderColor"];
    borderColorAnimation.fromValue = (__bridge id)([UIColor colorWithRed:1.0 green:0 blue:0 alpha:0].CGColor);
    borderColorAnimation.toValue = (__bridge id)([UIColor redColor].CGColor);
    
    [self.layer pop_addAnimation:borderWidthAnimation forKey:nil];
    [self.layer pop_addAnimation:borderColorAnimation forKey:nil];
  }
}

- (void)setValid:(BOOL)valid
{
  if (_valid != valid) {
    _valid = valid;
    [self animateForValidity];
  }
}

- (void)validateWithBlock:(BOOL (^)(void))validator
{
  _valid = validator();
  [self animateForValidity];
}

@end
