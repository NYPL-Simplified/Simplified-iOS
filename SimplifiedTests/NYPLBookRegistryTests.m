#import <XCTest/XCTest.h>

#import "NYPLBookRegistry.h"

@interface NYPLBookRegistryTests : XCTestCase

@end

@implementation NYPLBookRegistryTests

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
