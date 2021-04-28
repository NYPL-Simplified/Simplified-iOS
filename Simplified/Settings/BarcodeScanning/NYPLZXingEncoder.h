#import <Foundation/Foundation.h>

#import <ZXingObjC/ZXBarcodeFormat.h>
@class ZXEncodeHints;

/// The ZXingObj framework encoder throws exceptions, which Swift is not
/// built to handle, so this class wraps the encoding function.
@interface NYPLZXingEncoder : NSObject

+ (UIImage *)encodeWithString:(NSString *)string
                       format:(ZXBarcodeFormat)format
                        width:(int)width
                       height:(int)height
                      library:(NSString *)library
                  encodeHints:(ZXEncodeHints *)hints;

@end
