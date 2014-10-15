@import XCTest;

#import "NYPLMyBooksRegistry.h"

@interface NYPLMyBooksRegistryTests : XCTestCase

@end

@implementation NYPLMyBooksRegistryTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testRegistryDirectory
{
  XCTAssert([[NYPLMyBooksRegistry sharedRegistry] registryDirectory]);
}

@end
