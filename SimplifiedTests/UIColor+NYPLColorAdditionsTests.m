#import "UIColor+NYPLColorAdditions.h"

#import <XCTest/XCTest.h>

@interface UIColor_NYPLColorAdditionsTests : XCTestCase

@end

@implementation UIColor_NYPLColorAdditionsTests

- (void)test
{
  UIColor *const color = [UIColor colorWithRed:0.65 green:0.23 blue:0.8 alpha:0.4];
  
  XCTAssertEqualObjects([color javascriptHexString], @"#A63BCC");
}

@end
