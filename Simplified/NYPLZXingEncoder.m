#import "NYPLZXingEncoder.h"

@implementation NYPLZXingEncoder

+ (UIImage *)encodeWithString:(NSString *)string
                       format:(ZXBarcodeFormat)format
                        width:(int)width
                       height:(int)height
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
    if (result) {
      CGImageRef imageRef = [[ZXImage imageWithMatrix:result] cgimage];
      UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
      if (image) {
        return image;
      } else {
        return nil;
      }
    } else {
      NSString *errorMessage = [error localizedDescription];
      NYPLLOG_F(@"Error encoding barcode string. Description: %@", errorMessage);
      return nil;
    }
  }
  @catch (NSException *exception) {
    NYPLLOG_F(@"Exception thrown during barcode image encoding: %@",exception.name);
    return nil;
  }
}

@end
