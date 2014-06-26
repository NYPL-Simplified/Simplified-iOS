@import XCTest;

#import <SMXMLDocument/SMXMLDocument.h>

#import "NSDate+NYPLDateAdditions.h"
#import "NYPLOPDSFeed.h"

@interface NYPLOPDSFeedTests : XCTestCase

@property (nonatomic) NYPLOPDSFeed *feed;

@end

@implementation NYPLOPDSFeedTests

- (void)setUp
{
  [super setUp];
  
  NSData *const data =
    [NSData dataWithContentsOfFile:
     [[NSBundle bundleForClass:[self class]] pathForResource:@"main" ofType:@"xml"]];
  assert(data);
  
  SMXMLDocument *const document = [SMXMLDocument documentWithData:data error:NULL];
  assert(document);
  
  self.feed = [[NYPLOPDSFeed alloc] initWithDocument:document];
  assert(self.feed);
}

- (void)tearDown
{
  [super tearDown];
  
  self.feed = nil;
}

- (void)testHandlesNilInit
{
  XCTAssertNil([[NYPLOPDSFeed alloc] initWithDocument:nil]);
}

- (void)testEntriesPresent
{
  XCTAssert(self.feed.entries);
}

- (void)testIdentifier
{
  XCTAssertEqualObjects(self.feed.identifier, @"http://localhost/main");
}

- (void)testLinkCount
{
  XCTAssertEqual(self.feed.links.count, 2U);
}

- (void)testTitle
{
  XCTAssertEqualObjects(self.feed.title, @"The Big Front Page");
}

- (void)testUpdated
{
  NSDate *const date = self.feed.updated;
  XCTAssert(date);
  
  NSDateComponents *const dateComponents = [date UTCComponents];
  XCTAssertEqual(dateComponents.year, 2014);
  XCTAssertEqual(dateComponents.month, 6);
  XCTAssertEqual(dateComponents.day, 2);
  XCTAssertEqual(dateComponents.hour, 16);
  XCTAssertEqual(dateComponents.minute, 59);
  XCTAssertEqual(dateComponents.second, 57);
}

@end
