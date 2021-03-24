#import "NYPLTenPrintCoverView.h"

@interface NYPLTenPrintCoverView (NYPLImageAdditions)

// Must be called on the main thread.
+ (UIImage *)imageForBook:(NYPLBook *const)book;

@end
