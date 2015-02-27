@import XCTest;

#import "NYPLBookRegistry.h"

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
  XCTAssert([[NYPLBookRegistry sharedRegistry] registryDirectory]);
}

@end
