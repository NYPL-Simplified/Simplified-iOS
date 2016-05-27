//
//  NYPLValidatingTextField.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLValidatingTextField.h"

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

- (void)setValid:(BOOL)valid
{
  if (_valid != valid) {
    _valid = valid;
  }
}

- (void) validate
{
  if (self.validator)
    _valid = self.validator();
}

@end
