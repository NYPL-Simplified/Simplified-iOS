//
//  StringUtilities.m
//  Simplified
//
//  Created by Aferdita Muriqi on 6/20/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

#import "StringUtilities.h"

@implementation StringUtils

NSString * NYPLLocalizedString(NSString * key, NSString * comment) {
  
  NSString * localizedString = NSLocalizedString(key, comment);
  
  if ([localizedString isEqualToString:key]) {
    NSString * path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
    NSBundle * languageBundle = [NSBundle bundleWithPath:path];
    localizedString = [languageBundle localizedStringForKey:key value:comment table:nil];
  }
  
  return localizedString;
}

@end
