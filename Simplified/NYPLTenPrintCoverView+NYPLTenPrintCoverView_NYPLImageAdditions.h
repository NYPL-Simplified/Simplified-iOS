#import "NYPLTenPrintCoverView.h"

@interface NYPLTenPrintCoverView (NYPLTenPrintCoverView_NYPLImageAdditions)

// Must be called on the main thread.
+ (UIImage *)imageForBook:(NYPLBook *const)book;

@end
