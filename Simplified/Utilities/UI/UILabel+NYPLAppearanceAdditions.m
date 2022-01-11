//
//  UILabel+NYPLAppearanceAdditions.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL. All rights reserved.
//

#import "UILabel+NYPLAppearanceAdditions.h"

@implementation UILabel (NYPLAppearanceAdditions)

- (NSString *)fontName
{
  return self.font.fontName;
}

- (void)setFontName:(NSString *)fontName
{
  UIFont *currentFont = self.font;
  CGFloat fontSize = currentFont.pointSize;
  UIFont *newFont = [UIFont fontWithName:fontName size:fontSize];
  self.font = newFont;
}

@end
