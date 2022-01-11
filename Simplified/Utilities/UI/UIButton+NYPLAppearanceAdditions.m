//
//  UIButton+NYPLAppearanceAdditions.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL. All rights reserved.
//

#import "UIButton+NYPLAppearanceAdditions.h"

@implementation UIButton (NYPLAppearanceAdditions)

- (NSString *)titleFontName
{
  return self.titleLabel.font.fontName;
}

- (void)setTitleFontName:(NSString *)titleFontName
{
  CGFloat fontSize = self.titleLabel.font.pointSize;
  UIFont *newFont = [UIFont fontWithName:titleFontName size:fontSize];
  self.titleLabel.font = newFont;
}

@end
