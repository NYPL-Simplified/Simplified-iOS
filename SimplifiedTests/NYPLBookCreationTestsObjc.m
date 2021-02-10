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
  // These are the minimum requirements for the `initWithDictionary`
  // initializer to create a non-nil NYPLBook instance. With this initializer
  // it's possible to create a book without acquisitions...
  NYPLBook *book = [[NYPLBook alloc] initWithDictionary:@{
    @"categories" : @[@"Fantasy"],
    @"id": @"666",
    @"title": @"The Lord of the Rings",
    @"updated": @"2020-09-08T09:22:45Z"
  }];
  XCTAssertNotNil(book);

  // ...but the member-wise initializer (used by `bookWithMetadataFromBook:`)
  // doesn't allow that. This assertion ensures that the `nonnull` qualifier for
  // `bookWithMetadataFromBook:` is therefore respected.
  XCTAssertThrows([book bookWithMetadataFromBook:book]);
}

@end
