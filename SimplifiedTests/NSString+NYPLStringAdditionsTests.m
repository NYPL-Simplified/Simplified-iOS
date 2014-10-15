@import XCTest;

#import "NSString+NYPLStringAdditions.h"

@interface NSString_NYPLStringAdditionsTests : XCTestCase

@end

@implementation NSString_NYPLStringAdditionsTests

- (void)testEncode
{
  NSString *const s = [@"ynJZEsWMnTudEGg646Tmua"
                       fileSystemSafeBase64EncodedStringUsingEncoding:NSUTF8StringEncoding];
  
  XCTAssertEqualObjects(s, @"eW5KWkVzV01uVHVkRUdnNjQ2VG11YQ");
}

- (void)testDecode
{
  NSString *const s = [@"eW5KWkVzV01uVHVkRUdnNjQ2VG11YQ"
                       fileSystemSafeBase64DecodedStringUsingEncoding:NSUTF8StringEncoding];
  
  XCTAssertEqualObjects(s, @"ynJZEsWMnTudEGg646Tmua");
}

@end
