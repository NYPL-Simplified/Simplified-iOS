#import <XCTest/XCTest.h>

#import "NYPLOPDSAcquisitionFeed.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSLink.h"

@interface NYPLOPDSLinkTests : XCTestCase

@property (nonatomic) NSArray *links;

@end

@implementation NYPLOPDSLinkTests

- (void)setUp
{
  [super setUp];
  
  NSData *data = [NSData dataWithContentsOfFile:
                  [[NSBundle bundleForClass:[self class]]
                   pathForResource:@"single_entry"
                   ofType:@"xml"]];
  assert(data);
  
  SMXMLDocument *document = [SMXMLDocument documentWithData:data error:NULL];
  assert(document);
  
  NYPLOPDSAcquisitionFeed *acquisitionFeed =
    [[NYPLOPDSAcquisitionFeed alloc] initWithDocument:document];
  assert(acquisitionFeed);
  
  self.links = ((NYPLOPDSEntry *) acquisitionFeed.entries[0]).links;
  assert(self.links);
}

- (void)tearDown
{
  [super tearDown];
  
  self.links = nil;
}

- (void)testCount
{
  XCTAssertEqual(self.links.count, 5);
}

- (void)testLink0
{
  NYPLOPDSLink *link = self.links[0];
  XCTAssertEqualObjects(link.href, [NSURL URLWithString:
                                    @"http://localhost/works/4c87a3af9d312c5fd2d44403efc57e2b"]);
  XCTAssertNil(link.rel);
  XCTAssertNil(link.type);
  XCTAssertNil(link.hreflang);
  XCTAssertNil(link.title);
  XCTAssertNil(link.length);
}

- (void)testLink1
{
  NYPLOPDSLink *link = self.links[1];
  XCTAssertEqualObjects(link.href, [NSURL URLWithString:
                                    @"http://www.gutenberg.org/ebooks/177.epub.noimages"]);
  XCTAssertEqualObjects(link.rel, @"http://opds-spec.org/acquisition/open-access");
  XCTAssertEqualObjects(link.type, @"application/epub+zip");
  XCTAssertNil(link.hreflang);
  XCTAssertNil(link.title);
  XCTAssertNil(link.length);
}

- (void)testLink2
{
  NYPLOPDSLink *link = self.links[2];
  XCTAssertEqualObjects(link.href, [NSURL URLWithString:
                                    @"http://covers.openlibrary.org/b/id/244619-S.jpg"]);
  XCTAssertEqualObjects(link.rel, @"http://opds-spec.org/image/thumbnail");
  XCTAssertNil(link.type);
  XCTAssertNil(link.hreflang);
  XCTAssertNil(link.title);
  XCTAssertNil(link.length);
}

- (void)testLink3
{
  NYPLOPDSLink *link = self.links[3];
  XCTAssertEqualObjects(link.href, [NSURL URLWithString:
                                    @"http://covers.openlibrary.org/b/id/244619-L.jpg"]);
  XCTAssertEqualObjects(link.rel, @"http://opds-spec.org/image");
  XCTAssertNil(link.type);
  XCTAssertNil(link.hreflang);
  XCTAssertNil(link.title);
  XCTAssertNil(link.length);
}

- (void)testLink4
{
  NYPLOPDSLink *link = self.links[4];
  XCTAssertEqualObjects(link.href, [NSURL URLWithString:@"http://localhost/lanes/Nonfiction"]);
  XCTAssertEqualObjects(link.rel, @"collection");
  XCTAssertNil(link.type);
  XCTAssertNil(link.hreflang);
  XCTAssertEqualObjects(link.title, @"Nonfiction");
  XCTAssertNil(link.length);
}

@end
