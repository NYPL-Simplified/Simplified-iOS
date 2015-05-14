@import XCTest;

#import "NSString+NYPLStringAdditions.h"

@interface NSString_NYPLStringAdditionsTests : XCTestCase

@end

@implementation NSString_NYPLStringAdditionsTests

- (void)testBase64Encode
{
  NSString *const s = [@"ynJZEsWMnTudEGg646Tmua"
                       fileSystemSafeBase64EncodedStringUsingEncoding:NSUTF8StringEncoding];
  
  XCTAssertEqualObjects(s, @"eW5KWkVzV01uVHVkRUdnNjQ2VG11YQ");
}

- (void)testBase64Decode
{
  NSString *const s = [@"eW5KWkVzV01uVHVkRUdnNjQ2VG11YQ"
                       fileSystemSafeBase64DecodedStringUsingEncoding:NSUTF8StringEncoding];
  
  XCTAssertEqualObjects(s, @"ynJZEsWMnTudEGg646Tmua");
}

- (void)testSHA256
{
  XCTAssertEqualObjects([@"967824¬Ó¨⁄€™®©♟♞♝♜♛♚♙♘♗♖♕♔" SHA256],
                        @"269b80eff0cd705e4b1de9fdbb2e1b0bccf30e6124cdc3487e8d74620eedf254");
}

@end
