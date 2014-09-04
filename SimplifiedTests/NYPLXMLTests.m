@import XCTest;

#import "NYPLXML.h"

@interface NYPLXMLTests : XCTestCase

@property (nonatomic) NYPLXML *XML;

@end

@implementation NYPLXMLTests

- (void)testValid
{
  NYPLXML *const root = [NYPLXML XMLWithData:[NSData dataWithContentsOfURL:
                                              [[NSBundle bundleForClass:[self class]]
                                               URLForResource:@"valid"
                                               withExtension:@"xml"]]];
  XCTAssert(root);
  
  XCTAssertEqualObjects(root.attributes, @{});
  XCTAssertEqual(root.children.count, 3U);
  XCTAssertEqualObjects(root.name, @"foo");
  XCTAssertEqualObjects(root.namespaceURI, @"http://example.com");
  XCTAssertNil(root.parent);
  XCTAssertEqualObjects(root.qualifiedName, @"ex:foo");
  XCTAssertNotNil(root.value);
  
  NYPLXML *const bar0 = root.children[0];
  XCTAssertEqualObjects(bar0.attributes, @{});
  XCTAssertNotNil(bar0.children);
  XCTAssertEqual(bar0.children.count, 0U);
  XCTAssertEqualObjects(bar0.name, @"bar");
  XCTAssertEqualObjects(bar0.namespaceURI, @"");
  XCTAssertEqualObjects(bar0.parent, root);
  XCTAssertEqualObjects(bar0.qualifiedName, @"bar");
  XCTAssertEqualObjects(bar0.value, @"\n    42\n  ");
  
  NYPLXML *const bar1 = root.children[1];
  NSDictionary *const bar1Attributes = @{@"a": @"hello", @"b": @"goodbye"};
  XCTAssertEqualObjects(bar1.attributes, bar1Attributes);
  XCTAssertNotNil(bar1.children);
  XCTAssertEqual(bar1.children.count, 0U);
  XCTAssertEqualObjects(bar1.name, @"bar");
  XCTAssertEqualObjects(bar1.namespaceURI, @"");
  XCTAssertEqualObjects(bar1.parent, root);
  XCTAssertEqualObjects(bar1.qualifiedName, @"bar");
  XCTAssertEqualObjects(bar1.value, @"100");
  
  NYPLXML *const baz = root.children[2];
  XCTAssertEqualObjects(baz.attributes, @{});
  XCTAssertEqual(baz.children.count, 2U);
  XCTAssertEqualObjects(baz.name, @"baz");
  XCTAssertEqualObjects(baz.namespaceURI, @"");
  XCTAssertEqualObjects(baz.parent, root);
  XCTAssertEqualObjects(baz.qualifiedName, @"baz");
  XCTAssertEqualObjects(baz.value, @"\n    one\n    \n    two\n    \n  ");
  
  NYPLXML *const quux0 = baz.children[0];
  XCTAssertEqualObjects(quux0.attributes, @{});
  XCTAssertNotNil(quux0.children);
  XCTAssertEqual(quux0.children.count, 0U);
  XCTAssertEqualObjects(quux0.name, @"quux");
  XCTAssertEqualObjects(quux0.namespaceURI, @"");
  XCTAssertEqualObjects(quux0.parent, baz);
  XCTAssertEqualObjects(quux0.qualifiedName, @"quux");
  XCTAssertEqualObjects(quux0.value, @"");
  
  NYPLXML *const quux1 = baz.children[1];
  XCTAssertEqualObjects(quux1.attributes, @{});
  XCTAssertNotNil(quux1.children);
  XCTAssertEqual(quux1.children.count, 0U);
  XCTAssertEqualObjects(quux1.name, @"quux");
  XCTAssertEqualObjects(quux1.namespaceURI, @"");
  XCTAssertEqualObjects(quux1.parent, baz);
  XCTAssertEqualObjects(quux1.qualifiedName, @"quux");
  XCTAssertEqualObjects(quux1.value, @"\n      three\n    ");
  
  NSArray *const bars = @[bar0, bar1];
  NSArray *const quuxes = @[quux0, quux1];
  XCTAssertEqualObjects([root childrenWithName:@"bar"], bars);
  XCTAssertEqualObjects([root childrenWithName:@"baz"], @[baz]);
  XCTAssertEqualObjects([root childrenWithName:@"quux"], @[]);
  XCTAssertEqualObjects([root childrenWithName:nil], @[]);
  XCTAssertEqualObjects([baz childrenWithName:@"quux"], quuxes);
  XCTAssertEqualObjects([baz childrenWithName:@"glor"], @[]);
  XCTAssertEqualObjects([baz childrenWithName:nil], @[]);
}

- (void)testInvalid
{
  NYPLXML *const root = [NYPLXML XMLWithData:[NSData dataWithContentsOfURL:
                                              [[NSBundle bundleForClass:[self class]]
                                               URLForResource:@"invalid"
                                               withExtension:@"xml"]]];
  XCTAssertNil(root);
}

- (void)testNoData
{
  NYPLXML *const root = [NYPLXML XMLWithData:nil];
  XCTAssertNil(root);
}

@end