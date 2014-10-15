@import XCTest;

#import "NYPLKeychain.h"

@interface NYPLKeychainTests : XCTestCase

@end

@implementation NYPLKeychainTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)test0
{
  [[NYPLKeychain sharedKeychain] setObject:@"foo" forKey:@"D5AAFADD-E036-4CA6-BBC7-B5962455831D"];
  XCTAssertEqualObjects(@"foo",
                        [[NYPLKeychain sharedKeychain]
                         objectForKey:@"D5AAFADD-E036-4CA6-BBC7-B5962455831D"]);

  [[NYPLKeychain sharedKeychain] setObject:@"bar" forKey:@"D5AAFADD-E036-4CA6-BBC7-B5962455831D"];
  XCTAssertEqualObjects(@"bar",
                        [[NYPLKeychain sharedKeychain]
                         objectForKey:@"D5AAFADD-E036-4CA6-BBC7-B5962455831D"]);

  [[NYPLKeychain sharedKeychain] setObject:@"baz" forKey:@"7D6F207E-9D04-4EE8-9D96-6E07777376C0"];
  XCTAssertEqualObjects(@"baz",
                        [[NYPLKeychain sharedKeychain]
                         objectForKey:@"7D6F207E-9D04-4EE8-9D96-6E07777376C0"]);

  XCTAssertEqualObjects(@"bar",
                        [[NYPLKeychain sharedKeychain]
                         objectForKey:@"D5AAFADD-E036-4CA6-BBC7-B5962455831D"]);

  [[NYPLKeychain sharedKeychain] removeObjectForKey:@"D5AAFADD-E036-4CA6-BBC7-B5962455831D"];
  XCTAssertNil([[NYPLKeychain sharedKeychain]
                objectForKey:@"D5AAFADD-E036-4CA6-BBC7-B5962455831D"]);
  
  XCTAssertEqualObjects(@"baz",
                        [[NYPLKeychain sharedKeychain]
                         objectForKey:@"7D6F207E-9D04-4EE8-9D96-6E07777376C0"]);
  
  [[NYPLKeychain sharedKeychain] removeObjectForKey:@"7D6F207E-9D04-4EE8-9D96-6E07777376C0"];
  XCTAssertNil([[NYPLKeychain sharedKeychain]
                objectForKey:@"7D6F207E-9D04-4EE8-9D96-6E07777376C0"]);
}

@end
