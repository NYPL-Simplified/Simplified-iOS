#import <XCTest/XCTest.h>

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
  NSDate *date = [NSDate dateWithRFC3339:@"not a valid date"];
  XCTAssertNil(date);
}

- (void)testCanHandleNilArgument
{
  XCTAssertFalse([NSDate dateWithRFC3339:nil]);
}

- (void)testDateParsesCorrectly
{
  NSDate *date = [NSDate dateWithRFC3339:@"1984-09-08T08:23:45Z"];
  
  XCTAssert(date);
  
  NSDateComponents *dateComponents = [date UTCComponents];
  
  XCTAssertEqual(dateComponents.year, 1984);
  XCTAssertEqual(dateComponents.month, 9);
  XCTAssertEqual(dateComponents.day, 8);
  XCTAssertEqual(dateComponents.hour, 8);
  XCTAssertEqual(dateComponents.minute, 23);
  XCTAssertEqual(dateComponents.second, 45);
}

- (void)testDateWithFractionalSecondsParsesCorrectly
{
  NSDate *date = [NSDate dateWithRFC3339:@"1984-09-08T08:23:45.99Z"];
  
  XCTAssert(date);
  
  NSDateComponents *dateComponents = [date UTCComponents];
  
  XCTAssertEqual(dateComponents.year, 1984);
  XCTAssertEqual(dateComponents.month, 9);
  XCTAssertEqual(dateComponents.day, 8);
  XCTAssertEqual(dateComponents.hour, 8);
  XCTAssertEqual(dateComponents.minute, 23);
  XCTAssertEqual(dateComponents.second, 45);
}

@end
