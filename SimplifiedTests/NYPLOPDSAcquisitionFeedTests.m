#import <SMXMLDocument/SMXMLDocument.h>
#import <XCTest/XCTest.h>

#import "NSDate+NYPLDateAdditions.h"
#import "NYPLOPDSAcquisitionFeed.h"

@interface NYPLOPDSAcquisitionFeedTests : XCTestCase

@property (nonatomic) NYPLOPDSAcquisitionFeed *acquisitionFeed;

@end

@implementation NYPLOPDSAcquisitionFeedTests

- (void)setUp
{
  [super setUp];
  
  NSData *data = [NSData dataWithContentsOfFile:
                  [[NSBundle mainBundle] pathForResource:@"main" ofType:@"xml"]];
  
  SMXMLDocument *document = [SMXMLDocument documentWithData:data error:NULL];
  assert(document);
  
  self.acquisitionFeed = [[NYPLOPDSAcquisitionFeed alloc] initWithDocument:document];
  assert(self.acquisitionFeed);
}

- (void)tearDown
{
  [super tearDown];
  
  self.acquisitionFeed = nil;
}

- (void)testIdentifier
{
  XCTAssertEqualObjects(self.acquisitionFeed.identifier, @"http://localhost/main");
}

- (void)testTitle
{
  XCTAssertEqualObjects(self.acquisitionFeed.title, @"The Big Front Page");
}

- (void)testUpdated
{
  NSDate *date = self.acquisitionFeed.updated;
  
  XCTAssert(date);
  
  NSDateComponents *dateComponents = [date UTCComponents];

  XCTAssertEqual(dateComponents.year, 2014);
  XCTAssertEqual(dateComponents.month, 6);
  XCTAssertEqual(dateComponents.day, 2);
  XCTAssertEqual(dateComponents.hour, 16);
  XCTAssertEqual(dateComponents.minute, 59);
  XCTAssertEqual(dateComponents.second, 57);
}

@end
