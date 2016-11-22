//
//  NYPLBookTests.m
//  Simplified
//
//  Created by Jerry Horton on 11/21/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

@import XCTest;

#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
#import "NYPLOPDSFeed.h"
#import "NYPLOPDSEntry.h"
#import "NYPLXML.h"

#pragma GCC diagnostic ignored "-Wgnu"

@interface NYPLBookTests : XCTestCase

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NYPLOPDSEntry *entry;

@end

@implementation NYPLBookTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSString *pathString = [[NSBundle bundleForClass:[self class]] pathForResource:@"single_entry" ofType:@"xml"];
    
    NSData *const data = [NSData dataWithContentsOfFile:pathString];
    assert(data);
    
    NYPLXML *const feedXML = [NYPLXML XMLWithData:data];
    assert(feedXML);
    
    NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithXML:feedXML];
    assert(feed);
    
    self.entry = feed.entries[0];
    assert(self.entry);
    
    self.book = [NYPLBook bookWithEntry:self. entry];
    assert(self.book);
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBookAcquisitionEncodeDecode {
    
    NSString *fileName = @"NYPLBookAcquisition.plist";
    NSURL *documentsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                  inDomains:NSUserDomainMask] lastObject];
    NSURL *path = [documentsUrl URLByAppendingPathComponent:fileName];
    NSString *pathString = path.path;
    
    XCTAssertTrue([NSKeyedArchiver archiveRootObject:self.book.acquisition toFile:pathString]);
    
    NYPLBookAcquisition *unArchBookAcquisition = [NSKeyedUnarchiver unarchiveObjectWithFile:pathString];
    
    assert(unArchBookAcquisition);
    
}


- (void)testBookEncodeDecode {
    
    NSString *fileName = @"NYPLBook.plist";
    NSURL *documentsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                            inDomains:NSUserDomainMask] lastObject];
    NSURL *path = [documentsUrl URLByAppendingPathComponent:fileName];
    NSString *pathString = path.path;
    
    XCTAssertTrue([NSKeyedArchiver archiveRootObject:self.book toFile:pathString]);
    
    NYPLBook *unArchBook = [NSKeyedUnarchiver unarchiveObjectWithFile:pathString];
    
    assert(unArchBook);
    
    
}

- (void)testBookDecode {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
