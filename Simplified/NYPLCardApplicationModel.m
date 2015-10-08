//
//  NYPLCardApplicationModel.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationModel.h"

#define kNYPLCardApplicationModel     @"CardApplicationModel"
#define kNYPLCardApplicationDOB       @"DateOfBirth"
#define kNYPLCardApplicaitonInNYState @"IsInNYState"

@implementation NYPLCardApplicationModel
- (id) initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    self.error = NYPLCardApplicationNoError;
    self.dob = (NSDate *) [aDecoder decodeObjectForKey:kNYPLCardApplicationDOB];
    self.isInNYState = [aDecoder decodeBoolForKey:kNYPLCardApplicaitonInNYState];
  }
  return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:self.dob forKey:kNYPLCardApplicationDOB];
  [aCoder encodeBool:self.isInNYState forKey:kNYPLCardApplicaitonInNYState];
}

- (NSURL *) apiURL
{
  return [NSURL URLWithString:@"https://simplifiedcard.herokuapp.com/"];
}

@end
