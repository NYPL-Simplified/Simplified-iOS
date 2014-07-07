@import XCTest;

#import "NSDate+NYPLDateAdditions.h"

@interface NYPLDateAdditionsTests : XCTestCase

@end

@implementation NYPLDateAdditionsTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testInvalidStringReturnsNil
{
  NSDate *const date = [NSDate dateWithRFC3339String:@"not a valid date"];
  XCTAssertNil(date);
}

- (void)testCanHandleNilArgument
{
  XCTAssertFalse([NSDate dateWithRFC3339String:nil]);
}

- (void)testDateParsesCorrectly
{
  NSDate *const date = [NSDate dateWithRFC3339String:@"1984-09-08T08:23:45Z"];
  XCTAssert(date);
  
  NSDateComponents *const dateComponents = [date UTCComponents];
  XCTAssertEqual(dateComponents.year, 1984);
  XCTAssertEqual(dateComponents.month, 9);
  XCTAssertEqual(dateComponents.day, 8);
  XCTAssertEqual(dateComponents.hour, 8);
  XCTAssertEqual(dateComponents.minute, 23);
  XCTAssertEqual(dateComponents.second, 45);
}

- (void)testDateWithFractionalSecondsParsesCorrectly
{
  NSDate *const date = [NSDate dateWithRFC3339String:@"1984-09-08T08:23:45.99Z"];
  XCTAssert(date);
  
  NSDateComponents *const dateComponents = [date UTCComponents];
  XCTAssertEqual(dateComponents.year, 1984);
  XCTAssertEqual(dateComponents.month, 9);
  XCTAssertEqual(dateComponents.day, 8);
  XCTAssertEqual(dateComponents.hour, 8);
  XCTAssertEqual(dateComponents.minute, 23);
  XCTAssertEqual(dateComponents.second, 45);
}

- (void)testDateRoundTrip
{
  NSDate *const date = [NSDate dateWithRFC3339String:@"1984-09-08T10:23:45+0200"];
  XCTAssert(date);
  
  NSString *const string = [date RFC3339String];
  XCTAssert(string);
  
  XCTAssertEqualObjects(string, @"1984-09-08T08:23:45Z");
}

@end
