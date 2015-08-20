#import <XCTest/XCTest.h>

#import "NYPLQueue.h"

@interface NYPLQueueTests : XCTestCase

@property (nonatomic) id object0;
@property (nonatomic) id object1;
@property (nonatomic) id object2;

@end

@implementation NYPLQueueTests

- (void)setUp
{
  self.object0 = [[NSObject alloc] init];
  self.object1 = [[NSObject alloc] init];
  self.object2 = [[NSObject alloc] init];
}

- (void)testInitiallyEmpty
{
  NYPLQueue *const queue = [NYPLQueue queue];
  
  XCTAssertEqual(queue.count, 0U);
}

- (void)testCounts
{
  NYPLQueue *const queue = [NYPLQueue queue];
  
  [queue enqueue:self.object0];
  XCTAssertEqual(queue.count, 1U);
  
  [queue enqueue:self.object1];
  XCTAssertEqual(queue.count, 2U);
  
  [queue enqueue:self.object2];
  XCTAssertEqual(queue.count, 3U);
  
  [queue dequeue];
  XCTAssertEqual(queue.count, 2U);
  
  [queue dequeue];
  XCTAssertEqual(queue.count, 1U);
  
  [queue dequeue];
  XCTAssertEqual(queue.count, 0U);
}

- (void)testEmptyDequeue
{
  XCTAssertNil([[NYPLQueue queue] dequeue]);
}

- (void)testFIFO
{
  NYPLQueue *const queue = [NYPLQueue queue];
  
  [queue enqueue:self.object0];
  [queue enqueue:self.object1];
  [queue enqueue:self.object2];
  
  XCTAssertEqual([queue dequeue], self.object0);
  XCTAssertEqual([queue dequeue], self.object1);
  XCTAssertEqual([queue dequeue], self.object2);
}

@end
