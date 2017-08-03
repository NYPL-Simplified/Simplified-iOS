#import "NYPLTenPrintCoverView.h"

@interface NYPLTenPrintCoverView (NYPLImageAdditions)

// These functions must be called on the main thread.
+ (UIImage *)detailImageForBook:(NYPLBook *const)book;
+ (UIImage *)thumbnailImageForBook:(NYPLBook *const)book;
+ (UIImage *)imageForBook:(NYPLBook *const)book withSize:(CGSize)size;

@end
