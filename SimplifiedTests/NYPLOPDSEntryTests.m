@import XCTest;

#import "NSDate+NYPLDateAdditions.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSEntryGroupAttributes.h"
#import "NYPLOPDSFeed.h"
#import "NYPLXML.h"

@interface NYPLOPDSEntryTests : XCTestCase

@property (nonatomic) NYPLOPDSEntry *entry;

@end

@implementation NYPLOPDSEntryTests

- (void)setUp
{
  [super setUp];
  
  NSData *const data = [NSData dataWithContentsOfFile:
                        [[NSBundle bundleForClass:[self class]]
                         pathForResource:@"single_entry"
                         ofType:@"xml"]];
  assert(data);
  
  NYPLXML *const feedXML = [NYPLXML XMLWithData:data];
  assert(feedXML);
  
  NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithXML:feedXML];
  assert(feed);
  
  self.entry = feed.entries[0];
  assert(self.entry);
}

- (void)tearDown
{
  [super tearDown];
  
  self.entry = nil;
}

- (void)testHandlesNilInit
{
  XCTAssertNil([[NYPLOPDSEntry alloc] initWithXML:nil]);
}

- (void)testAuthorStrings
{
  XCTAssertEqual(self.entry.authorStrings.count, 2U);
  XCTAssertEqualObjects(self.entry.authorStrings[0], @"James, Henry");
  XCTAssertEqualObjects(self.entry.authorStrings[1], @"Author, Fictional");
}

- (void)testGroupAttributes
{
  NYPLOPDSEntryGroupAttributes *const attributes = self.entry.groupAttributes;
  XCTAssert(attributes);
  XCTAssertEqualObjects(attributes.href, [NSURL URLWithString:@"http://localhost/group"]);
  XCTAssertEqualObjects(attributes.title, @"Example");
}

- (void)testIdentifier
{
  XCTAssertEqualObjects(self.entry.identifier,
                        @"http://localhost/works/4c87a3af9d312c5fd2d44403efc57e2b");
}

- (void)testLinksPresent
{
  XCTAssert(self.entry.links);
}

- (void)testTitle
{
  XCTAssertEqualObjects(self.entry.title, @"The American");
}

- (void)testUpdated
{
  NSDate *const date = self.entry.updated;
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
