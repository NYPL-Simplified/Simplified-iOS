#import "NYPLTenPrintCoverView.h"

@interface NYPLTenPrintCoverView (NYPLImageAdditions)

+ (UIImage *)detailImageForBook:(NYPLBook *const)book;
+ (UIImage *)thumbnailImageForBook:(NYPLBook *const)book;

// Must be called on the main thread.
+ (UIImage *)imageForBook:(NYPLBook *const)book withSize:(CGSize)size;

@end
