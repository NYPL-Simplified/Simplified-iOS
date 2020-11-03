//
//  NYPLBookCreationTestsObjc.m
//  Simplified
//
//  Created by Ettore Pasquini on 10/28/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

@import XCTest;

#import "NYPLBook.h"

@interface NYPLBookCreationTestsObjc : XCTestCase

@end

@implementation NYPLBookCreationTestsObjc

- (void)testBookCreationFromBookDoesNotCreateInstance
{
  // it's possible to create a book without acquisitions from the dictionary
  // initializer...
  NYPLBook *book = [[NYPLBook alloc] initWithDictionary:@{
    @"categories" : @[@"Fantasy"],
    @"id": @"666",
    @"title": @"The Lord of the Rings",
    @"updated": @"2020-09-08T09:22:45Z"
  }];

  // ...but the member-wise initializer (used by `bookWithMetadataFromBook:`)
  // does not allow that. This ensures that the `nonnull` qualifier for
  // `bookWithMetadataFromBook:` is therefore respected.
  XCTAssertThrows([book bookWithMetadataFromBook:book]);
}

@end
