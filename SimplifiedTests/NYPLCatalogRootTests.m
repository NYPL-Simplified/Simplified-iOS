#import <XCTest/XCTest.h>

#import "NYPLCatalogRoot.h"
#import "NYPLConfiguration.h"

@interface NYPLCatalogRootTests : XCTestCase

@property (nonatomic) NYPLCatalogRoot *root;

@end

@implementation NYPLCatalogRootTests

- (void)setUp
{
  [super setUp];
  
  NSCondition *const condition = [[NSCondition alloc] init];
  __block volatile BOOL ready = NO;
  
  [NYPLCatalogRoot
   withURL:[NYPLConfiguration mainFeedURL]
   handler:^(NYPLCatalogRoot *const root) {
     self.root = root;
     [condition lock];
     ready = YES;
     [condition signal];
     [condition unlock];
   }];

  [condition lock];
  
  while(!ready) {
    [condition wait];
  }

  [condition unlock];
}

- (void)tearDown
{
  self.root = nil;
}

- (void)testLaneCount
{
  XCTAssertEqual(self.root.lanes.count, 19U);
}

@end
