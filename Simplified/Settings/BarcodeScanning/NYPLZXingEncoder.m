#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wquoted-include-in-framework-header"
@import ZXingObjC;
#pragma clang diagnostic pop

#import "NYPLZXingEncoder.h"
#import "SimplyE-Swift.h"

@implementation NYPLZXingEncoder

+ (UIImage *)encodeWithString:(NSString *)string
                       format:(ZXBarcodeFormat)format
                        width:(int)width
                       height:(int)height
                      library:(NSString *)library
                  encodeHints:(ZXEncodeHints *)hints
{
  @try {
    NSError *error = nil;
    ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
    ZXBitMatrix* result = [writer encode:string
                                  format:format
                                   width:width
                                  height:height
                                   hints:hints
                                   error:&error];
    if (result && !error) {
      // `[zxImage cgimage]` is garbage after `zxImage` is freed, so we bind it to
      // a variable here to ensure it lives long enough to initialize `image`.
      ZXImage *const zxImage = [ZXImage imageWithMatrix:result];
      UIImage *image = [[UIImage alloc] initWithCGImage:[zxImage cgimage]];
      return image;
    }
      
    NSString *errorMessage = [error localizedDescription];
    NYPLLOG_F(@"Error encoding barcode string. Description: %@", errorMessage);
    return nil;
  }
  @catch (NSException *exception) {
    NYPLLOG_F(@"Exception thrown during barcode image encoding: %@",exception.name);
    if (exception.name && exception.reason) {
      [NYPLErrorLogger logBarcodeException:exception library:library];
    }
    return nil;
  }
}

@end
